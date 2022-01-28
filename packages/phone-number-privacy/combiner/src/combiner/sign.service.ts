import {
  CombinerEndpoint,
  DomainRestrictedSignatureResponse,
  ErrorMessage,
  KEY_VERSION_HEADER,
  SignerEndpoint,
  SignMessageResponseFailure,
  SignMessageResponseSuccess,
  WarningMessage,
} from '@celo/phone-number-privacy-common'
import { Request, Response } from 'express'
import { BLSCryptographyClient } from '../bls/bls-cryptography-client'
import { respondWithError } from '../common/error-utils'
import { OdisConfig, VERSION } from '../config'
import { CombinerService } from './combiner.service'
import { ICombinerInputService } from './input.interface'

// TODO(Alec)
type SignerPnpResponse = SignMessageResponseFailure | SignMessageResponseSuccess

export abstract class SignService extends CombinerService {
  protected blsCryptoClient: BLSCryptographyClient

  public constructor(
    _config: OdisConfig,
    protected endpoint: CombinerEndpoint,
    protected inputService: ICombinerInputService,
    protected blindedMessage: string
  ) {
    super(_config, endpoint, inputService)
    this.blsCryptoClient = new BLSCryptographyClient(this.threshold, this.pubKey, this.polynomial)
  }

  protected async forwardToSigners(request: Request) {
    request.headers[KEY_VERSION_HEADER] = this.keyVersion.toString()
    return super.forwardToSigners(request)
  }

  protected async handleSuccessResponse(
    data: string,
    status: number,
    url: string,
    controller: AbortController
  ): Promise<void> {
    const res = JSON.parse(data)

    const resKeyVersion: number = Number(res.header(KEY_VERSION_HEADER))
    this.logger.info({ resKeyVersion }, 'Signer responded with key version')
    if (resKeyVersion !== this.keyVersion) {
      throw new Error(`Incorrect key version received from signer ${url}`)
    }

    const signature = this.parseSignature(res, url)

    if (!signature) {
      throw new Error(`Signature is missing from signer ${url}`)
    }

    if (this.signerEndpoint === SignerEndpoint.GET_BLINDED_MESSAGE_PARTIAL_SIG) {
      this.responses.push({ url, res, status })
    }

    this.logger.info({ signer: url }, 'Add signature')
    const signatureAdditionStart = Date.now()
    await this.blsCryptoClient.addSignature({ url, signature })
    this.logger.info(
      {
        signer: url,
        hasSufficientSignatures: this.blsCryptoClient.hasSufficientSignatures(),
        additionLatency: Date.now() - signatureAdditionStart,
      },
      'Added signature'
    )
    // Send response immediately once we cross threshold
    // BLS threshold signatures can be combined without all partial signatures
    if (this.blsCryptoClient.hasSufficientSignatures()) {
      try {
        await this.blsCryptoClient.combinePartialBlindedSignatures(this.blindedMessage)
        // Close outstanding requests
        controller.abort()
      } catch {
        // Already logged, continue to collect signatures
      }
    }
  }

  protected async combineSignerResponses(response: Response<any>): Promise<void> {
    this.logResponseDiscrepancies()

    if (this.blsCryptoClient.hasSufficientSignatures()) {
      try {
        const combinedSignature = await this.blsCryptoClient.combinePartialBlindedSignatures(
          this.blindedMessage,
          this.logger
        )
        response.json({ success: true, combinedSignature, version: VERSION })
        return
      } catch {
        // May fail upon combining signatures if too many sigs are invalid
        // Fallback to handleMissingSignatures
      }
    }

    this.handleMissingSignatures(this.getMajorityErrorCode(), response)
  }

  protected abstract logResponseDiscrepancies(): void

  // TODO(Alec)
  private parseSignature(res: any, signerUrl: string): string | undefined {
    if (isPnpSignatureResponse(res, this.endpoint)) {
      if (!res.success) {
        // Continue on failure as long as signature is present to unblock user
        this.logger.error(
          {
            error: res.error,
            signer: signerUrl,
          },
          'Signer responded with error'
        )
      }
      return res.signature
    }
    if (isDomainRestrictedSignatureResponse(res, this.endpoint)) {
      if (!res.success) {
        return undefined
      }
      return res.signature
    }

    throw new Error(`Implementation error. Signature endpoint ${this.endpoint} not recognized`)
  }

  private handleMissingSignatures(majorityErrorCode: number | null, response: Response) {
    if (majorityErrorCode === 403) {
      respondWithError(response, 403, WarningMessage.EXCEEDED_QUOTA, this.logger)
    } else {
      respondWithError(
        response,
        majorityErrorCode || 500,
        ErrorMessage.NOT_ENOUGH_PARTIAL_SIGNATURES,
        this.logger
      )
    }
  }
}

// TODO(Alec)
function isDomainRestrictedSignatureResponse(
  _res: any,
  endpoint: CombinerEndpoint
): _res is DomainRestrictedSignatureResponse {
  return endpoint === CombinerEndpoint.DOMAIN_SIGN
}

// TODO(Alec)
function isPnpSignatureResponse(_res: any, endpoint: CombinerEndpoint): _res is SignerPnpResponse {
  return endpoint === CombinerEndpoint.GET_BLINDED_MESSAGE_SIG
}

import * as fs from 'fs'

const KEY_TO_BE_REPLACED_IN_TEMPLATES = '{TICKER}'

const StableTokenTemplate = `pragma solidity ^0.5.13;

import "./StableToken.sol";

contract StableToken{TICKER} is StableToken {
  \/**
   * @notice Sets initialized == true on implementation contracts.
   * @param test Set to true to skip implementation initialization.
   */
  constructor(bool test) public StableToken(test) {}

  /**
   * @notice Returns the storage, major, minor, and patch version of the contract.
   * @dev This function is overloaded to maintain a distinct version from StableToken.sol.
   * @return The storage, major, minor, and patch version of the contract.
   */
  function getVersionNumber() external pure returns (uint256, uint256, uint256, uint256) {
    return (1, 1, 0, 0);
  }
}
`

const ExchangeTemplate = `pragma solidity ^0.5.13;

import "./Exchange.sol";

contract Exchange{TICKER} is Exchange {
  \/**
   * @notice Sets initialized == true on implementation contracts
   * @param test Set to true to skip implementation initialization
   */
  constructor(bool test) public Exchange(test) {}

  /**
   * @notice Returns the storage, major, minor, and patch version of the contract.
   * @dev This function is overloaded to maintain a distinct version from Exchange.sol.
   * @return The storage, major, minor, and patch version of the contract.
   */
  function getVersionNumber() external pure returns (uint256, uint256, uint256, uint256) {
    return (1, 1, 0, 0);
  }
}
`

const StableTokenProxyTemplate = `pragma solidity ^0.5.13;

import "../../common/Proxy.sol";

/* solhint-disable no-empty-blocks */
contract StableToken{TICKER}Proxy is Proxy {}
`

const ExchangeProxyTemplate = `pragma solidity ^0.5.13;

import "../../common/Proxy.sol";

/* solhint-disable no-empty-blocks */
contract Exchange{TICKER}Proxy is Proxy {}
`

const migrationStableTemplate = `/* tslint:disable:no-console */
import { ensureLeading0x, eqAddress, NULL_ADDRESS } from '@celo/base/lib/address'
import { CeloContractName } from '@celo/protocol/lib/registry-utils'
import {
  deploymentForCoreContract,
  getDeployedProxiedContract,
} from '@celo/protocol/lib/web3-utils'
import { config } from '@celo/protocol/migrationsConfig'
import { toFixed } from '@celo/utils/lib/fixidity'
import {
  FeeCurrencyWhitelistInstance,
  FreezerInstance,
  ReserveInstance,
  SortedOraclesInstance,
  StableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}Instance,
} from 'types'
import Web3 from 'web3'

const truffle = require('@celo/protocol/truffle-config.js')

const initializeArgs = async (): Promise<any[]> => {
  const rate = toFixed(config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.inflationRate)
  return [
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.tokenName,
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.tokenSymbol,
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.decimals,
    config.registry.predeployedProxyAddress,
    rate.toString(),
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.inflationPeriod,
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.initialBalances.addresses,
    config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.initialBalances.values,
    'Exchange[KEY_TO_BE_REPLACED_IN_TEMPLATES}',
  ]
}

// TODO make this general
module.exports = deploymentForCoreContract<StableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}Instance>(
  web3,
  artifacts,
  CeloContractName.StableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES},
  initializeArgs,
  async (stableToken: StableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}Instance, _web3: Web3, networkName: string) => {
    if (config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.frozen) {
      const freezer: FreezerInstance = await getDeployedProxiedContract<FreezerInstance>(
        'Freezer',
        artifacts
      )
      await freezer.freeze(stableToken.address)
    }
    const sortedOracles: SortedOraclesInstance = await getDeployedProxiedContract<SortedOraclesInstance>(
      'SortedOracles',
      artifacts
    )

    for (const oracle of config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.oracles) {
      console.info(\`Adding \${ oracle } as an Oracle for StableToken([KEY_TO_BE_REPLACED_IN_TEMPLATES})\`)
      await sortedOracles.addOracle(stableToken.address, ensureLeading0x(oracle))
    }

    const goldPrice = config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.goldPrice
    if (goldPrice) {
      const fromAddress = truffle.networks[networkName].from
      const isOracle = config.stableToken[KEY_TO_BE_REPLACED_IN_TEMPLATES}.oracles.some((o) => eqAddress(o, fromAddress))
      if (!isOracle) {
        console.warn(
          \`Gold price specified in migration but \${ fromAddress } not explicitly authorized as oracle, authorizing...\`
        )
        await sortedOracles.addOracle(stableToken.address, ensureLeading0x(fromAddress))
      }
      console.info('Reporting price of StableToken ([KEY_TO_BE_REPLACED_IN_TEMPLATES}) to oracle')
      await sortedOracles.report(
        stableToken.address,
        toFixed(goldPrice),
        NULL_ADDRESS,
        NULL_ADDRESS
      )
      const reserve: ReserveInstance = await getDeployedProxiedContract<ReserveInstance>(
        'Reserve',
        artifacts
      )
      console.info('Adding StableToken ([KEY_TO_BE_REPLACED_IN_TEMPLATES}) to Reserve')
      await reserve.addToken(stableToken.address)
    }

    console.info('Whitelisting StableToken ([KEY_TO_BE_REPLACED_IN_TEMPLATES}) as a fee currency')
    const feeCurrencyWhitelist: FeeCurrencyWhitelistInstance = await getDeployedProxiedContract<FeeCurrencyWhitelistInstance>(
      'FeeCurrencyWhitelist',
      artifacts
    )
    await feeCurrencyWhitelist.addToken(stableToken.address)
  }
)
`

const migrationExchangeTemplate = `/* tslint:disable:no-console */

import { CeloContractName } from '@celo/protocol/lib/registry-utils'
import {
  deploymentForCoreContract,
  getDeployedProxiedContract,
} from '@celo/protocol/lib/web3-utils'
import { config } from '@celo/protocol/migrationsConfig'
import { toFixed } from '@celo/utils/lib/fixidity'
import { Exchange{TICKER}Instance, FreezerInstance, ReserveInstance } from 'types'

const initializeArgs = async (): Promise<any[]> => {
  return [
    config.registry.predeployedProxyAddress,
    CeloContractName.StableToken{TICKER},
    toFixed(config.exchange.spread).toString(),
    toFixed(config.exchange.reserveFraction).toString(),
    config.exchange.updateFrequency,
    config.exchange.minimumReports,
  ]
}

module.exports = deploymentForCoreContract<Exchange{TICKER}Instance>(
  web3,
  artifacts,
  CeloContractName.Exchange{TICKER},
  initializeArgs,
  async (exchange: Exchange{TICKER}Instance) => {
    if (config.exchange.frozen) {
      const freezer: FreezerInstance = await getDeployedProxiedContract<FreezerInstance>(
        'Freezer',
        artifacts
      )
      await freezer.freeze(exchange.address)
    }

    const reserve: ReserveInstance = await getDeployedProxiedContract<ReserveInstance>(
      'Reserve',
      artifacts
    )
    // cUSD doesn't need to be added as it is currently harcoded in Reserve.sol
    await reserve.addExchangeSpender(exchange.address)
    await exchange.activateStable()
  }
)
`

function errorFunct(err) {
  if (err) {
    // tslint:disable-next-line: no-console
    return console.log(err)
  }
}

try {
  const argv = require('minimist')(process.argv.slice(2), {
    string: ['stableTokenTicker'],
  })
  const fiatTicker = argv.stableTokenTicker

  const stabilityContractPath = './contracts/stability'
  const stabilityProxyPath = './contracts/stability/proxies'
  const migrationPath = './migrations'

  // contracts
  fs.writeFile(
    `${stabilityContractPath}/StableToken${fiatTicker}.sol`,
    StableTokenTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )
  fs.writeFile(
    `${stabilityContractPath}/Exchange${fiatTicker}.sol`,
    ExchangeTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )

  // proxy
  fs.writeFile(
    `${stabilityProxyPath}/StableToken${fiatTicker}.sol`,
    StableTokenProxyTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )
  fs.writeFile(
    `${stabilityProxyPath}/Exchange${fiatTicker}.sol`,
    ExchangeProxyTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )

  // migration
  fs.writeFile(
    `${migrationPath}/09_999_stableToken_${fiatTicker}.sol`,
    migrationStableTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )
  fs.writeFile(
    `${migrationPath}/10_999_exchange_${fiatTicker}.sol`,
    migrationExchangeTemplate.replace(KEY_TO_BE_REPLACED_IN_TEMPLATES, fiatTicker),
    errorFunct
  )

  // tslint:disable-next-line: no-console
  console.log(`Other thinks that should be updated:
  * Add constitution parameters: packages/protocol/governanceConstitution.js
  * Rename migration with right number: packages/protocol/migrations/09_Y_stableToken_X.ts and packages/protocol/migrations/10_Y_Exchange_X.ts
  * Add keys to migration config: packages/protocol/migrationsConfig.js
  * Add files to the build: packages/protocol/scripts/build.ts
  * Add it to the env tests packages/protocol/test/common/integration.ts
  `)
} catch (e) {
  // tslint:disable-next-line: no-console
  console.error(`Something went wrong: ${e}`)
}
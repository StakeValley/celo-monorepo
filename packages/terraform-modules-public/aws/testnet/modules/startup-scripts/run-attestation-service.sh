#! /bin/bash

export CELO_IMAGE=${celo_image}
export NETWORK_ID=${celo_network_id}
export CELO_VALIDATOR_ADDRESS=${validator_address}
NODE_DIRECTORY=/home/ubuntu/celo-attestations-node

mkdir $NODE_DIRECTORY
mkdir $NODE_DIRECTORY/keystore

cd $NODE_DIRECTORY

export CELO_ATTESTATION_SIGNER_ADDRESS=${attestation_signer_address}

SECRET_ID=${attestation_signer_private_key_arn}
GET_SECRET_VALUE_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID")
KEY_FILENAME=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .filename)
KEY_FILE_CONTENTS=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .file_contents)
KEY_FILE_PASSWORD=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .password)

echo $KEY_FILE_CONTENTS > keystore/$KEY_FILENAME
echo $KEY_FILE_PASSWORD > .password

export CELO_IMAGE_ATTESTATION=${celo_image_attestation}
export CONFIG_FILE_PATH=.attestationconfig

# adapted from https://github.com/StakeValley/celo-monorepo/blob/master/packages/attestation-service/config/.env.development
echo 'DATABASE_URL=${database_url}' >> $CONFIG_FILE_PATH
echo 'CELO_PROVIDERS=https://baklava-forno.celo-testnet.org,http://${proxy_internal_ip}' >> $CONFIG_FILE_PATH
echo 'CELO_VALIDATOR_ADDRESS=0x${validator_address}' >> $CONFIG_FILE_PATH
echo 'ATTESTATION_SIGNER_ADDRESS=0x${attestation_signer_address}' >> $CONFIG_FILE_PATH
echo 'ATTESTATION_SIGNER_KEYSTORE_DIRPATH=/root/.celo' >> $CONFIG_FILE_PATH

# TODO: add twilioverify, nexmo, and messagebird 
echo 'SMS_PROVIDERS=twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_CN=twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_VN=messagebird,twilioverify' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_TR=twilioverify' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_US=twilioverify,messagebird' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_BR=messagebird,twilioverify,twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_IN=messagebird,twilioverify,twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_VE=messagebird,twilioverify,twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_GH=messagebird,twilioverify,twiliomessaging' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_PH=messagebird,twilioverify,twiliomessaging,nexmo' >> $CONFIG_FILE_PATH
# echo 'SMS_PROVIDERS_DE=messagebird,twilioverify,twiliomessaging' >> $CONFIG_FILE_PATH

echo 'PORT=80' >> $CONFIG_FILE_PATH
echo 'RATE_LIMIT_REQS_PER_MIN=100' >> $CONFIG_FILE_PATH

echo 'NEXMO_KEY=${nexmo_api_key}' >> $CONFIG_FILE_PATH
echo 'NEXMO_SECRET=${nexmo_api_secret}' >> $CONFIG_FILE_PATH
echo 'NEXMO_ACCOUNT_BALANCE_METRIC=0' >> $CONFIG_FILE_PATH
echo 'NEXMO_UNSUPPORTED_REGIONS=${nexmo_unsupported_regions}' >> $CONFIG_FILE_PATH

echo 'TWILIO_ACCOUNT_SID=${twilio_account_sid}' >> $CONFIG_FILE_PATH
echo 'TWILIO_MESSAGING_SERVICE_SID=${twilio_messaging_service_sid}' >> $CONFIG_FILE_PATH
echo 'TWILIO_VERIFY_SERVICE_SID=${twilio_verify_service_sid}' >> $CONFIG_FILE_PATH
echo 'TWILIO_AUTH_TOKEN=${twilio_auth_token}' >> $CONFIG_FILE_PATH
echo 'TWILIO_UNSUPPORTED_REGIONS=${twilio_unsupported_regions}' >> $CONFIG_FILE_PATH

echo 'MESSAGEBIRD_API_KEY=${messagebird_api_key}' >> $CONFIG_FILE_PATH
echo 'MESSAGEBIRD_UNSUPPORTED_REGIONS=${messagebird_unsupported_regions}' >> $CONFIG_FILE_PATH

echo 'MAX_DELIVERY_ATTEMPTS=3' >> $CONFIG_FILE_PATH
echo 'MAX_AGE_LATEST_BLOCK_SECS=20' >> $CONFIG_FILE_PATH
echo 'DB_RECORD_EXPIRY_MINS=1440' >> $CONFIG_FILE_PATH
echo 'VERIFY_CONFIG_ON_STARTUP=1' >> $CONFIG_FILE_PATH

echo 'APP_SIGNATURE=${attestation_app_signature}' >> $CONFIG_FILE_PATH

echo 'LOG_FORMAT=json' >> $CONFIG_FILE_PATH
echo 'LOG_LEVEL=info' >> $CONFIG_FILE_PATH

ATTESTATION_SERVICE_CLOUDWATCH_LOG_GROUP_NAME=${cloudwatch_attestation_service_log_group_name}
ATTESTATION_SERVICE_CLOUDWATCH_LOG_STREAM_NAME=${cloudwatch_attestation_service_log_stream_name}

if [[ -z $ATTESTATION_SERVICE_CLOUDWATCH_LOG_GROUP_NAME || -z $ATTESTATION_SERVICE_CLOUDWATCH_LOG_STREAM_NAME ]]; then
  DOCKER_LOGGING_PARAMS=''
else
  DOCKER_LOGGING_PARAMS="--log-driver=awslogs --log-opt awslogs-group=$ATTESTATION_SERVICE_CLOUDWATCH_LOG_GROUP_NAME --log-opt awslogs-stream=$ATTESTATION_SERVICE_CLOUDWATCH_LOG_STREAM_NAME"
fi

docker run -d --name celo-attestation-service $DOCKER_LOGGING_PARAMS --restart always --entrypoint /bin/bash --network host --env-file $CONFIG_FILE_PATH -p 80:80 -v $PWD:/root/.celo $CELO_IMAGE_ATTESTATION -c " cd /celo-monorepo/packages/attestation-service && yarn run db:migrate && yarn start "

#! /bin/bash
CELO_IMAGE=${celo_image}
CELO_VALIDATOR_SIGNER_ADDRESS=${validator_signer_address}

NODE_DIRECTORY=/home/ubuntu/celo-proxy-node

mkdir $NODE_DIRECTORY
mkdir $NODE_DIRECTORY/keystore
cd $NODE_DIRECTORY

PROXY_ADDRESS=${proxy_address}

SECRET_ID=${proxy_account_private_key_arn}
GET_SECRET_VALUE_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ID")
KEY_FILENAME=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .filename)
KEY_FILE_CONTENTS=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .file_contents)
KEY_FILE_PASSWORD=$(echo $GET_SECRET_VALUE_JSON | jq --raw-output '.SecretString' | jq -r .password)

echo $KEY_FILE_CONTENTS > keystore/$KEY_FILENAME
echo $KEY_FILE_PASSWORD > .password

PROXY_ENODE_JSON=$(aws secretsmanager get-secret-value --secret-id "${proxy_enode_private_key_arn}")
PROXY_ENODE_PRIVATE_KEY=$(echo $PROXY_ENODE_JSON | jq --raw-output '.SecretString' | jq -r .privateKey)
echo $PROXY_ENODE_PRIVATE_KEY > .nodekey

CLOUDWATCH_LOG_GROUP_NAME=${cloudwatch_log_group_name}
CLOUDWATCH_LOG_STREAM_NAME=${cloudwatch_log_stream_name}

if [[ -z $CLOUDWATCH_LOG_GROUP_NAME || -z $CLOUDWATCH_LOG_STREAM_NAME ]]; then
  DOCKER_LOGGING_PARAMS=''
else
  DOCKER_LOGGING_PARAMS="--log-driver=awslogs --log-opt awslogs-group=$CLOUDWATCH_LOG_GROUP_NAME --log-opt awslogs-stream=$CLOUDWATCH_LOG_STREAM_NAME"
fi

CHAINDATA_ARCHIVE_URL=${chaindata_archive_url}
if [[ ! -z $CHAINDATA_ARCHIVE_URL ]]; then
  aws s3 cp $CHAINDATA_ARCHIVE_URL celo/chaindataarchive.tar.gz
  tar -zxf celo/chaindataarchive.tar.gz --directory celo
fi

# Adapted from https://docs.celo.org/getting-started/baklava-testnet/running-a-validator-in-baklava#deploy-a-proxy
docker run -d --name celo-proxy $DOCKER_LOGGING_PARAMS --restart unless-stopped -p 30303:30303 -p 30303:30303/udp -p 30503:30503 -p 30503:30503/udp -v $PWD:/root/.celo $CELO_IMAGE --verbosity 3 --syncmode full --nousb  --proxy.proxy --proxy.proxiedvalidatoraddress $CELO_VALIDATOR_SIGNER_ADDRESS --proxy.internalendpoint :30503 --etherbase $PROXY_ADDRESS --unlock $PROXY_ADDRESS --password /root/.celo/.password --allow-insecure-unlock --baklava --datadir /root/.celo --celostats=${validator_name}@${ethstats_host} --nodekey /root/.celo/.nodekey
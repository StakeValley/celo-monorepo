# !/bin/bash
CELO_IMAGE=${celo_image}
CELO_VALIDATOR_SIGNER_ADDRESS=${validator_signer_address}

NETWORK_ID=${celo_network_id}

NODE_DIRECTORY=/home/ubuntu/celo-validator-node

mkdir $NODE_DIRECTORY
mkdir $NODE_DIRECTORY/keystore
cd $NODE_DIRECTORY

PROXY_ENODE=${proxy_enode}
PROXY_INTERNAL_IP=${proxy_internal_ip}
PROXY_EXTERNAL_IP=${proxy_external_ip}

echo -n '${validator_signer_private_key_password}' > .password
echo -n '${validator_signer_private_key_file_contents}' > keystore/${validator_signer_private_key_filename}

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

# Adapted from https://docs.celo.org/getting-started/baklava-testnet/running-a-validator-in-baklava#deploy-a-validator
docker run -d --name celo-validator $DOCKER_LOGGING_PARAMS --restart unless-stopped --stop-timeout 300 -p 30303:30303 -p 30303:30303/udp -v $PWD:/root/.celo $CELO_IMAGE --verbosity 3 --syncmode full --mine --etherbase $CELO_VALIDATOR_SIGNER_ADDRESS --nodiscover --nousb  --proxy.proxied --proxy.proxyenodeurlpair=enode://$PROXY_ENODE@$PROXY_INTERNAL_IP:30503\;enode://$PROXY_ENODE@$PROXY_EXTERNAL_IP:30303 --unlock=$CELO_VALIDATOR_SIGNER_ADDRESS --password /root/.celo/.password --celostats=${validator_name}@${ethstats_host} --baklava --datadir /root/.celo
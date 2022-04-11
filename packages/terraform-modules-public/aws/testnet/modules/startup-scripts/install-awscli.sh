#! /bin/bash

AWSCLI_FOLDER=/tmp/awscli-install
mkdir $AWSCLI_FOLDER
cd $AWSCLI_FOLDER

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
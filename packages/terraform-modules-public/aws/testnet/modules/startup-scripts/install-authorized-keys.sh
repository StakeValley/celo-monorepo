#! /bin/bash

touch /home/ubuntu/.ssh/authorized_keys

%{ for ssh_key in authorized_ssh_keys ~}
  echo "${ssh_key}" >> /home/ubuntu/.ssh/authorized_keys
%{ endfor ~}     

chown ubuntu: /home/ubuntu/.ssh/authorized_keys
chmod 0600 /home/ubuntu/.ssh/authorized_keys
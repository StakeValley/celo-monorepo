module "ami" {
  source = "../ami"
}

resource "aws_instance" "attestation_service" {
  for_each = var.attestation_services

  ami                    = module.ami.ami_ids.ubuntu_latest
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_size = var.volume_size
  }

  user_data = join("\n", [
    templatefile("${path.module}/../startup-scripts/install-authorized-keys.sh", {
      authorized_ssh_keys = var.authorized_ssh_keys
    }),
    file("${path.module}/../startup-scripts/install-base.sh"),
    var.cloudwatch_collect_disk_and_memory_usage ? file("${path.module}/../startup-scripts/install-cloudwatch-agent.sh") : "",
    file("${path.module}/../startup-scripts/install-docker.sh"),
    file("${path.module}/../startup-scripts/install-chrony.sh"),
    file("${path.module}/../startup-scripts/install-postgres-client.sh"),
    templatefile("${path.module}/../startup-scripts/run-attestation-service.sh", {
      validator_address                              = each.value.validator_address
      attestation_app_signature                      = "celo_attestation_service_${each.key}"
      attestation_signer_address                     = each.value.attestation_signer_address
      attestation_signer_private_key_arn             = each.value.attestation_signer_private_key_arn
      proxy_internal_ip                              = each.value.proxy_private_ip
      database_url                                   = var.database_url
      twilio_messaging_service_sid                   = var.twilio_messaging_service_sid
      twilio_verify_service_sid                      = var.twilio_verify_service_sid
      twilio_account_sid                             = var.twilio_account_sid
      twilio_unsupported_regions                     = var.twilio_unsupported_regions
      twilio_auth_token                              = var.twilio_auth_token
      nexmo_api_key                                  = var.nexmo_api_key
      nexmo_api_secret                               = var.nexmo_api_secret
      nexmo_unsupported_regions                      = var.nexmo_unsupported_regions
      messagebird_api_key                            = var.messagebird_api_key
      messagebird_unsupported_regions                = var.messagebird_unsupported_regions
      celo_image                                     = var.celo_image
      celo_network_id                                = var.celo_network_id
      celo_image_attestation                         = var.celo_image_attestation
      cloudwatch_attestation_node_log_group_name     = var.cloudwatch_attestation_node_log_group_name
      cloudwatch_attestation_node_log_stream_name    = "celo_attestation_node_${each.key}"
      cloudwatch_attestation_service_log_group_name  = var.cloudwatch_attestation_service_log_group_name
      cloudwatch_attestation_service_log_stream_name = "celo_attestation_service_${each.key}"
    }),
    file("${path.module}/../startup-scripts/final-hardening.sh")
  ])

  tags = {
    Name = "${var.cluster_name}-attestation-service-${each.value.validator_name}"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

resource "aws_eip" "attestation_service" {
  for_each = var.attestation_services

  instance = aws_instance.attestation_service[each.key].id
  vpc      = true
}

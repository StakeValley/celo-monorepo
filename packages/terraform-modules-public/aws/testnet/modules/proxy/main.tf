module "ami" {
  source = "../ami"
}

resource "aws_instance" "celo_proxy" {
  for_each = var.proxies

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
    var.chaindata_archive_url != "" ? file("${path.module}/../startup-scripts/install-awscli.sh") : "",
    file("${path.module}/../startup-scripts/install-docker.sh"),
    file("${path.module}/../startup-scripts/install-chrony.sh"),
    templatefile("${path.module}/../startup-scripts/run-proxy-node.sh", {
      celo_image                    = var.celo_image
      celo_network_id               = var.celo_network_id
      ethstats_host                 = var.ethstats_host
      validator_name                = each.value.validator_name
      validator_signer_address      = each.value.validator_signer_address
      proxy_address                 = each.value.proxy_address
      proxy_account_private_key_arn = each.value.proxy_account_private_key_arn
      proxy_enode_private_key_arn   = each.value.proxy_enode_private_key_arn
      cloudwatch_log_group_name     = var.cloudwatch_log_group_name
      cloudwatch_log_stream_name    = "celo_proxy_${each.key}"
      chaindata_archive_url         = var.chaindata_archive_url
    }),
    file("${path.module}/../startup-scripts/final-hardening.sh")
  ])

  tags = {
    Name = "${var.cluster_name}-proxy-${each.value.validator_name}"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

resource "aws_eip" "celo_proxy" {
  for_each = var.proxies

  instance = aws_instance.celo_proxy[each.key].id
  vpc      = true
}
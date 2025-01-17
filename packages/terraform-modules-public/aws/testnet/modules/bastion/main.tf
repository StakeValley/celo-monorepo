module "ami" {
  source = "../ami"
}

resource "aws_instance" "bastion" {
  ami                         = module.ami.ami_ids.ubuntu_latest
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    var.security_group_id
  ]
  key_name             = var.key_pair_name
  iam_instance_profile = var.iam_instance_profile

  user_data = join("\n", [
    templatefile("${path.module}/../startup-scripts/install-authorized-keys.sh", {
      authorized_ssh_keys = var.authorized_ssh_keys
    }),
    file("${path.module}/../startup-scripts/install-base.sh"),
    file("${path.module}/../startup-scripts/install-chrony.sh"),
    file("${path.module}/../startup-scripts/configure-bastion.sh"),
    file("${path.module}/../startup-scripts/final-hardening.sh")
  ])

  tags = {
    Name = var.name
  }
}

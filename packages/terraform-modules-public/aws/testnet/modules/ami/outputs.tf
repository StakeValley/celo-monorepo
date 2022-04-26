output "ami_ids" {
  value = {
    ubuntu_latest = data.aws_ami.ubuntu.id
  }
}
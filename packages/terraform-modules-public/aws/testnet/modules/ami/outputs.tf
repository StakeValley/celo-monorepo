output ami_ids {
  value = {
    ubuntu_20_04 = data.aws_ami.ubuntu.id
  }
}
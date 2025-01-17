variable "instance_type" {
  type        = string
  description = "AWS instance type for this node"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to place this proxy. This should be a public subnet from your Celo VPC."
}

variable "security_group_id" {
  type        = string
  description = "VPC Security group for this instance"
}

variable "key_pair_name" {
  type        = string
  description = "Name of the SSH key pair to access this node from the bastion"
}

variable "volume_size" {
  type        = number
  description = "GB size for the EBS volume"
  default     = 256
}

variable "celo_image" {
  type        = string
  description = "Name of the docker image to run"
}

variable "celo_network_id" {
  type        = string
  description = "Celo network ID to join"
}

variable "ethstats_host" {
  type        = string
  description = "Hostname for ethstats"
}

variable "validators" {
  description = "Map of validator configurations"
  type = map(object({
    name                        = string
    signer_address              = string
    signer_private_key_arn      = string
    proxy_enode_private_key_arn = string
    proxy_private_ip            = string
    proxy_public_ip             = string
  }))
}

variable "iam_instance_profile" {
  type    = string
  default = null
}

variable "cloudwatch_log_group_name" {
  type    = string
  default = ""
}

variable "cloudwatch_collect_disk_and_memory_usage" {
  type    = bool
  default = false
}

variable "chaindata_archive_url" {
  type    = string
  default = ""
}

variable "authorized_ssh_keys" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  type        = string
}
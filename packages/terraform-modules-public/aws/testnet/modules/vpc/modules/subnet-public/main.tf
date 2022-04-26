resource "aws_subnet" "public" {
  vpc_id               = var.vpc_id
  cidr_block           = var.cidr_block
  availability_zone_id = var.availability_zone_id

  tags = {
    Name = "celo-public-${var.availability_zone_id}"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "celo-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "celo-nat-gateway-${var.availability_zone_id}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = "celo-public-route-table-${var.availability_zone_id}"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "celo-public-acl-${var.availability_zone_id}"
  }
}

resource "aws_network_acl_rule" "ssh_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  count          = length(var.allowed_ssh_clients_cidr_blocks)
  rule_number    = 100 + count.index
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  cidr_block     = element(var.allowed_ssh_clients_cidr_blocks, count.index)
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "http_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = 110
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "ssl_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = 120
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "celo_tcp_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = 130
  protocol       = "tcp"
  from_port      = 30303
  to_port        = 30303
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "celo_udp_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = 131
  protocol       = "udp"
  from_port      = 30303
  to_port        = 30303
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "nat_ingress" {
  network_acl_id = aws_network_acl.public.id
  egress         = false
  rule_number    = 140
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "wildcard_egress" {
  network_acl_id = aws_network_acl.public.id
  egress         = true
  rule_number    = 200
  protocol       = -1
  to_port        = 0
  from_port      = 0
  cidr_block     = "0.0.0.0/0"
  rule_action    = "allow"
}


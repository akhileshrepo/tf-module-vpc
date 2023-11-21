resource "aws_vpc" "main" {
  cidr_block = var.cidr
}

module "public_subnet_ids" {
  source = "./subnets"
  for_each = var.subnets
  subnets = each.value
  vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route" "igw" {
  for_each = lookup(lookup(module.public_subnet_ids, "public", null), "route_table_ids", null)
  route_table_id         = each.value["id"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "ngw" {
  count = length(local.public_subnet_ids)
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.public_subnet_ids)
  allocation_id = element(aws_eip.ngw.*.id, count.index)
  subnet_id = element(local.public_subnet_ids, count.index)
}

resource "aws_route" "ngw" {
  count = length(local.public_subnet_ids)
  route_table_id = element(local.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.vpc_default_vpc_id
  auto_accept   = true
}

resource "aws_route" "peer" {
  count = length(local.private_route_table_ids)
  route_table_id = element(local.private_route_table_ids, count.index)
  destination_cidr_block = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "default-vpc-peer-entry" {
  route_table_id = var.default_vpc_route_table_id
  destination_cidr_block = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_instance" "main" {
  instance_type = "t2.micro"
  ami = "ami-8874282q8"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = local.app_subnet_ids[0]
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

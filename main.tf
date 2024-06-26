resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags = merge(local.tags, { Name = "${var.env}-vpc" })
}

module "subnets" {
  source = "./subnets"

  for_each = var.subnets
  subnets = each.value
  vpc_id = aws_vpc.main.id
  tags =    local.tags
  env      = var.env
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "${var.env}-igw" })
}

resource "aws_route" "igw" {
  for_each = lookup(lookup(module.subnets, "public", null), "route_table_ids", null)
  route_table_id = each.value["id"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "ngw" {
  count = length(local.public_subnet_ids)
  domain   = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.public_subnet_ids)
  allocation_id = element(aws_eip.ngw.*.id, count.index)
  subnet_id     = element(local.public_subnet_ids, count.index)
  tags = merge(local.tags, { Name = "${var.env}-ngw" })
}

resource "aws_route" "ngw" {
  count                     = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids, count.index)
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id = var.default_vpc_id
  vpc_id      = aws_vpc.main.id
  auto_accept = true
  tags = merge(local.tags, { Name = "${var.env}-peer" })
}

resource "aws_route" "peering" {
  count = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids, count.index)
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "default-vpc-peer-entry" {
  route_table_id            = var.default_route_table_id
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_instance" "main" {
  ami           = "ami-0b4f379183e5706b9"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = local.app_subnet_ids[0]
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow from TLS"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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



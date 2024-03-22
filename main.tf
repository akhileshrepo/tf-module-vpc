resource "aws_vpc" "main" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = "${var.env}-vpc" })
}

module "subnets" {
  source   = "./subnets"
  for_each = var.subnets
  subnets  = each.value
  vpc_id   = aws_vpc.main.id
  tags     = local.tags
  env      = var.env
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${var.env}-igw" })
}

resource "aws_route" "igw" {
  for_each               = lookup(lookup(module.subnets, "public", null), "route_table_ids", null)
  route_table_id         = each.value["id"]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_eip" "ngw" {
  count  = length(local.public_subnet_ids)
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  count         = length(local.public_subnet_ids)
  allocation_id = element(aws_eip.ngw.*.id, count.index)
  subnet_id     = element(local.public_subnet_ids, count.index)
  tags          = merge(local.tags, { Name = "${var.env}-ngw" })
}

resource "aws_route" "ngw" {
  count                  = length(local.private_route_table_ids)
  route_table_id         = element(local.private_route_table_ids, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_vpc_peering_connection" "peering" {
  peer_vpc_id = aws_vpc.main.id
  vpc_id      = var.default_vpc_id
  auto_accept = true
  tags        = merge(local.tags, { Name = "${var.env}-peer" })
}

resource "aws_route" "peer" {
  count                     = length(local.private_route_table_ids)
  route_table_id            = element(local.private_route_table_ids, count.index)
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "default-vpc-peer-entry" {
  route_table_id            = var.default_vpc_route_table_id
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

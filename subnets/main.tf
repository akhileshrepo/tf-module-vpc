resource "aws_subnet" "main" {
  for_each = var.subnets
  vpc_id     = var.vpc_id
  cidr_block = each.value["cidr"]

}

resource "aws_route_table" "main" {
  for_each = var.subnets
  vpc_id = var.vpc_id

}
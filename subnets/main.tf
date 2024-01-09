resource "aws_subnet" "main" {
  for_each          = var.subnets
  vpc_id            = var.vpc_id
  cidr_block        = each.value["cidr"]
  availability_zone = each.value["az"]
  tags = {
    Name = each.key
  }
}

resource "aws_route_table" "example" {
  for_each = var.subnets
  vpc_id = var.vpc_id

  tags = {
    Name = each.key
  }
}

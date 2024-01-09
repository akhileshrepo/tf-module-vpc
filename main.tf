resource "aws_vpc" "main" {
  cidr_block = var.cidr
  //tags       = merge(local.tags, { Name = "${var.env}-vpc" })
}
module "subnets" {
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
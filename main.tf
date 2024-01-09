resource "aws_vpc" "main" {
  cidr_block = var.cidr
  //tags       = merge(local.tags, { Name = "${var.env}-vpc" })
}


resource "aws_subnet" "main" {
  for_each = var.subnets
  vpc_id     = var.vpc_id
  cidr_block = each.value["cidr"]

}

resource "aws_route_table" "main" {
  for_each = var.subnets
  vpc_id = var.vpc_id
}

resource "aws_route_table_association" "main" {
  for_each = var.subnets
  subnet_id      = lookup(lookup(aws_subnet.main, each.key, null), "id", null)
  route_table_id = lookup(lookup(aws_route_table.main, each.key, null), "id", null)
}

output "subnet_ids" {
  value = aws_subnet.main
}

output "route_table_ids" {
  value = aws_route_table.main
}
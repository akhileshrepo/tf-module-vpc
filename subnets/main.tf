resource "aws_subnet" "main" {
  for_each = var.subnets
  vpc_id     = var.vpc_id
  cidr_block = each.value["cidr"]

}

resource "aws_route_table" "main" {
  for_each = var.subnets
  vpc_id = var.vpc_id
}

# resource "aws_route_table_association" "a" {
#   for_each = var.subnets
#   subnet_id      = aws_subnet.main.id
#   route_table_id = aws_route_table.main.id
# }

output "subnet_id" {
  value = aws_subnet.main
}

output "route_table_id" {
  value = aws_route_table.main
}
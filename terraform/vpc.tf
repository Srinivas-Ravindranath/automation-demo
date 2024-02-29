resource "aws_vpc" "project_vpc" {
  cidr_block         = var.vpc_cidr
  enable_dns_support = var.enable_dns_support_vpc

  enable_dns_hostnames = var.enable_dns_hostnames_vpc

  tags = {
    Name = "Custom VPC for project"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.project_vpc.id
  count      = var.public_subnet_count
  cidr_block = element(var.public_subnets_cidr, count.index)

  tags = {
    Name = "Public Subnet ${count.index}"
  }
  availability_zone = element(var.availability_zones, count.index)
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.project_vpc.id
  count      = var.private_subnet_count
  cidr_block = element(var.private_subnets_cidr, count.index)

  tags = {
    Name = "Private Subnet ${count.index}"
  }
  availability_zone = element(var.availability_zones, count.index)
}


#resource "aws_eip" "nat_gateway_ip" {
#  depends_on = [aws_internet_gateway.public_subnet_gateway]
#  domain     = "vpc"
#}


resource "aws_internet_gateway" "public_subnet_gateway" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "Customer Managed Internet Gateway"
  }
}

#resource "aws_nat_gateway" "private_subnet_gateway" {
#  depends_on = [aws_internet_gateway.public_subnet_gateway]
#
#  allocation_id = aws_eip.nat_gateway_ip.id
#  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
#
#  tags = {
#    Name = "Customer Managed Nat Gateway"
#  }
#
#}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "Route table for the public subnet"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "Route table for the private subnet"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_subnet_gateway.id
}

#resource "aws_route" "private_nat_gateway" {
#  route_table_id         = aws_route_table.private.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_nat_gateway.private_subnet_gateway.id
#}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id

}
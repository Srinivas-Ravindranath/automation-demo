# Create a custom VPC with public and private subnets
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "project_vpc" {
  cidr_block         = var.vpc_cidr
  enable_dns_support = var.enable_dns_support_vpc

  enable_dns_hostnames = var.enable_dns_hostnames_vpc

  tags = {
    Name = "Custom VPC for project"
  }
}

# Create a public subnet that will be used by the public facing resources
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.project_vpc.id
  count      = var.public_subnet_count
  cidr_block = element(var.public_subnets_cidr, count.index)

  tags = {
    Name = "Public Subnet ${count.index}"
  }
  availability_zone = element(var.availability_zones, count.index)
}

# Create a private subnet that will be used by the private resources
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.project_vpc.id
  count      = var.private_subnet_count
  cidr_block = element(var.private_subnets_cidr, count.index)

  tags = {
    Name = "Private Subnet ${count.index}"
  }
  availability_zone = element(var.availability_zones, count.index)
}

# EIP for the NAT Gateway
resource "aws_eip" "nat_gateway_ip" {
  depends_on = [aws_internet_gateway.public_subnet_gateway]
  domain     = "vpc"
}

# Create an internet gateway to allow the VPC to connect to the internet
resource "aws_internet_gateway" "public_subnet_gateway" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "Customer Managed Internet Gateway"
  }
}

# Creat a NAT Gateway to allow the private subnet to connect to the internet
resource "aws_nat_gateway" "private_subnet_gateway" {
  depends_on = [aws_internet_gateway.public_subnet_gateway]

  allocation_id = aws_eip.nat_gateway_ip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = {
    Name = "Customer Managed Nat Gateway"
  }

}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "Route table for the public subnet"
  }
}

#Create a route table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    Name = "Route table for the private subnet"
  }
}

# Add a route to the public subnet route table to allow the subnet to connect to the internet
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_subnet_gateway.id
}

# Add a route to the private subnet route table to allow the subnet to connect to the internet
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.private_subnet_gateway.id
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id

}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id

}
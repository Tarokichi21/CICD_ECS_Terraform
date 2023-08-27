#VPC
resource "aws_vpc" "vpc" {
  cidr_block                       = "10.1.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
}

#IGW
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}

#Public_Subnet
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.0.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true
}

#Public_RouteTable
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

#Public_RouteTable_Association
resource "aws_route_table_association" "route_table_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "route_table_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

#Private_Subnet
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}a"

}

resource "aws_subnet" "private_subnet_c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}c"

}

#Private_RouteTable
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
}

#Private_RouteTable_Association
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_route_table.id
}

#EIP
resource "aws_eip" "nat_a" {
  domain = "vpc"
}

#NAT_Gateway
resource "aws_nat_gateway" "nat_a" {
  subnet_id     = aws_subnet.public_subnet_a.id
  allocation_id = aws_eip.nat_a.id
}
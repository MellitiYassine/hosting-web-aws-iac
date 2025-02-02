# VPC
resource "aws_vpc" "ecommerce_vpc" {
  cidr_block = "10.0.0.0/23" # 512 IPs
  tags = {
    Name = "ecommerce-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "ecommerce_pub_subnet_1" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.0.0/27" # 32 IPs
  map_public_ip_on_launch = true          # Public subnet
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ecommerce-pub-subnet-1"
  }
}

resource "aws_subnet" "ecommerce_pub_subnet_2" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.0.32/27" # 32 IPs
  map_public_ip_on_launch = true           # Public subnet
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ecommerce-pub-subnet-2"
  }
}

# Private Subnets
resource "aws_subnet" "ecommerce_priv_subnet_1" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.1.0/27" # 32 IPs
  map_public_ip_on_launch = false         # Private subnet
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ecommerce-priv-subnet-1"
  }
}

resource "aws_subnet" "ecommerce_priv_subnet_2" {
  vpc_id                  = aws_vpc.ecommerce_vpc.id
  cidr_block              = "10.0.1.32/27" # 32 IPs (fixed overlap)
  map_public_ip_on_launch = false          # Private subnet
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ecommerce-priv-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecommerce_gw" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  tags = {
    Name = "ecommerce-igw"
  }
}

# Public Route Table
resource "aws_route_table" "ecommerce_rt_public" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecommerce_gw.id
  }
  tags = {
    Name = "ecommerce-rt-public"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "ecommerce_rta_pub_1" {
  subnet_id      = aws_subnet.ecommerce_pub_subnet_1.id
  route_table_id = aws_route_table.ecommerce_rt_public.id
}

resource "aws_route_table_association" "ecommerce_rta_pub_2" {
  subnet_id      = aws_subnet.ecommerce_pub_subnet_2.id
  route_table_id = aws_route_table.ecommerce_rt_public.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "ecommerce_eip_1" {
  domain = "vpc"
  tags = {
    Name = "ecommerce-eip-1"
  }
}

resource "aws_eip" "ecommerce_eip_2" {
  domain = "vpc"
  tags = {
    Name = "ecommerce-eip-2"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "ecommerce_nat_1" {
  allocation_id = aws_eip.ecommerce_eip_1.id
  subnet_id     = aws_subnet.ecommerce_pub_subnet_1.id # NAT in public subnet
  tags = {
    Name = "ecommerce-nat-1"
  }
}

resource "aws_nat_gateway" "ecommerce_nat_2" {
  allocation_id = aws_eip.ecommerce_eip_2.id
  subnet_id     = aws_subnet.ecommerce_pub_subnet_2.id # NAT in public subnet
  tags = {
    Name = "ecommerce-nat-2"
  }
}

# Private Route Tables
resource "aws_route_table" "ecommerce_rt_private_1" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecommerce_nat_1.id
  }
  tags = {
    Name = "ecommerce-rt-private-1"
  }
}

resource "aws_route_table" "ecommerce_rt_private_2" {
  vpc_id = aws_vpc.ecommerce_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecommerce_nat_2.id
  }
  tags = {
    Name = "ecommerce-rt-private-2"
  }
}

# Associate Private Subnets with Private Route Tables
resource "aws_route_table_association" "ecommerce_rta_priv_1" {
  subnet_id      = aws_subnet.ecommerce_priv_subnet_1.id
  route_table_id = aws_route_table.ecommerce_rt_private_1.id
}

resource "aws_route_table_association" "ecommerce_rta_priv_2" {
  subnet_id      = aws_subnet.ecommerce_priv_subnet_2.id
  route_table_id = aws_route_table.ecommerce_rt_private_2.id
}
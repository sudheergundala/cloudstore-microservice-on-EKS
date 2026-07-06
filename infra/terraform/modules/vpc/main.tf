# In this VPC module we will configure all the components and thier required settings for our infrastructure setup.
# the components include VPC, Subnets(Public and Private), Internet gateway, NAT Gateways(one per private subnet in AZ), Public route table (route to internet gateway),
# Private route tables(one per private subnet and route to local NAT gateway in the AZ), ElasticIPs for NAT gateways.



resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # required for EKS node registration
  enable_dns_support   = true # required for EKS DNS resolution
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Internet gateway (for public subnets <--> internet, bidirectional)
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Public Subnets(one per AZ, host NAT gateways,load balancers), tagged for internet EKS load balancers.

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 48)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Private Subnet(one per AZ, host EKS nodes & pods, ElastiCache,RDS)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  count             = length(var.availability_zones)
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]
  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# ElasticIPs for NAT Gateways

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${var.availability_zones[count.index]}"
  })
  depends_on = [aws_internet_gateway.this]
}

# NAT Gateway( one per AZ, launched in public subnet)

resource "aws_nat_gateway" "this" {
  count         = length(var.availability_zones)
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  depends_on    = [aws_internet_gateway.this]
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${var.availability_zones[count.index]}"
  })
}

# Public Route table (one,shared, route 0.0.0.0/0 ---> internet gateway)

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-routetable"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table(one per private subnet in AZ, route 0.0.0.0/0 --> local AZs NAT Gateway)

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  count  = length(var.availability_zones)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-routetable-${var.availability_zones[count.index]}"
  })
}
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

}
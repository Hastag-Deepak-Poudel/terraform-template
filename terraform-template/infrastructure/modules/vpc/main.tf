################################################################################
# VPC
################################################################################
resource "aws_vpc" "custom_vpc" {
  cidr_block = var.networking.cidr_block

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-VPC"
  })
}

################################################################################
# PUBLIC SUBNETS
################################################################################
resource "aws_subnet" "public_subnets" {
  count                   = var.networking.public_subnets == null || var.networking.public_subnets == "" ? 0 : length(var.networking.public_subnets)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.networking.public_subnets[count.index]
  availability_zone       = var.networking.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name                                        = "${var.naming_prefix}-public-subnet-${count.index}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

################################################################################
# PRIVATE SUBNETS
################################################################################
resource "aws_subnet" "private_subnets" {
  count                   = var.networking.private_subnets == null || var.networking.private_subnets == "" ? 0 : length(var.networking.private_subnets)
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = var.networking.private_subnets[count.index]
  availability_zone       = var.networking.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name                                        = "${var.naming_prefix}-private-subnet-${count.index}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

################################################################################
# INTERNET GATEWAY
################################################################################
resource "aws_internet_gateway" "i_gateway" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-i-gateway"
  })
}

################################################################################
# EIPs
################################################################################
resource "aws_eip" "elastic_ip" {
  count      = var.networking.private_subnets == null || var.networking.nat_gateways == false ? 0 : length(var.networking.private_subnets)
  depends_on = [aws_internet_gateway.i_gateway]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-eip-${count.index}"
  })
}

################################################################################
# NAT GATEWAYS
################################################################################
resource "aws_nat_gateway" "nats" {
  count             = var.networking.private_subnets == null || var.networking.nat_gateways == false ? 0 : length(var.networking.private_subnets)
  subnet_id         = aws_subnet.public_subnets[count.index].id
  connectivity_type = "public"
  allocation_id     = aws_eip.elastic_ip[count.index].id
  depends_on        = [aws_internet_gateway.i_gateway]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-nat-gw-${count.index}"
  })
}

################################################################################
# PUBLIC ROUTE TABLE
################################################################################
resource "aws_route_table" "public_table" {
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "public_routes" {
  route_table_id         = aws_route_table.public_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.i_gateway.id
}

resource "aws_route_table_association" "assoc_public_routes" {
  count          = length(var.networking.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_table.id
}

################################################################################
# PRIVATE ROUTE TABLES
################################################################################
resource "aws_route_table" "private_tables" {
  count  = length(var.networking.azs)
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "private_routes" {
  count                  = length(var.networking.private_subnets)
  route_table_id         = aws_route_table.private_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats[count.index].id
}

resource "aws_route_table_association" "assoc_private_routes" {
  count          = length(var.networking.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_tables[count.index].id
}

################################################################################
# SECURITY GROUPS
################################################################################
resource "aws_security_group" "sec_groups" {
  for_each    = { for sec in var.security_groups : sec.name => sec }
  name        = "${var.naming_prefix}-${each.value.name}"
  description = each.value.description
  vpc_id      = aws_vpc.custom_vpc.id

  dynamic "ingress" {
    for_each = try(each.value.ingress, [])
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = try(each.value.egress, [])
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
    }
  }
}
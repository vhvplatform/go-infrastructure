terraform {
  required_version = ">= 1.10.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Optional: Configure S3 backend for state management
  # backend "s3" {
  #   bucket = "saas-framework-terraform-state"
  #   key    = "dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = local.common_tags
  }
}

# ============================================================================
# Local Values
# ============================================================================

locals {
  environment  = "dev"
  project_name = "saas-framework"
  
  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = local.project_name
  }
  
  cluster_name = "${local.project_name}-${local.environment}"
}

# ============================================================================
# VPC Configuration
# ============================================================================
# Note: This is a simplified example. In production, consider using
# the official AWS VPC module: terraform-aws-modules/vpc/aws

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                                           = "${local.cluster_name}-public-${var.availability_zones[count.index]}"
      "kubernetes.io/role/elb"                       = "1"
      "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name                                           = "${local.cluster_name}-private-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb"              = "1"
      "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
    }
  )
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-nat"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-private-rt"
    }
  )
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# EKS Cluster
# ============================================================================

module "eks_cluster" {
  source = "../../modules/kubernetes-cluster-aws"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = aws_subnet.private[*].id

  desired_node_count = var.desired_node_count
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count
  instance_types     = var.instance_types

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = var.allowed_cidr_blocks

  tags = local.common_tags
}

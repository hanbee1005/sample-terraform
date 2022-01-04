# AWS용 프로바이더 구성
provider "aws" {
  profile = "default"
  region = "ap-northeast-2"
}

# 서울 리전만 지정
variable "region" {
  default = "ap-northeast-2"
}

locals {
  ## 신규 VPC 를 구성하는 경우 svc_nm 과 pem_file 를 새로 넣어야 한다.
  svc_nm = "hson-tf"
  creator = "hson"
  group = "hson"

  pem_file = "hson-histech-2"

  ## 신규 구축하는 시스템의 cidr 를 지정한다.
  public_subnets = {
    "${var.region}a" = "10.128.101.0/24"
    "${var.region}c" = "10.128.103.0/24"
  }
  private_subnets = {
    "${var.region}a" = "10.128.111.0/24"
    "${var.region}c" = "10.128.113.0/24"
  }
  azs = {
    "${var.region}a" = "a"
    "${var.region}c" = "c"
  }
}

### VPC ###
resource "aws_vpc" "this" {
  ## cidr 를 지정해야 한다.
  cidr_block = "10.128.0.0/16"

  tags = {
    Name = "${local.svc_nm}-vpc",
    Creator= local.creator,
    Group = local.group
  }
}

### SUBNET ###
resource "aws_subnet" "public" {
  count      = length(local.public_subnets)
  cidr_block = element(values(local.public_subnets), count.index)
  vpc_id     = aws_vpc.this.id

  map_public_ip_on_launch = true
  availability_zone       = element(keys(local.public_subnets), count.index)

  tags = {
    Name = "${local.svc_nm}-sb-public-${element(values(local.azs), count.index)}",
    Creator= local.creator,
    Group = local.group
  }
}

resource "aws_subnet" "private" {
  count      = length(local.private_subnets)
  cidr_block = element(values(local.private_subnets), count.index)
  vpc_id     = aws_vpc.this.id

  map_public_ip_on_launch = true
  availability_zone       = element(keys(local.private_subnets), count.index)

  tags = {
    Name = "${local.svc_nm}-sb-private-${element(values(local.azs), count.index)}",
    Creator= local.creator,
    Group = local.group
  }
}

### INTERNET GATEWAY ###
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.svc_nm}-igw",
    Creator= local.creator,
    Group = local.group
  }
}

### PUBLIC ROUTING TABLE ###
resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.this.main_route_table_id

  tags = {
    Name = "${local.svc_nm}-public",
    Creator= local.creator,
    Group = local.group
  }
}

# 라우팅 테이블과 인터넷 게이트웨이 연결
resource "aws_route" "internet_gateway" {
  count                  = length(local.public_subnets)
  route_table_id         = aws_default_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

# 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_default_route_table.public.id
}

### ELASTIC IP for NAT ###
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${local.svc_nm}-eip",
    Creator= local.creator,
    Group = local.group
  }
}

### NAT GATEWAY ###
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.svc_nm}-nat-gw",
    Creator= local.creator,
    Group = local.group
  }
}

### PRIVATE ROUTING TABLE ###
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.svc_nm}-private",
    Creator= local.creator,
    Group = local.group
  }
}

# 라우팅 테이블과 nat 게이트웨이 연결
resource "aws_route" "nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id

  timeouts {
    create = "5m"
  }
}

# 라우팅 테이블과 서브넷 연결
resource "aws_route_table_association" "private" {
  count          = length(local.private_subnets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

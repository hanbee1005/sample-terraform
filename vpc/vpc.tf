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

resource "aws_vpc" "this" {
  ## cidr 를 지정해야 한다.
  cidr_block = "10.128.0.0/16"

  tags = {
    Name = "${local.svc_nm}-vpc",
    Creator= local.creator,
    Group = local.group
  }
}

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
# AWS용 프로바이더 구성
provider "aws" {
  profile = "default"
  region = "ap-northeast-2"
}

resource "aws_vpc" "this" {
  ## cidr 를 지정해야 한다.
  cidr_block = "10.155.0.0/16"

  tags = {
    Name = "hson-tf-vpc",
    Creator= "hson",
    Group = "hson"
  }
}
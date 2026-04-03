terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 주의: 이 코드를 실행하기 전에 AWS에 'my-terraform-state-bucket'이라는 S3 버킷을 미리 만들어두어야 합니다.
  backend "s3" {
    bucket = "terraform-bucket-hello" # 본인이 생성한 S3 버킷 이름으로 변경
    key    = "github-actions/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# 항상 최신 Ubuntu 22.04 LTS 이미지를 찾아오는 Data Source
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu 공식 제공자)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 인스턴스 리소스
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  # 요청하신 초기화 스크립트
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3 python3-pip python3-venv git curl
              EOF

  # 인스턴스에 퍼블릭 IP를 자동 할당 (필요에 따라 서브넷 지정 가능)
  associate_public_ip_address = true

  tags = {
    Name = "MyActionEC2"
  }
}
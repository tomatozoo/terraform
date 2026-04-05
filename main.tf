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

# k3s 및 Python 앱 운영에 필요한 최소 보안 그룹
resource "aws_security_group" "k3s_sg" {
  name        = "k3s-minimal-sg"
  description = "Allow SSH, HTTP, HTTPS, and k3s API"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (Python 앱)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (Python 앱)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # k3s API 서버 (kubectl 접근용)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort 범위 (k3s 서비스 외부 노출용)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 외부 통신 (패키지 설치 등)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 인스턴스 리소스
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]

  # k3s 자동 설치 스크립트
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y curl
              curl -sfL https://get.k3s.io | sh -
              EOF

  associate_public_ip_address = true

  tags = {
    Name = "MyActionEC2"
  }
}
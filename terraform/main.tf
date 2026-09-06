resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ecommerce-vpc"
  }
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-public-subnet"
  }
}
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecommerce-public-2"
  }
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "ecommerce-private-subnet"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecommerce-igw"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecommerce-public-rt"
  }
}
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "backend" {
  name        = "ecommerce-backend-sg"
  description = "Security group for E-Commerce backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Node Exporter from monitoring"
    from_port       = 9100
    to_port         = 9100
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }

  ingress {
    description     = "cAdvisor from monitoring"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }

  ingress {
    description     = "Backend API from ALB"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-backend-sg"
  }
}
resource "aws_instance" "backend" {
  ami           = "ami-081b0a6eac00b4f53"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.backend.id
  ]

  iam_instance_profile = aws_iam_instance_profile.backend_ssm.name

  key_name = "ecommerce-bastion-key"

  tags = {
    Name = "ecommerce-backend"
  }
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "ecommerce-nat-eip"
  }
}
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "ecommerce-nat"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecommerce-private-rt"
  }
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "bastion" {
  name        = "ecommerce-bastion-sg"
  description = "Security group for E-Commerce Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["156.203.140.70/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-081b0a6eac00b4f53"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  iam_instance_profile = aws_iam_instance_profile.bastion_ssm.name

  key_name = "ecommerce-bastion-key"

  user_data = <<-EOF
  #!/bin/bash
  systemctl unmask sshd
  systemctl enable sshd
  systemctl restart sshd
  systemctl status sshd --no-pager > /tmp/sshd-status.txt 2>&1
EOF

  tags = {
    Name = "ecommerce-bastion"
  }
}

resource "aws_security_group" "monitoring" {
  name        = "ecommerce-monitoring-sg"
  description = "Security group for monitoring server"
  vpc_id      = aws_vpc.main.id

  # Prometheus/Grafana access from my IP
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["156.203.197.211/32"]
  }

  # Monitoring server can scrape backend metrics

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-monitoring-sg"
  }
}
resource "aws_instance" "monitoring" {
  ami           = "ami-081b0a6eac00b4f53"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.monitoring.id
  ]

  iam_instance_profile = aws_iam_instance_profile.backend_ssm.name

  tags = {
    Name = "ecommerce-monitoring"
  }
}

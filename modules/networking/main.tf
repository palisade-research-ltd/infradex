
data "aws_ami" "amazon_linux" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.pro_name}-vpc"
    Environment = var.pro_environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pro_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.pro_name}-public-subnet"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.pro_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "data_pipeline_sg" {
  name        = "${var.pro_name}-security-group"
  description = "Security group for data pipeline EC2 instance"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access for web interfaces
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ClickHouse HTTP interface
  ingress {
    description = "ClickHouse HTTP"
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ClickHouse native protocol
  ingress {
    description = "ClickHouse Native"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ML Model API
  ingress {
    description = "ML Model API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Data Pipeline API
  ingress {
    description = "Data Pipeline API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.pro_name}-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.pro_name}-key"
  public_key = var.public_key
}

resource "aws_instance" "data_pipeline" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.data_pipeline_sg.id]
  subnet_id             = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name = "${var.pro_name}-root-volume"
    }
  }

  # User data script to setup Docker and services
  user_data = file("../../scripts/userdata.sh")

  tags = {
    Name        = "${var.pro_name}-instance"
    Environment = var.pro_environment
    Purpose     = "Data Pipeline Infrastructure"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_route_table_association.public
  ]
}

resource "aws_eip" "data_pipeline_eip" {
  instance = aws_instance.data_pipeline.id
  domain   = "vpc"

  tags = {
    Name = "${var.pro_name}-eip"
  }

  depends_on = [aws_internet_gateway.main]
}


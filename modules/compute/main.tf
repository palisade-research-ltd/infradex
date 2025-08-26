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

resource "aws_instance" "data_pipeline" {
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = "${var.pro_id}-key-pair"
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group
  subnet_id              = var.subnet_id

  # Add more storage for Docker containers and data
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name = "${var.pro_id}-root-volume"
    }
  }

  # User data script to setup Docker and services
  user_data = file("../../scripts/userdata.sh")

  tags = {
    Name        = "${var.pro_id}-instance"
    Environment = var.pro_environment
    Purpose     = "Data Pipeline Infrastructure"
  }

}

resource "aws_eip" "data_pipeline_eip" {
  instance = aws_instance.data_pipeline.id
  domain   = "vpc"

  tags = {
    Name = "${var.pro_id}-eip"
  }

}



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
  instance_type          = var.instance_type
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.data_pipeline_sg.id]
  subnet_id             = aws_subnet.public.id

  # Add more storage for Docker containers and data
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

  # Wait for instance to be ready
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


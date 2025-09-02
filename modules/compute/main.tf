
# --- ------------------------------------------------------- DATA: AMI for the EC2 --- #
# --- ------------------------------------------------------- --------------------- --- #

data "aws_ami" "amazon_linux" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

}

# --- --------------------------------------------------------------- RESOURCE: EC2 --- #
# --- --------------------------------------------------------------- ------------- --- #

resource "aws_instance" "features_compute" {

  ami                    = data.aws_ami.amazon_linux.id
  key_name               = var.key_pair_name
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.ec2_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name = "${var.pro_id}-root-volume"
    }
  }

  tags = {
    Name        = "${var.pro_id}-compute-instance"
    Environment = var.pro_environment
    Project     = var.pro_id
    Purpose     = "Compute features and models inference"
  }

}

# --- ------------------------------------------------------------ RESOURCE: EC2 IP --- #
# --- ------------------------------------------------------------- --------------- --- #

resource "aws_eip" "features_compute_eip" {

  instance = aws_instance.features_compute.id
  domain   = "vpc"

  tags = {
    Name = "${var.pro_id}-compute-eip"
  }

}


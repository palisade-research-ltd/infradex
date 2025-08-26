
module "networking" {

  source = "../../modules/networking"

  pro_id          = var.pro_id
  pro_environment = var.pro_environment
  pro_region      = var.pro_region

  public_key       = var.public_key
  private_key_path = var.private_key_path

}

module "compute" {

  source = "../../modules/compute"

  public_key       = var.public_key
  private_key_path = var.private_key_path

  security_group = module.networking.aws_security_group_id
  subnet_id      = module.networking.aws_subnet_id

  depends_on = [module.networking]

}

# # # Data source for AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]
#
#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
#
#   filter {
#     name   = "state"
#     values = ["available"]
#   }
# }
#
# # Create VPC
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   enable_dns_support   = true
#
#   tags = {
#     Name        = "${var.pro_name}-vpc"
#     Environment = var.pro_environment
#   }
# }
#
# # Create Internet Gateway
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id
#
#   tags = {
#     Name = "${var.pro_name}-igw"
#   }
# }
#
# # Create public subnet
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   map_public_ip_on_launch = true
#
#   tags = {
#     Name = "${var.pro_name}-public-subnet"
#   }
# }
#
# # Get availability zones
# data "aws_availability_zones" "available" {
#   state = "available"
# }
#
# # Create route table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }
#
#   tags = {
#     Name = "${var.pro_name}-public-rt"
#   }
# }
#
# # Associate route table with subnet
# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }
#
# # Security Group
# resource "aws_security_group" "data_pipeline_sg" {
#   name        = "${var.pro_name}-security-group"
#   description = "Security group for data pipeline EC2 instance"
#   vpc_id      = aws_vpc.main.id
#
#   # SSH access
#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # HTTP access for web interfaces
#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # HTTPS access
#   ingress {
#     description = "HTTPS"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # ClickHouse HTTP interface
#   ingress {
#     description = "ClickHouse HTTP"
#     from_port   = 8123
#     to_port     = 8123
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # ClickHouse native protocol
#   ingress {
#     description = "ClickHouse Native"
#     from_port   = 9000
#     to_port     = 9000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # ML Model API
#   ingress {
#     description = "ML Model API"
#     from_port   = 5000
#     to_port     = 5000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # Data Pipeline API
#   ingress {
#     description = "Data Pipeline API"
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   # All outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name = "${var.pro_name}-sg"
#   }
# }
#
# # Key pair (you'll need to create this in AWS console or import your public key)
# resource "aws_key_pair" "deployer" {
#   key_name   = "${var.pro_name}-key"
#   public_key = var.public_key
# }
#
# # EC2 Instance
# resource "aws_instance" "data_pipeline" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = var.instance_type
#   key_name               = aws_key_pair.deployer.key_name
#   vpc_security_group_ids = [aws_security_group.data_pipeline_sg.id]
#   subnet_id              = aws_subnet.public.id
#
#   # Add more storage for Docker containers and data
#   root_block_device {
#     volume_type = "gp3"
#     volume_size = 30
#     encrypted   = true
#
#     tags = {
#       Name = "${var.pro_name}-root-volume"
#     }
#   }
#
#   # User data script to setup Docker and services
#   user_data = file("../../scripts/userdata.sh")
#
#   tags = {
#     Name        = "${var.pro_name}-instance"
#     Environment = var.pro_environment
#     Purpose     = "Data Pipeline Infrastructure"
#   }
#
#   # Wait for instance to be ready
#   depends_on = [
#     aws_internet_gateway.main,
#     aws_route_table_association.public
#   ]
# }
#
# # Elastic IP for static public IP
# resource "aws_eip" "data_pipeline_eip" {
#   instance = aws_instance.data_pipeline.id
#   domain   = "vpc"
#
#   tags = {
#     Name = "${var.pro_name}-eip"
#   }
#
#   depends_on = [aws_internet_gateway.main]
# }
#

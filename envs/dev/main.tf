
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


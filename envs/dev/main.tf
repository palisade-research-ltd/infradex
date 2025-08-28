
module "networking" {

  source = "../../modules/networking"

  pro_id          = var.pro_id
  pro_environment = var.pro_environment
  pro_region      = var.pro_region
  private_key_path = var.private_key_path

}

module "compute" {

  source = "../../modules/compute"

  security_group = module.networking.aws_security_group_id
  subnet_id      = module.networking.aws_subnet_id
  private_key_path = var.private_key_path

  depends_on = [module.networking]

}

module "datalake" {

  source = "../../modules/datalake"
  public_ip = module.compute.instance_public_ip
  private_key_path = var.private_key_path

  depends_on = [module.compute]

}


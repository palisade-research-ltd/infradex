module "networking" {
  source          = "../../modules/networking"
  pro_id          = var.pro_id
  pro_environment = var.pro_environment
}

module "roles" {
  source     = "../../modules/roles"
  pro_id     = var.pro_id
  depends_on = [module.networking]
}

module "compute" {
  source         = "../../modules/compute"
  subnet_id      = module.networking.aws_subnet_id
  security_group = module.networking.aws_security_group_id
  key_pair_name  = var.key_pair_name
  ec2_profile    = module.roles.ec2_profile
  depends_on     = [module.networking]
}

module "datalake" {
  source         = "../../modules/datalake"
  subnet_id      = module.networking.aws_subnet_id
  security_group = module.networking.aws_security_group_id
  key_pair_name  = var.key_pair_name
  ec2_profile    = module.roles.ec2_profile
  depends_on     = [module.networking]
}


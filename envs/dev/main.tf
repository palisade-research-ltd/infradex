
module "networking" {

  source          = "../../modules/networking"
  pro_id          = var.pro_id
  pro_environment = var.pro_environment

}

module "compute" {

  source         = "../../modules/compute"
  security_group = module.networking.aws_security_group_id
  subnet_id      = module.networking.aws_subnet_id

  depends_on = [module.networking]

}

module "datalake" {

  source         = "../../modules/datalake"
  subnet_id      = module.networking.aws_subnet_id
  security_group = module.networking.aws_security_group_id

  depends_on = [module.networking]

}

# 
# module "roles" {
#
#   source = "../../modules/roles"
#   deployment_files_id = module.datalake.deployment_files_id
#   collector_build_id = module.datalake.s3_collector_build_arn
#   collector_configs_id = module.datalake.s3_collector_configs_arn
#   collector_scripts_id = module.datalake.s3_collector_scripts_arn
#
# }
#


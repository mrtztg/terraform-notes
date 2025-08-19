
### RDS Instance

data "aws_rds_engine_version" "db_cluster" {
  engine = "postgres"
}

resource "aws_db_instance" "db" {
  allocated_storage   = var.db_config.allocated_storage
  db_name             = var.db_config.db_name
  engine              = "postgres"
  engine_version      = data.aws_rds_engine_version.db_cluster.version
  instance_class      = var.db_config.instance_type
  username            = var.db_credentials.username
  password            = var.db_credentials.password
  skip_final_snapshot = true
  tags = {
    purpose = local.purpose_tag
  }
}

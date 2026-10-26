locals {
  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
    [
      {
        "name": "LOG_LEVEL",
        "value": "debug,info"
      },
      {
        "name": "NUM_HISTORY_SHARDS",
        "value": "128"
      },
      {
        "name": "DB",
        "value": "postgresql"
      },
      {
        "name": "POSTGRES_HOST",
        "value": module.temporal_aurora_rds.cluster_endpoint
      },
      {
        "name": "POSTGRES_PORT",
        "value": tostring(module.temporal_aurora_rds.cluster_port)
      },
      {
        "name": "POSTGRES_USER",
        "value": var.temporal_aurora_username
      },
      {
        "name": "DBNAME",
        "value": "temporal"
      },
      {
        "name": "DBNAME_VISIBILITY",
        "value": "temporal_visibility"
      },
      {
        "name": "DYNAMIC_CONFIG_FILE_PATH",
        "value": "/etc/temporal/ecs/dynamic_config/dynamicconfig-sql.yaml"
      },
      {
        "name": "ECS_DEPLOYED",
        "value": "true"
      }
    ]
  )

  # Through the ECS `secrets` block so the task definition holds only the ARN.
  # Referencing the secret version (not the secret) makes ECS wait for a value.
  secrets = [
    {
      name      = "POSTGRES_PASSWORD"
      valueFrom = aws_secretsmanager_secret_version.temporal_aurora_password.secret_id
    },
  ]
}
locals {
  environment_variables = concat(
    var.additional_env_vars, # add additional environment variables
    local.temporal_mtls_config,
    [
      {
        name  = "NODE_ENV"
        value = var.node_env
      },
      {
        name  = "FORCE_DEPLOYMENT"
        value = tostring(var.force_deployment)
      },
      {
        name  = "POSTGRES_DB"
        value = "hammerhead_production"
      },
      {
        name  = "POSTGRES_HOST"
        value = aws_db_instance.this.address
      },
      {
        name  = "POSTGRES_SSL_ENABLED"
        value = "true"
      },
      {
        name  = "POSTGRES_PORT"
        value = "5432"
      },
      {
        "name"  = "POSTGRES_USER",
        "value" = var.rds_username
      },
      # Workflows-specific
      {
        "name": "WORKFLOW_BACKEND_HOST",
        "value": "http://workflow-backend.retoolsvc:3000"
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_NAMESPACE",
        "value": var.temporal_cluster_config.namespace
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_HOST",
        "value": var.temporal_cluster_config.host
      },
      {
        "name": "WORKFLOW_TEMPORAL_CLUSTER_FRONTEND_PORT",
        "value": var.temporal_cluster_config.port
      },
      {
        "name": "WORKFLOW_TEMPORAL_TLS_ENABLED",
        "value": tostring(var.temporal_cluster_config.tls_enabled)
      }
    ]
  )

  # Sensitive values reach the containers through the ECS `secrets` block, so a
  # task definition only holds secret ARNs. Values in `environment` are readable
  # by anyone with ecs:DescribeTaskDefinition.
  # Referencing the secret version (not the secret) makes ECS wait for a value.
  secrets = concat(
    var.additional_secrets,
    [
      {
        name      = "POSTGRES_PASSWORD"
        valueFrom = aws_secretsmanager_secret_version.rds_password.secret_id
      },
      {
        name      = "JWT_SECRET"
        valueFrom = aws_secretsmanager_secret_version.jwt_secret.secret_id
      },
      {
        name      = "ENCRYPTION_KEY"
        valueFrom = aws_secretsmanager_secret_version.encryption_key.secret_id
      },
      {
        name      = "LICENSE_KEY"
        valueFrom = aws_secretsmanager_secret_version.license_key.secret_id
      },
    ]
  )

  temporal_mtls_config = (
    var.temporal_cluster_config.tls_enabled && var.temporal_cluster_config.tls_crt != null && var.temporal_cluster_config.tls_key != null ? 
      [
        {
          "name": "WORKFLOW_TEMPORAL_TLS_CRT",
          "value": var.temporal_cluster_config.tls_crt
        },
        {
          "name": "WORKFLOW_TEMPORAL_TLS_KEY",
          "value": var.temporal_cluster_config.tls_key
        } 
      ] : 
      []
  )
}

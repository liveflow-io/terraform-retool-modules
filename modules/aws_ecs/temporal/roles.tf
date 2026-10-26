data "aws_iam_policy_document" "task_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.deployment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_policy.json
  path               = "/"
}

data "aws_iam_policy_document" "service_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "service_role_policy" {
  statement {
    actions = [
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.deployment_name}-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_role_assume_policy.json
  path               = "/"
}

resource "aws_iam_role_policy" "service_role" {
  name   = "${var.deployment_name}-service-policy"
  role   = aws_iam_role.service_role.id
  policy = data.aws_iam_policy_document.service_role_policy.json
}

# Task execution role. ECS uses it to pull secrets into the containers, which
# both launch types need, so it exists for FARGATE and EC2.
data "aws_iam_policy_document" "execution_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.deployment_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role_assume_policy.json
}

moved {
  from = aws_iam_role.execution_role[0]
  to   = aws_iam_role.execution_role
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

moved {
  from = aws_iam_role_policy_attachment.execution_role[0]
  to   = aws_iam_role_policy_attachment.execution_role
}

data "aws_iam_policy_document" "execution_role_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = distinct([for s in local.secrets : s.valueFrom])
  }
}

resource "aws_iam_role_policy" "execution_role_secrets" {
  name   = "${var.deployment_name}-execution-secrets"
  role   = aws_iam_role.execution_role.id
  policy = data.aws_iam_policy_document.execution_role_secrets.json
}
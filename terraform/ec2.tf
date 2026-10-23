data "aws_ssm_parameter" "app_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.app_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.app.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  user_data = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail

    dnf install -y docker awscli-2
    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent

    for attempt in {1..12}; do
      if aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 343551558539.dkr.ecr.us-east-2.amazonaws.com; then
        break
      fi
      sleep 5
    done

    docker pull ${aws_ecr_repository.app.repository_url}:v2
    docker run -d \
      --name aws-devops-app \
      --restart unless-stopped \
      --log-opt max-size=10m \
      --log-opt max-file=3 \
      -p 80:5000 \
      ${aws_ecr_repository.app.repository_url}:v2
  SCRIPT

  depends_on = [
    aws_iam_role_policy.ecr_pull,
    aws_iam_role_policy_attachment.ssm
  ]

  tags = {
    Name = "aws-devops-app"
  }
}

output "app_url" {
  value = "http://${aws_instance.app.public_ip}"
}

output "instance_id" {
  value = aws_instance.app.id
}

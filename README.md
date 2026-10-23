# AWS DevOps Pipeline

A containerized Python application deployed to AWS EC2 using Docker, Amazon ECR, and Terraform. I built this project to practice managing AWS infrastructure with code and testing the full deployment process.

## What I built

The application is a small Flask API with a main endpoint and a health check. It runs inside a Docker container using Gunicorn.

I used Terraform to configure the EC2 instance, security group, and IAM permissions. The Docker image is stored in Amazon ECR, and the EC2 instance pulls the image during startup.

GitHub Actions handles automated Python testing and Docker builds whenever code is pushed to the repository.

## Tech stack

- Python, Flask, and Gunicorn
- Docker
- AWS EC2 and Amazon ECR
- Terraform
- AWS IAM and Systems Manager
- GitHub Actions
- Linux

## How it works

1. Code is pushed to GitHub.
2. GitHub Actions runs the Python tests and checks that the Docker image builds.
3. The application image is built locally and pushed to Amazon ECR.
4. Terraform provisions the AWS infrastructure.
5. EC2 installs Docker, pulls the image from ECR, and starts the container on port 80.
6. The running application can be checked through the main endpoint and /health.

The AWS deployment is currently a manual process. GitHub Actions automates the testing and Docker build, not the deployment.

## Testing the deployment

I deployed the application to EC2 in the AWS Ohio region (us-east-2).

The main endpoint returned HTTP 200 with a JSON response confirming the application was running. The /health endpoint returned:

```json
{"status":"healthy"}
```

I also verified that all three GitHub Actions workflow runs completed successfully.

## Security and infrastructure

- EC2 runs with an IAM instance role for ECR image access and Systems Manager.
- Inbound access is limited to HTTP on port 80, with no SSH port opened.
- EC2 requires IMDSv2.
- The root EBS volume is encrypted.
- Docker runs the application using a non-root user.
- Terraform state and sensitive local files are excluded from Git.

The deployment uses HTTP for demonstration purposes. HTTPS would be needed for a production-facing application.

## Cleanup

After confirming the deployment, I used Terraform to remove the temporary EC2 instance and associated infrastructure instead of leaving it running.

The ECR repository and both image tags, v1 and v2, were preserved. The EC2 infrastructure can be recreated using the Terraform configuration, but a normal terraform apply may create billable AWS resources.

## What I learned

Working through this project helped me understand how Terraform, Docker, IAM, and ECR fit together during a deployment.

One issue I ran into was the application initially refusing connections while the EC2 startup process was still running. After the container started, I verified the response using curl and checked the health endpoint separately.

I also practiced reviewing Terraform plans and state before cleanup, particularly because the ECR repository needed to remain in place while the temporary server was removed.

# Exchange Rate Application - ECS Deployment

This project is a pyhton Flask application that displays current NGN to USD exchange rates, containerized and deployed to AWS ECS using Terraform and automated with GitHub Actions.

## Application Overview

This application fetches real-time exchange rates between Nigerian Naira (NGN) and US Dollar (USD) using the ExchangeRate-API and displays them in a web interface.

## Architecture

- **Application**: Flask web application
- **Container**: Docker containerization
- **Infrastructure**: AWS ECS Fargate with Application Load Balancer
- **Container Registry**: Amazon ECR
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions with security scanning
- **Code Quality**: SonarQube integration
- **Security Scanning**: Trivy vulnerability scanner

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- GitHub account
- Git

## Local Development

### Running with Docker Compose

```bash
docker-compose up --build
```

Access the application at `http://localhost:5000`

### Running Locally

```bash
pip install -r requirements.txt
python app.py
```

## Infrastructure Setup

### Automated Deployment (Recommended)

Use the provided script for one-command deployment:

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

This script will:
- Check prerequisites (AWS CLI, Terraform, Docker)
- Deploy infrastructure with Terraform
- Build and push Docker image to ECR
- Display the application URL

### Manual Deployment

#### 1. Deploy Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- VPC with public subnets
- Application Load Balancer
- ECS Cluster and Service
- ECR Repository
- Security Groups
- IAM Roles
- CloudWatch Log Groups

#### 2. Initial Docker Image Push

After Terraform deployment, push the initial image:

```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
docker build -t exchange-rate-app .
docker tag exchange-rate-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/exchange-rate-app:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/exchange-rate-app:latest
```

## GitHub Actions Setup

### Required Secrets

Add these secrets to your GitHub repository:

1. Go to Settings > Secrets and variables > Actions
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `SONAR_TOKEN`: SonarQube authentication token
   - `SONAR_HOST_URL`: SonarQube server URL


### Set up Sonar cloud environment

 - For this project, use the sonarcloud free account. 
 - Go to www.sonarcloud.io to create an account
 - Sign up with your GitHub account. Link your repisitory. 
 - Under Account settings, you will see the sonar token. 
 - Copy it and use it to configure your repository secrets. 
 - For the Sonar host url, use www.sonarcloud.io 


### Workflow Triggers

The deployment workflow triggers on:
- Push to `main` branch
- Pull requests to `main` branch

## CI/CD Pipeline

The pipeline consists of three jobs that run sequentially:

### 1. Code Quality & Tests
- **Linting**: flake8 code style checks
- **Security**: Bandit Python security analysis
- **Dependencies**: Safety vulnerability checks
- **Unit Tests**: pytest test execution
- **Code Quality**: SonarQube analysis

### 2. Security Scanning
- **Container Scanning**: Trivy vulnerability assessment
- **Filesystem Scanning**: Source code security analysis
- **SARIF Upload**: Results to GitHub Security tab
- **Severity Gates**: Blocks on CRITICAL/HIGH vulnerabilities

### 3. Deployment (main branch only)
- **Build**: Docker image creation
- **Push**: Image pushed to ECR
- **Deploy**: ECS service update
- **Verify**: Service stability check

## Testing

### Running Tests Locally

```bash
# Install test dependencies
pip install pytest flake8 bandit safety

# Run linting
flake8 .

# Run security checks
bandit -r .
safety check

# Run unit tests
pytest
```

### Security Scanning

```bash
# Scan Docker image with Trivy
docker build -t exchange-rate-app .
trivy image exchange-rate-app

# Scan filesystem
trivy fs .
```

## Configuration

### Terraform Variables

Modify `terraform/variables.tf` to customize:

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change region if needed
}

variable "project_name" {
  default = "exchange-rate-app"  # Change project name
}
```

### Environment-Specific Configurations

For different environments, create separate `.tfvars` files:

```bash
# terraform/prod.tfvars
aws_region = "us-east-1"
project_name = "exchange-rate-app-prod"
```

Deploy with:
```bash
terraform apply -var-file="prod.tfvars"
```

## Monitoring and Logs

### CloudWatch Logs

View application logs:
```bash
aws logs describe-log-groups --log-group-name-prefix "/ecs/exchange-rate-app"
```

### ECS Service Monitoring

Check service status:
```bash
aws ecs describe-services --cluster exchange-rate-app-cluster --services exchange-rate-app-service
```

## Scaling

### Manual Scaling

Update desired count in Terraform:
```hcl
resource "aws_ecs_service" "app" {
  desired_count = 3  # Increase from 2
}
```

### Auto Scaling (Optional Enhancement)

Add auto scaling configuration to `main.tf`:

```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

## Security Considerations

- **Container Security**: Trivy scanning for vulnerabilities
- **Code Security**: Bandit static analysis
- **Dependency Security**: Safety vulnerability checks
- **ECR Scanning**: Image scanning enabled
- **Network Security**: Security groups restrict access
- **Access Control**: IAM roles follow least privilege
- **Pipeline Security**: Security gates prevent vulnerable deployments

## Cost Optimization

- Uses Fargate Spot (can be configured)
- CloudWatch log retention set to 30 days
- Right-sized task definitions (256 CPU, 512 MB memory)

## Troubleshooting

### Common Issues

1. **ECS Service Won't Start**
   - Check CloudWatch logs
   - Verify security group rules
   - Ensure ECR image exists

2. **GitHub Actions Fails**
   - Verify AWS credentials
   - Check IAM permissions
   - Ensure ECR repository exists

3. **Application Not Accessible**
   - Check ALB health checks
   - Verify target group registration
   - Check security group rules

4. **Security Scan Failures**
   - Review Trivy scan results in GitHub Security tab
   - Check Bandit security warnings
   - Update vulnerable dependencies

5. **SonarQube Integration Issues**
   - Verify SONAR_TOKEN and SONAR_HOST_URL secrets
   - Check SonarQube server accessibility
   - Review sonar-project.properties configuration

### Useful Commands

```bash
# Check ECS service events
aws ecs describe-services --cluster exchange-rate-app-cluster --services exchange-rate-app-service --query 'services[0].events'

# View recent logs
aws logs tail /ecs/exchange-rate-app --follow

# Force new deployment
aws ecs update-service --cluster exchange-rate-app-cluster --service exchange-rate-app-service --force-new-deployment
```

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Note**: This will delete all AWS resources created by Terraform.

## File Structure

```
.
├── app.py                          # Flask application
├── test_app.py                     # Unit tests
├── requirements.txt                # Python dependencies
├── sonar-project.properties        # SonarQube configuration
├── deploy.sh                       # Automated deployment script
├── Dockerfile                      # Container configuration
├── docker-compose.yml              # Local development
├── .dockerignore                   # Docker ignore rules
├── .gitignore                      # Git ignore rules
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD pipeline with security
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Terraform variables
│   └── outputs.tf                  # Terraform outputs
└── README.md                       # This file
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test locally with Docker Compose
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Creator
 
Created with love by Johntoby 

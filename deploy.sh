#!/bin/bash

set -e

# Configuration
AWS_REGION="us-east-1"
PROJECT_NAME="exchange-rate-app"

echo "🚀 Starting deployment process..."

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"

# Deploy infrastructure
echo "🏗️  Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# Get ECR repository URL
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
echo "✅ ECR Repository: $ECR_REPOSITORY_URL"

# Return to root directory
cd ..

# Login to ECR
echo "🔐 Logging into Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URL

# Build and push Docker image
echo "🐳 Building Docker image..."
docker build -t $PROJECT_NAME .

echo "📤 Pushing image to ECR..."
docker tag $PROJECT_NAME:latest $ECR_REPOSITORY_URL:latest
docker push $ECR_REPOSITORY_URL:latest

# Get load balancer URL
ALB_URL=$(cd terraform && terraform output -raw load_balancer_url)

echo "✅ Deployment completed successfully!"
echo "🌐 Application URL: $ALB_URL"
echo "📝 Note: It may take a few minutes for the service to be fully available. Please be patient"
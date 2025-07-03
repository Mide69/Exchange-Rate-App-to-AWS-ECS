#!/bin/bash

set -e

echo "🚀 Starting deployment of Exchange Rate Application to AWS ECS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are installed${NC}"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
PROJECT_NAME="exchange-rate-app"

echo -e "${YELLOW}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${YELLOW}AWS Region: ${AWS_REGION}${NC}"

# Deploy infrastructure
echo -e "${YELLOW}🏗️  Deploying infrastructure with Terraform...${NC}"
cd terraform

terraform init
terraform plan
terraform apply -auto-approve

# Get ECR repository URL
ECR_REPO_URL=$(terraform output -raw ecr_repository_url)
echo -e "${GREEN}ECR Repository URL: ${ECR_REPO_URL}${NC}"

cd ..

# Build and push Docker image
echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}

# Build image
docker build -t ${PROJECT_NAME} .

# Tag image
docker tag ${PROJECT_NAME}:latest ${ECR_REPO_URL}:latest

# Push image
docker push ${ECR_REPO_URL}:latest

echo -e "${GREEN}✅ Docker image pushed successfully${NC}"

# Get load balancer URL
cd terraform
LB_URL=$(terraform output -raw load_balancer_url)
cd ..

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}Application URL: ${LB_URL}${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for the service to be fully available.${NC}"

# Wait for service to be stable
echo -e "${YELLOW}⏳ Waiting for ECS service to stabilize...${NC}"
aws ecs wait services-stable --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION}

echo -e "${GREEN}✅ ECS service is now stable and ready!${NC}"
echo -e "${GREEN}🌐 Access your application at: ${LB_URL}${NC}"
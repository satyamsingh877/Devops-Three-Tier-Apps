provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# Frontend ECR Repository
resource "aws_ecr_repository" "frontend" {
  name                 = "frontend-app"
  image_tag_mutability = "MUTABLE"  # Can be "MUTABLE" or "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true  # Enable vulnerability scanning on push
  }

  encryption_configuration {
    encryption_type = "AES256"  # Default encryption (or "KMS" for AWS KMS)
  }

  tags = {
    Environment = "Production"
    Component   = "Frontend"
  }
}

# Backend ECR Repository
resource "aws_ecr_repository" "backend" {
  name                 = "backend-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = "Production"
    Component   = "Backend"
  }
}

# Output ECR Repository URLs
output "frontend_ecr_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_url" {
  value = aws_ecr_repository.backend.repository_url
}

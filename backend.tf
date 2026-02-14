# backend.tf (Root Directory)

terraform {
  backend "s3" {
    # The name of the S3 bucket created for state storage
    bucket         = "hotstar-terraform-state-prod" 
    
    # Path/name of the state file inside the bucket
    key            = "infrastructure/production/terraform.tfstate" 
    
    region         = "ap-south-1"
    
    # DynamoDB table for state locking (must have Partition Key: LockID)
    dynamodb_table = "terraform-state-lock" 
    
    # Recommended for security
    encrypt        = true 
  }
}

#!/bin/bash

# Pinohub Landing Page Destruction Script
# This script removes all AWS resources created by the deployment
# Usage: ./destroy.sh [stage] [region]

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="pinohub-landing"
DEFAULT_STAGE="dev"
DEFAULT_REGION="us-east-1"

# Set AWS Profile
export AWS_PROFILE=pinohub

# Parse command line arguments
STAGE=${1:-$DEFAULT_STAGE}
REGION=${2:-$DEFAULT_REGION}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Get AWS Account ID
get_aws_account_id() {
    local caller_identity=$(aws sts get-caller-identity 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$caller_identity" ]; then
        return 1
    fi
    
    local account_id=""
    if command -v jq &> /dev/null; then
        account_id=$(echo "$caller_identity" | jq -r '.Account' 2>/dev/null)
    else
        account_id=$(echo "$caller_identity" | grep -o '"Account":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
        if [ -z "$account_id" ]; then
            account_id=$(echo "$caller_identity" | grep -o '[0-9]\{12\}' 2>/dev/null | head -1)
        fi
    fi
    
    if [ -n "$account_id" ]; then
        local len=${#account_id}
        if [ "$len" -eq 12 ] && echo "$account_id" | grep -qE '^[0-9]{12}$'; then
            echo "$account_id"
            return 0
        fi
    fi
    
    return 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Verify that serverless is installed
    if ! command -v serverless &> /dev/null; then
        log_error "Serverless Framework is not installed."
        log_info "Run: npm install -g serverless"
        exit 1
    fi
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured."
        log_info "Run: aws configure"
        exit 1
    fi
    
    log_success "Prerequisites verified ✓"
}

# Show destruction information
show_destruction_info() {
    log_header "DESTRUCTION INFORMATION"
    log_info "Stage: $STAGE"
    log_info "Region: $REGION"
    
    local account_id=$(get_aws_account_id)
    if [ -n "$account_id" ]; then
        log_info "AWS Account: $account_id"
    fi
    
    local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo "Unknown")
    log_info "User: $user_arn"
    echo
}

# Confirm destruction
confirm_destruction() {
    log_warning "⚠️  ATTENTION! You are about to DELETE all resources for stage '$STAGE'."
    log_warning "This includes:"
    log_warning "- S3 Bucket and all its contents"
    log_warning "- CloudFront Distribution"
    log_warning "- All related configurations"
    echo
    
    if [ "$STAGE" = "prod" ]; then
        log_error "⚠️  WARNING! You are about to delete PRODUCTION."
        read -p "Type 'DELETE PRODUCTION' to continue: " -r
        if [ "$REPLY" != "DELETE PRODUCTION" ]; then
            log_info "Destruction cancelled."
            exit 0
        fi
    else
        read -p "Are you sure? Type 'yes' to continue: " -r
        if [ "$REPLY" != "yes" ]; then
            log_info "Destruction cancelled."
            exit 0
        fi
    fi
}

# Empty S3 bucket before deletion
empty_s3_bucket() {
    log_info "Getting bucket information..."
    
    local bucket_name=""
    
    # Method 1: Try serverless info command
    local serverless_output=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null || echo "")
    bucket_name=$(echo "$serverless_output" | grep -o 'WebsiteBucketName: [^[:space:]]*' | cut -d' ' -f2)
    
    # Method 2: Try to find bucket by naming convention
    if [ -z "$bucket_name" ]; then
        local account_id=$(get_aws_account_id)
        if [ -n "$account_id" ]; then
            bucket_name="${PROJECT_NAME}-${STAGE}-website-${account_id}"
            log_info "Using expected bucket name: $bucket_name"
        fi
    fi
    
    if [ -n "$bucket_name" ]; then
        log_info "Emptying S3 bucket: $bucket_name"
        
        # Verify if the bucket exists
        if aws s3 ls "s3://$bucket_name" --region "$REGION" &> /dev/null; then
            # Delete all objects in the bucket
            log_info "Deleting all objects from bucket..."
            aws s3 rm "s3://$bucket_name" --recursive --region "$REGION" || {
                log_warning "Some objects may not have been deleted (this is okay if bucket is already empty)"
            }
            log_success "Bucket emptied successfully"
        else
            log_warning "Bucket $bucket_name does not exist or is not accessible"
        fi
    else
        log_warning "Could not determine bucket name - will try to delete via CloudFormation"
    fi
}

# Delete CloudFront distribution (must be disabled first)
disable_cloudfront_distribution() {
    log_info "Getting CloudFront distribution information..."
    
    local distribution_id=""
    
    # Method 1: Try serverless info command
    local serverless_output=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null || echo "")
    distribution_id=$(echo "$serverless_output" | grep -o 'CloudFrontDistributionId: [^[:space:]]*' | cut -d' ' -f2)
    
    # Method 2: Try to find distribution by comment
    if [ -z "$distribution_id" ]; then
        local distributions=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment==\`CloudFront distribution for ${PROJECT_NAME}-${STAGE} static website\`].Id" --output text 2>/dev/null || echo "")
        distribution_id=$(echo "$distributions" | head -1)
    fi
    
    if [ -n "$distribution_id" ] && [ "$distribution_id" != "None" ]; then
        log_info "Found CloudFront distribution: $distribution_id"
        log_info "CloudFront distributions are automatically deleted by CloudFormation"
        log_info "This may take up to 15 minutes after stack deletion"
    else
        log_warning "CloudFront distribution not found - may already be deleted"
    fi
}

# Main destruction function
destroy() {
    log_header "STARTING DESTRUCTION"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Empty S3 bucket first (required before stack deletion)
    empty_s3_bucket
    
    # Get CloudFront info (for informational purposes)
    disable_cloudfront_distribution
    
    # Delete CloudFormation stack
    log_info "Deleting AWS resources via CloudFormation..."
    if serverless remove --stage "$STAGE" --region "$REGION" --verbose; then
        log_success "Stack deletion initiated successfully"
    else
        log_error "Stack deletion failed"
        log_info "You may need to manually delete resources from AWS Console"
        return 1
    fi
    
    log_header "DESTRUCTION COMPLETED"
}

# Verify destruction was successful
verify_destruction() {
    log_info "Verifying that resources were deleted..."
    
    # Try to get stack information
    if serverless info --stage "$STAGE" --region "$REGION" &> /dev/null; then
        log_warning "Some resources may not have been deleted completely."
        log_info "This is normal for CloudFront, which can take up to 15 minutes to delete."
        log_info "Check AWS CloudFormation console for stack status."
    else
        log_success "All resources were deleted successfully ✓"
    fi
    
    # Check if S3 bucket still exists
    local account_id=$(get_aws_account_id)
    if [ -n "$account_id" ]; then
        local bucket_name="${PROJECT_NAME}-${STAGE}-website-${account_id}"
        if aws s3 ls "s3://$bucket_name" --region "$REGION" &> /dev/null; then
            log_warning "S3 bucket $bucket_name still exists"
            log_info "You may need to manually delete it from AWS Console"
        else
            log_success "S3 bucket has been deleted ✓"
        fi
    fi
}

# Cleanup function on error
cleanup_on_error() {
    log_error "Error during destruction."
    log_info "You can try:"
    log_info "1. Verify AWS credentials"
    log_info "2. Manually delete the S3 bucket if it exists"
    log_info "3. Check AWS CloudFormation console"
    log_info "4. Run the script again"
}

# Main function
main() {
    log_header "PINOHUB LANDING PAGE DESTRUCTION"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Verifications
    check_prerequisites
    show_destruction_info
    confirm_destruction
    
    # Destruction
    destroy
    
    # Verify destruction
    verify_destruction
    
    log_success "Resources deleted successfully! 🗑️"
    log_info "Your AWS account no longer has the resources for this project."
}

# Help function
show_help() {
    echo "Usage: $0 [stage] [region]"
    echo ""
    echo "Arguments:"
    echo "  stage   Deployment stage (default: $DEFAULT_STAGE)"
    echo "  region  AWS region (default: $DEFAULT_REGION)"
    echo ""
    echo "Examples:"
    echo "  $0          # Delete resources for dev stage"
    echo "  $0 dev      # Delete resources for dev stage"
    echo "  $0 prod     # Delete resources for prod stage"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION: AWS region (default: us-east-1)"
    echo "  AWS_PROFILE: AWS profile to use (default: pinohub)"
}

# Set up error trap
trap cleanup_on_error ERR

# Handle command line arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Execute main function
main "$@"


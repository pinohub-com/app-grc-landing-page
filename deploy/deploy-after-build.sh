#!/bin/bash

# Pinohub Landing Page Deployment Script (Post-Build)
# This script deploys the prepared artifacts to AWS
# Usage: ./deploy-after-build.sh [stage] [region]
# Prerequisites: Run ./build.sh first

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")/src"
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

# Logging functions - output to stderr so they don't get captured in command substitution
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if build artifacts exist
check_build_artifacts() {
    log_info "=========================================="
    log_info "BUILD ARTIFACTS CHECK - Verifying build artifacts"
    log_info "=========================================="
    
    local build_dir="build-artifacts/${STAGE}"
    
    log_info "Checking for build artifacts directory: $build_dir"
    
    if [ ! -d "$build_dir" ]; then
        log_error "Build artifacts directory not found: $build_dir"
        log_error "Please run ./build.sh first to prepare the deployment artifacts"
        log_info "Available directories:"
        ls -la build-artifacts/ 2>/dev/null || log_warning "build-artifacts directory does not exist"
        exit 1
    fi
    
    log_success "Build artifacts directory found: $build_dir"
    
    # Check for required files
    local required_files=("build-info.json" "index.html")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$build_dir/$file" ]; then
            log_error "Required file not found: $build_dir/$file"
            missing_files+=("$file")
        else
            log_success "Found required file: $file"
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        log_error "Missing required files: ${missing_files[*]}"
        log_error "Build artifacts appear to be incomplete"
        log_info "Contents of build artifacts directory:"
        ls -la "$build_dir" 2>/dev/null | head -20 || log_warning "Could not list build artifacts directory"
        exit 1
    fi
    
    log_success "=========================================="
    log_success "BUILD ARTIFACTS CHECK - Completed successfully"
    log_success "=========================================="
}

# Check if AWS profile exists and is valid
check_aws_profile() {
    log_info "Checking AWS profile configuration..."
    
    # Check if AWS_PROFILE is set
    if [ -z "$AWS_PROFILE" ]; then
        log_error "AWS_PROFILE is not set"
        log_error "Please set AWS_PROFILE environment variable or configure it in the script"
        return 1
    fi
    
    log_info "AWS_PROFILE is set to: $AWS_PROFILE"
    
    # Test if the profile actually works by trying to get caller identity
    log_info "Testing profile '$AWS_PROFILE' with AWS CLI..."
    local test_output=$(aws sts get-caller-identity --profile "$AWS_PROFILE" 2>&1)
    local test_exit_code=$?
    
    if [ $test_exit_code -eq 0 ]; then
        log_success "Profile '$AWS_PROFILE' is valid and working"
        return 0
    else
        log_error "Profile '$AWS_PROFILE' is not working"
        log_error "AWS CLI error output: $test_output"
        return 1
    fi
}

# Get AWS Account ID
get_aws_account_id() {
    # Suppress stderr to avoid error messages in output
    local caller_identity=$(aws sts get-caller-identity 2>/dev/null)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$caller_identity" ]; then
        return 1
    fi
    
    # Try to parse with jq if available, otherwise use basic parsing
    local account_id=""
    if command -v jq &> /dev/null; then
        account_id=$(echo "$caller_identity" | jq -r '.Account' 2>/dev/null)
    else
        account_id=$(echo "$caller_identity" | grep -o '"Account":"[^"]*"' | cut -d'"' -f4 2>/dev/null)
        if [ -z "$account_id" ]; then
            account_id=$(echo "$caller_identity" | grep -o '[0-9]\{12\}' 2>/dev/null | head -1)
        fi
    fi
    
    # Validate account ID (should be 12 digits)
    if [ -n "$account_id" ]; then
        local len=${#account_id}
        if [ "$len" -eq 12 ] && echo "$account_id" | grep -qE '^[0-9]{12}$'; then
            echo "$account_id"
            return 0
        fi
    fi
    
    return 1
}

# Check AWS credentials
check_aws_credentials() {
    log_info "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        log_error "Please configure AWS credentials using:"
        log_error "aws configure"
        exit 1
    fi
    
    local caller_identity=$(aws sts get-caller-identity)
    
    if command -v jq &> /dev/null; then
        local account_id=$(echo $caller_identity | jq -r '.Account')
        local user_arn=$(echo $caller_identity | jq -r '.Arn')
    else
        local account_id=$(echo $caller_identity | grep -o '"Account":"[^"]*"' | cut -d'"' -f4)
        local user_arn=$(echo $caller_identity | grep -o '"Arn":"[^"]*"' | cut -d'"' -f4)
    fi
    
    log_success "AWS credentials validated"
    log_info "Account ID: $account_id"
    log_info "User/Role: $user_arn"
}

# Deploy the service
deploy_service() {
    log_info "Deploying service to stage: $STAGE, region: $REGION"
    
    # Ensure we're in the correct directory
    if [ ! -f "serverless.yml" ]; then
        log_error "No serverless configuration files found in current directory"
        log_error "Expected to find serverless.yml"
        exit 1
    fi
    
    # Set environment variables for deployment
    export AWS_REGION="$REGION"
    
    # Deploy with error handling
    if serverless deploy \
        --stage "$STAGE" \
        --region "$REGION" \
        --verbose; then
        log_success "Deployment completed successfully"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Sync website files to S3 bucket
sync_website_to_s3() {
    log_info "=========================================="
    log_info "S3 SYNC PHASE - Starting website sync"
    log_info "=========================================="
    
    # Try to get the S3 bucket name from serverless outputs first
    local bucket_name=""
    
    log_info "Step 1: Finding S3 bucket name..."
    
    # Method 1: Try serverless info command
    log_info "Method 1: Checking serverless info output..."
    local serverless_output=$(serverless info --stage "$STAGE" --region "$REGION" 2>&1)
    bucket_name=$(echo "$serverless_output" | grep -o 'WebsiteBucketName: [^[:space:]]*' | cut -d' ' -f2)
    if [ -n "$bucket_name" ]; then
        log_success "Found bucket name from serverless info: $bucket_name"
    else
        log_warning "Bucket name not found in serverless info"
    fi
    
    # Method 2: Try to find bucket in AWS
    if [ -z "$bucket_name" ]; then
        log_info "Method 2: Searching AWS for existing buckets..."
        local account_id=$(get_aws_account_id)
        if [ -n "$account_id" ]; then
            local aws_buckets=$(aws s3api list-buckets --region "$REGION" --query "Buckets[?contains(Name, '${PROJECT_NAME}-${STAGE}-website-${account_id}')].Name" --output text 2>&1)
            bucket_name=$(echo "$aws_buckets" | head -1)
            if [ -n "$bucket_name" ] && [ "$bucket_name" != "None" ]; then
                log_success "Found bucket name from AWS search: $bucket_name"
            fi
        fi
    fi
    
    # Method 3: Use expected naming convention with account ID
    if [ -z "$bucket_name" ]; then
        local account_id=$(get_aws_account_id)
        if [ -n "$account_id" ]; then
            bucket_name="${PROJECT_NAME}-${STAGE}-website-${account_id}"
            log_info "Method 3: Using expected bucket name with account ID: $bucket_name"
        else
            log_error "Failed to get AWS account ID for bucket name"
            return 1
        fi
    fi
    
    log_info "Final bucket name: $bucket_name"
    
    # Check if bucket exists
    log_info "Step 2: Verifying bucket exists..."
    if aws s3 ls "s3://$bucket_name" --region "$REGION" > /dev/null 2>&1; then
        log_success "Bucket exists and is accessible"
    else
        log_error "S3 bucket does not exist or is not accessible: $bucket_name"
        return 1
    fi
    
    # Locate source files (use build artifacts if available, otherwise use source dir)
    log_info "Step 3: Locating website files..."
    local source_dir=""
    local build_dir="build-artifacts/${STAGE}"
    
    if [ -d "$build_dir" ] && [ -f "$build_dir/index.html" ]; then
        source_dir="$build_dir"
        log_info "Using build artifacts directory: $source_dir"
    elif [ -d "$SOURCE_DIR" ] && [ -f "$SOURCE_DIR/index.html" ]; then
        source_dir="$SOURCE_DIR"
        log_info "Using source directory: $source_dir"
    else
        log_error "Website source directory not found"
        log_error "Expected: $build_dir or $SOURCE_DIR"
        return 1
    fi
    
    log_success "Found website source directory: $source_dir"
    
    # Sync files to S3
    log_info "Step 4: Syncing website to S3..."
    log_info "Source: $source_dir"
    log_info "Target: s3://$bucket_name/"
    log_info "Region: $REGION"
    
    # Use s3 sync to upload all files
    # Set appropriate cache headers for different file types
    local sync_result=$(aws s3 sync "$source_dir" "s3://$bucket_name/" \
        --region "$REGION" \
        --cache-control "public, max-age=31536000, immutable" \
        --exclude "*.html" \
        --exclude "build-info.json" \
        2>&1)
    local sync_exit_code=$?
    
    # Upload HTML files with no-cache headers
    if [ $sync_exit_code -eq 0 ]; then
        log_info "Uploading HTML files with no-cache headers..."
        find "$source_dir" -name "*.html" -type f | while read -r html_file; do
            local relative_path="${html_file#$source_dir/}"
            local s3_path="s3://$bucket_name/$relative_path"
            
            aws s3 cp "$html_file" "$s3_path" \
                --content-type "text/html; charset=utf-8" \
                --cache-control "no-store, no-cache, must-revalidate, max-age=0" \
                --region "$REGION" \
                >/dev/null 2>&1 || log_warning "Failed to upload HTML file: $relative_path"
        done
        
        log_success "Website synced to S3 successfully"
    else
        log_error "Failed to sync website to S3"
        log_error "Sync exit code: $sync_exit_code"
        log_error "Sync result: $sync_result"
        return 1
    fi
    
    # Get CloudFront distribution ID
    log_info "Step 5: Getting CloudFront distribution ID..."
    local distribution_id=""
    
    # Try to get from serverless outputs
    local serverless_output=$(serverless info --stage "$STAGE" --region "$REGION" 2>&1)
    distribution_id=$(echo "$serverless_output" | grep -o 'CloudFrontDistributionId: [^[:space:]]*' | cut -d' ' -f2)
    
    if [ -z "$distribution_id" ]; then
        # Try to find distribution by tags or name pattern
        log_info "Searching for CloudFront distribution..."
        local distributions=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment==\`CloudFront distribution for ${PROJECT_NAME}-${STAGE} static website\`].Id" --output text 2>&1)
        distribution_id=$(echo "$distributions" | head -1)
    fi
    
    if [ -n "$distribution_id" ] && [ "$distribution_id" != "None" ]; then
        log_success "Found CloudFront distribution ID: $distribution_id"
        
        # Create CloudFront invalidation
        log_info "Step 6: Creating CloudFront invalidation..."
        local invalidation_result=$(aws cloudfront create-invalidation \
            --distribution-id "$distribution_id" \
            --paths "/*" \
            --region "$REGION" \
            2>&1)
        local invalidation_exit_code=$?
        
        if [ $invalidation_exit_code -eq 0 ]; then
            log_success "CloudFront invalidation created successfully"
        else
            log_warning "Failed to create CloudFront invalidation"
            log_info "You may need to manually invalidate the CloudFront cache"
        fi
    else
        log_warning "CloudFront distribution ID not found - skipping invalidation"
        log_info "The distribution may still be deploying. Invalidation can be done manually later."
    fi
    
    # Get the CloudFront URL
    log_info "Step 7: Getting CloudFront URL..."
    local cloudfront_url=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null | grep -o 'CloudFrontDistributionUrl: [^[:space:]]*' | cut -d' ' -f2)
    if [ -n "$cloudfront_url" ]; then
        log_success "CloudFront URL: $cloudfront_url"
        log_info "✅ Your website is accessible via HTTPS at: $cloudfront_url"
    else
        local cloudfront_domain=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null | grep -o 'CloudFrontDistributionDomain: [^[:space:]]*' | cut -d' ' -f2)
        if [ -n "$cloudfront_domain" ]; then
            cloudfront_url="https://$cloudfront_domain"
            log_success "CloudFront URL: $cloudfront_url"
            log_info "✅ Your website is accessible via HTTPS at: $cloudfront_url"
        else
            log_warning "CloudFront URL not found in serverless outputs"
        fi
    fi
    
    log_success "=========================================="
    log_success "S3 SYNC PHASE - Completed successfully"
    log_success "=========================================="
}

# Get deployment information
get_deployment_info() {
    log_info "Retrieving deployment information..."
    
    # Get CloudFront URL
    local cloudfront_url=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null | grep -o 'CloudFrontDistributionUrl: [^[:space:]]*' | cut -d' ' -f2)
    if [ -z "$cloudfront_url" ]; then
        local cloudfront_domain=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null | grep -o 'CloudFrontDistributionDomain: [^[:space:]]*' | cut -d' ' -f2)
        if [ -n "$cloudfront_domain" ]; then
            cloudfront_url="https://$cloudfront_domain"
        fi
    fi
    
    if [ -n "$cloudfront_url" ]; then
        log_success "CloudFront URL: $cloudfront_url"
    else
        log_warning "Could not retrieve CloudFront URL"
    fi
    
    # Get S3 bucket name
    local bucket_name=$(serverless info --stage "$STAGE" --region "$REGION" 2>/dev/null | grep -o 'WebsiteBucketName: [^[:space:]]*' | cut -d' ' -f2)
    if [ -n "$bucket_name" ]; then
        log_success "S3 Bucket: $bucket_name"
    fi
}

# Main deployment function
main() {
    log_info "Starting deployment of $PROJECT_NAME"
    log_info "Stage: $STAGE"
    log_info "Region: $REGION"
    log_info "Working directory: $SCRIPT_DIR"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run deployment steps
    check_build_artifacts
    
    # Check AWS profile first (before credentials check)
    if ! check_aws_profile; then
        log_error "AWS profile validation failed"
        exit 1
    fi
    
    check_aws_credentials
    
    # Verify we can get AWS account ID (needed for S3 bucket names)
    log_info "Verifying AWS account ID retrieval..."
    local test_account_id=$(get_aws_account_id 2>/dev/null)
    if [ -z "$test_account_id" ]; then
        log_error "Cannot retrieve AWS account ID - this is required for deployment"
        log_error "Please verify AWS credentials are configured correctly"
        exit 1
    else
        log_success "AWS Account ID verified: $test_account_id"
    fi
    
    # Deploy infrastructure FIRST
    log_info "=========================================="
    log_info "PHASE 1: INFRASTRUCTURE DEPLOYMENT"
    log_info "=========================================="
    if ! deploy_service; then
        log_error "Infrastructure deployment failed"
        exit 1
    fi
    log_success "✅ Infrastructure deployment completed"
    
    # Wait a moment for resources to be fully created
    log_info "Waiting for resources to be fully available..."
    sleep 5
    
    # Configure S3 and upload files
    log_info "=========================================="
    log_info "PHASE 2: S3 CONFIGURATION AND UPLOAD"
    log_info "=========================================="
    if ! sync_website_to_s3; then
        log_error "❌ S3 website sync failed"
        exit 1
    fi
    log_success "✅ S3 website sync completed"
    
    get_deployment_info
    
    log_success "Deployment process completed successfully!"
    log_info "Your landing page is now live and accessible via CloudFront"
}

# Help function
show_help() {
    echo "Usage: $0 [stage] [region]"
    echo ""
    echo "Arguments:"
    echo "  stage   Deployment stage (default: $DEFAULT_STAGE)"
    echo "  region  AWS region (default: $DEFAULT_REGION)"
    echo ""
    echo "Prerequisites:"
    echo "  - Run ./build.sh first to prepare all artifacts and files"
    echo "  - AWS CLI configured with appropriate credentials"
    echo "  - Build artifacts must exist in build-artifacts-{stage}/ directory"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy to dev stage in us-east-1"
    echo "  $0 prod               # Deploy to prod stage in us-east-1"
    echo "  $0 dev us-west-2      # Deploy to dev stage in us-west-2"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac


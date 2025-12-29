#!/bin/bash

# Pinohub Landing Page Deployment Script (Integrated)
# This script orchestrates the build and deployment phases into a single call
# Usage: ./deploy.sh [stage] [region]
# 
# This script calls:
#   1. build.sh - Prepares all artifacts and files
#   2. deploy-after-build.sh - Deploys to AWS
#
# For more control, you can run the phases separately:
#   ./build.sh [stage] [region]
#   ./deploy-after-build.sh [stage] [region]

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

# Check if required scripts exist
check_required_scripts() {
    log_info "Checking required scripts..."
    
    local required_scripts=("build.sh" "deploy-after-build.sh")
    local missing_scripts=()
    
    for script in "${required_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            log_success "Found: $script"
        else
            log_error "Missing: $script"
            missing_scripts+=("$script")
        fi
    done
    
    if [ ${#missing_scripts[@]} -ne 0 ]; then
        log_error "Missing required scripts: ${missing_scripts[*]}"
        log_error "Please ensure build.sh and deploy-after-build.sh are present"
        exit 1
    fi
}

# Make scripts executable
make_scripts_executable() {
    log_info "Ensuring scripts are executable..."
    
    chmod +x "$SCRIPT_DIR/build.sh" 2>/dev/null || log_warning "Could not make build.sh executable"
    chmod +x "$SCRIPT_DIR/deploy-after-build.sh" 2>/dev/null || log_warning "Could not make deploy-after-build.sh executable"
    
    log_success "Scripts are executable"
}

# Run build phase
run_build_phase() {
    log_info "🚀 Starting BUILD phase..."
    log_info "Running: ./build.sh $STAGE $REGION"
    
    # Ensure environment variables are passed to build script
    export STAGE
    export REGION
    
    if "$SCRIPT_DIR/build.sh" "$STAGE" "$REGION"; then
        log_success "✅ BUILD phase completed successfully"
        return 0
    else
        log_error "❌ BUILD phase failed"
        return 1
    fi
}

# Run deployment phase
run_deployment_phase() {
    log_info "🚀 Starting DEPLOYMENT phase..."
    log_info "Running: ./deploy-after-build.sh $STAGE $REGION"
    
    # Ensure environment variables are passed to deploy script
    export STAGE
    export REGION
    
    if "$SCRIPT_DIR/deploy-after-build.sh" "$STAGE" "$REGION"; then
        log_success "✅ DEPLOYMENT phase completed successfully"
        return 0
    else
        log_error "❌ DEPLOYMENT phase failed"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    
    # DO NOT clean up build artifacts - they are needed for debugging and retry
    # Build artifacts should persist even after deployment failure
    if [ "$DEPLOYMENT_FAILED" = "true" ]; then
        log_info "Deployment failed - build artifacts preserved for debugging"
        log_info "Build artifacts location: build-artifacts/${STAGE}/"
        log_info "You can retry deployment with: ./deploy-after-build.sh ${STAGE}"
    fi
}

# Main deployment function
main() {
    log_info "Starting integrated deployment of $PROJECT_NAME"
    log_info "Stage: $STAGE"
    log_info "Region: $REGION"
    log_info "Working directory: $SCRIPT_DIR"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Set up trap for cleanup on exit
    trap cleanup EXIT
    
    # Initialize deployment failure flag
    export DEPLOYMENT_FAILED="false"
    
    # Run pre-deployment checks
    check_required_scripts
    make_scripts_executable
    
    # Phase 1: Build
    log_info "=========================================="
    log_info "PHASE 1: BUILD AND PREPARATION"
    log_info "=========================================="
    
    if ! run_build_phase; then
        log_error "Build phase failed. Deployment aborted."
        exit 1
    fi
    
    # Phase 2: Deploy
    log_info "=========================================="
    log_info "PHASE 2: AWS DEPLOYMENT"
    log_info "=========================================="
    
    if ! run_deployment_phase; then
        log_error "Deployment phase failed."
        export DEPLOYMENT_FAILED="true"
        exit 1
    fi
    
    # Success
    log_success "=========================================="
    log_success "🎉 INTEGRATED DEPLOYMENT COMPLETED!"
    log_success "=========================================="
    log_info "Your landing page is now live and ready"
    log_info "The website has been uploaded to S3 and is accessible via CloudFront"
    
    # Show build artifacts location
    local build_dir="build-artifacts/${STAGE}"
    if [ -d "$build_dir" ]; then
        log_info "Build artifacts are available in: $build_dir/"
        log_info "You can reuse these artifacts for future deployments"
    fi
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
    echo "  $0                    # Deploy to dev stage in us-east-1"
    echo "  $0 prod               # Deploy to prod stage in us-east-1"
    echo "  $0 dev us-west-2      # Deploy to dev stage in us-west-2"
    echo ""
    echo "What this script does (INTEGRATED DEPLOYMENT):"
    echo "  🔧 PHASE 1 - BUILD:"
    echo "     • Sets stage-specific environment variables"
    echo "     • Installs all dependencies (Node.js, Serverless Framework)"
    echo "     • Creates build artifacts directory"
    echo "     • Prepares all files for deployment"
    echo "  🚀 PHASE 2 - DEPLOY:"
    echo "     • Validates AWS credentials"
    echo "     • Deploys infrastructure using Serverless Framework"
    echo "     • Configures S3 bucket and uploads website files"
    echo "     • Creates CloudFront invalidation"
    echo "     • Provides deployment information"
    echo ""
    echo "This script is equivalent to running:"
    echo "  ./build.sh [stage] [region]"
    echo "  ./deploy-after-build.sh [stage] [region]"
    echo ""
    echo "For more control, you can run the phases separately:"
    echo "  ./build.sh [stage] [region]        # Build phase only"
    echo "  ./deploy-after-build.sh [stage] [region]  # Deploy phase only"
    echo ""
    echo "Prerequisites:"
    echo "  - Node.js (>=18.0.0)"
    echo "  - AWS CLI configured"
    echo "  - Internet connection for dependency installation"
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
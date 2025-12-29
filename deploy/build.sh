#!/bin/bash

# Pinohub Landing Page Build Script
# This script prepares all artifacts and files necessary for deployment
# Usage: ./build.sh [stage] [region]

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

# Logging functions
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

# Check if required tools are installed
check_dependencies() {
    log_info "Checking and installing required dependencies..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install it first:"
        log_error "https://nodejs.org/"
        exit 1
    fi
    
    # Check Node.js version
    local node_version=$(node --version | cut -d'v' -f2)
    local required_version="18.0.0"
    
    if [ "$(printf '%s\n' "$required_version" "$node_version" | sort -V | head -n1)" != "$required_version" ]; then
        log_error "Node.js version $node_version is too old. Required: $required_version or higher"
        exit 1
    fi
    
    log_success "Node.js version $node_version is compatible"
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        log_error "npm is not available. Please install Node.js with npm:"
        log_error "https://nodejs.org/"
        exit 1
    fi
    
    # Install serverless globally if not available
    if ! command -v serverless &> /dev/null; then
        log_info "Installing Serverless Framework globally..."
        npm install -g serverless@latest --silent
        
        if ! command -v serverless &> /dev/null; then
            log_error "Failed to install Serverless Framework"
            exit 1
        fi
        log_success "Serverless Framework installed globally"
    else
        log_success "Serverless Framework is already installed"
    fi
    
    log_success "✅ All required tools are available"
}

# Install dependencies
install_dependencies() {
    log_info "🚀 Installing all required dependencies automatically..."
    log_info "📦 This script will install:"
    log_info "   • Global Serverless Framework (if not already installed)"
    log_info "   • Serverless Framework dependencies"
    log_info ""
    
    # Install dependencies in infra directory (Serverless Framework dependencies)
    cd "$SCRIPT_DIR"
    
    if [ -f "package.json" ]; then
        log_info "Installing Serverless Framework dependencies..."
        log_info "Current directory: $(pwd)"
        
        # Clean install to ensure all dependencies are fresh
        rm -rf node_modules package-lock.json 2>/dev/null || true
        
        # Install dependencies and capture output/errors
        log_info "Running npm install..."
        if ! npm install 2>&1; then
            log_error "❌ npm install failed!"
            log_error "Current directory: $(pwd)"
            log_error "package.json exists: $([ -f package.json ] && echo 'YES' || echo 'NO')"
            exit 1
        fi
        
        log_success "✅ Serverless Framework dependencies installed and verified"
    else
        log_warning "No package.json found in infra directory, skipping dependency installation"
    fi
    
    log_success "🎉 All dependencies installed successfully - ready for deployment"
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
        log_error ""
        log_error "Troubleshooting steps:"
        log_error "1. Verify the profile exists: aws configure list-profiles"
        log_error "2. Check profile credentials: aws configure list --profile $AWS_PROFILE"
        log_error "3. Test the profile: aws sts get-caller-identity --profile $AWS_PROFILE"
        log_error "4. If profile doesn't exist, create it: aws configure --profile $AWS_PROFILE"
        return 1
    fi
}

# Create build artifacts directory
create_build_artifacts() {
    log_info "=========================================="
    log_info "BUILD ARTIFACTS - Creating build artifacts"
    log_info "=========================================="
    
    # Create organized build artifacts structure
    local build_base_dir="build-artifacts"
    local build_dir="${build_base_dir}/${STAGE}"
    mkdir -p "$build_dir"
    
    log_info "Build artifacts directory: $build_dir"
    
    # Copy source files to build directory
    if [ -d "$SOURCE_DIR" ]; then
        log_info "Copying source files to build artifacts..."
        cp -r "$SOURCE_DIR"/* "$build_dir/" 2>/dev/null || {
            log_warning "Some files may not have been copied (this is okay if they don't exist)"
        }
        log_success "Source files copied to build artifacts"
    else
        log_error "Source directory not found: $SOURCE_DIR"
        return 1
    fi
    
    # Create build info file
    log_info "Creating build info file..."
    cat > "$build_dir/build-info.json" << EOF
{
    "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "stage": "$STAGE",
    "region": "$REGION",
    "project_name": "$PROJECT_NAME",
    "source_dir": "$SOURCE_DIR"
}
EOF
    
    log_success "Build info file created"
    
    # Verify build artifacts were created
    log_info "Verifying build artifacts..."
    local artifact_count=$(find "$build_dir" -type f | wc -l)
    log_info "Total files in build artifacts: $artifact_count"
    
    if [ $artifact_count -gt 0 ]; then
        log_success "Build artifacts created successfully in: $build_dir"
        log_info "Build artifacts include:"
        ls -la "$build_dir" 2>/dev/null | head -20 || log_warning "Could not list build artifacts"
    else
        log_error "No build artifacts were created!"
        return 1
    fi
    
    log_success "=========================================="
    log_success "BUILD ARTIFACTS - Completed successfully"
    log_success "=========================================="
}

# Main build function
main() {
    log_info "Starting build process for $PROJECT_NAME"
    log_info "Stage: $STAGE"
    log_info "Region: $REGION"
    log_info "Working directory: $SCRIPT_DIR"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run build steps
    check_dependencies
    install_dependencies
    
    # Check AWS profile before any AWS operations
    if ! check_aws_profile; then
        log_error "AWS profile validation failed"
        exit 1
    fi
    
    # Create build artifacts
    if ! create_build_artifacts; then
        log_error "Build artifacts creation failed"
        exit 1
    fi
    
    log_success "Build process completed successfully!"
    log_info "All artifacts and files are ready for deployment"
    log_info "Run ./deploy-after-build.sh to deploy to AWS"
    log_info "Build artifacts are available in: build-artifacts/${STAGE}/"
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
    echo "  $0                    # Build for dev stage in us-east-1"
    echo "  $0 prod               # Build for prod stage in us-east-1"
    echo "  $0 dev us-west-2      # Build for dev stage in us-west-2"
    echo ""
    echo "What this script does (BUILD PHASE):"
    echo "  🔧 ENVIRONMENT SETUP:"
    echo "     • Validates environment configuration"
    echo "  📦 DEPENDENCY INSTALLATION:"
    echo "     • Installs Serverless Framework globally (if needed)"
    echo "     • Installs Serverless Framework dependencies"
    echo "     • Verifies all dependencies are correctly installed"
    echo "  📄 BUILD ARTIFACTS:"
    echo "     • Copies source files to build artifacts directory"
    echo "     • Creates build info file"
    echo "     • Prepares all files for deployment"
    echo ""
    echo "After running this script:"
    echo "  • All dependencies are installed"
    echo "  • Build artifacts are ready in build-artifacts/${STAGE}/"
    echo "  • Run ./deploy-after-build.sh to complete deployment"
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


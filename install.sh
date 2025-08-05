#!/bin/bash

# Snape - Snippet Manager Installation Script
# This script downloads and installs the Snape snippet manager from GitHub releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BINARY_NAME="snape"
INSTALL_DIR="/usr/local/bin"
REPO_URL="https://github.com/rgcr/snape"
API_URL="https://api.github.com/repos/rgcr/snape/releases/latest"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists go; then
        print_error "Go is not installed. Please install Go 1.19 or later."
        print_status "Visit: https://golang.org/doc/install"
        exit 1
    fi
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git."
        exit 1
    fi
    
    GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
    print_status "Found Go version: $GO_VERSION"
    
    # Check if we can write to install directory
    if [ ! -w "$INSTALL_DIR" ] && [ "$EUID" -ne 0 ]; then
        print_warning "Cannot write to $INSTALL_DIR without sudo privileges"
        print_status "You may need to run this script with sudo or choose a different install directory"
    fi
}

# Download and build the application
download_and_build() {
    print_status "Downloading Snape from $REPO_URL..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone the repository
    if ! git clone "$REPO_URL" snape; then
        print_error "Failed to clone repository"
        exit 1
    fi
    
    cd snape
    print_success "Repository downloaded successfully"
    
    print_status "Building Snape snippet manager..."
    
    # Build the binary
    if go build -o "$BINARY_NAME" -ldflags "-s -w" .; then
        print_success "Build completed successfully"
        # Move binary to original location for installation
        mv "$BINARY_NAME" "$OLDPWD/"
        cd "$OLDPWD"
        rm -rf "$TEMP_DIR"
    else
        print_error "Build failed"
        cd "$OLDPWD"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
}

# Install the binary
install_binary() {
    print_status "Installing $BINARY_NAME to $INSTALL_DIR..."
    
    # Try to install without sudo first
    if cp "$BINARY_NAME" "$INSTALL_DIR/" 2>/dev/null; then
        print_success "Installed $BINARY_NAME to $INSTALL_DIR"
    else
        # If that fails, try with sudo
        print_status "Attempting installation with sudo..."
        if sudo cp "$BINARY_NAME" "$INSTALL_DIR/"; then
            print_success "Installed $BINARY_NAME to $INSTALL_DIR (with sudo)"
        else
            print_error "Failed to install $BINARY_NAME to $INSTALL_DIR"
            print_status "You can manually copy the binary:"
            print_status "  sudo cp $BINARY_NAME $INSTALL_DIR/"
            print_status "Or copy it to a directory in your PATH"
            exit 1
        fi
    fi
    
    # Make sure the binary is executable
    chmod +x "$INSTALL_DIR/$BINARY_NAME" 2>/dev/null || sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
}

# Create snippets directory
setup_snippets_dir() {
    SNIPPETS_DIR="$HOME/.snape"
    print_status "Setting up snippets directory at $SNIPPETS_DIR..."
    
    if [ ! -d "$SNIPPETS_DIR" ]; then
        mkdir -p "$SNIPPETS_DIR"
        print_success "Created snippets directory: $SNIPPETS_DIR"
    else
        print_status "Snippets directory already exists: $SNIPPETS_DIR"
    fi
}

# Display installation summary
show_summary() {
    print_success "Installation completed successfully!"
    echo
    print_status "Summary:"
    echo "  • Binary installed: $INSTALL_DIR/$BINARY_NAME"
    echo "  • Snippets directory: $HOME/.snape"
    echo
    print_status "Usage:"
    echo "  $BINARY_NAME                    # Launch snippet selector"
    echo "  $BINARY_NAME --help             # Show help"
    echo "  $BINARY_NAME --verbose          # Verbose output"
    echo
    print_status "To get started:"
    echo "  1. Add your snippets to ~/.snape/ as text files"
    echo "  2. Run '$BINARY_NAME' to select and copy snippets"
    echo
    print_status "Keyboard shortcuts:"
    echo "  • a-z, A-Z: Quick selection by index"
    echo "  • /: Filter mode"
    echo "  • ↑↓: Navigate, Enter: Select"
    echo "  • ?: Show about dialog"
}

# Cleanup function
cleanup() {
    if [ -f "$BINARY_NAME" ] && [ "$BINARY_NAME" != "$INSTALL_DIR/$BINARY_NAME" ]; then
        print_status "Cleaning up build artifacts..."
        rm -f "$BINARY_NAME"
    fi
}

# Main installation process
main() {
    echo -e "${BLUE}🧙 Snape - Snippet Manager Installation${NC}"
    echo "========================================"
    echo
    
    # Parse command line arguments
    LOCAL_INSTALL=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local)
                LOCAL_INSTALL=true
                INSTALL_DIR="$HOME/.local/bin"
                mkdir -p "$INSTALL_DIR"
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo
                echo "This script downloads and builds Snape from GitHub:"
                echo "Repository: $REPO_URL"
                echo
                echo "Options:"
                echo "  --local         Install to ~/.local/bin instead of /usr/local/bin"
                echo "  --help          Show this help message"
                echo
                echo "Prerequisites:"
                echo "  • Go 1.19+ (for building)"
                echo "  • Git (for downloading source)"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run installation steps
    check_prerequisites
    download_and_build
    install_binary
    setup_snippets_dir
    cleanup
    show_summary
}

# Handle interruption
trap cleanup EXIT

# Run main function
main "$@"
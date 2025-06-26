#!/bin/bash

# COVID Elections Project Sync Script
# Syncs project from development host (osprey) to web host (bataleon)
# Author: Raymond
# Date: $(date)

set -e  # Exit on any error

# Configuration
DEV_HOST="osprey"
DEV_USER="raymond"
DEV_PATH="/Users/raymond/covid_elections"

WEB_HOST="bataleon"
WEB_USER="raymond"
WEB_PATH="/var/www/html/covid_elections"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if we can connect to hosts
check_connectivity() {
    print_status "Checking connectivity to hosts..."
    
    # Check development host
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${DEV_USER}@${DEV_HOST}" exit 2>/dev/null; then
        print_success "Connected to development host (${DEV_HOST})"
    else
        print_error "Cannot connect to development host (${DEV_HOST})"
        exit 1
    fi
    
    # Check web host
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${WEB_USER}@${WEB_HOST}" exit 2>/dev/null; then
        print_success "Connected to web host (${WEB_HOST})"
    else
        print_error "Cannot connect to web host (${WEB_HOST})"
        exit 1
    fi
}

# Function to create backup on web host
create_backup() {
    print_status "Creating backup on web host..."
    
    BACKUP_DIR="/tmp/covid_elections_backup_$(date +%Y%m%d_%H%M%S)"
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        if [ -d '${WEB_PATH}' ]; then
            cp -r '${WEB_PATH}' '${BACKUP_DIR}'
            echo 'Backup created at: ${BACKUP_DIR}'
        else
            echo 'No existing directory to backup'
        fi
    "
}

# Function to ensure web directory exists with correct permissions
setup_web_directory() {
    print_status "Setting up web directory..."
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        # Create directory if it doesn't exist
        sudo mkdir -p '${WEB_PATH}'
        
        # Set ownership to www-data (typical web server user)
        sudo chown -R www-data:www-data '${WEB_PATH}'
        
        # Set permissions: directories 755, files 644
        sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \;
        sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \;
        
        # Make sure the raymond user can write to it
        sudo chmod g+w '${WEB_PATH}'
        sudo usermod -a -G www-data raymond || true
    "
}

# Function to sync files
sync_files() {
    print_status "Syncing files from ${DEV_HOST} to ${WEB_HOST}..."
    
    # First, copy from dev host to local temp directory
    LOCAL_TEMP="/tmp/covid_elections_sync_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$LOCAL_TEMP"
    
    print_status "Copying from development host to local temp..."
    scp -r "${DEV_USER}@${DEV_HOST}:${DEV_PATH}/" "$LOCAL_TEMP/"
    
    # Clean up unnecessary files
    print_status "Cleaning up unnecessary files..."
    find "$LOCAL_TEMP" -name ".DS_Store" -delete 2>/dev/null || true
    find "$LOCAL_TEMP" -name "*.tmp" -delete 2>/dev/null || true
    find "$LOCAL_TEMP" -name "Thumbs.db" -delete 2>/dev/null || true
    
    # Copy the dashboard HTML file to the root of the web directory
    if [ -f "covid_dashboard.html" ]; then
        cp "covid_dashboard.html" "$LOCAL_TEMP/covid_elections/"
        print_status "Added dashboard HTML file to sync"
    fi
    
    # Now sync to web host
    print_status "Copying to web host..."
    
    # Use rsync for efficient transfer with delete option to remove files not in source
    rsync -avz --delete \
        --exclude='.git/' \
        --exclude='*.log' \
        --exclude='node_modules/' \
        --exclude='.env' \
        "$LOCAL_TEMP/covid_elections/" \
        "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/"
    
    # Clean up local temp
    rm -rf "$LOCAL_TEMP"
    
    print_success "Files synced successfully"
}

# Function to set final permissions
set_final_permissions() {
    print_status "Setting final permissions on web host..."
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        # Ensure www-data owns everything
        sudo chown -R www-data:www-data '${WEB_PATH}'
        
        # Set proper permissions
        sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \;
        sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \;
        
        # Make HTML files executable for web server
        sudo find '${WEB_PATH}' -name '*.html' -exec chmod 644 {} \;
        sudo find '${WEB_PATH}' -name '*.css' -exec chmod 644 {} \;
        sudo find '${WEB_PATH}' -name '*.js' -exec chmod 644 {} \;
        sudo find '${WEB_PATH}' -name '*.csv' -exec chmod 644 {} \;
        
        # Create index.html if dashboard exists
        if [ -f '${WEB_PATH}/covid_dashboard.html' ] && [ ! -f '${WEB_PATH}/index.html' ]; then
            sudo ln -sf covid_dashboard.html '${WEB_PATH}/index.html'
        fi
    "
}

# Function to verify sync
verify_sync() {
    print_status "Verifying sync..."
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        echo 'Files in web directory:'
        ls -la '${WEB_PATH}/' | head -20
        echo ''
        echo 'Directory size:'
        du -sh '${WEB_PATH}'
        echo ''
        echo 'Key data files:'
        find '${WEB_PATH}' -name '*.csv' | wc -l | xargs echo 'CSV files found:'
        find '${WEB_PATH}' -name '*.html' | wc -l | xargs echo 'HTML files found:'
    "
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -n, --no-backup     Skip backup creation"
    echo "  -v, --verify-only   Only verify the sync, don't perform it"
    echo "  -f, --force         Force sync without confirmation"
    echo ""
    echo "Examples:"
    echo "  $0                  # Interactive sync with backup"
    echo "  $0 -f               # Force sync without confirmation"
    echo "  $0 -n               # Sync without creating backup"
    echo "  $0 -v               # Just verify current state"
}

# Parse command line arguments
SKIP_BACKUP=false
VERIFY_ONLY=false
FORCE_SYNC=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -n|--no-backup)
            SKIP_BACKUP=true
            shift
            ;;
        -v|--verify-only)
            VERIFY_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE_SYNC=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "=================================="
    echo "COVID Elections Project Sync Tool"
    echo "=================================="
    echo ""
    
    # Check connectivity first
    check_connectivity
    
    if [ "$VERIFY_ONLY" = true ]; then
        verify_sync
        exit 0
    fi
    
    # Show current status
    print_status "Current sync configuration:"
    echo "  Development: ${DEV_USER}@${DEV_HOST}:${DEV_PATH}"
    echo "  Web Host:    ${WEB_USER}@${WEB_HOST}:${WEB_PATH}"
    echo "  Backup:      $([ "$SKIP_BACKUP" = true ] && echo "Disabled" || echo "Enabled")"
    echo ""
    
    # Confirmation prompt unless forced
    if [ "$FORCE_SYNC" != true ]; then
        read -p "Do you want to proceed with the sync? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Sync cancelled by user"
            exit 0
        fi
    fi
    
    # Execute sync steps
    if [ "$SKIP_BACKUP" != true ]; then
        create_backup
    fi
    
    setup_web_directory
    sync_files
    set_final_permissions
    verify_sync
    
    print_success "Sync completed successfully!"
    echo ""
    print_status "You can now access your COVID dashboard at:"
    echo "  http://${WEB_HOST}/covid_elections/"
    echo "  https://${WEB_HOST}/covid_elections/ (if SSL is configured)"
}

# Run main function
main "$@"
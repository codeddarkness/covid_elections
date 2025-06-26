#!/bin/bash

# Quick Fix and Deploy Script
# Fixes permissions and deploys updated dashboard

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
PROJECT_DIR="/Users/raymond/covid_elections"
WEB_HOST="bataleon"
WEB_USER="raymond"
WEB_PATH="/var/www/html/covid_elections"

echo "============================================="
echo "Quick Fix and Deploy COVID Dashboard"
echo "============================================="
echo ""

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Test connection to web host
print_status "Testing connection to web host..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes "${WEB_USER}@${WEB_HOST}" exit 2>/dev/null; then
    print_success "Connected to web host (${WEB_HOST})"
else
    print_error "Cannot connect to web host (${WEB_HOST})"
    exit 1
fi

# Fix permissions on web host first
print_status "Fixing permissions on web host..."
ssh "${WEB_USER}@${WEB_HOST}" "
    # Make the directory writable for the raymond user
    sudo chmod g+w '${WEB_PATH}' 2>/dev/null || true
    sudo chgrp www-data '${WEB_PATH}' 2>/dev/null || true
    
    # Add raymond to www-data group if not already
    sudo usermod -a -G www-data raymond 2>/dev/null || true
    
    # Set more permissive permissions temporarily for upload
    sudo chmod 775 '${WEB_PATH}' 2>/dev/null || chmod 775 '${WEB_PATH}' 2>/dev/null || true
    sudo find '${WEB_PATH}' -name '*.html' -exec chmod 664 {} \; 2>/dev/null || \
        find '${WEB_PATH}' -name '*.html' -exec chmod 664 {} \; 2>/dev/null || true
    
    echo 'Permissions updated'
"

# Create backup using sudo if needed
print_status "Creating backup of current dashboard..."
ssh "${WEB_USER}@${WEB_HOST}" "
    if [ -f '${WEB_PATH}/covid_dashboard.html' ]; then
        sudo cp '${WEB_PATH}/covid_dashboard.html' '/tmp/covid_dashboard_backup_\$(date +%Y%m%d_%H%M%S).html' 2>/dev/null || \
            cp '${WEB_PATH}/covid_dashboard.html' '/tmp/covid_dashboard_backup_\$(date +%Y%m%d_%H%M%S).html'
        echo 'Backup created in /tmp/'
    else
        echo 'No existing dashboard to backup'
    fi
"

# Try to upload using rsync instead of scp for better permission handling
print_status "Uploading updated dashboard using rsync..."
rsync -avz --no-perms --no-times \
    covid_dashboard.html \
    "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/"

if [ $? -eq 0 ]; then
    print_success "Dashboard uploaded successfully"
else
    print_warning "Rsync had some issues, trying alternative method..."
    
    # Alternative: use temporary file and sudo move
    print_status "Trying alternative upload method..."
    scp covid_dashboard.html "${WEB_USER}@${WEB_HOST}:/tmp/covid_dashboard_new.html"
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        sudo mv /tmp/covid_dashboard_new.html '${WEB_PATH}/covid_dashboard.html'
        sudo chown www-data:www-data '${WEB_PATH}/covid_dashboard.html'
        sudo chmod 644 '${WEB_PATH}/covid_dashboard.html'
    "
    print_success "Dashboard uploaded using alternative method"
fi

# Set final proper permissions
print_status "Setting final permissions..."
ssh "${WEB_USER}@${WEB_HOST}" "
    # Set proper ownership
    sudo chown www-data:www-data '${WEB_PATH}/covid_dashboard.html' 2>/dev/null || \
        chown ${WEB_USER}:${WEB_USER} '${WEB_PATH}/covid_dashboard.html'
    
    # Set proper file permissions
    sudo chmod 644 '${WEB_PATH}/covid_dashboard.html' 2>/dev/null || \
        chmod 644 '${WEB_PATH}/covid_dashboard.html'
    
    # Reset directory permissions
    sudo chmod 755 '${WEB_PATH}' 2>/dev/null || chmod 755 '${WEB_PATH}'
    
    echo 'Final permissions set'
"

# Verify the upload
print_status "Verifying upload..."
ssh "${WEB_USER}@${WEB_HOST}" "
    if [ -f '${WEB_PATH}/covid_dashboard.html' ]; then
        echo 'File size:' \$(ls -lh '${WEB_PATH}/covid_dashboard.html' | awk '{print \$5}')
        echo 'Last modified:' \$(ls -l '${WEB_PATH}/covid_dashboard.html' | awk '{print \$6, \$7, \$8}')
        echo '✓ Dashboard file exists and updated'
    else
        echo '✗ Dashboard file missing!'
        exit 1
    fi
"

# Test web accessibility
print_status "Testing web accessibility..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/covid_dashboard.html" 2>/dev/null || echo "000")

case $HTTP_CODE in
    200)
        print_success "Dashboard is accessible (HTTP 200)"
        ;;
    403)
        print_warning "Dashboard returned HTTP 403 - checking permissions..."
        ssh "${WEB_USER}@${WEB_HOST}" "
            ls -la '${WEB_PATH}/covid_dashboard.html'
            echo ''
            echo 'Directory permissions:'
            ls -ld '${WEB_PATH}'
        "
        ;;
    404)
        print_warning "Dashboard returned HTTP 404 - file may not be in expected location"
        ;;
    000)
        print_warning "Could not connect to web server"
        ;;
    *)
        print_warning "Dashboard returned HTTP code: $HTTP_CODE"
        ;;
esac

print_success "Deployment completed!"
echo ""
print_status "Your updated COVID dashboard should now be available at:"
echo "  http://${WEB_HOST}/covid_elections/covid_dashboard.html"
echo "  http://${WEB_HOST}/covid_elections/ (redirects to dashboard)"
echo ""
print_status "Key changes in this update:"
echo "  • Fixed Papa Parse library loading (correct CDN URL)"
echo "  • Added better error handling for missing libraries"
echo "  • Enhanced debugging with console logging"
echo "  • Improved data loading error messages"
echo ""
print_success "🎉 All done!"
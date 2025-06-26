#!/bin/bash

# Quick script to update just the dashboard HTML file
# Run this from your development machine (osprey)

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
PROJECT_DIR="/Users/raymond/covid_elections"
WEB_HOST="bataleon"
WEB_USER="raymond"
WEB_PATH="/var/www/html/covid_elections"
DASHBOARD_FILE="covid_dashboard.html"

echo "========================================="
echo "COVID Dashboard Quick Update"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Check if dashboard file exists
if [ ! -f "$DASHBOARD_FILE" ]; then
    print_error "Dashboard file not found: $DASHBOARD_FILE"
    print_status "Please save the updated dashboard HTML content to this file first."
    exit 1
fi

print_status "Found dashboard file: $DASHBOARD_FILE"

# Test connection to web host
print_status "Testing connection to web host..."
if ssh -o ConnectTimeout=5 -o BatchMode=yes "${WEB_USER}@${WEB_HOST}" exit 2>/dev/null; then
    print_success "Connected to web host (${WEB_HOST})"
else
    print_error "Cannot connect to web host (${WEB_HOST})"
    exit 1
fi

# Backup existing dashboard on web host
print_status "Creating backup of current dashboard..."
ssh "${WEB_USER}@${WEB_HOST}" "
    if [ -f '${WEB_PATH}/${DASHBOARD_FILE}' ]; then
        cp '${WEB_PATH}/${DASHBOARD_FILE}' '${WEB_PATH}/${DASHBOARD_FILE}.backup.$(date +%Y%m%d_%H%M%S)'
        echo 'Backup created'
    else
        echo 'No existing dashboard to backup'
    fi
"

# Copy updated dashboard file
print_status "Uploading updated dashboard..."
scp "$DASHBOARD_FILE" "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/${DASHBOARD_FILE}"

# Set proper permissions
print_status "Setting permissions..."
ssh "${WEB_USER}@${WEB_HOST}" "
    sudo chown www-data:www-data '${WEB_PATH}/${DASHBOARD_FILE}' 2>/dev/null || \
        chown ${WEB_USER}:${WEB_USER} '${WEB_PATH}/${DASHBOARD_FILE}'
    sudo chmod 644 '${WEB_PATH}/${DASHBOARD_FILE}' 2>/dev/null || \
        chmod 644 '${WEB_PATH}/${DASHBOARD_FILE}'
"

print_success "Dashboard updated successfully!"
echo ""
print_status "Your updated COVID dashboard is now available at:"
echo "  http://${WEB_HOST}/covid_elections/covid_dashboard.html"
echo ""

# Test the page
print_status "Testing dashboard accessibility..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/covid_dashboard.html" 2>/dev/null || echo "000")

case $HTTP_CODE in
    200)
        print_success "Dashboard is accessible (HTTP 200)"
        ;;
    *)
        print_error "Dashboard returned HTTP code: $HTTP_CODE"
        print_status "You may need to check your web server configuration"
        ;;
esac

echo ""
print_success "Update completed! 🎉"
print_status "Changes made:"
echo "  • Fixed Papa Parse library loading"
echo "  • Added better error handling for data loading"
echo "  • Added console logging for debugging"
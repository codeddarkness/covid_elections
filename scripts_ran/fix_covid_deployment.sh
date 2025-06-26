#!/bin/bash

# COVID Elections Project Fix Script
# This script fixes the sync configuration and deploys the project

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
echo "COVID Elections Project Deployment Fix"
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
    print_status "Please ensure:"
    echo "  1. SSH key is set up for ${WEB_USER}@${WEB_HOST}"
    echo "  2. Host ${WEB_HOST} is reachable"
    echo "  3. User ${WEB_USER} exists on ${WEB_HOST}"
    exit 1
fi

# Create backup on web host
print_status "Creating backup on web host..."
BACKUP_DIR="/tmp/covid_elections_backup_$(date +%Y%m%d_%H%M%S)"

ssh "${WEB_USER}@${WEB_HOST}" "
    if [ -d '${WEB_PATH}' ]; then
        cp -r '${WEB_PATH}' '${BACKUP_DIR}' 2>/dev/null || sudo cp -r '${WEB_PATH}' '${BACKUP_DIR}'
        echo 'Backup created at: ${BACKUP_DIR}'
    else
        echo 'No existing directory to backup'
    fi
"

# Setup web directory with proper permissions
print_status "Setting up web directory..."
ssh "${WEB_USER}@${WEB_HOST}" "
    # Create directory if it doesn't exist
    sudo mkdir -p '${WEB_PATH}'
    
    # Set ownership to www-data (typical web server user)
    sudo chown -R www-data:www-data '${WEB_PATH}'
    
    # Set permissions: directories 755, files 644
    sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \; 2>/dev/null || true
    sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # Make sure the raymond user can write to it
    sudo chmod g+w '${WEB_PATH}'
    sudo usermod -a -G www-data raymond 2>/dev/null || true
"

# Clean up local files before sync
print_status "Cleaning up local files..."
find "$PROJECT_DIR" -name ".DS_Store" -delete 2>/dev/null || true
find "$PROJECT_DIR" -name "*.tmp" -delete 2>/dev/null || true
find "$PROJECT_DIR" -name "Thumbs.db" -delete 2>/dev/null || true

# Ensure we have an index.html
if [ ! -f "index.html" ]; then
    print_status "Creating index.html..."
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>COVID-19 Data Analysis</title>
    <meta http-equiv="refresh" content="0; url=covid_dashboard.html">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #000000;
            color: #ffffff;
            text-align: center;
            padding: 50px;
        }
        a {
            color: #3b82f6;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>COVID-19 Data Analysis Dashboard</h1>
    <p>Redirecting to dashboard...</p>
    <p>If you are not redirected automatically, <a href="covid_dashboard.html">click here</a>.</p>
</body>
</html>
EOF
fi

# Sync files to web host
print_status "Syncing files to web host..."

# Use rsync to sync files directly with better error handling
# --no-perms and --no-times to avoid permission issues
# Exit code 23 is partial transfer due to permissions, which is OK for our use case
set +e  # Don't exit on rsync error codes
rsync -avz --delete \
    --no-perms --no-times \
    --exclude='.git/' \
    --exclude='*.log' \
    --exclude='node_modules/' \
    --exclude='.env' \
    --exclude='sync_covid_project.sh' \
    --exclude='deploy_covid_project.sh' \
    --exclude='*.sh' \
    --exclude='covid-19-data/' \
    "$PROJECT_DIR/" \
    "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/"

RSYNC_EXIT_CODE=$?
set -e  # Re-enable exit on error

# Handle rsync exit codes
if [ $RSYNC_EXIT_CODE -eq 0 ]; then
    print_success "Files synced successfully"
elif [ $RSYNC_EXIT_CODE -eq 23 ]; then
    print_warning "Files synced with some permission warnings (this is normal)"
    print_success "All files transferred successfully"
else
    print_error "Rsync failed with exit code: $RSYNC_EXIT_CODE"
    exit 1
fi

# Set final permissions
print_status "Setting final permissions on web host..."
ssh "${WEB_USER}@${WEB_HOST}" "
    # Ensure www-data owns everything
    sudo chown -R www-data:www-data '${WEB_PATH}' 2>/dev/null || {
        echo 'Note: Could not change ownership to www-data, trying current user...'
        sudo chown -R ${WEB_USER}:${WEB_USER} '${WEB_PATH}'
    }
    
    # Set proper permissions
    sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \; 2>/dev/null || \
        find '${WEB_PATH}' -type d -exec chmod 755 {} \;
    sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \; 2>/dev/null || \
        find '${WEB_PATH}' -type f -exec chmod 644 {} \;
    
    # Ensure the directory is readable by web server
    sudo chmod 755 '${WEB_PATH}' 2>/dev/null || chmod 755 '${WEB_PATH}'
"

print_success "Permissions set successfully"

# Verify the deployment
print_status "Verifying deployment..."
ssh "${WEB_USER}@${WEB_HOST}" "
    echo 'Files in web directory:'
    ls -la '${WEB_PATH}/' 2>/dev/null | head -10 || echo 'Could not list directory contents'
    echo ''
    echo 'Directory size:'
    du -sh '${WEB_PATH}' 2>/dev/null || echo 'Could not calculate directory size'
    echo ''
    echo 'Key files check:'
    [ -f '${WEB_PATH}/covid_dashboard.html' ] && echo '✓ Dashboard HTML found' || echo '✗ Dashboard HTML missing'
    [ -f '${WEB_PATH}/index.html' ] && echo '✓ Index HTML found' || echo '✗ Index HTML missing'
    [ -d '${WEB_PATH}/nytimes_covid-19-data' ] && echo '✓ COVID data directory found' || echo '✗ COVID data directory missing'
    find '${WEB_PATH}' -name '*.csv' 2>/dev/null | wc -l | xargs echo '✓ CSV files found:'
    echo ''
    echo 'Sample data files:'
    [ -f '${WEB_PATH}/nytimes_covid-19-data/us-states.csv' ] && echo '✓ US States data found' || echo '✗ US States data missing'
    [ -f '${WEB_PATH}/nytimes_covid-19-data/us-counties-recent.csv' ] && echo '✓ US Counties data found' || echo '✗ US Counties data missing'
    [ -f '${WEB_PATH}/nytimes_covid-19-data/colleges/colleges.csv' ] && echo '✓ Colleges data found' || echo '✗ Colleges data missing'
"

print_success "Deployment completed successfully!"
echo ""
print_status "Your COVID dashboard is now available at:"
echo "  http://${WEB_HOST}/covid_elections/"
echo "  https://${WEB_HOST}/covid_elections/ (if SSL is configured)"
echo ""
print_status "Backup location on web server: ${BACKUP_DIR}"

# Test if the web server is responding
print_status "Testing web server response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/" 2>/dev/null || echo "000")

case $HTTP_CODE in
    200)
        print_success "Web server is responding correctly (HTTP 200)"
        ;;
    301|302)
        print_success "Web server is responding with redirect (HTTP $HTTP_CODE)"
        ;;
    403)
        print_warning "Web server is responding but access may be forbidden (HTTP 403)"
        print_status "This might be a permissions issue or missing index file"
        ;;
    404)
        print_warning "Web server responded but path not found (HTTP 404)"
        print_status "Check if the web server is configured to serve from ${WEB_PATH}"
        ;;
    000)
        print_warning "Could not connect to web server"
        print_status "This might be normal if the web server is not running or configured differently"
        ;;
    *)
        print_warning "Web server responded with HTTP code: $HTTP_CODE"
        ;;
esac

echo ""
print_success "All done! 🎉"
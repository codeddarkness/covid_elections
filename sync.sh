#!/bin/bash

# COVID Elections Project - Minimal Sync Script
# Syncs only essential website files (no huge data files)
# Version: Essential Files Only

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
PROJECT_DIR="/Users/raymond/covid_elections"
WEB_HOST="bataleon"
WEB_USER="raymond"
WEB_PATH="/var/www/html/covid_elections"

# Core website files
CORE_FILES=(
    "covid_dashboard.html"
    "election_dashboard.html"
    "index.html"
    "README_WEB.md"
    "countypres_2020.csv"
)

# Essential COVID data files only (small, frequently used)
COVID_DATA_FILES=(
    "nytimes_covid-19-data/us-states.csv"
    "nytimes_covid-19-data/us-counties-recent.csv"
    "nytimes_covid-19-data/colleges/colleges.csv"
    "nytimes_covid-19-data/prisons/facilities.csv"
    "nytimes_covid-19-data/prisons/systems.csv"
    "nytimes_covid-19-data/excess-deaths/deaths.csv"
    "nytimes_covid-19-data/mask-use/mask-use-by-county.csv"
)

# Parse command line arguments
DASHBOARD_ONLY=false
NO_BACKUP=false
FORCE_MODE=false

show_usage() {
    echo "COVID Elections Minimal Sync Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dashboard     Dashboard file only"
    echo "  -n, --no-backup     Skip backup creation"
    echo "  -f, --force         Force sync without confirmation"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                  # Sync essential website files"
    echo "  $0 -d               # Dashboard only"
    echo "  $0 -f               # Force sync without prompts"
    echo ""
    echo "Essential files synced:"
    for file in "${CORE_FILES[@]}"; do
        echo "  • $file"
    done
    echo ""
    echo "Essential COVID data files:"
    for file in "${COVID_DATA_FILES[@]}"; do
        echo "  • $file"
    done
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dashboard) DASHBOARD_ONLY=true; shift ;;
        -n|--no-backup) NO_BACKUP=true; shift ;;
        -f|--force) FORCE_MODE=true; shift ;;
        -h|--help) show_usage; exit 0 ;;
        *) print_error "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

echo "============================================="
echo "COVID Elections Minimal Sync"
echo "============================================="
echo ""

# Environment check
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Check for required files
check_files() {
    local missing_files=()
    
    print_status "Checking essential files..."
    
    if [ "$DASHBOARD_ONLY" = true ]; then
        # Only check dashboard file
        if [ ! -f "covid_dashboard.html" ]; then
            missing_files+=("covid_dashboard.html")
        fi
    else
        # Check core files
        for file in "${CORE_FILES[@]}"; do
            if [ ! -f "$file" ]; then
                missing_files+=("$file")
            fi
        done
        
        # Check essential COVID data files
        for file in "${COVID_DATA_FILES[@]}"; do
            if [ ! -f "$file" ]; then
                missing_files+=("$file")
            fi
        done
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Missing files:"
        for file in "${missing_files[@]}"; do
            print_warning "  • $file"
        done
        
        if [ "$FORCE_MODE" != true ]; then
            read -p "Continue anyway? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Sync cancelled due to missing files"
                exit 1
            fi
        fi
    else
        print_success "All required files found"
    fi
}

# Connection test
print_status "Testing connection to $WEB_HOST..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${WEB_USER}@${WEB_HOST}" exit 2>/dev/null; then
    print_error "Cannot connect to $WEB_HOST"
    exit 1
fi
print_success "Connected to $WEB_HOST"

# Check files
check_files

# Calculate total size
calculate_size() {
    local total_size=0
    local file
    
    if [ "$DASHBOARD_ONLY" = true ]; then
        if [ -f "covid_dashboard.html" ]; then
            size=$(stat -f%z "covid_dashboard.html" 2>/dev/null || stat -c%s "covid_dashboard.html" 2>/dev/null || echo "0")
            total_size=$((total_size + size))
        fi
    else
        for file in "${CORE_FILES[@]}"; do
            if [ -f "$file" ]; then
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                total_size=$((total_size + size))
            fi
        done
        
        for file in "${COVID_DATA_FILES[@]}"; do
            if [ -f "$file" ]; then
                size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
                total_size=$((total_size + size))
            fi
        done
    fi
    
    # Convert to human readable
    if [ $total_size -gt 1048576 ]; then
        echo "$((total_size / 1048576))MB"
    elif [ $total_size -gt 1024 ]; then
        echo "$((total_size / 1024))KB"
    else
        echo "${total_size}B"
    fi
}

# Show sync plan
if [ "$DASHBOARD_ONLY" = true ]; then
    print_status "Sync mode: Dashboard Only"
    SYNC_LIST=("covid_dashboard.html")
else
    print_status "Sync mode: Essential Website Files"
    SYNC_LIST=("${CORE_FILES[@]}" "${COVID_DATA_FILES[@]}")
fi

echo "  Source: $(pwd)"
echo "  Target: ${WEB_USER}@${WEB_HOST}:${WEB_PATH}"
echo "  Total size: $(calculate_size)"
echo ""
echo "  Files to sync:"

if [ "$DASHBOARD_ONLY" = true ]; then
    if [ -f "covid_dashboard.html" ]; then
        size=$(ls -lh "covid_dashboard.html" | awk '{print $5}')
        echo "    ✓ covid_dashboard.html ($size)"
    fi
else
    echo "    Core files:"
    for file in "${CORE_FILES[@]}"; do
        if [ -f "$file" ]; then
            size=$(ls -lh "$file" | awk '{print $5}')
            echo "      ✓ $file ($size)"
        else
            echo "      ✗ $file (missing)"
        fi
    done
    
    echo "    Essential COVID data:"
    for file in "${COVID_DATA_FILES[@]}"; do
        if [ -f "$file" ]; then
            size=$(ls -lh "$file" | awk '{print $5}')
            basename_file=$(basename "$file")
            echo "      ✓ $basename_file ($size)"
        else
            echo "      ✗ $(basename "$file") (missing)"
        fi
    done
fi

echo ""

# Confirmation (unless forced)
if [ "$FORCE_MODE" != true ]; then
    read -p "Proceed with sync? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Sync cancelled"
        exit 0
    fi
fi

# Create backup
if [ "$NO_BACKUP" != true ]; then
    print_status "Creating backup..."
    BACKUP_NAME="covid_backup_$(date +%Y%m%d_%H%M%S)"
    
    ssh "${WEB_USER}@${WEB_HOST}" "
        if [ -d '${WEB_PATH}' ]; then
            cp -r '${WEB_PATH}' '/tmp/${BACKUP_NAME}' || true
            if [ -d '/tmp/${BACKUP_NAME}' ]; then
                echo 'Backup created: /tmp/${BACKUP_NAME}'
            fi
        fi
    "
fi

# Setup target directory
print_status "Setting up target directory..."
TEMP_DIR="/tmp/covid_sync_$$"

ssh "${WEB_USER}@${WEB_HOST}" "
    # Create staging directory
    mkdir -p '${TEMP_DIR}'
    chmod 755 '${TEMP_DIR}'
    
    # Setup target directory
    sudo mkdir -p '${WEB_PATH}' 2>/dev/null || mkdir -p '${WEB_PATH}' || exit 1
    sudo chmod 775 '${WEB_PATH}' 2>/dev/null || chmod 775 '${WEB_PATH}' || true
    sudo chown ${WEB_USER}:www-data '${WEB_PATH}' 2>/dev/null || true
"

# Upload files
print_status "Uploading files..."

if [ "$DASHBOARD_ONLY" = true ]; then
    print_status "  → covid_dashboard.html"
    scp "covid_dashboard.html" "${WEB_USER}@${WEB_HOST}:${TEMP_DIR}/"
else
    # Upload core files
    print_status "  Uploading core files..."
    for file in "${CORE_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_status "    → $file"
            scp "$file" "${WEB_USER}@${WEB_HOST}:${TEMP_DIR}/"
        fi
    done
    
    # Create COVID data directory structure and upload essential files
    print_status "  Uploading essential COVID data..."
    ssh "${WEB_USER}@${WEB_HOST}" "
        mkdir -p '${TEMP_DIR}/nytimes_covid-19-data/colleges'
        mkdir -p '${TEMP_DIR}/nytimes_covid-19-data/prisons'
        mkdir -p '${TEMP_DIR}/nytimes_covid-19-data/excess-deaths'
        mkdir -p '${TEMP_DIR}/nytimes_covid-19-data/mask-use'
    "
    
    for file in "${COVID_DATA_FILES[@]}"; do
        if [ -f "$file" ]; then
            basename_file=$(basename "$file")
            dirname_file=$(dirname "$file")
            print_status "    → $basename_file"
            scp "$file" "${WEB_USER}@${WEB_HOST}:${TEMP_DIR}/${dirname_file}/"
        fi
    done
fi

# Move files to final location
print_status "Installing files..."
ssh "${WEB_USER}@${WEB_HOST}" "
    # Move files to web directory
    sudo cp -r '${TEMP_DIR}'/* '${WEB_PATH}/' 2>/dev/null || cp -r '${TEMP_DIR}'/* '${WEB_PATH}/' || exit 1
    
    # Set permissions
    sudo chown -R www-data:www-data '${WEB_PATH}' 2>/dev/null || chown -R ${WEB_USER}:${WEB_USER} '${WEB_PATH}' || true
    sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \; 2>/dev/null || find '${WEB_PATH}' -type d -exec chmod 755 {} \; || true
    sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \; 2>/dev/null || find '${WEB_PATH}' -type f -exec chmod 644 {} \; || true
    
    # Cleanup staging
    rm -rf '${TEMP_DIR}'
"

# Verify deployment
print_status "Verifying deployment..."
VERIFICATION=$(ssh "${WEB_USER}@${WEB_HOST}" "
    cd '${WEB_PATH}' 2>/dev/null || exit 1
    
    echo 'Deployed files:'
    [ -f 'covid_dashboard.html' ] && echo '✓ COVID Dashboard' || echo '✗ COVID Dashboard missing'
    [ -f 'election_dashboard.html' ] && echo '✓ Election Dashboard' || echo '✗ Election Dashboard missing'  
    [ -f 'countypres_2020.csv' ] && echo '✓ Election Data' || echo '✗ Election Data missing'
    [ -f 'index.html' ] && echo '✓ Index Page' || echo '✗ Index Page missing'
    
    # Check COVID data
    [ -f 'nytimes_covid-19-data/us-states.csv' ] && echo '✓ US States Data' || echo '✗ US States Data missing'
    [ -f 'nytimes_covid-19-data/us-counties-recent.csv' ] && echo '✓ US Counties Data' || echo '✗ US Counties Data missing'
    [ -f 'nytimes_covid-19-data/colleges/colleges.csv' ] && echo '✓ Colleges Data' || echo '✗ Colleges Data missing'
    [ -f 'nytimes_covid-19-data/prisons/facilities.csv' ] && echo '✓ Prison Facilities Data' || echo '✗ Prison Facilities Data missing'
    
    echo ''
    echo 'Total size:' \$(du -sh . 2>/dev/null | cut -f1 || echo 'unknown')
    
    # Check for integration features
    if [ -f 'covid_dashboard.html' ] && grep -q 'showPoliticalAnalysis' 'covid_dashboard.html'; then
        echo '✓ Political integration enabled'
    fi
")

echo "$VERIFICATION"

# Test web access
print_status "Testing web access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/" 2>/dev/null || echo "000")

case $HTTP_CODE in
    200) print_success "✓ Website accessible (HTTP $HTTP_CODE)" ;;
    301|302) print_success "✓ Website redirecting (HTTP $HTTP_CODE)" ;;
    403) print_warning "⚠ Access forbidden (HTTP 403)" ;;
    404) print_warning "⚠ Not found (HTTP 404)" ;;
    *) print_warning "⚠ Unexpected response (HTTP $HTTP_CODE)" ;;
esac

print_success "Sync completed successfully!"
echo ""

# Show results
echo "============================================="
print_success "🚀 DEPLOYMENT COMPLETE"
echo "============================================="
echo ""
print_status "🌐 Access URLs:"
echo "  Main Site: http://${WEB_HOST}/covid_elections/"
echo "  COVID Dashboard: http://${WEB_HOST}/covid_elections/covid_dashboard.html"
if [ -f "election_dashboard.html" ]; then
    echo "  Election Dashboard: http://${WEB_HOST}/covid_elections/election_dashboard.html"
fi
echo ""

if [ "$NO_BACKUP" != true ]; then
    print_status "📦 Backup: /tmp/${BACKUP_NAME:-backup} (on ${WEB_HOST})"
fi

# Integration status
if grep -q "showPoliticalAnalysis" "covid_dashboard.html" 2>/dev/null; then
    echo ""
    print_status "🔗 Integration Features Active:"
    echo "  ✓ Political analysis toggle"
    echo "  ✓ Election data integration"
    echo "  ✓ Essential COVID datasets"
    echo ""
    print_status "💡 Quick Test:"
    echo "  1. Visit http://${WEB_HOST}/covid_elections/"
    echo "  2. Select 'US States' or 'US Counties'"
    echo "  3. Add a region (e.g., Florida)"
    echo "  4. Check 'Show Political Analysis'"
    echo "  5. View integrated data!"
fi

echo ""
print_success "✨ Ready to use!"
echo "============================================="

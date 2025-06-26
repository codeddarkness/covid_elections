#!/bin/bash

# COVID Elections Project - Universal Sync Script (Updated for Integration)
# Syncs from osprey.darkremy to bataleon web server
# Version: Integration Update - Includes political analysis features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_feature() { echo -e "${PURPLE}[FEATURE]${NC} $1"; }

# Configuration
PROJECT_DIR="/Users/raymond/covid_elections"
WEB_HOST="bataleon"
WEB_USER="raymond"
WEB_PATH="/var/www/html/covid_elections"

# Parse command line arguments
QUICK_MODE=false
DASHBOARD_ONLY=false
NO_BACKUP=false
FORCE_MODE=false
INTEGRATION_MODE=false

show_usage() {
    echo "COVID Elections Sync Script (Integration Edition)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -q, --quick         Quick sync (dashboard only)"
    echo "  -d, --dashboard     Dashboard file only"
    echo "  -i, --integration   Integration mode (dashboard + election data)"
    echo "  -n, --no-backup     Skip backup creation"
    echo "  -f, --force         Force sync without confirmation"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full sync with backup"
    echo "  $0 -q               # Quick dashboard-only sync"
    echo "  $0 -i               # Integration sync (dashboard + election data)"
    echo "  $0 -f               # Force full sync without prompts"
    echo "  $0 -d -n            # Dashboard only, no backup"
    echo ""
    echo "🔗 Integration Features:"
    echo "  • Political analysis toggle in COVID dashboard"
    echo "  • 2020 election data integration"
    echo "  • Enhanced region tags with vote percentages"
    echo "  • Political summary statistics"
    echo "  • Cross-correlation charts and analysis"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -q|--quick) QUICK_MODE=true; DASHBOARD_ONLY=true; shift ;;
        -d|--dashboard) DASHBOARD_ONLY=true; shift ;;
        -i|--integration) INTEGRATION_MODE=true; shift ;;
        -n|--no-backup) NO_BACKUP=true; shift ;;
        -f|--force) FORCE_MODE=true; shift ;;
        -h|--help) show_usage; exit 0 ;;
        *) print_error "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

echo "============================================="
echo "COVID Elections Project Sync (Integration)"
echo "============================================="
echo ""

# Environment check
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Check for integration features
check_integration_files() {
    local issues=0
    
    print_status "Checking integration files..."
    
    # Check if COVID dashboard has integration features
    if [ -f "covid_dashboard.html" ]; then
        if grep -q "showPoliticalAnalysis" "covid_dashboard.html"; then
            print_success "✓ COVID dashboard has political integration"
        else
            print_warning "⚠ COVID dashboard missing political integration"
            print_status "  Run the integration deployment script first"
            ((issues++))
        fi
    else
        print_error "✗ COVID dashboard not found"
        ((issues++))
    fi
    
    # Check election data
    if [ -f "countypres_2020.csv" ]; then
        local size=$(wc -c < "countypres_2020.csv")
        print_success "✓ Election data found (${size} bytes)"
    else
        print_warning "⚠ Election data file missing: countypres_2020.csv"
        print_status "  Political analysis features will not work"
        ((issues++))
    fi
    
    # Check standalone election dashboard
    if [ -f "election_dashboard.html" ]; then
        print_success "✓ Standalone election dashboard found"
    else
        print_warning "⚠ Standalone election dashboard missing"
    fi
    
    # Check COVID data
    if [ -d "nytimes_covid-19-data" ]; then
        local csv_count=$(find "nytimes_covid-19-data" -name "*.csv" | wc -l)
        print_success "✓ COVID data directory found (${csv_count} files)"
    else
        print_error "✗ COVID data directory missing"
        ((issues++))
    fi
    
    return $issues
}

# Connection test
print_status "Testing connection to $WEB_HOST..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${WEB_USER}@${WEB_HOST}" exit 2>/dev/null; then
    print_error "Cannot connect to $WEB_HOST"
    exit 1
fi
print_success "Connected to $WEB_HOST"

# Check integration status
if ! check_integration_files; then
    print_warning "Integration files have issues, but continuing..."
    echo ""
fi

# Determine sync mode
if [ "$INTEGRATION_MODE" = true ]; then
    SYNC_MODE="Integration (Dashboard + Election Data)"
    SYNC_FILES=(
        "covid_dashboard.html"
        "countypres_2020.csv"
        "election_dashboard.html"
        "index.html"
        "README_WEB.md"
    )
elif [ "$DASHBOARD_ONLY" = true ]; then
    SYNC_MODE="Dashboard Only"
    SYNC_FILES=("covid_dashboard.html")
else
    SYNC_MODE="Full Project"
    SYNC_FILES=("*")
fi

# Show sync plan
print_status "Sync mode: $SYNC_MODE"
echo "  Source: $(pwd)"
echo "  Target: ${WEB_USER}@${WEB_HOST}:${WEB_PATH}"
echo "  Backup: $([ "$NO_BACKUP" = true ] && echo "Disabled" || echo "Enabled")"

if [ "$INTEGRATION_MODE" = true ] || [ "$DASHBOARD_ONLY" != true ]; then
    echo ""
    print_feature "🔗 Integration Features Being Deployed:"
    echo "  • Political analysis toggle in COVID dashboard"
    echo "  • 2020 Presidential election data (county-level)"
    echo "  • Enhanced visualization with political context"
    echo "  • Cross-correlation analysis capabilities"
fi

echo ""

# Confirmation (unless forced or quick mode)
if [ "$FORCE_MODE" != true ] && [ "$QUICK_MODE" != true ]; then
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
            sudo cp -r '${WEB_PATH}' '/tmp/${BACKUP_NAME}' 2>/dev/null || cp -r '${WEB_PATH}' '/tmp/${BACKUP_NAME}'
            echo 'Backup created: /tmp/${BACKUP_NAME}'
        fi
    " || print_warning "Backup creation had issues, continuing..."
fi

# Setup permissions
print_status "Setting up permissions..."
ssh "${WEB_USER}@${WEB_HOST}" "
    sudo mkdir -p '${WEB_PATH}' 2>/dev/null || mkdir -p '${WEB_PATH}'
    sudo chmod 775 '${WEB_PATH}' 2>/dev/null || chmod 775 '${WEB_PATH}' 2>/dev/null || true
    sudo usermod -a -G www-data raymond 2>/dev/null || true
" || print_warning "Permission setup had issues, continuing..."

# Sync files based on mode
if [ "$INTEGRATION_MODE" = true ]; then
    print_status "Syncing integration files..."
    
    # Sync core files
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_status "  Syncing $file..."
            rsync -avz --no-perms --no-times \
                "$file" \
                "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/" || {
                print_warning "Rsync failed for $file, trying scp..."
                scp "$file" "${WEB_USER}@${WEB_HOST}:/tmp/$(basename $file)_new"
                ssh "${WEB_USER}@${WEB_HOST}" "
                    sudo mv '/tmp/$(basename $file)_new' '${WEB_PATH}/$file' 2>/dev/null || \
                        mv '/tmp/$(basename $file)_new' '${WEB_PATH}/$file'
                "
            }
        else
            print_warning "  File not found: $file"
        fi
    done
    
    # Sync COVID data directory
    if [ -d "nytimes_covid-19-data" ]; then
        print_status "  Syncing COVID data directory..."
        rsync -avz --no-perms --no-times \
            "nytimes_covid-19-data/" \
            "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/nytimes_covid-19-data/" || {
            print_warning "COVID data sync had issues"
        }
    fi

elif [ "$DASHBOARD_ONLY" = true ]; then
    print_status "Syncing dashboard file..."
    if [ ! -f "covid_dashboard.html" ]; then
        print_error "Dashboard file not found: covid_dashboard.html"
        exit 1
    fi
    
    rsync -avz --no-perms --no-times \
        covid_dashboard.html \
        "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/" || {
        print_warning "Rsync failed, trying alternative method..."
        scp covid_dashboard.html "${WEB_USER}@${WEB_HOST}:/tmp/dashboard_new.html"
        ssh "${WEB_USER}@${WEB_HOST}" "
            sudo mv /tmp/dashboard_new.html '${WEB_PATH}/covid_dashboard.html' 2>/dev/null || \
                mv /tmp/dashboard_new.html '${WEB_PATH}/covid_dashboard.html'
        "
    }

else
    print_status "Syncing full project..."
    rsync -avz --delete --no-perms --no-times \
        --exclude='.git/' \
        --exclude='*.log' \
        --exclude='node_modules/' \
        --exclude='.env' \
        --exclude='*.sh' \
        --exclude='scripts_ran/' \
        --exclude='covid_dashboard.html_v*' \
        --exclude='retry_later' \
        --exclude='*backup*' \
        --exclude='integration_usage_guide.md' \
        --exclude='test_integration.sh' \
        --exclude='deploy_integrated_dashboard.sh' \
        --exclude='update_covid_nav.sh' \
        "$PROJECT_DIR/" \
        "${WEB_USER}@${WEB_HOST}:${WEB_PATH}/" || {
        print_error "Full sync failed"
        exit 1
    }
fi

# Set final permissions
print_status "Setting final permissions..."
ssh "${WEB_USER}@${WEB_HOST}" "
    sudo chown -R www-data:www-data '${WEB_PATH}' 2>/dev/null || chown -R ${WEB_USER}:${WEB_USER} '${WEB_PATH}' 2>/dev/null || true
    sudo find '${WEB_PATH}' -type d -exec chmod 755 {} \; 2>/dev/null || find '${WEB_PATH}' -type d -exec chmod 755 {} \; 2>/dev/null || true
    sudo find '${WEB_PATH}' -type f -exec chmod 644 {} \; 2>/dev/null || find '${WEB_PATH}' -type f -exec chmod 644 {} \; 2>/dev/null || true
" || print_warning "Final permissions had issues, but files should still work"

# Verify deployment
print_status "Verifying deployment..."
ssh "${WEB_USER}@${WEB_HOST}" "
    echo 'Key files:'
    [ -f '${WEB_PATH}/covid_dashboard.html' ] && echo '✓ COVID Dashboard' || echo '✗ COVID Dashboard missing'
    [ -f '${WEB_PATH}/election_dashboard.html' ] && echo '✓ Election Dashboard' || echo '⚠ Election Dashboard missing'
    [ -f '${WEB_PATH}/countypres_2020.csv' ] && echo '✓ Election Data' || echo '⚠ Election Data missing'
    [ -f '${WEB_PATH}/index.html' ] && echo '✓ Index' || echo '✗ Index missing'
    [ -d '${WEB_PATH}/nytimes_covid-19-data' ] && echo '✓ COVID Data directory' || echo '✗ COVID Data directory missing'
    echo ''
    echo 'Directory size:' \$(du -sh '${WEB_PATH}' 2>/dev/null | cut -f1)
    
    # Check for integration features
    if [ -f '${WEB_PATH}/covid_dashboard.html' ]; then
        if grep -q 'showPoliticalAnalysis' '${WEB_PATH}/covid_dashboard.html'; then
            echo '✓ Political integration enabled'
        else
            echo '⚠ Political integration not detected'
        fi
    fi
"

# Test web access
print_status "Testing web access..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/" 2>/dev/null || echo "000")

case $HTTP_CODE in
    200|301|302) print_success "Web server responding (HTTP $HTTP_CODE)" ;;
    403) print_warning "Access forbidden (HTTP 403) - check permissions" ;;
    404) print_warning "Not found (HTTP 404) - check web server config" ;;
    *) print_warning "Unexpected response (HTTP $HTTP_CODE)" ;;
esac

# Test election data access if in integration mode
if [ "$INTEGRATION_MODE" = true ] || [ "$DASHBOARD_ONLY" != true ]; then
    print_status "Testing election data access..."
    ELECTION_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://${WEB_HOST}/covid_elections/countypres_2020.csv" 2>/dev/null || echo "000")
    
    case $ELECTION_HTTP in
        200) print_success "Election data accessible (HTTP $ELECTION_HTTP)" ;;
        404) print_warning "Election data not accessible (HTTP 404)" ;;
        *) print_warning "Election data response (HTTP $ELECTION_HTTP)" ;;
    esac
fi

print_success "Sync completed successfully!"
echo ""
print_status "🌐 Available URLs:"
echo "  Main Dashboard: http://${WEB_HOST}/covid_elections/"
echo "  COVID Dashboard: http://${WEB_HOST}/covid_elections/covid_dashboard.html"
if [ -f "election_dashboard.html" ]; then
    echo "  Election Dashboard: http://${WEB_HOST}/covid_elections/election_dashboard.html"
fi
echo ""

if [ "$NO_BACKUP" != true ]; then
    print_status "📦 Backup location: /tmp/${BACKUP_NAME:-latest_backup}"
fi

echo ""
if [ "$INTEGRATION_MODE" = true ] || grep -q "showPoliticalAnalysis" "covid_dashboard.html" 2>/dev/null; then
    print_feature "🔗 Integration Features Deployed:"
    echo "  ✓ Political analysis toggle in controls"
    echo "  ✓ Enhanced region tags with vote percentages"
    echo "  ✓ Political summary statistics section"
    echo "  ✓ Cross-correlation charts and analysis"
    echo "  ✓ 2020 election data integration"
    echo ""
    print_status "💡 Usage Tips:"
    echo "  1. Select US states or counties in the dashboard"
    echo "  2. Check 'Show Political Analysis' checkbox"
    echo "  3. View integrated COVID + political data"
    echo "  4. Analyze correlations and patterns"
fi

echo ""
print_success "🚀 All done!"

# Show quick start guide for integration
if [ "$INTEGRATION_MODE" = true ]; then
    echo ""
    echo "=================================================="
    print_feature "🎯 QUICK START GUIDE"
    echo "=================================================="
    echo ""
    echo "To test the political integration:"
    echo ""
    echo "1. Open: http://${WEB_HOST}/covid_elections/"
    echo "2. Select 'US States' or 'US Counties' data type"
    echo "3. Add regions like 'Florida', 'California', etc."
    echo "4. Check ☑ 'Show Political Analysis'"
    echo "5. View enhanced data with political context!"
    echo ""
    echo "Example regions to try:"
    echo "  • States: Florida, Pennsylvania, Arizona"
    echo "  • Counties: Orange (CA), Miami-Dade (FL), Cook (IL)"
    echo ""
    echo "=================================================="
fi
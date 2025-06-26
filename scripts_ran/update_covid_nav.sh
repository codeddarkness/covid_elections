#!/bin/bash

# Script to update covid_dashboard.html navigation to include election data link
# Author: Assistant
# Date: $(date +"%Y-%m-%d")

set -euo pipefail

# Configuration
COVID_DASHBOARD="covid_dashboard.html"
BACKUP_SUFFIX=".nav-backup-$(date +%Y%m%d-%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if covid_dashboard.html exists
if [[ ! -f "$COVID_DASHBOARD" ]]; then
    error "COVID dashboard file '$COVID_DASHBOARD' not found in current directory."
    error "Please run this script from the directory containing covid_dashboard.html"
    exit 1
fi

log "Found COVID dashboard file: $COVID_DASHBOARD"

# Create backup
log "Creating backup: ${COVID_DASHBOARD}${BACKUP_SUFFIX}"
cp "$COVID_DASHBOARD" "${COVID_DASHBOARD}${BACKUP_SUFFIX}"

# Check if election link already exists
if grep -q "election_dashboard.html" "$COVID_DASHBOARD"; then
    warning "Election dashboard link already exists in navigation menu."
    echo "Do you want to continue anyway? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Operation cancelled."
        exit 0
    fi
fi

# Create temporary file with updated navigation
log "Updating navigation menu to include election data link..."

# Use here document with sed to update the navigation
cat > temp_nav_update.sed << 'EOF'
# Find the nav-content section and add election link after Data Dashboard
/<div class="nav-content">/{
    n
    /<a href="#" onclick="showPage('dashboard')">Data Dashboard<\/a>/{
        a\
                <a href="election_dashboard.html">Election Data Dashboard</a>
    }
}
EOF

# Apply the sed script
sed -f temp_nav_update.sed "$COVID_DASHBOARD" > "${COVID_DASHBOARD}.tmp"

# Check if the update was successful
if grep -q "election_dashboard.html" "${COVID_DASHBOARD}.tmp"; then
    # Replace original file with updated version
    mv "${COVID_DASHBOARD}.tmp" "$COVID_DASHBOARD"
    success "Successfully updated navigation menu in $COVID_DASHBOARD"
    
    # Show the updated navigation section
    log "Updated navigation section:"
    echo "----------------------------------------"
    grep -A 10 -B 2 "nav-content" "$COVID_DASHBOARD" | head -15
    echo "----------------------------------------"
    
else
    error "Failed to update navigation menu. Restoring from backup."
    cp "${COVID_DASHBOARD}${BACKUP_SUFFIX}" "$COVID_DASHBOARD"
    rm -f "${COVID_DASHBOARD}.tmp"
    exit 1
fi

# Clean up temporary files
rm -f temp_nav_update.sed

# Verify the file is still valid HTML
log "Verifying HTML structure..."
if command -v xmllint &> /dev/null; then
    if xmllint --html --noout "$COVID_DASHBOARD" 2>/dev/null; then
        success "HTML structure is valid"
    else
        warning "HTML validation failed - file may have syntax issues"
    fi
else
    warning "xmllint not found - skipping HTML validation"
fi

# Summary
echo
echo "=================================================="
success "Navigation update completed successfully!"
echo "=================================================="
echo
log "What was done:"
echo "  • Created backup: ${COVID_DASHBOARD}${BACKUP_SUFFIX}"
echo "  • Added 'Election Data Dashboard' link to navigation menu"
echo "  • Link points to: election_dashboard.html"
echo
log "Next steps:"
echo "  1. Save the election dashboard HTML as 'election_dashboard.html'"
echo "  2. Ensure 'countypres_2020.csv' file is in the same directory"
echo "  3. Test both dashboards in a web browser"
echo
warning "Remember to deploy both files to your web server!"

# Optional: Test link accessibility
if [[ -f "election_dashboard.html" ]]; then
    success "election_dashboard.html found - link should work correctly"
else
    warning "election_dashboard.html not found - create this file for the link to work"
fi

echo
log "Backup file saved as: ${COVID_DASHBOARD}${BACKUP_SUFFIX}"
log "You can remove the backup once you've verified everything works correctly."
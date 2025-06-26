#!/bin/bash

# Script to deploy the integrated COVID-19 and Election Data Dashboard
# Author: Assistant
# Date: $(date +"%Y-%m-%d")

set -euo pipefail

# Configuration
CURRENT_COVID_DASHBOARD="covid_dashboard.html"
INTEGRATED_DASHBOARD="covid_dashboard_integrated.html"
BACKUP_SUFFIX=".pre-integration-backup-$(date +%Y%m%d-%H%M%S)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if current COVID dashboard exists
    if [[ ! -f "$CURRENT_COVID_DASHBOARD" ]]; then
        error "Current COVID dashboard '$CURRENT_COVID_DASHBOARD' not found."
        error "Please run this script from the directory containing your COVID dashboard."
        exit 1
    fi
    
    # Check if election data file exists
    if [[ ! -f "countypres_2020.csv" ]]; then
        warning "Election data file 'countypres_2020.csv' not found."
        warning "The political analysis features will not work without this file."
        echo "Do you want to continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Deployment cancelled."
            exit 0
        fi
    else
        success "Election data file found: countypres_2020.csv"
    fi
    
    # Check if COVID data directory exists
    if [[ ! -d "nytimes_covid-19-data" ]]; then
        error "COVID data directory 'nytimes_covid-19-data' not found."
        error "Please ensure the COVID data is available before deploying."
        exit 1
    else
        success "COVID data directory found: nytimes_covid-19-data"
    fi
    
    success "Prerequisites check completed"
}

# Function to create the integrated dashboard file
create_integrated_dashboard() {
    log "Creating integrated dashboard file..."
    
    # Here we would normally copy the integrated dashboard content
    # For this script, we'll assume the user has the integrated HTML content ready
    if [[ ! -f "$INTEGRATED_DASHBOARD" ]]; then
        error "Integrated dashboard file '$INTEGRATED_DASHBOARD' not found."
        echo
        info "Please save the integrated dashboard HTML content as '$INTEGRATED_DASHBOARD'"
        info "You can find this in the artifacts from the previous response."
        echo
        echo "After saving the file, run this script again."
        exit 1
    fi
    
    success "Integrated dashboard file found: $INTEGRATED_DASHBOARD"
}

# Function to validate the integrated dashboard
validate_dashboard() {
    log "Validating integrated dashboard..."
    
    # Check for key integration features
    local features_found=0
    
    if grep -q "showPoliticalAnalysis" "$INTEGRATED_DASHBOARD"; then
        success "✓ Political analysis toggle found"
        ((features_found++))
    else
        warning "✗ Political analysis toggle not found"
    fi
    
    if grep -q "electionData" "$INTEGRATED_DASHBOARD"; then
        success "✓ Election data integration found"
        ((features_found++))
    else
        warning "✗ Election data integration not found"
    fi
    
    if grep -q "political-info" "$INTEGRATED_DASHBOARD"; then
        success "✓ Political info styling found"
        ((features_found++))
    else
        warning "✗ Political info styling not found"
    fi
    
    if grep -q "countypres_2020.csv" "$INTEGRATED_DASHBOARD"; then
        success "✓ Election data file reference found"
        ((features_found++))
    else
        warning "✗ Election data file reference not found"
    fi
    
    if [[ $features_found -eq 4 ]]; then
        success "All integration features validated successfully"
    else
        warning "Some integration features may be missing ($features_found/4 found)"
        echo "Do you want to continue with deployment? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Deployment cancelled."
            exit 0
        fi
    fi
}

# Function to create backup
create_backup() {
    log "Creating backup of current dashboard..."
    cp "$CURRENT_COVID_DASHBOARD" "${CURRENT_COVID_DASHBOARD}${BACKUP_SUFFIX}"
    success "Backup created: ${CURRENT_COVID_DASHBOARD}${BACKUP_SUFFIX}"
}

# Function to deploy the integrated dashboard
deploy_dashboard() {
    log "Deploying integrated dashboard..."
    
    # Replace the current dashboard with the integrated version
    cp "$INTEGRATED_DASHBOARD" "$CURRENT_COVID_DASHBOARD"
    
    # Verify the deployment
    if [[ -f "$CURRENT_COVID_DASHBOARD" ]] && grep -q "Political Analysis" "$CURRENT_COVID_DASHBOARD"; then
        success "Integrated dashboard deployed successfully"
    else
        error "Deployment verification failed"
        # Restore from backup
        warning "Restoring from backup..."
        cp "${CURRENT_COVID_DASHBOARD}${BACKUP_SUFFIX}" "$CURRENT_COVID_DASHBOARD"
        error "Deployment failed - original dashboard restored"
        exit 1
    fi
}

# Function to test the deployment
test_deployment() {
    log "Testing deployment..."
    
    # Basic HTML validation
    if command -v xmllint &> /dev/null; then
        if xmllint --html --noout "$CURRENT_COVID_DASHBOARD" 2>/dev/null; then
            success "HTML structure is valid"
        else
            warning "HTML validation warnings found (may be normal)"
        fi
    else
        info "xmllint not found - skipping HTML validation"
    fi
    
    # Check file size (should be larger due to additional features)
    local file_size=$(wc -c < "$CURRENT_COVID_DASHBOARD")
    if [[ $file_size -gt 50000 ]]; then
        success "Dashboard file size looks reasonable (${file_size} bytes)"
    else
        warning "Dashboard file seems small (${file_size} bytes) - may be incomplete"
    fi
    
    success "Deployment testing completed"
}

# Function to show deployment summary
show_summary() {
    echo
    echo "=================================================="
    success "🎉 INTEGRATED DASHBOARD DEPLOYMENT COMPLETED! 🎉"
    echo "=================================================="
    echo
    info "🔗 New Features Added:"
    echo "   • Political Analysis Toggle (checkbox in controls)"
    echo "   • Political data integration for US states/counties"
    echo "   • Enhanced region tags with vote percentages"
    echo "   • Political summary section with aggregated stats"
    echo "   • Political breakdown charts (Democrat vs Republican)"
    echo "   • Enhanced comparison table with political data"
    echo
    info "📊 How to Use:"
    echo "   1. Select US states or counties as usual"
    echo "   2. Check 'Show Political Analysis' checkbox"
    echo "   3. View integrated COVID + political data"
    echo "   4. Analyze correlations between health and political data"
    echo
    info "📁 Files:"
    echo "   • Active dashboard: $CURRENT_COVID_DASHBOARD"
    echo "   • Backup created: ${CURRENT_COVID_DASHBOARD}${BACKUP_SUFFIX}"
    echo "   • Election data: countypres_2020.csv"
    echo "   • COVID data: nytimes_covid-19-data/"
    echo
    warning "🚀 Next Steps:"
    echo "   • Test the dashboard in a web browser"
    echo "   • Deploy to your web server using your sync script"
    echo "   • Share with users interested in COVID-political correlations"
    echo
    info "💡 Research Applications:"
    echo "   • Analyze pandemic response across political contexts"
    echo "   • Study health outcomes vs voting patterns"
    echo "   • Compare policy effectiveness by political leaning"
    echo "   • Geographic correlation studies"
    echo
    log "Backup location: ${CURRENT_COVID_DASHBOARD}${BACKUP_SUFFIX}"
    warning "Remove backup file once you've verified everything works correctly"
}

# Main execution
main() {
    echo
    echo "=================================================="
    echo "🔄 COVID-19 + Election Data Integration Deployment"
    echo "=================================================="
    echo
    
    log "Starting integrated dashboard deployment..."
    
    check_prerequisites
    echo
    
    create_integrated_dashboard
    echo
    
    validate_dashboard
    echo
    
    # Confirm deployment
    warning "This will replace your current COVID dashboard with the integrated version."
    echo "Current dashboard will be backed up automatically."
    echo
    echo "Do you want to proceed with deployment? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "Deployment cancelled by user."
        exit 0
    fi
    
    echo
    create_backup
    echo
    
    deploy_dashboard
    echo
    
    test_deployment
    echo
    
    show_summary
}

# Handle script interruption
trap 'error "Script interrupted!"; exit 1' INT TERM

# Run main function
main "$@"
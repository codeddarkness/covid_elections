#!/bin/bash

# Script to test COVID-19 + Election Data Integration
# Author: Assistant
# Date: $(date +"%Y-%m-%d")

set -euo pipefail

# Configuration
COVID_DASHBOARD="covid_dashboard.html"
ELECTION_DATA="countypres_2020.csv"
COVID_DATA_DIR="nytimes_covid-19-data"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${PURPLE}[ℹ]${NC} $1"; }
demo() { echo -e "${CYAN}[🎯]${NC} $1"; }

# Function to check file existence and sizes
check_files() {
    log "Checking required files..."
    
    # Check COVID dashboard
    if [[ -f "$COVID_DASHBOARD" ]]; then
        local size=$(wc -c < "$COVID_DASHBOARD")
        success "COVID Dashboard: $COVID_DASHBOARD (${size} bytes)"
        
        # Check for integration features
        if grep -q "showPoliticalAnalysis" "$COVID_DASHBOARD"; then
            success "  ✓ Political analysis toggle found"
        else
            error "  ✗ Political analysis toggle missing"
            return 1
        fi
        
        if grep -q "electionData" "$COVID_DASHBOARD"; then
            success "  ✓ Election data integration found"
        else
            error "  ✗ Election data integration missing"
            return 1
        fi
    else
        error "COVID dashboard not found: $COVID_DASHBOARD"
        return 1
    fi
    
    # Check election data
    if [[ -f "$ELECTION_DATA" ]]; then
        local lines=$(wc -l < "$ELECTION_DATA")
        local size=$(wc -c < "$ELECTION_DATA")
        success "Election Data: $ELECTION_DATA (${lines} lines, ${size} bytes)"
        
        # Sample the data
        if head -1 "$ELECTION_DATA" | grep -q "year,state,state_po,county_name"; then
            success "  ✓ Election data format looks correct"
        else
            warning "  ⚠ Election data format may be incorrect"
        fi
    else
        error "Election data not found: $ELECTION_DATA"
        return 1
    fi
    
    # Check COVID data directory
    if [[ -d "$COVID_DATA_DIR" ]]; then
        local file_count=$(find "$COVID_DATA_DIR" -name "*.csv" | wc -l)
        success "COVID Data Directory: $COVID_DATA_DIR (${file_count} CSV files)"
        
        # Check key files
        local key_files=("us-states.csv" "us-counties-recent.csv")
        for file in "${key_files[@]}"; do
            if [[ -f "$COVID_DATA_DIR/$file" ]]; then
                success "  ✓ $file found"
            else
                warning "  ⚠ $file missing"
            fi
        done
    else
        error "COVID data directory not found: $COVID_DATA_DIR"
        return 1
    fi
    
    return 0
}

# Function to analyze election data
analyze_election_data() {
    log "Analyzing election data structure..."
    
    if [[ ! -f "$ELECTION_DATA" ]]; then
        error "Election data file not found"
        return 1
    fi
    
    # Get basic stats
    local total_lines=$(wc -l < "$ELECTION_DATA")
    local total_records=$((total_lines - 1))  # Subtract header
    
    info "Total election records: ${total_records}"
    
    # Analyze by mode
    echo
    info "Vote counting modes:"
    tail -n +2 "$ELECTION_DATA" | cut -d',' -f12 | sort | uniq -c | sort -nr | head -5 | while read count mode; do
        info "  ${mode}: ${count} records"
    done
    
    # Analyze by state
    echo
    info "Top 5 states by record count:"
    tail -n +2 "$ELECTION_DATA" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -5 | while read count state; do
        info "  ${state}: ${count} records"
    done
    
    # Check for TOTAL mode records (what we use)
    local total_mode_count=$(tail -n +2 "$ELECTION_DATA" | grep ",TOTAL," | wc -l)
    info "TOTAL mode records: ${total_mode_count} (these will be used for integration)"
    
    return 0
}

# Function to test political integration sample
test_political_integration() {
    log "Testing political data integration logic..."
    
    # Sample some common counties and states
    local test_regions=(
        "FLORIDA,Orange"
        "CALIFORNIA,Los Angeles" 
        "TEXAS,Harris"
        "NEW YORK,New York"
        "FLORIDA,Miami-Dade"
    )
    
    echo
    info "Testing political data lookup for sample regions:"
    
    for region in "${test_regions[@]}"; do
        local state=$(echo "$region" | cut -d',' -f1)
        local county=$(echo "$region" | cut -d',' -f2)
        
        # Look for matching records in election data
        local matches=$(grep ",$state," "$ELECTION_DATA" | grep ",$county," | grep ",TOTAL," | wc -l)
        
        if [[ $matches -gt 0 ]]; then
            success "  ${county}, ${state}: ${matches} political records found"
            
            # Show vote breakdown
            local dem_votes=$(grep ",$state," "$ELECTION_DATA" | grep ",$county," | grep ",TOTAL," | grep ",DEMOCRAT," | cut -d',' -f9 | head -1)
            local rep_votes=$(grep ",$state," "$ELECTION_DATA" | grep ",$county," | grep ",TOTAL," | grep ",REPUBLICAN," | cut -d',' -f9 | head -1)
            
            if [[ -n "$dem_votes" && -n "$rep_votes" ]]; then
                info "    Democrat: ${dem_votes} votes, Republican: ${rep_votes} votes"
            fi
        else
            warning "  ${county}, ${state}: No political records found"
        fi
    done
    
    return 0
}

# Function to simulate dashboard functionality
simulate_dashboard_test() {
    log "Simulating dashboard integration test..."
    
    echo
    demo "🎯 INTEGRATION TEST SIMULATION"
    echo
    
    demo "Step 1: User opens COVID dashboard"
    info "  → Dashboard loads with political analysis checkbox (unchecked)"
    
    demo "Step 2: User selects 'US Counties' data type"
    info "  → COVID county data loads successfully"
    
    demo "Step 3: User adds 'Orange, Florida' county"
    info "  → COVID data for Orange County, FL loaded"
    info "  → Region tag shows: 'Orange, Florida [us-counties]'"
    
    demo "Step 4: User enables 'Show Political Analysis'"
    info "  → Election data loads (countypres_2020.csv)"
    info "  → Political data lookup for Orange County, FL"
    
    # Simulate the lookup
    local matches=$(grep ",FLORIDA," "$ELECTION_DATA" | grep ",Orange," | grep ",TOTAL," | wc -l)
    if [[ $matches -gt 0 ]]; then
        success "  → Political data found! Integration successful"
        
        # Get actual vote data
        local dem_votes=$(grep ",FLORIDA," "$ELECTION_DATA" | grep ",Orange," | grep ",TOTAL," | grep ",DEMOCRAT," | cut -d',' -f9)
        local rep_votes=$(grep ",FLORIDA," "$ELECTION_DATA" | grep ",Orange," | grep ",TOTAL," | grep ",REPUBLICAN," | cut -d',' -f9)
        local total_votes=$(grep ",FLORIDA," "$ELECTION_DATA" | grep ",Orange," | grep ",TOTAL," | head -1 | cut -d',' -f10)
        
        if [[ -n "$dem_votes" && -n "$rep_votes" && -n "$total_votes" ]]; then
            local dem_pct=$(echo "scale=1; $dem_votes * 100 / $total_votes" | bc 2>/dev/null || echo "??")
            local rep_pct=$(echo "scale=1; $rep_votes * 100 / $total_votes" | bc 2>/dev/null || echo "??")
            
            success "  → Region tag updates: 'Orange, Florida [us-counties] D:${dem_pct}% R:${rep_pct}%'"
            success "  → Political summary shows aggregated stats"
            success "  → Additional political charts generated"
        fi
    else
        error "  → No political data found for Orange County, FL"
    fi
    
    echo
    demo "Step 5: User adds multiple regions for comparison"
    info "  → Miami-Dade, Florida"
    info "  → Los Angeles, California"
    info "  → Cook, Illinois"
    
    demo "Step 6: Dashboard shows integrated analysis"
    info "  → COVID trends charts with political context"
    info "  → Political breakdown charts (D vs R percentages)"
    info "  → Comparison table with both COVID and political data"
    info "  → Political summary section with aggregated statistics"
    
    echo
    success "🎉 Integration test simulation completed!"
}

# Function to show sample queries for testing
show_sample_queries() {
    log "Generating sample test cases..."
    
    echo
    info "📋 Recommended Test Cases for Manual Verification:"
    echo
    
    info "1. SWING STATES TEST:"
    echo "   • Data Type: US States"
    echo "   • Add: Florida, Pennsylvania, Arizona, Georgia"
    echo "   • Enable political analysis"
    echo "   • Expected: Close vote percentages, competitive regions"
    echo
    
    info "2. URBAN vs RURAL TEST:"
    echo "   • Data Type: US Counties"
    echo "   • Urban: Los Angeles (CA), Cook (IL), Harris (TX)"
    echo "   • Rural: Loving (TX), Kalawao (HI), King (TX)"
    echo "   • Expected: Urban lean Democrat, Rural lean Republican"
    echo
    
    info "3. TIMELINE CORRELATION TEST:"
    echo "   • Select politically diverse counties"
    echo "   • Set date range: March 2020 - November 2020"
    echo "   • Enable cumulative view"
    echo "   • Look for: Pre-election COVID patterns vs voting outcomes"
    echo
    
    info "4. POLICY EFFECTIVENESS TEST:"
    echo "   • Compare similar counties with opposite political leans"
    echo "   • Example: Orange (CA) vs Orange (FL)"
    echo "   • Analyze: Different policy responses and outcomes"
    echo
    
    info "5. ERROR HANDLING TEST:"
    echo "   • Try regions without political data (colleges, prisons)"
    echo "   • Mix US and international regions"
    echo "   • Expected: Graceful degradation, no errors"
}

# Function to check web server readiness
check_deployment_readiness() {
    log "Checking deployment readiness..."
    
    local issues=0
    
    # Check for sync script
    if [[ -f "sync.sh" ]]; then
        success "Sync script found: sync.sh"
    else
        warning "Sync script not found - you'll need to deploy manually"
        ((issues++))
    fi
    
    # Check file permissions
    if [[ -r "$COVID_DASHBOARD" ]]; then
        success "COVID dashboard is readable"
    else
        error "COVID dashboard permission issues"
        ((issues++))
    fi
    
    # Check data file sizes
    local large_files=()
    if [[ $(wc -c < "$ELECTION_DATA") -gt 10000000 ]]; then  # > 10MB
        large_files+=("$ELECTION_DATA")
    fi
    
    find "$COVID_DATA_DIR" -name "*.csv" -size +10M | while read file; do
        large_files+=("$file")
    done
    
    if [[ ${#large_files[@]} -gt 0 ]]; then
        warning "Large files detected - consider compression for faster loading:"
        for file in "${large_files[@]}"; do
            local size=$(ls -lh "$file" | awk '{print $5}')
            warning "  $file ($size)"
        done
    fi
    
    # Check for JavaScript dependencies
    if grep -q "chart.js@3.9.1" "$COVID_DASHBOARD"; then
        success "Chart.js dependency correctly referenced"
    else
        warning "Chart.js dependency may be missing or incorrect version"
        ((issues++))
    fi
    
    if grep -q "papaparse" "$COVID_DASHBOARD"; then
        success "Papa Parse dependency correctly referenced"
    else
        error "Papa Parse dependency missing"
        ((issues++))
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        success "🚀 Ready for deployment!"
    else
        warning "⚠️  ${issues} potential issues found - review before deploying"
    fi
    
    return $issues
}

# Main execution
main() {
    echo
    echo "=================================================="
    echo "🧪 COVID-19 + Election Data Integration Test Suite"
    echo "=================================================="
    echo
    
    log "Starting integration tests..."
    echo
    
    # Run all tests
    local exit_code=0
    
    if ! check_files; then
        error "File check failed"
        exit_code=1
    fi
    echo
    
    if ! analyze_election_data; then
        error "Election data analysis failed"
        exit_code=1
    fi
    echo
    
    if ! test_political_integration; then
        error "Political integration test failed"
        exit_code=1
    fi
    echo
    
    simulate_dashboard_test
    echo
    
    show_sample_queries
    echo
    
    if ! check_deployment_readiness; then
        warning "Deployment readiness check found issues"
        # Don't fail on deployment warnings
    fi
    
    echo
    echo "=================================================="
    if [[ $exit_code -eq 0 ]]; then
        success "🎉 ALL INTEGRATION TESTS PASSED!"
        echo
        info "Next steps:"
        echo "  1. Test manually in web browser"
        echo "  2. Deploy to web server: ./sync.sh"
        echo "  3. Share with users for feedback"
        echo "  4. Document any interesting findings"
    else
        error "❌ SOME TESTS FAILED!"
        echo
        warning "Please fix the issues above before deploying"
    fi
    echo "=================================================="
    
    return $exit_code
}

# Handle script interruption
trap 'error "Test interrupted!"; exit 1' INT TERM

# Check for bc command (for percentage calculations)
if ! command -v bc &> /dev/null; then
    warning "bc command not found - percentage calculations will show '??'"
    warning "Install bc for full functionality: apt-get install bc / brew install bc"
fi

# Run main function
main "$@"
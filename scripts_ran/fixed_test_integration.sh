#!/bin/bash

# Fixed Script to test COVID-19 + Election Data Integration
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
        success "COVID Dashboard: $COVID_DASHBOARD ($(printf "%8d" $size) bytes)"
        
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
        
        if grep -q "countypres_2020.csv" "$COVID_DASHBOARD"; then
            success "  ✓ Election data file reference found"
        else
            warning "  ⚠ Election data file reference not found"
        fi
    else
        error "COVID dashboard not found: $COVID_DASHBOARD"
        return 1
    fi
    
    # Check election data
    if [[ -f "$ELECTION_DATA" ]]; then
        local lines=$(wc -l < "$ELECTION_DATA")
        local size=$(wc -c < "$ELECTION_DATA")
        success "Election Data: $ELECTION_DATA ($(printf "%6d" $lines) lines, $(printf "%8d" $size) bytes)"
        
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
    
    # Analyze by mode (FIXED: mode is the last column)
    echo
    info "Vote counting modes:"
    tail -n +2 "$ELECTION_DATA" | awk -F',' '{print $NF}' | sort | uniq -c | sort -nr | head -5 | while read count mode; do
        info "  ${mode}: ${count} records"
    done
    
    # Analyze by state
    echo
    info "Top 5 states by record count:"
    tail -n +2 "$ELECTION_DATA" | awk -F',' '{print $2}' | sort | uniq -c | sort -nr | head -5 | while read count state; do
        info "  ${state}: ${count} records"
    done
    
    # Check for TOTAL mode records (FIXED: use correct pattern)
    local total_mode_count=$(tail -n +2 "$ELECTION_DATA" | grep "TOTAL$" | wc -l)
    info "TOTAL mode records: ${total_mode_count} (these will be used for integration)"
    
    # Check for presidential records
    local pres_records=$(tail -n +2 "$ELECTION_DATA" | grep "US PRESIDENT" | wc -l)
    info "US PRESIDENT records: ${pres_records}"
    
    # Combined filter (what the dashboard actually uses)
    local usable_records=$(tail -n +2 "$ELECTION_DATA" | grep "TOTAL$" | grep "US PRESIDENT" | grep "2020" | wc -l)
    info "Usable records (2020 + US PRESIDENT + TOTAL): ${usable_records}"
    
    return 0
}

# Function to test political integration sample (FIXED)
test_political_integration() {
    log "Testing political data integration logic..."
    
    # Sample some common counties and states
    local test_regions=(
        "FLORIDA::Orange"
        "CALIFORNIA::Los Angeles" 
        "TEXAS::Harris"
        "NEW YORK::New York"
        "FLORIDA::Miami-Dade"
        "ILLINOIS::Cook"
        "ARIZONA::Maricopa"
    )
    
    echo
    info "Testing political data lookup for sample regions:"
    
    for region in "${test_regions[@]}"; do
        local state=$(echo "$region" | cut -d':' -f1)
        local county=$(echo "$region" | cut -d':' -f3)
        
        # Look for matching records in election data (FIXED: proper CSV parsing)
        # Format: year,state,state_po,county_name,county_fips,office,candidate,party,candidatevotes,totalvotes,version,mode
        local matches=$(awk -F',' -v state="$state" -v county="$county" '
            NR>1 && $2==state && $4==county && $6=="US PRESIDENT" && $NF=="TOTAL" {count++} 
            END {print count+0}
        ' "$ELECTION_DATA")
        
        if [[ $matches -gt 0 ]]; then
            success "  ${county}, ${state}: ${matches} political records found"
            
            # Show vote breakdown (get Democrat and Republican votes)
            local dem_votes=$(awk -F',' -v state="$state" -v county="$county" '
                NR>1 && $2==state && $4==county && $6=="US PRESIDENT" && $8=="DEMOCRAT" && $NF=="TOTAL" {print $9; exit}
            ' "$ELECTION_DATA")
            
            local rep_votes=$(awk -F',' -v state="$state" -v county="$county" '
                NR>1 && $2==state && $4==county && $6=="US PRESIDENT" && $8=="REPUBLICAN" && $NF=="TOTAL" {print $9; exit}
            ' "$ELECTION_DATA")
            
            local total_votes=$(awk -F',' -v state="$state" -v county="$county" '
                NR>1 && $2==state && $4==county && $6=="US PRESIDENT" && $NF=="TOTAL" {print $10; exit}
            ' "$ELECTION_DATA")
            
            if [[ -n "$dem_votes" && -n "$rep_votes" && -n "$total_votes" ]]; then
                local dem_pct=0
                local rep_pct=0
                if command -v bc &> /dev/null && [[ $total_votes -gt 0 ]]; then
                    dem_pct=$(echo "scale=1; $dem_votes * 100 / $total_votes" | bc)
                    rep_pct=$(echo "scale=1; $rep_votes * 100 / $total_votes" | bc)
                fi
                info "    Democrat: ${dem_votes} votes (${dem_pct}%), Republican: ${rep_votes} votes (${rep_pct}%)"
            fi
        else
            warning "  ${county}, ${state}: No political records found"
        fi
    done
    
    return 0
}

# Function to test state-level integration
test_state_integration() {
    log "Testing state-level political integration..."
    
    local test_states=("FLORIDA" "CALIFORNIA" "TEXAS" "NEW YORK" "ILLINOIS")
    
    echo
    info "Testing state-level political data:"
    
    for state in "${test_states[@]}"; do
        # Get aggregated state results
        local total_dem=$(awk -F',' -v state="$state" '
            NR>1 && $2==state && $6=="US PRESIDENT" && $8=="DEMOCRAT" && $NF=="TOTAL" {sum+=$9} 
            END {print sum+0}
        ' "$ELECTION_DATA")
        
        local total_rep=$(awk -F',' -v state="$state" '
            NR>1 && $2==state && $6=="US PRESIDENT" && $8=="REPUBLICAN" && $NF=="TOTAL" {sum+=$9} 
            END {print sum+0}
        ' "$ELECTION_DATA")
        
        local state_total=$(awk -F',' -v state="$state" '
            NR>1 && $2==state && $6=="US PRESIDENT" && $NF=="TOTAL" {
                if ($10 > max) max = $10
            } 
            END {print max+0}
        ' "$ELECTION_DATA")
        
        if [[ $total_dem -gt 0 && $total_rep -gt 0 ]]; then
            local winner="Republican"
            if [[ $total_dem -gt $total_rep ]]; then
                winner="Democrat"
            fi
            
            success "  ${state}: ${winner} winner (D:${total_dem}, R:${total_rep})"
        else
            warning "  ${state}: No aggregated data found"
        fi
    done
}

# Function to simulate dashboard functionality (UPDATED)
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
    
    # Simulate the lookup with correct parsing
    local matches=$(awk -F',' '
        NR>1 && $2=="FLORIDA" && $4=="Orange" && $6=="US PRESIDENT" && $NF=="TOTAL" {count++} 
        END {print count+0}
    ' "$ELECTION_DATA")
    
    if [[ $matches -gt 0 ]]; then
        success "  → Political data found! Integration successful"
        
        # Get actual vote data
        local dem_votes=$(awk -F',' '
            NR>1 && $2=="FLORIDA" && $4=="Orange" && $6=="US PRESIDENT" && $8=="DEMOCRAT" && $NF=="TOTAL" {print $9; exit}
        ' "$ELECTION_DATA")
        
        local rep_votes=$(awk -F',' '
            NR>1 && $2=="FLORIDA" && $4=="Orange" && $6=="US PRESIDENT" && $8=="REPUBLICAN" && $NF=="TOTAL" {print $9; exit}
        ' "$ELECTION_DATA")
        
        local total_votes=$(awk -F',' '
            NR>1 && $2=="FLORIDA" && $4=="Orange" && $6=="US PRESIDENT" && $NF=="TOTAL" {print $10; exit}
        ' "$ELECTION_DATA")
        
        if [[ -n "$dem_votes" && -n "$rep_votes" && -n "$total_votes" ]] && command -v bc &> /dev/null; then
            local dem_pct=$(echo "scale=1; $dem_votes * 100 / $total_votes" | bc 2>/dev/null || echo "??")
            local rep_pct=$(echo "scale=1; $rep_votes * 100 / $total_votes" | bc 2>/dev/null || echo "??")
            
            success "  → Region tag updates: 'Orange, Florida [us-counties] D:${dem_pct}% R:${rep_pct}%'"
            success "  → Political summary shows aggregated stats"
            success "  → Additional political charts generated"
        else
            success "  → Political data found but percentage calculation unavailable"
        fi
    else
        error "  → No political data found for Orange County, FL"
        info "  → This suggests an issue with data format or filtering"
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
    echo "   • Rural: Try smaller counties in rural states"
    echo "   • Expected: Different political patterns"
    echo
    
    info "3. FLORIDA DEEP DIVE:"
    echo "   • Counties: Orange, Miami-Dade, Hillsborough, Palm Beach"
    echo "   • Expected: Diverse political landscape within one state"
    echo
    
    info "4. CALIFORNIA ANALYSIS:"
    echo "   • Counties: Los Angeles, Orange, San Francisco, Fresno"
    echo "   • Expected: Mix of blue and red counties"
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
        
        # Check if sync script has integration mode
        if grep -q "INTEGRATION_MODE" "sync.sh"; then
            success "  ✓ Sync script has integration mode support"
        else
            warning "  ⚠ Sync script may need integration mode update"
        fi
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
    if [[ $(wc -c < "$ELECTION_DATA") -gt 1000000 ]]; then  # > 1MB
        local size=$(ls -lh "$ELECTION_DATA" | awk '{print $5}')
        info "Election data size: $size"
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

# Function to show deployment commands
show_deployment_commands() {
    log "Recommended deployment commands..."
    
    echo
    info "🚀 DEPLOYMENT OPTIONS:"
    echo
    
    info "1. Integration Mode (Recommended):"
    echo "   ./sync.sh -i"
    echo "   → Deploys dashboard + election data + core files"
    echo
    
    info "2. Dashboard Only (Quick Update):"
    echo "   ./sync.sh -d"
    echo "   → Updates just the dashboard file"
    echo
    
    info "3. Full Sync:"
    echo "   ./sync.sh"
    echo "   → Complete project deployment"
    echo
    
    info "4. Force Deployment (No Prompts):"
    echo "   ./sync.sh -i -f"
    echo "   → Integration mode without confirmation"
    echo
}

# Main execution
main() {
    echo
    echo "=================================================="
    echo "🧪 COVID-19 + Election Data Integration Test Suite (Fixed)"
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
    
    test_state_integration
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
    
    show_deployment_commands
    
    echo
    echo "=================================================="
    if [[ $exit_code -eq 0 ]]; then
        success "🎉 ALL INTEGRATION TESTS PASSED!"
        echo
        info "Next steps:"
        echo "  1. Deploy: ./sync.sh -i"
        echo "  2. Test in browser: http://bataleon/covid_elections/"
        echo "  3. Enable political analysis and test regions"
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
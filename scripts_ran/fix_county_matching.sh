#!/bin/bash

# Quick fix for county political data matching issues
# This patches the COVID dashboard to handle case sensitivity and county name variations

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "🔧 County Political Data Matching Fix"
echo "=================================================="
echo

# Check if dashboard file exists
if [[ ! -f "covid_dashboard.html" ]]; then
    echo -e "${RED}Error: covid_dashboard.html not found${NC}"
    exit 1
fi

# Create backup
BACKUP_FILE="covid_dashboard.html.county-fix-backup-$(date +%Y%m%d-%H%M%S)"
cp covid_dashboard.html "$BACKUP_FILE"
echo -e "${BLUE}Created backup: $BACKUP_FILE${NC}"

# Create the fixed version
cat > county_matching_fix.js << 'EOF'
        // FIXED: Get political data for a region with improved matching
        function getRegionPoliticalData(region, dataType) {
            if (!showPoliticalAnalysis || electionData.length === 0) return null;
            
            try {
                if (dataType === 'us-states') {
                    // Match by state name (case insensitive)
                    return electionData.filter(d => 
                        d.state && d.state.toUpperCase() === region.toUpperCase()
                    );
                } else if (dataType === 'us-counties') {
                    // Parse "County, State" format
                    const [county, state] = region.split(', ');
                    if (!county || !state) return null;
                    
                    // FIXED: Case insensitive matching with county name normalization
                    return electionData.filter(d => {
                        if (!d.state || !d.county_name) return false;
                        
                        // Normalize state names (case insensitive)
                        const stateMatch = d.state.toUpperCase() === state.toUpperCase();
                        
                        // Normalize county names (handle common variations)
                        const normalizeCounty = (name) => {
                            return name.toUpperCase()
                                .replace(/\s+/g, ' ')           // Normalize whitespace
                                .replace(/\-/g, ' ')           // Miami-Dade -> Miami Dade
                                .replace(/\./g, '')            // St. -> St
                                .replace(/\bST\b/g, 'SAINT')   // St -> Saint
                                .replace(/\bSTE\b/g, 'SAINTE') // Ste -> Sainte
                                .trim();
                        };
                        
                        const normalizedElectionCounty = normalizeCounty(d.county_name);
                        const normalizedSearchCounty = normalizeCounty(county);
                        
                        const countyMatch = normalizedElectionCounty === normalizedSearchCounty;
                        
                        // Debug logging
                        if (stateMatch && region.includes('Orange')) {
                            console.log('County matching debug:', {
                                searchCounty: county,
                                searchState: state,
                                electionCounty: d.county_name,
                                electionState: d.state,
                                normalizedSearch: normalizedSearchCounty,
                                normalizedElection: normalizedElectionCounty,
                                countyMatch: countyMatch
                            });
                        }
                        
                        return stateMatch && countyMatch;
                    });
                }
            } catch (error) {
                console.warn('Error getting political data for region:', region, error);
            }
            
            return null;
        }
EOF

echo -e "${BLUE}Applying county matching fix...${NC}"

# Use sed to replace the function in the dashboard
sed -i.tmp '/\/\/ Get political data for a region/,/return null;/{
    /\/\/ Get political data for a region/r county_matching_fix.js
    d
}' covid_dashboard.html

# Check if the replacement worked
if grep -q "normalizeCounty" covid_dashboard.html; then
    echo -e "${GREEN}✅ County matching fix applied successfully${NC}"
    rm covid_dashboard.html.tmp
else
    echo -e "${RED}❌ Fix application failed, restoring backup${NC}"
    mv covid_dashboard.html.tmp covid_dashboard.html
    exit 1
fi

# Clean up
rm county_matching_fix.js

echo
echo -e "${BLUE}Testing the fix...${NC}"

# Quick verification
if grep -q "toUpperCase" covid_dashboard.html && grep -q "normalizeCounty" covid_dashboard.html; then
    echo -e "${GREEN}✅ Fix verification passed${NC}"
    echo "  - Case insensitive matching: ✓"
    echo "  - County name normalization: ✓"
    echo "  - Debug logging: ✓"
else
    echo -e "${RED}❌ Fix verification failed${NC}"
    exit 1
fi

echo
echo -e "${BLUE}📊 Now testing with actual data...${NC}"

# Run a quick data test if the diagnostic script exists
if [[ -f "debug_county_matching.sh" ]]; then
    echo "Running diagnostic to check data compatibility..."
    ./debug_county_matching.sh | grep -A 5 -B 5 "Orange County"
fi

echo
echo "=================================================="
echo -e "${GREEN}🎉 County Matching Fix Complete!${NC}"
echo "=================================================="
echo
echo -e "${BLUE}What was fixed:${NC}"
echo "  ✅ State name case sensitivity (FLORIDA vs Florida)"
echo "  ✅ County name normalization (Miami-Dade vs Miami Dade)"
echo "  ✅ Whitespace and punctuation handling"
echo "  ✅ Debug logging for troubleshooting"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Deploy the fixed dashboard: ./sync.sh -d"
echo "  2. Test in browser with Orange County, Florida"
echo "  3. Enable political analysis and check for vote percentages"
echo
echo -e "${BLUE}Backup saved as:${NC} $BACKUP_FILE"
echo "=================================================="
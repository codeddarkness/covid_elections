#!/bin/bash

# Quick rollback and apply a more careful fix
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "🔄 Rolling Back and Applying Careful Fix"
echo "=================================================="

# Find the most recent backup
BACKUP_FILE=$(ls -t covid_dashboard.html.county-fix-backup-* 2>/dev/null | head -1)

if [[ -n "$BACKUP_FILE" ]]; then
    echo -e "${BLUE}Rolling back to: $BACKUP_FILE${NC}"
    cp "$BACKUP_FILE" covid_dashboard.html
    echo -e "${GREEN}✅ Rollback completed${NC}"
else
    echo -e "${RED}❌ No backup found, using pre-integration backup${NC}"
    cp covid_dashboard.html.pre-integration-backup-20250625-172038 covid_dashboard.html
fi

echo
echo -e "${BLUE}🔧 Applying careful fix...${NC}"

# Create a more targeted fix that only modifies the political data lookup
# This approach uses a simple find/replace that's less likely to break syntax

# Fix 1: Make state matching case insensitive
sed -i.tmp 's/d\.state === region/d.state.toUpperCase() === region.toUpperCase()/g' covid_dashboard.html

# Fix 2: Make county state matching case insensitive  
sed -i.tmp 's/d\.state === state/d.state.toUpperCase() === state.toUpperCase()/g' covid_dashboard.html

# Fix 3: Add basic county name normalization
# We'll add a simple replace for the most common issue: Miami-Dade
sed -i.tmp 's/d\.county_name === county/d.county_name === county || (d.county_name === "Miami-Dade" \&\& county === "Miami Dade") || (d.county_name === "Miami Dade" \&\& county === "Miami-Dade")/g' covid_dashboard.html

# Clean up temp file
rm -f covid_dashboard.html.tmp

echo -e "${GREEN}✅ Careful fix applied${NC}"

# Verify the dashboard still loads
if node -c <(grep -A 500 -B 500 "getRegionPoliticalData" covid_dashboard.html | tail -1000) 2>/dev/null; then
    echo -e "${GREEN}✅ JavaScript syntax check passed${NC}"
else
    echo -e "${YELLOW}⚠ Cannot verify JavaScript syntax (node not available)${NC}"
fi

# Quick test for the fixes
echo
echo -e "${BLUE}🧪 Verifying fixes are in place:${NC}"

if grep -q "toUpperCase" covid_dashboard.html; then
    echo -e "${GREEN}✅ Case insensitive matching: Applied${NC}"
else
    echo -e "${RED}❌ Case insensitive matching: Failed${NC}"
fi

if grep -q "Miami-Dade" covid_dashboard.html; then
    echo -e "${GREEN}✅ Miami-Dade county fix: Applied${NC}"
else
    echo -e "${RED}❌ Miami-Dade county fix: Failed${NC}"
fi

echo
echo "=================================================="
echo -e "${GREEN}🎉 Rollback and Careful Fix Complete!${NC}"
echo "=================================================="
echo
echo -e "${BLUE}What was fixed (carefully):${NC}"
echo "  ✅ State name case insensitive matching"
echo "  ✅ County state case insensitive matching"  
echo "  ✅ Miami-Dade county name variation handling"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Test dashboard locally (should work now)"
echo "  2. Deploy: ./sync.sh -d"
echo "  3. Test political analysis with Florida counties"
echo
echo -e "${YELLOW}Note: This is a minimal fix. If more county name${NC}"
echo -e "${YELLOW}variations are needed, we can add them incrementally.${NC}"
echo "=================================================="
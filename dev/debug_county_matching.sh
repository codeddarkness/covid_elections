#!/bin/bash

# Debug script to check county name matching between COVID and election data
# This will help identify why political data isn't showing for counties

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "🔍 County Political Data Matching Diagnostic"
echo "=================================================="
echo

# Check if files exist
if [[ ! -f "countypres_2020.csv" ]]; then
    echo -e "${RED}Error: countypres_2020.csv not found${NC}"
    exit 1
fi

if [[ ! -f "nytimes_covid-19-data/us-counties-recent.csv" ]]; then
    echo -e "${RED}Error: COVID county data not found${NC}"
    exit 1
fi

echo -e "${BLUE}📊 ELECTION DATA ANALYSIS${NC}"
echo "=================================="

# Show election data structure
echo "Election data header:"
head -1 countypres_2020.csv
echo

# Show sample election records for Florida
echo "Sample Florida election records:"
grep "^2020,FLORIDA," countypres_2020.csv | grep ",TOTAL$" | head -3
echo

# Check unique counties in Florida election data
echo "Florida counties in election data (first 10):"
grep "^2020,FLORIDA," countypres_2020.csv | grep ",TOTAL$" | cut -d',' -f4 | sort -u | head -10
echo

echo -e "${BLUE}📊 COVID DATA ANALYSIS${NC}"
echo "==============================="

# Show COVID data structure  
echo "COVID data header:"
head -1 nytimes_covid-19-data/us-counties-recent.csv
echo

# Show sample COVID records for Florida
echo "Sample Florida COVID records:"
grep ",Florida," nytimes_covid-19-data/us-counties-recent.csv | head -3
echo

# Check unique counties in Florida COVID data
echo "Florida counties in COVID data (first 10):"
grep ",Florida," nytimes_covid-19-data/us-counties-recent.csv | cut -d',' -f2 | sort -u | head -10
echo

echo -e "${BLUE}🔍 MATCHING ANALYSIS${NC}"
echo "========================="

# Key test case: Orange County, Florida
echo "Testing Orange County, Florida matching:"
echo

echo "Election data lookup for Orange County, FL:"
echo "  Query: grep \"^2020,FLORIDA,\" countypres_2020.csv | grep \",Orange,\" | grep \",TOTAL$\""
ELECTION_ORANGE=$(grep "^2020,FLORIDA," countypres_2020.csv | grep ",Orange," | grep ",TOTAL$" | wc -l)
echo "  Results: $ELECTION_ORANGE records found"
if [[ $ELECTION_ORANGE -gt 0 ]]; then
    echo "  Sample record:"
    grep "^2020,FLORIDA," countypres_2020.csv | grep ",Orange," | grep ",TOTAL$" | head -1
fi
echo

echo "COVID data lookup for Orange County, FL:"
echo "  Query: grep \",Orange,Florida,\" nytimes_covid-19-data/us-counties-recent.csv"
COVID_ORANGE=$(grep ",Orange,Florida," nytimes_covid-19-data/us-counties-recent.csv | wc -l)
echo "  Results: $COVID_ORANGE records found"
if [[ $COVID_ORANGE -gt 0 ]]; then
    echo "  Sample record:"
    grep ",Orange,Florida," nytimes_covid-19-data/us-counties-recent.csv | head -1
fi
echo

# Test case: Miami-Dade County, Florida
echo "Testing Miami-Dade County, Florida matching:"
echo

echo "Election data lookup for Miami-Dade County, FL:"
ELECTION_MIAMI=$(grep "^2020,FLORIDA," countypres_2020.csv | grep -E ",Miami-Dade|,Miami Dade," | grep ",TOTAL$" | wc -l)
echo "  Results: $ELECTION_MIAMI records found"
if [[ $ELECTION_MIAMI -gt 0 ]]; then
    echo "  Sample record:"
    grep "^2020,FLORIDA," countypres_2020.csv | grep -E ",Miami-Dade|,Miami Dade," | grep ",TOTAL$" | head -1
fi
echo

echo "COVID data lookup for Miami-Dade County, FL:"
COVID_MIAMI=$(grep -E ",Miami-Dade,Florida,|,Miami Dade,Florida," nytimes_covid-19-data/us-counties-recent.csv | wc -l)
echo "  Results: $COVID_MIAMI records found"
if [[ $COVID_MIAMI -gt 0 ]]; then
    echo "  Sample record:"
    grep -E ",Miami-Dade,Florida,|,Miami Dade,Florida," nytimes_covid-19-data/us-counties-recent.csv | head -1
fi
echo

echo -e "${BLUE}📋 SPECIFIC COUNTY COMPARISON${NC}"
echo "=================================="

# Compare county names directly
echo "Checking for exact county name matches between datasets..."

# Create temporary files with county names
grep "^2020,FLORIDA," countypres_2020.csv | grep ",TOTAL$" | cut -d',' -f4 | sort -u > /tmp/election_fl_counties.txt
grep ",Florida," nytimes_covid-19-data/us-counties-recent.csv | cut -d',' -f2 | sort -u > /tmp/covid_fl_counties.txt

echo "Counties in BOTH datasets:"
comm -12 /tmp/election_fl_counties.txt /tmp/covid_fl_counties.txt | head -10

echo
echo "Counties ONLY in election data:"
comm -23 /tmp/election_fl_counties.txt /tmp/covid_fl_counties.txt | head -10

echo
echo "Counties ONLY in COVID data:"
comm -13 /tmp/election_fl_counties.txt /tmp/covid_fl_counties.txt | head -10

# Clean up
rm -f /tmp/election_fl_counties.txt /tmp/covid_fl_counties.txt

echo
echo -e "${BLUE}🔧 INTEGRATION ISSUES FOUND${NC}"
echo "============================="

# Check for common issues
echo "Potential matching issues:"

# Issue 1: State name case
ELECTION_STATE_CASE=$(head -5 countypres_2020.csv | grep -c "FLORIDA" || echo "0")
COVID_STATE_CASE=$(head -5 nytimes_covid-19-data/us-counties-recent.csv | grep -c "Florida" || echo "0")

if [[ $ELECTION_STATE_CASE -gt 0 && $COVID_STATE_CASE -gt 0 ]]; then
    echo -e "${YELLOW}⚠ Issue 1: State name case mismatch${NC}"
    echo "  Election data uses: 'FLORIDA' (uppercase)"
    echo "  COVID data uses: 'Florida' (title case)"
fi

# Issue 2: County name differences
echo
echo -e "${YELLOW}⚠ Issue 2: County name format differences${NC}"
echo "  Some counties may have different naming conventions"
echo "  (e.g., 'Miami-Dade' vs 'Miami Dade', 'St.' vs 'Saint')"

echo
echo -e "${BLUE}💡 RECOMMENDED FIXES${NC}"
echo "==================="

echo "1. Fix state name case matching in dashboard JavaScript:"
echo "   Change: d.state === state"
echo "   To: d.state.toUpperCase() === state.toUpperCase()"
echo

echo "2. Add county name normalization:"
echo "   - Handle hyphen variations (Miami-Dade vs Miami Dade)"
echo "   - Handle abbreviation differences (St. vs Saint)"
echo

echo "3. Add debug logging to dashboard:"
echo "   - Log actual search terms being used"
echo "   - Log number of matches found"

echo
echo "=================================================="
echo -e "${GREEN}Diagnostic complete!${NC}"
echo "Use the information above to fix county matching issues."
echo "=================================================="
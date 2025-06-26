#!/bin/bash

# COVID Dashboard Deployment Script
# This script should be run from your local development machine (osprey)
# It will prepare the dashboard and sync it to the web server

set -e

# Configuration
PROJECT_DIR="/Users/raymond/covid_elections"
DASHBOARD_FILE="covid_dashboard.html"
SYNC_SCRIPT="sync_covid_project.sh"

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

# Check if we're in the right directory
check_environment() {
    print_status "Checking environment..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory not found: $PROJECT_DIR"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    if [ ! -d "nytimes_covid-19-data" ]; then
        print_error "COVID data directory not found. Please ensure nytimes_covid-19-data is present."
        exit 1
    fi
    
    print_success "Environment check passed"
}

# Create the dashboard HTML file if it doesn't exist
create_dashboard() {
    print_status "Creating dashboard file..."
    
    if [ ! -f "$DASHBOARD_FILE" ]; then
        print_warning "Dashboard HTML file not found. You need to save the dashboard HTML to $DASHBOARD_FILE"
        echo ""
        echo "Please save the COVID dashboard HTML content to: $PROJECT_DIR/$DASHBOARD_FILE"
        echo "Then run this script again."
        exit 1
    fi
    
    print_success "Dashboard file found: $DASHBOARD_FILE"
}

# Validate data files
validate_data() {
    print_status "Validating data files..."
    
    local data_files=(
        "nytimes_covid-19-data/us-states.csv"
        "nytimes_covid-19-data/us-counties-recent.csv"
        "nytimes_covid-19-data/colleges/colleges.csv"
        "nytimes_covid-19-data/prisons/facilities.csv"
        "nytimes_covid-19-data/prisons/systems.csv"
        "nytimes_covid-19-data/excess-deaths/deaths.csv"
        "nytimes_covid-19-data/mask-use/mask-use-by-county.csv"
    )
    
    local missing_files=()
    
    for file in "${data_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Some data files are missing:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        print_warning "The dashboard may not work properly with missing data files."
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All expected data files found"
    fi
}

# Create a simple index.html that redirects to the dashboard
create_index() {
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
    
    print_success "Index file created"
}

# Create README for the web deployment
create_web_readme() {
    print_status "Creating web README..."
    
    cat > README_WEB.md << 'EOF'
# COVID-19 Data Analysis Dashboard

This is a web-based dashboard for analyzing COVID-19 data collected by The New York Times.

## Files Structure

- `index.html` - Main entry point (redirects to dashboard)
- `covid_dashboard.html` - Main dashboard application
- `nytimes_covid-19-data/` - COVID-19 datasets
  - `us-states.csv` - State-level data
  - `us-counties-*.csv` - County-level data
  - `colleges/` - College and university data
  - `prisons/` - Prison and detention facility data
  - `excess-deaths/` - Excess mortality data
  - `mask-use/` - Mask usage survey data

## Usage

1. Open the dashboard in a web browser
2. Select a data type from the dropdown
3. Choose regions to compare
4. View interactive charts and statistics

## Data Sources

All data is provided by The New York Times COVID-19 Data Repository.
Licensed under Creative Commons Attribution-NonCommercial 4.0 International.

## Last Updated

Generated on: $(date)
EOF
    
    print_success "Web README created"
}

# Run the sync script
run_sync() {
    print_status "Running sync to web server..."
    
    if [ -f "$SYNC_SCRIPT" ]; then
        chmod +x "$SYNC_SCRIPT"
        ./"$SYNC_SCRIPT" "$@"
    else
        print_error "Sync script not found: $SYNC_SCRIPT"
        print_status "You can sync manually using rsync:"
        echo "rsync -avz --delete $PROJECT_DIR/ raymond@bataleon:/var/www/html/covid_elections/"
        exit 1
    fi
}

# Main function
main() {
    echo "========================================"
    echo "COVID Dashboard Deployment Script"
    echo "========================================"
    echo ""
    
    check_environment
    create_dashboard
    validate_data
    create_index
    create_web_readme
    
    print_success "Preparation complete!"
    echo ""
    
    # Ask if user wants to sync now
    read -p "Do you want to sync to the web server now? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$SYNC_SCRIPT" ]; then
            run_sync "$@"
        else
            print_warning "Sync script not found. Please run sync manually:"
            echo "rsync -avz --delete $PROJECT_DIR/ raymond@bataleon:/var/www/html/covid_elections/"
        fi
    else
        print_status "Deployment prepared. You can sync later using:"
        echo "  ./$SYNC_SCRIPT"
        echo "  or manually with rsync"
    fi
    
    echo ""
    print_success "Deployment script completed!"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script prepares the COVID dashboard for deployment."
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --sync     Automatically sync after preparation"
    echo "  -f, --force    Force operations without confirmation"
    echo ""
    echo "The script will:"
    echo "  1. Check the environment and data files"
    echo "  2. Validate the dashboard HTML file"
    echo "  3. Create index.html and documentation"
    echo "  4. Optionally sync to the web server"
}

# Parse command line arguments
AUTO_SYNC=false
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -s|--sync)
            AUTO_SYNC=true
            shift
            ;;
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
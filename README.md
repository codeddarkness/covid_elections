# COVID-19 Data Analysis Dashboard Project

## Project Overview

This project is a comprehensive web-based dashboard for analyzing COVID-19 data collected by The New York Times. The dashboard provides interactive visualization and comparison capabilities across multiple data types including US states, counties, colleges, prisons, excess deaths, and mask usage surveys.

## Key Features

- Cross-data type comparison (compare states vs counties vs colleges vs prisons)
- Interactive time series charts with cumulative and daily views
- Comparison tables with detailed metrics
- Mobile-responsive design with dark theme
- Real-time CSV data loading and parsing
- Mixed data visualization with logarithmic scaling
- Proper sorting (states then regions within data types)

## Technology Stack

- HTML5 with responsive CSS3
- JavaScript (ES6+)
- Chart.js v3.9.1 for data visualization
- Papa Parse for CSV data processing
- Date-fns adapter for Chart.js time series

## Folder Structure

```
covid_elections/
├── covid_dashboard.html              # Main dashboard application
├── index.html                        # Redirect page to dashboard
├── README_WEB.md                     # Web deployment documentation
├── sync.sh                           # Universal sync script
├── sources.txt                       # Data source references
├── nytimes_covid-19-data/           # COVID-19 datasets
│   ├── us-states.csv                # State-level time series data
│   ├── us-counties-recent.csv       # Recent county-level data
│   ├── us-counties-2020.csv         # County data for 2020
│   ├── us-counties-2021.csv         # County data for 2021
│   ├── us-counties-2022.csv         # County data for 2022
│   ├── us-counties-2023.csv         # County data for 2023
│   ├── us-counties.csv              # Complete county dataset
│   ├── us.csv                       # National-level data
│   ├── colleges/
│   │   ├── colleges.csv             # College and university cases
│   │   └── README.md                # College data methodology
│   ├── prisons/
│   │   ├── facilities.csv           # Individual prison facilities
│   │   ├── systems.csv              # Prison system totals
│   │   └── README.md                # Prison data methodology
│   ├── excess-deaths/
│   │   ├── deaths.csv               # Excess mortality data
│   │   └── README.md                # Excess deaths methodology
│   ├── mask-use/
│   │   ├── mask-use-by-county.csv   # County-level mask usage survey
│   │   └── README.md                # Mask survey methodology
│   └── rolling-averages/
│       ├── us-states.csv            # State rolling averages
│       ├── us-counties-recent.csv   # County rolling averages
│       ├── anomalies.csv            # Data anomaly documentation
│       └── README.md                # Rolling averages methodology
├── electoral_data/                  # Election turnout data (separate)
│   ├── MSA_Turnout_2020_2024_v1.0.csv
│   ├── Turnout_2020G_v1.2.csv
│   └── Turnout_2024G_v0.3.csv
└── scripts_ran/                     # Archive of old deployment scripts
```

## Data Structure

### US States Data (us-states.csv)
- date: Date in YYYY-MM-DD format
- state: State name
- fips: State FIPS code
- cases: Cumulative confirmed cases
- deaths: Cumulative confirmed deaths

### US Counties Data (us-counties-*.csv)
- date: Date in YYYY-MM-DD format
- county: County name
- state: State name
- fips: County FIPS code
- cases: Cumulative confirmed cases
- deaths: Cumulative confirmed deaths

### Colleges Data (colleges/colleges.csv)
- date: Last update date
- state: State where college is located
- county: County where college is located
- city: City where college is located
- ipeds_id: College identification number
- college: College/university name
- cases: Total cases since pandemic start
- cases_2021: Cases reported in 2021 only
- notes: Methodological notes

### Prison Data (prisons/facilities.csv)
- nyt_id: Unique facility identifier
- facility_name: Name of the facility
- facility_type: Type of correctional facility
- facility_city: City location
- facility_state: State location
- latest_inmate_population: Current inmate count
- total_inmate_cases: Total inmate COVID cases
- total_inmate_deaths: Total inmate COVID deaths
- total_officer_cases: Total staff COVID cases
- total_officer_deaths: Total staff COVID deaths

## Deployment Scripts

### sync.sh - Universal Sync Script
Main deployment script with multiple modes:

```bash
./sync.sh                    # Full sync with backup
./sync.sh -q                 # Quick dashboard-only sync
./sync.sh -d -n              # Dashboard only, no backup
./sync.sh -f                 # Force sync without prompts
./sync.sh -h                 # Help and usage information
```

Options:
- -q, --quick: Quick sync (dashboard only)
- -d, --dashboard: Dashboard file only
- -n, --no-backup: Skip backup creation
- -f, --force: Force sync without confirmation
- -h, --help: Show help message

## Development Environment

### Source Host (Development)
- Host: osprey.darkremy
- User: raymond
- Path: /Users/raymond/covid_elections

### Target Host (Web Server)
- Host: bataleon
- User: raymond
- Path: /var/www/html/covid_elections
- Web Server: Apache/Nginx with www-data ownership

## Data Sources and Attribution

### Primary Data Source
The New York Times COVID-19 Data Repository
- License: Creative Commons Attribution-NonCommercial 4.0 International
- Repository: https://github.com/nytimes/covid-19-data
- Data collection period: January 2020 - March 2023

### State and County Data
- Source: State and local government health departments
- Collection method: Journalistic monitoring and verification
- Update frequency: Daily (archived as of March 2023)

### College Data
- Source: Survey of 1,900+ American colleges and universities
- Collection period: July 2020 - May 2021
- Scope: Four-year public institutions and NCAA-competing private colleges

### Prison Data
- Source: State/federal prison systems, ICE, local jails
- Collection method: Direct inquiries and public records requests
- Facilities covered: 2,805 facilities nationwide

### Excess Deaths Data
- Source: National and municipal health departments, vital statistics offices
- Countries covered: 32 countries
- Collection method: Official government data releases

### Mask Usage Data
- Source: Dynata survey firm
- Survey period: July 2-14, 2020
- Sample size: 250,000 responses
- Geographic level: County-level estimates

## Technical Implementation

### Frontend Architecture
- Single-page application (SPA) with multiple views
- Responsive CSS Grid and Flexbox layout
- Dark theme with blue accent colors (#1e3a8a)
- Mobile-first responsive design

### Data Loading
- Asynchronous CSV fetching with Papa Parse
- Client-side data processing and filtering
- Data caching to prevent redundant requests
- Error handling with user-friendly messages

### Chart Implementation
- Chart.js v3.9.1 with date-fns adapter
- Time series charts for temporal data
- Bar charts for categorical comparisons
- Logarithmic scaling for mixed data types
- Interactive tooltips and legends

### Cross-Data Type Comparison
- Support for comparing different data types
- Normalized visualization with appropriate scaling
- Detailed comparison tables with relevant metrics
- Data type labeling in region selection tags

## Key Changes and Improvements

### Data Loading and Processing
- Implemented real CSV data loading replacing sample data
- Added Papa Parse integration for robust CSV parsing
- Created data caching system to improve performance
- Enhanced error handling for network and parsing issues

### Sorting and Organization
- Counties sorted by state then county name
- Colleges sorted by state then institution name
- Prison facilities sorted by state then facility name
- Improved user experience with logical data organization

### Chart.js Integration
- Fixed Chart.js loading issues with proper CDN URLs
- Added chartjs-adapter-date-fns for time series support
- Implemented chart destruction to prevent canvas reuse errors
- Enhanced chart styling with dark theme compatibility

### Cross-Data Type Functionality
- Enabled comparison between different data types
- Added data type indicators in region tags
- Created mixed comparison charts with logarithmic scaling
- Implemented comprehensive comparison tables

### User Interface Enhancements
- Added cumulative vs daily view toggle for time series
- Implemented comparison table toggle functionality
- Enhanced mobile responsiveness
- Improved button states and user feedback

### Deployment Infrastructure
- Created unified sync script replacing multiple broken scripts
- Added backup functionality and permission management
- Implemented graceful error handling and verification
- Added support for different sync modes and options

## Browser Compatibility

- Modern browsers with ES6+ support
- Chrome 60+, Firefox 60+, Safari 12+, Edge 79+
- Mobile browsers on iOS 12+ and Android 7+
- Requires JavaScript enabled for full functionality

## Performance Considerations

- CSV files range from 157KB (colleges) to 100MB+ (full county data)
- Uses recent county data by default for faster loading
- Client-side processing may be slower on older devices
- Implements progressive loading of different data types

## Security and Privacy

- No user data collection or tracking
- All data processing occurs client-side
- No external API calls except for CDN resources
- Static file hosting with no server-side processing

## License and Usage

The dashboard code is provided for educational and research purposes. The underlying COVID-19 data is licensed under Creative Commons Attribution-NonCommercial 4.0 International license by The New York Times.

## Future Development Considerations

- Could implement server-side data processing for better performance
- Additional data export functionality (CSV, JSON)
- More sophisticated statistical analysis features
- Integration with other pandemic-related datasets
- API development for programmatic access
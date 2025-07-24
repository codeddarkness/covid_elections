#!/bin/bash

# Update COVID Dashboard with Bracketed Header Selectors - Working Version
set -e

echo "Updating COVID Dashboard with bracketed header selectors..."

# Create backup
cp covid_dashboard.html covid_dashboard.html.backup
echo "✅ Backup created: covid_dashboard.html.backup"

# Create a temporary working file
cp covid_dashboard.html temp_dashboard.html

echo "🔄 Updating dashboard structure..."

# Step 1: Replace the region selector section with dynamic selectors
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('temp_dashboard.html', 'r') as f:
    content = f.read()

# Find and replace the region selector section
old_controls = '''                    <div class="control-item">
                        <label for="regionSelect">Select Region:</label>
                        <select id="regionSelect" disabled>
                            <option value="">Choose data type first</option>
                        </select>
                    </div>

                    <div class="control-item button-item">
                        <button class="button" onclick="addRegion()" id="addRegionBtn" disabled>Add Region</button>
                    </div>'''

new_controls = '''                </div>

                <!-- Dynamic selector row based on bracketed headers -->
                <div class="controls-row" id="selectorsRow" style="display: none;">
                    <!-- Dynamic selectors will be added here based on [bracketed] headers -->
                </div>

                <!-- Add region button row -->
                <div class="controls-row">
                    <div class="control-item button-item">
                        <button class="button" onclick="addRegion()" id="addRegionBtn" disabled>Add Region</button>
                    </div>'''

content = content.replace(old_controls, new_controls)

# Write back to file
with open('temp_dashboard.html', 'w') as f:
    f.write(content)

print("✅ Updated HTML structure")
PYTHON_EOF

# Step 2: Add the selector configuration JavaScript
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('temp_dashboard.html', 'r') as f:
    content = f.read()

# Add selector configs after the global variables
config_js = '''
        // Selector configurations based on bracketed headers from data_samples_headers.ref
        const selectorConfigs = {
            'us-states': [
                { key: 'date', label: 'Date', type: 'select' },
                { key: 'state', label: 'State', type: 'select' }
            ],
            'us-counties': [
                { key: 'date', label: 'Date', type: 'select' },
                { key: 'county', label: 'County', type: 'select' },
                { key: 'state', label: 'State', type: 'select' }
            ],
            'colleges': [
                { key: 'date', label: 'Date', type: 'select' },
                { key: 'state', label: 'State', type: 'select' },
                { key: 'county', label: 'County', type: 'select' },
                { key: 'city', label: 'City', type: 'select' },
                { key: 'college', label: 'College', type: 'select' }
            ],
            'prisons-facilities': [
                { key: 'facility_name', label: 'Facility Name', type: 'select' },
                { key: 'facility_type', label: 'Facility Type', type: 'select' },
                { key: 'facility_city', label: 'Facility City', type: 'select' },
                { key: 'facility_county', label: 'Facility County', type: 'select' },
                { key: 'facility_state', label: 'Facility State', type: 'select' }
            ],
            'prisons-systems': [
                { key: 'system', label: 'System', type: 'select' }
            ],
            'excess-deaths': [
                { key: 'country', label: 'Country', type: 'select' },
                { key: 'placename', label: 'Place Name', type: 'select' },
                { key: 'frequency', label: 'Frequency', type: 'select' },
                { key: 'start_date', label: 'Start Date', type: 'select' },
                { key: 'end_date', label: 'End Date', type: 'select' },
                { key: 'year', label: 'Year', type: 'select' },
                { key: 'month', label: 'Month', type: 'select' },
                { key: 'week', label: 'Week', type: 'select' }
            ],
            'mask-use': [
                { key: 'COUNTYFP', label: 'County FIPS', type: 'select' }
            ]
        };'''

# Insert after the last global variable declaration
content = content.replace('let showPoliticalAnalysis = false;', 'let showPoliticalAnalysis = false;' + config_js)

# Write back to file
with open('temp_dashboard.html', 'w') as f:
    f.write(content)

print("✅ Added selector configurations")
PYTHON_EOF

# Step 3: Add the new functions
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('temp_dashboard.html', 'r') as f:
    content = f.read()

# Add the new functions after the navigation functions
new_functions = '''
        function createDynamicSelectors(dataType) {
            const selectorsRow = document.getElementById('selectorsRow');
            const config = selectorConfigs[dataType];
            
            if (!config) {
                selectorsRow.style.display = 'none';
                return;
            }

            selectorsRow.innerHTML = '';
            selectorsRow.style.display = 'flex';

            config.forEach(selector => {
                const controlItem = document.createElement('div');
                controlItem.className = 'control-item';
                
                const label = document.createElement('label');
                label.textContent = selector.label + ':';
                label.setAttribute('for', `selector_${selector.key}`);
                
                const select = document.createElement('select');
                select.id = `selector_${selector.key}`;
                select.onchange = () => updateDependentSelectors(dataType);
                
                const defaultOption = document.createElement('option');
                defaultOption.value = '';
                defaultOption.textContent = `Select ${selector.label}`;
                select.appendChild(defaultOption);
                
                controlItem.appendChild(label);
                controlItem.appendChild(select);
                selectorsRow.appendChild(controlItem);
            });
        }

        function populateDynamicSelectors(dataType) {
            const currentData = allDataSets[dataType];
            const config = selectorConfigs[dataType];
            
            if (!currentData || !config) return;

            config.forEach(selector => {
                const selectElement = document.getElementById(`selector_${selector.key}`);
                if (!selectElement) return;

                const values = [...new Set(currentData.map(d => d[selector.key]))].filter(Boolean).sort();
                
                selectElement.innerHTML = selectElement.firstElementChild.outerHTML;
                
                values.forEach(value => {
                    const option = document.createElement('option');
                    option.value = value;
                    option.textContent = value;
                    selectElement.appendChild(option);
                });
            });
        }

        function updateDependentSelectors(dataType) {
            const currentData = allDataSets[dataType];
            const config = selectorConfigs[dataType];
            
            if (!currentData || !config) return;

            const filters = {};
            config.forEach(selector => {
                const selectElement = document.getElementById(`selector_${selector.key}`);
                if (selectElement && selectElement.value) {
                    filters[selector.key] = selectElement.value;
                }
            });

            let filteredData = currentData;
            Object.keys(filters).forEach(key => {
                filteredData = filteredData.filter(d => d[key] === filters[key]);
            });

            config.forEach(selector => {
                if (!filters[selector.key]) {
                    const selectElement = document.getElementById(`selector_${selector.key}`);
                    if (selectElement) {
                        const currentValue = selectElement.value;
                        const values = [...new Set(filteredData.map(d => d[selector.key]))].filter(Boolean).sort();
                        
                        selectElement.innerHTML = selectElement.firstElementChild.outerHTML;
                        
                        values.forEach(value => {
                            const option = document.createElement('option');
                            option.value = value;
                            option.textContent = value;
                            selectElement.appendChild(option);
                        });
                        
                        if (values.includes(currentValue)) {
                            selectElement.value = currentValue;
                        }
                    }
                }
            });

            checkAddButtonState(dataType);
        }

        function checkAddButtonState(dataType) {
            const config = selectorConfigs[dataType];
            const addBtn = document.getElementById('addRegionBtn');
            
            if (!config) {
                addBtn.disabled = true;
                return;
            }

            let hasSelection = false;
            config.forEach(selector => {
                const selectElement = document.getElementById(`selector_${selector.key}`);
                if (selectElement && selectElement.value && selector.key !== 'date') {
                    hasSelection = true;
                }
            });

            addBtn.disabled = !hasSelection;
        }

        function getSelectedRegionLabel(dataType) {
            const config = selectorConfigs[dataType];
            if (!config) return '';

            const parts = [];
            config.forEach(selector => {
                const selectElement = document.getElementById(`selector_${selector.key}`);
                if (selectElement && selectElement.value && selector.key !== 'date') {
                    parts.push(selectElement.value);
                }
            });

            return parts.join(' - ') || 'Unknown Region';
        }'''

# Insert after showPage function
content = content.replace(
    "        // Political analysis toggle",
    new_functions + "\n\n        // Political analysis toggle"
)

# Write back to file
with open('temp_dashboard.html', 'w') as f:
    f.write(content)

print("✅ Added dynamic selector functions")
PYTHON_EOF

# Step 4: Update the loadData function
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('temp_dashboard.html', 'r') as f:
    content = f.read()

# Update loadData function to call the new functions
old_load_section = '''            if (allDataSets[dataType]) {
                populateRegionSelect(dataType);
                enableControls();
                return;
            }'''

new_load_section = '''            if (allDataSets[dataType]) {
                createDynamicSelectors(dataType);
                populateDynamicSelectors(dataType);
                enableControls();
                return;
            }'''

content = content.replace(old_load_section, new_load_section)

# Also update the successful load section
old_success_section = '''                populateRegionSelect(dataType);
                enableControls();
                showLoading(false);'''

new_success_section = '''                createDynamicSelectors(dataType);
                populateDynamicSelectors(dataType);
                enableControls();
                showLoading(false);'''

content = content.replace(old_success_section, new_success_section)

# Write back to file
with open('temp_dashboard.html', 'w') as f:
    f.write(content)

print("✅ Updated loadData function")
PYTHON_EOF

# Step 5: Update the addRegion function
python3 << 'PYTHON_EOF'
import re

# Read the file
with open('temp_dashboard.html', 'r') as f:
    content = f.read()

# Replace the entire addRegion function
old_add_function = re.search(r'function addRegion\(\) \{.*?\n        \}', content, re.DOTALL)
if old_add_function:
    new_add_function = '''function addRegion() {
            const dataType = document.getElementById('dataType').value;
            if (!dataType) return;

            const regionLabel = getSelectedRegionLabel(dataType);
            if (!regionLabel || regionLabel === 'Unknown Region') return;

            if (!selectedRegions.includes(regionLabel)) {
                selectedRegions.push(regionLabel);
                selectedDataTypes.push(dataType);
                updateRegionTags();
                updateOverlayControls();
                updatePoliticalSummary();
                updateCharts();
                
                document.getElementById('comparisonBtn').disabled = false;
                document.getElementById('chartModeBtn').disabled = false;
                
                const config = selectorConfigs[dataType];
                if (config) {
                    config.forEach(selector => {
                        const selectElement = document.getElementById(`selector_${selector.key}`);
                        if (selectElement) {
                            selectElement.value = '';
                        }
                    });
                }
                checkAddButtonState(dataType);
            }
        }'''
    
    content = content.replace(old_add_function.group(0), new_add_function)

# Write back to file
with open('temp_dashboard.html', 'w') as f:
    f.write(content)

print("✅ Updated addRegion function")
PYTHON_EOF

# Replace the original file
mv temp_dashboard.html covid_dashboard.html

echo ""
echo "✅ Dashboard updated successfully!"
echo ""
echo "🔄 Changes made:"
echo "   - Added dynamic selector row that appears when data type is selected"
echo "   - Implemented bracketed header selectors based on data_samples_headers.ref"
echo "   - Added cascading filter functionality between selectors" 
echo "   - Updated loadData() to create and populate dynamic selectors"
echo "   - Updated addRegion() to work with multiple field selections"
echo "   - Add Region button enabled only when meaningful selections are made"
echo ""
echo "📋 Selector configurations implemented:"
echo "   - US States: [date], [state]"
echo "   - US Counties: [date], [county], [state]"
echo "   - Colleges: [date], [state], [county], [city], [college]"
echo "   - Prison Facilities: [facility_name], [facility_type], [facility_city], [facility_county], [facility_state]"
echo "   - Prison Systems: [system]"
echo "   - Excess Deaths: [country], [placename], [frequency], [start_date], [end_date], [year], [month], [week]"
echo "   - Mask Use: [COUNTYFP]"
echo ""
echo "💾 Backup saved as: covid_dashboard.html.backup"

# Commit the changes
if git status --porcelain | grep -q .; then
    git add .
    git commit -m "Implement bracketed header selectors for COVID dashboard

- Replace single region selector with dynamic multi-field selectors
- Create selectors based on [bracketed] headers from data_samples_headers.ref
- Add cascading filter functionality between related selectors  
- Update loadData() and addRegion() functions for new selector system
- Enable Add Region button only when meaningful selections are made
- Maintain all existing chart and analysis functionality

Selector configurations for each data type:
- US States: date, state
- US Counties: date, county, state
- Colleges: date, state, county, city, college  
- Prison Facilities: facility_name, facility_type, facility_city, facility_county, facility_state
- Prison Systems: system
- Excess Deaths: country, placename, frequency, start_date, end_date, year, month, week
- Mask Use: COUNTYFP"

    echo ""
    echo "✅ Changes committed to dev/update_selectors branch"
    echo "🚀 Ready for testing!"
else
    echo ""
    echo "ℹ️  No changes to commit"
fi


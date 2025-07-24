# COVID-19 Data Analysis Dashboard with Political Integration

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live%20Demo-brightgreen)](https://codeddarkness.github.io/covid_elections/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![NYT COVID Data](https://img.shields.io/badge/Data%20Source-NYT%20COVID--19-red)](https://github.com/nytimes/covid-19-data)
[![MIT Election Lab](https://img.shields.io/badge/Election%20Data-MIT%20MEDSL-purple)](https://electionlab.mit.edu/)

> **Interactive web dashboard analyzing COVID-19 data alongside 2020 Presidential Election results to explore correlations between public health outcomes and political geography.**

## 🚀 Live Demo

**[📊 Launch Dashboard](https://codeddarkness.github.io/covid_elections/)**

### Quick Access
- **[COVID Dashboard](https://codeddarkness.github.io/covid_elections/covid_dashboard.html)** - Main analysis interface
- **[Election Dashboard](https://codeddarkness.github.io/covid_elections/election_dashboard.html)** - Election data viewer

## ✨ Key Features

- 🔗 **Political Integration**: Toggle to overlay 2020 election results with COVID data
- 📊 **Multiple Data Sources**: States, counties, colleges, prisons, mask usage surveys
- 🎯 **Interactive Charts**: Dynamic visualizations with Chart.js
- 📱 **Mobile Responsive**: Works on all devices
- 🎓 **Educational Tool**: Perfect for research and teaching

## 🎮 Quick Start

1. **[Open Dashboard](https://codeddarkness.github.io/covid_elections/)** → Select data type → Choose regions
2. **Enable "Political Analysis"** to see voting data overlay
3. **Explore patterns** between COVID outcomes and political geography

### Example Analysis
```
Swing State Study:
1. Select "US States" 
2. Add: Florida, Pennsylvania, Arizona
3. Enable political analysis
4. Compare COVID trends with 2020 voting patterns
```

## 📚 Data Sources & Attribution

### COVID-19 Data
- **Source**: [The New York Times COVID-19 Data Repository](https://github.com/nytimes/covid-19-data)
- **License**: Creative Commons Attribution-NonCommercial 4.0 International
- **Coverage**: January 2020 - March 2023
- **Quality**: Journalistically verified from official health departments

### Election Data
- **Source**: [MIT Election Data and Science Lab (MEDSL)](https://electionlab.mit.edu/)
- **Dataset**: [County Presidential Election Returns 2000-2020](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ)
- **License**: Public domain for research and educational use
- **Coverage**: 2020 Presidential Election results for all US counties

## 🛠️ Technology Stack

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Visualization**: Chart.js v3.9.1 for interactive charts
- **Data Processing**: Papa Parse v5.4.1 for CSV handling
- **Hosting**: GitHub Pages (free static hosting)
- **Architecture**: Client-side only, no server required

## 📖 Research Applications

### Academic Use Cases
- **Political Science**: Voting behavior and public health compliance
- **Public Health**: Policy effectiveness across political contexts
- **Geography**: Spatial analysis of pandemic impacts
- **Statistics**: Real-world correlation vs causation examples

### Educational Applications
- University courses in political science, public health, statistics
- High school AP classes in government and current events
- Data literacy and visualization training
- Critical thinking about data interpretation

## 🔧 Local Development

```bash
# Clone and run locally
git clone https://github.com/codeddarkness/covid_elections.git
cd covid_elections

# Serve with any static server
python -m http.server 8000
# or: npx serve .

# Open http://localhost:8000
```

## 📄 License & Attribution

### Software License
MIT License - see [LICENSE](LICENSE) for details

### Data Attribution
- **COVID-19 Data**: © 2020-2023 The New York Times Company (CC BY-NC 4.0)
- **Election Data**: MIT Election Data and Science Lab (Public Domain)

### Citation
```
COVID-19 Data Analysis Dashboard with Political Integration (2025)
Repository: https://github.com/codeddarkness/covid_elections
Data Sources: NYT COVID-19 Repository, MIT Election Lab
```

## ⚠️ Important Notes

- **Correlation ≠ Causation**: Patterns may reflect confounding variables
- **Educational Purpose**: For learning and research, not policy recommendations
- **Data Limitations**: Temporal mismatch between election (Nov 2020) and COVID data (2020-2023)

## 🤝 Support

- **Issues**: [Report bugs](https://github.com/codeddarkness/covid_elections/issues)
- **Discussions**: [Ask questions](https://github.com/codeddarkness/covid_elections/discussions)

---

*Explore the intersection of public health and political geography responsibly.*

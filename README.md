# Patrick Norton - Data Science Portfolio

A collection of data science and analytics projects showcasing skills in Python, R, data wrangling, statistical analysis, machine learning, and visualization.

## Projects

### Ware Spending Analysis (`ware-analysis/`)
**Language:** Python (pandas, matplotlib, seaborn, numpy)

Audit and investigation of employee Ware's purchasing activity, including:
- Merging and standardizing order data from multiple CSV sources
- Address cleaning and normalization using regex
- Spending analysis with 8 professional visualizations (monthly trends, category breakdowns, order size distributions, shipping address analysis)
- Summary statistics and large-order identification for management reporting

### PARCA Donor Analysis (`parca-donor-analysis/`)
**Language:** R (tidyverse, ggplot2, tidymodels, xgboost, forecast, lubridate)

Nonprofit donor geographic and time series analysis for PARCA, including:
- State and city-level donor distribution analysis with 3D pie charts and faceted bar plots
- High financial score donor identification by geography
- Time series forecasting of monthly donor acquisition using XGBoost and ARIMA/ETS models
- 12-month donor prediction by state with heatmap and bar chart visualizations
- State name standardization and non-U.S. location filtering

### Dos Pueblos Grade Analysis (`dos-pueblos-grade-analysis/`)
**Language:** R (tidyverse, dplyr, ggplot2)

Statistical analysis of grade distributions at Dos Pueblos High School, including:
- Grade categorization and department-level analysis
- Visualization of grade shares by department
- Computer Science grade trends over time (2009-2022)
- Cross-departmental grade trend comparisons

### New York Student Debt Analysis (`new-york-student-debt/`)
**Language:** R (tidyverse)

Analysis of student debt and college costs using federal education data, including:
- CPI-adjusted (real dollar) debt and cost calculations
- Comparison across income levels (low, median, high income)
- Public vs. private institution analysis
- Merging education, cost, and CPI datasets for comprehensive analysis

### Boulder Project (`boulder-project/`)
Boulder-area data analysis project (PDF report).

### R Markdown Exercise (`r-markdown-exercise/`)
Demonstration of R Markdown for reproducible document generation (PDF report).

## Repository Structure

```
.
├── README.md
├── ware-analysis/
│   └── WareAnalysis.py
├── parca-donor-analysis/
│   ├── CopyOfPARCADonorScript.R
│   └── PARCAinsight.pdf
├── dos-pueblos-grade-analysis/
│   ├── DosPueblos.R
│   └── DosPueblos_modified.pdf
├── new-york-student-debt/
│   ├── NewYorkStuDebt.R
│   └── NewYorkAnalysis.pdf
├── boulder-project/
│   └── BoulderProject.pdf
└── r-markdown-exercise/
    └── RMarkdownExercise.pdf
```

## Tools & Technologies
- **Python:** pandas, matplotlib, seaborn, numpy
- **R:** tidyverse, dplyr, ggplot2, tidymodels, xgboost, forecast, lubridate, modeltime
- **Skills:** Data wrangling, statistical analysis, data visualization, time series forecasting, machine learning, exploratory data analysis

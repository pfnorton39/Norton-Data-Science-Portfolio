library(tidyverse)
library(ggplot2)
library(scales)
library(shadowtext)  
library(reshape2) 
library(plotrix)
library(lubridate)
library(forecast)
library(timetk)
library(tidymodels)
library(modeltime)

# Read the data
donors <- read.csv("PARCADonors.csv", stringsAsFactors = FALSE)

### Pie Chart Info ### 


# Clean and create state distribution
state_distribution <- donors %>%
  filter(!is.na(State) & State != "") %>%
  filter(!is.na(City) & City != "") %>%
  count(State, name = "donor_count") %>%
  mutate(percentage = donor_count / sum(donor_count) * 100) %>%
  arrange(desc(donor_count)) %>%
  mutate(State = if_else(row_number() <= 5, State, "Other")) %>%
  group_by(State) %>%
  summarise(
    donor_count = sum(donor_count),
    percentage = sum(percentage)
  ) %>%
  ungroup() %>%
  # Ensure "Other" is at the bottom
  mutate(State = factor(State, levels = c(State[State != "Other"], "Other"))) %>%
  arrange(desc(percentage))
  
state_distribution_pie <- donors %>%
  filter(!is.na(State) & State != "") %>%
  mutate(State = if_else(State == "CA", "California", "Other States")) %>%
  count(State, name = "donor_count") %>%
  mutate(percentage = donor_count / sum(donor_count) * 100) %>%
  arrange(desc(percentage))

# Convert to tibble for visualization
pie_data_pie <- state_distribution_pie %>%
  mutate(label = paste0(State, "\n", round(percentage, 1), "%"))


# Ensure colors are correctly assigned
colors <- rainbow(nrow(pie_data_pie))  

# Create 3D Pie Chart with improved view
pie3D(pie_data_pie$percentage,
      labels = pie_data_pie$label,
      explode = 0.07,  # Increased to spread slices more
      main = "Distribution of Donors by State",
      labelcex = 1,
      radius = .87,  # Increase size for better visibility
      theta = 1.6,  # More top-down view
      col = colors)




### Cities Info ### 



# Top cities in each top 5 state
top_5_states <- state_distribution %>%
  filter(State != "Other") %>%
  pull(State)

city_by_state <- donors %>%
  filter(State %in% top_5_states) %>%
  filter(!is.na(City) & City != "") %>%
  group_by(State, City) %>%
  summarise(donor_count = n(), .groups = 'drop') %>%
  group_by(State) %>%
  arrange(desc(donor_count)) %>%
  slice_head(n = 5)

# Create bar plot for each state's top cities
city_plot <- ggplot(city_by_state, 
                    aes(x = reorder(City, donor_count), 
                        y = donor_count, 
                        fill = State)) +
  geom_bar(stat = "identity") +
  facet_wrap(~State, scales = "free_y") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Top 5 Cities in Each State",
       x = "City",
       y = "Number of Donors") +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
        axis.text.y = element_text(size = 8))

# Save the plot
ggsave("cities_by_state.png", city_plot, width = 12, height = 8)

# High financial score cities
high_score_cities <- donors %>%
  filter(!is.na(Financial.Score) & Financial.Score > 89) %>%
  filter(!is.na(City) & City != "") %>%
  group_by(City, State) %>%
  summarise(donor_count = n(), .groups = 'drop') %>%
  arrange(desc(donor_count)) %>%
  slice_head(n = 10)

# Create bar plot for high score cities
high_score_plot <- ggplot(high_score_cities,
                          aes(x = reorder(paste(City, State, sep = ", "), 
                                          donor_count),
                              y = donor_count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Cities with Most High Financial Score Donors (Score > 89)",
       x = "City",
       y = "Number of Donors") +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold"))

# Save the plot
ggsave("high_score_cities.png", high_score_plot, width = 12, height = 8)

# Print summary statistics
print("Summary of donor distribution by state:")
print(state_distribution)

print("\nTop cities in each state:")
print(city_by_state)

print("\nCities with most high financial score donors:")
print(high_score_cities)






### Time Series Analysis ###
donors <- donors %>%
  mutate(create_date = mdy(Create.Date)) %>%
  filter(!is.na(create_date) & create_date >= as.Date("2023-10-01"))

# Aggregate donations by month
donor_ts <- donors %>%
  count(month = floor_date(create_date, "month")) %>%
  complete(month = seq.Date(min(month), max(month), by = "month"), fill = list(n = 0))

# Convert "month" to numeric representation (e.g., number of days since start)
donor_ts <- donor_ts %>%
  mutate(month_num = as.numeric(month))

# Split data into training and testing sets
splits <- initial_time_split(donor_ts, prop = 0.8)

# Define Recipe
recipe_spec <- recipe(n ~ month_num, data = training(splits)) %>%
  step_normalize(all_numeric_predictors())

# Model Specification (XGBoost for forecasting)
model_spec <- boost_tree(mode = "regression", trees = 500, min_n = 5) %>%
  set_engine("xgboost")

# Create Workflow
workflow_spec <- workflow() %>%
  add_model(model_spec) %>%
  add_recipe(recipe_spec)

# Train the Model
model_fit <- workflow_spec %>%
  fit(training(splits))

# Forecast for the next 12 months
future_dates <- tibble(month = seq.Date(max(donor_ts$month) + months(1),
                                        max(donor_ts$month) + months(12), by = "month")) %>%
  mutate(month_num = as.numeric(month))

predictions <- predict(model_fit, new_data = future_dates) %>%
  bind_cols(future_dates)


# Plot Forecast
ggplot() +
  geom_line(data = donor_ts, aes(x = month, y = n), color = "blue") +
  geom_line(data = predictions, aes(x = month, y = .pred), color = "red", linetype = "dashed") +
  scale_y_continuous(breaks = seq(1, 20, by = 1)) +  # Ensures y-axis labels from 1 to 20
  scale_x_date(date_breaks = "2 months", date_labels = "%m-%Y") +  # X-axis labels every 3 months
  labs(title = "Monthly Donation Forecast (From Oct 2023)", x = "Date", y = "Number of Donations") +
  theme_minimal()






# Prepare time series data
donor_ts <- donors %>%
  mutate(create_date = mdy(Create.Date)) %>%
  filter(!is.na(create_date)) %>%
  count(month = floor_date(create_date, "month")) %>%
  complete(month = seq.Date(min(month), max(month), by = "month"), fill = list(n = 0))

# Get the first month where data starts
start_month <- min(donor_ts$month[donor_ts$n > 0], na.rm = TRUE)

# Visualize
donor_ts %>%
  filter(month >= start_month) %>%  # Start visualization from first non-zero month
  plot_time_series(month, n, .interactive = FALSE,
                   .title = "Monthly Donor Acquisition Trend") +
  scale_y_continuous(limits = c(1, 10), breaks = 1:10) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +  # Every other month
  labs(y = "# of donors added", x = "Month") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Create time series model
donor_ts_model <- donor_ts %>%
  model(
    ARIMA = ARIMA(n),
    ETS = ETS(n)
  )

# Generate forecasts
donor_forecast <- donor_ts_model %>%
  forecast(h = 12) %>%
  hilo(level = 95)

# Plot forecast
donor_forecast %>%
  autoplot(donor_ts) +
  scale_y_continuous(limits = c(1, 10), breaks = 1:10) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +  # Every other month
  labs(title = "12-Month Donor Acquisition Forecast", y = "# of donors added", x = "Month") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))







# Convert create_date
donors <- donors %>%
  mutate(create_date = mdy(Create.Date)) %>%
  filter(!is.na(create_date))

# Aggregate donations by state and month
state_donor_ts <- donors %>%
  count(State, month = floor_date(create_date, "month")) %>%
  complete(State, month = seq.Date(min(month), max(month), by = "month"), fill = list(n = 0))

# Convert "month" to numeric representation
state_donor_ts <- state_donor_ts %>%
  mutate(month_num = as.numeric(month))

# Split data into training and testing
splits <- initial_time_split(state_donor_ts, prop = 0.8)

# Define Recipe
recipe_spec <- recipe(n ~ month_num + State, data = training(splits)) %>%
  step_dummy(all_nominal_predictors()) %>% # Convert State to dummy variables
  step_normalize(all_numeric_predictors())

# Model Specification (XGBoost for forecasting)
model_spec <- boost_tree(mode = "regression", trees = 500, min_n = 5) %>%
  set_engine("xgboost")

# Create Workflow
workflow_spec <- workflow() %>%
  add_model(model_spec) %>%
  add_recipe(recipe_spec)

# Train the Model
model_fit <- workflow_spec %>%
  fit(training(splits))

# Forecast for 2025
future_dates <- expand.grid(
  month = seq.Date(as.Date("2025-01-01"), as.Date("2025-12-01"), by = "month"),
  State = unique(state_donor_ts$State)
) %>%
  mutate(month_num = as.numeric(month))

# Make Predictions
predictions <- predict(model_fit, new_data = future_dates) %>%
  bind_cols(future_dates)

# Visualization: Heatmap of Donor Predictions by State
ggplot(predictions, aes(x = month, y = State, fill = .pred)) +
  geom_tile() +
  scale_fill_gradient(low = "lightblue", high = "darkred") +
  labs(title = "Predicted Donors by State for 2025", x = "Month", y = "State", fill = "Predicted Donors") +
  theme_minimal()

# Alternative: Bar Chart of Total Donors Per State in 2025
predictions %>%
  group_by(State) %>%
  summarise(total_donors = sum(.pred)) %>%
  ggplot(aes(x = reorder(State, -total_donors), y = total_donors, fill = State)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Total Predicted Donors by State (2025)", x = "State", y = "Total Donors") +
  theme_minimal()



### Donor Location Prediction ###
# Load required libraries
library(tidyverse)
library(lubridate)
library(tidymodels)
library(modeltime)
library(xgboost)
library(ggplot2)
library(scales)

donors <- donors %>%
  mutate(create_date = mdy(Create.Date)) %>%
  filter(!is.na(create_date))

# **Fix inconsistent state names**
# Standardizing common variations (e.g., "CA", "Ca", "California" → "CA")
state_corrections <- c("California" = "CA", "Ca" = "CA", "ca" = "CA",
                       "Connecticut" = "CT", "Ct" = "CT", "ct" = "CT",
                       "North Carolina" = "NC")

non_us_states <- c("British Columbia", "BC", "Vic", "Oxon", "Unknown", "N/A", "")

# **Apply corrections and remove non-U.S. locations**
donors <- donors %>%
  mutate(State = recode(State, !!!state_corrections)) %>%
  filter(!State %in% non_us_states)  

# Aggregate donations by state and month
state_donor_ts <- donors %>%
  count(State, month = floor_date(create_date, "month")) %>%
  complete(State, month = seq.Date(min(month), max(month), by = "month"), fill = list(n = 0))

# Convert "month" to numeric representation
state_donor_ts <- state_donor_ts %>%
  mutate(month_num = as.numeric(month))

# Split data into training and testing sets
splits <- initial_time_split(state_donor_ts, prop = 0.8)

# Define Recipe
recipe_spec <- recipe(n ~ month_num + State, data = training(splits)) %>%
  step_dummy(all_nominal_predictors()) %>%  # Convert State to dummy variables
  step_normalize(all_numeric_predictors())

# Model Specification (XGBoost for forecasting)
model_spec <- boost_tree(mode = "regression", trees = 500, min_n = 5) %>%
  set_engine("xgboost")

# Create Workflow
workflow_spec <- workflow() %>%
  add_model(model_spec) %>%
  add_recipe(recipe_spec)

# Train the Model
model_fit <- workflow_spec %>%
  fit(training(splits))

# Forecast for 2025 (New Donors by Month & Area)
future_dates <- expand.grid(
  month = seq.Date(as.Date("2025-01-01"), as.Date("2025-12-01"), by = "month"),
  State = unique(state_donor_ts$State)
) %>%
  mutate(month_num = as.numeric(month))

# Make Predictions
predictions <- predict(model_fit, new_data = future_dates) %>%
  bind_cols(future_dates) %>%
  rename(predicted_donors = .pred)

# **Fix: Ensure at least 5 states are included & remove negative values**
top_states <- predictions %>%
  group_by(State) %>%
  summarise(total_donors = sum(predicted_donors)) %>%
  filter(total_donors > 0) %>%  # **Only keep states with positive donor counts**
  arrange(desc(total_donors)) %>%
  slice_head(n = 5) %>%  # Guarantees top 5 states
  pull(State)

# **Fix: Remove "Other" category entirely if negative or meaningless**
predictions <- predictions %>%
  mutate(State = as.character(State)) %>%  # Ensure State is not a factor
  filter(State %in% top_states)  # **Only keep states in the top 5, remove "Other"**

# **Fix: Use dynamic color assignment for legend**
ggplot(predictions, aes(x = month, y = predicted_donors, fill = State)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_viridis_d() +  # Automatically assigns distinct colors
  labs(title = "Predicted New Donors by State (2025)",
       x = "Month",
       y = "Predicted Donors",
       fill = "State") +
  scale_x_date(date_labels = "%b %Y", breaks = "2 months") +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))








donors <- donors %>%
  mutate(create_date = mdy(Create.Date)) %>%
  filter(!is.na(create_date))

# **Fix inconsistent state names**
state_corrections <- c("California" = "CA", "Ca" = "CA", "ca" = "CA",
                       "Connecticut" = "CT", "Ct" = "CT", "ct" = "CT",
                       "North Carolina" = "NC", "nc" = "NC", "Nc" = "NC")

# **List of non-U.S. locations to remove**
non_us_states <- c("British Columbia", "BC", "Vic", "Oxon", "Unknown", "N/A", "JPN", "")

# **Apply corrections and remove non-U.S. locations**
donors <- donors %>%
  mutate(State = recode(State, !!!state_corrections)) %>%
  filter(!State %in% non_us_states)

# Aggregate donations by state and month
state_donor_ts <- donors %>%
  count(State, month = floor_date(create_date, "month")) %>%
  complete(State, month = seq.Date(min(month), max(month), by = "month"), fill = list(n = 0))

# Convert "month" to numeric representation
state_donor_ts <- state_donor_ts %>%
  mutate(month_num = as.numeric(month))

# Split data into training and testing
splits <- initial_time_split(state_donor_ts, prop = 0.8)

# Define Recipe
recipe_spec <- recipe(n ~ month_num + State, data = training(splits)) %>%
  step_dummy(all_nominal_predictors()) %>%  # Convert State to dummy variables
  step_normalize(all_numeric_predictors())

# Model Specification (XGBoost for forecasting)
model_spec <- boost_tree(mode = "regression", trees = 500, min_n = 5) %>%
  set_engine("xgboost")

# Create Workflow
workflow_spec <- workflow() %>%
  add_model(model_spec) %>%
  add_recipe(recipe_spec)

# Train the Model
model_fit <- workflow_spec %>%
  fit(training(splits))

# Forecast for 2025
future_dates <- expand.grid(
  month = seq.Date(as.Date("2025-01-01"), as.Date("2025-12-01"), by = "month"),
  State = unique(state_donor_ts$State)
) %>%
  mutate(month_num = as.numeric(month))

# Make Predictions
predictions <- predict(model_fit, new_data = future_dates) %>%
  bind_cols(future_dates) %>%
  rename(predicted_donors = .pred) %>%
  filter(predicted_donors >= 0)  # **Ensures no negative donor values**

# **Ensure correct aggregation of predictions**
state_predictions <- predictions %>%
  group_by(State) %>%
  summarise(total_donors = sum(predicted_donors, na.rm = TRUE)) %>%  # **Ensure summing is correct**
  arrange(desc(total_donors))

# **Visualization: Corrected Bar Chart**
ggplot(state_predictions, aes(x = reorder(State, -total_donors), y = total_donors, fill = State)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_viridis_d() +  # **Distinct, readable colors**
  scale_y_continuous(limits = c(0, max(state_predictions$total_donors) + 5), 
                     breaks = seq(0, max(state_predictions$total_donors) + 5, by = 2)) +  # **Adaptive axis limits**
  labs(title = "Total Predicted Donors by State (2025)", 
       x = "State", 
       y = "Total Predicted Donors") +
  theme_minimal(base_size = 14)  # **Increased text size for readability**


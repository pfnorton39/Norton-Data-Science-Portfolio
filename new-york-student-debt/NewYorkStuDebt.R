# Patrick Norton
# New York Debt Project
# February 15, 2024

rm(list=ls()) # clear the environment
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
library(tidyverse)
#------ Uploading PERMID --------------------------------#
PERMID <- "4149092" #Type your PERMID with the quotation marks
PERMID <- as.numeric(gsub("\\D", "", PERMID)) #Don't touch
set.seed(PERMID) #Don't touch

# Part 1 

# 1
cpi_data <- read_csv("CPI_U_minneapolis_fed.csv") %>%
  select(year, CPI)

# 2
education_data_unclean <- read_csv("education_data.csv") 
education_data <- education_data_unclean %>%
  rename(year = 'YEAR') %>%
  rename(
    school_id = 'UNITID',
    school_name = 'INSTNM',
    state_id = 'STABBR',
    predominant_degree = 'PREDDEG',
    institution_type = 'CONTROL',
    median_debt_low_income = 'LO_INC_DEBT_MDN',
    median_debt_med_income = 'MD_INC_DEBT_MDN',
    median_debt_high_income = 'HI_INC_DEBT_MDN',
    default_rate = 'CDR3',
    avg_family_income = 'FAMINC') %>%
  mutate(school_name = tolower(school_name)) %>%
  mutate(
    median_debt_low_income = as.numeric(median_debt_low_income),
    median_debt_med_income = as.numeric(median_debt_med_income),
    median_debt_high_income = as.numeric(median_debt_high_income),
    default_rate = as.numeric(default_rate),
    avg_family_income = as.numeric(avg_family_income)
  )

# 3
education_data_clean <- education_data %>%
  mutate(institution_type = ifelse(institution_type == 1, "public", "private"))

# 4 
education_data_BA1 <- education_data_clean %>%
  filter(predominant_degree == 3)

# 5
education_data_BA <- left_join(education_data_BA1, cpi_data, by = "year")


education_data_BA$real_debt_low_income <- education_data_BA$median_debt_low_income * (251.1 / education_data_BA$CPI)
education_data_BA$real_debt_med_income <- education_data_BA$median_debt_med_income * (251.1 / education_data_BA$CPI)
education_data_BA$real_debt_high_income <- education_data_BA$median_debt_high_income * (251.1 / education_data_BA$CPI)
education_data_BA$real_family_income <- education_data_BA$avg_family_income * (251.1 / education_data_BA$CPI)

education_data_BA <- education_data_BA %>%
  select(-median_debt_low_income, -median_debt_med_income, -median_debt_high_income, -avg_family_income, -CPI)

col_order <- c(2,3,1,4:length(education_data_BA))

education_data_BA <- education_data_BA[, col_order]

# Part 2

# 1 
cost_data1 <- read_csv("cost_data.csv") %>%
  select(UNITID , INSTNM, YEAR , NPT41_PUB, NPT43_PUB, NPT45_PUB, NPT41_PRIV, NPT43_PRIV, NPT45_PRIV)

# 2 
data_description <- read_csv("data_description.csv")

cost_data2 <- cost_data1 %>%
  rename(year = YEAR) %>%
  rename(
    school_id = 'UNITID',
    school_name = 'INSTNM',
    mean_cost_low_income_public = 'NPT41_PUB',
    mean_cost_med_income_public = 'NPT43_PUB',
    mean_cost_high_income_public ='NPT45_PUB',
    mean_cost_low_income_private = 'NPT41_PRIV',
    mean_cost_med_income_private = 'NPT43_PRIV',
    mean_cost_high_income_private = 'NPT45_PRIV') %>%
  mutate(school_name = tolower(school_name)) %>%
  mutate(
    mean_cost_low_income_public = as.numeric(mean_cost_low_income_public),
    mean_cost_med_income_public = as.numeric(mean_cost_med_income_public),
    mean_cost_high_income_public = as.numeric(mean_cost_high_income_public),
    mean_cost_low_income_private = as.numeric(mean_cost_low_income_private),
    mean_cost_med_income_private = as.numeric(mean_cost_med_income_private),
    mean_cost_high_income_private = as.numeric(mean_cost_high_income_private))

# 3 
cost_data3 <- cost_data2 %>%
  mutate(mean_cost_low_income = coalesce(mean_cost_low_income_public, mean_cost_low_income_private),
         mean_cost_med_income = coalesce(mean_cost_med_income_public, mean_cost_med_income_private),
         mean_cost_high_income = coalesce(mean_cost_high_income_public, mean_cost_high_income_private)) %>%
  select(-mean_cost_low_income_public, -mean_cost_med_income_public, -mean_cost_high_income_public, -mean_cost_low_income_private, -mean_cost_med_income_private, -mean_cost_high_income_private)


# 4 
cost_data4 <- left_join(cost_data3, cpi_data, by = "year")

cost_data4 <- cost_data4 %>%
  mutate(real_cost_low_income = mean_cost_low_income * (251.1 / CPI),
         real_cost_med_income = mean_cost_med_income * (251.1 / CPI),
         real_cost_high_income = mean_cost_high_income * (251.1 / CPI))
# 5
cost_data <- cost_data4 %>%
  select(-c(mean_cost_low_income,mean_cost_med_income,mean_cost_high_income,CPI))
cost_data

# Part 3  

# 1
education_data_BA_cost <- left_join(education_data_BA, cost_data, by = c("year", "school_id")) %>%
  select(-c(school_name.y))

# 2 
debt_cost_sumstat_year <- education_data_BA_cost %>%
  group_by(year,institution_type) %>%
  summarise(mean_debt_for_low_income = mean(real_debt_low_income, na.rm = TRUE),
            mean_debt_for_median_income = mean(real_debt_med_income, na.rm = TRUE),
            mean_debt_for_high_income = mean(real_debt_high_income, na.rm = TRUE),
            mean_cost_for_low_income = mean(real_cost_low_income, na.rm = TRUE),
            mean_cost_for_median_income = mean(real_cost_med_income, na.rm = TRUE),
            mean_cost_for_high_income = mean(real_cost_high_income, na.rm = TRUE)) %>%
  ungroup()

# 3 
debt_long <- debt_cost_sumstat_year %>%
  select(-c(6:8)) %>%
  pivot_longer(cols = c(3:5), names_to = c("income_category"), values_to = c("debt") ) %>%
  mutate(income_category = case_when(
    str_detect(income_category, "low_income") ~ "low income",
    str_detect(income_category, "median_income") ~ "median income",
    str_detect(income_category, "high_income") ~ "high income"))

cost_long <- debt_cost_sumstat_year %>%
  pivot_longer(cols = c(6:8), names_to = c("income_category"), values_to = c("cost") ) %>%
  select(-c(3:5)) %>%
  mutate(income_category = case_when(
    str_detect(income_category, "low_income") ~ "low income",
    str_detect(income_category, "median_income") ~ "median income",
    str_detect(income_category, "high_income") ~ "high income"))

debt_cost_data_by_year  <- inner_join(debt_long, cost_long, by=c('year','institution_type', 'income_category')) 

# 4a
debt_sumstat_school_type <- education_data_BA_cost %>%
  group_by(institution_type) %>%
  summarise(mean_debt_for_low_income = mean(real_debt_low_income, na.rm = TRUE),
            mean_debt_for_median_income = mean(real_debt_med_income, na.rm = TRUE),
            mean_debt_for_high_income = mean(real_debt_high_income, na.rm = TRUE),
            mean_family_income = mean(real_family_income, na.rm = TRUE)) %>%
  mutate(mean_family_income) %>%
  ungroup()

# 4b
debt_sumstat_year <- education_data_BA_cost %>%
  group_by(year) %>%
  summarise(mean_debt_for_low_income = mean(real_debt_low_income, na.rm = TRUE),
            mean_debt_for_median_income = mean(real_debt_med_income, na.rm = TRUE),
            mean_debt_for_high_income = mean(real_debt_high_income, na.rm = TRUE),
            mean_family_income = mean(real_family_income, na.rm = TRUE)) %>%
  mutate(mean_family_income) %>%
  ungroup()

# 4c
cost_sumstat_school_type <- education_data_BA_cost %>%
  group_by(institution_type) %>%
  summarise(mean_cost_for_low_income = mean(real_cost_low_income, na.rm = TRUE),
            mean_cost_for_median_income = mean(real_cost_med_income, na.rm = TRUE),
            mean_cost_for_high_income = mean(real_cost_high_income, na.rm = TRUE)) %>%
  ungroup()

# 4d
cost_sumstat_year <- education_data_BA_cost %>%
  group_by(year) %>%
  summarise(mean_cost_for_low_income = mean(real_cost_low_income, na.rm = TRUE),
            mean_cost_for_median_income = mean(real_cost_med_income, na.rm = TRUE),
            mean_cost_for_high_income = mean(real_cost_high_income, na.rm = TRUE)) %>%
  ungroup()


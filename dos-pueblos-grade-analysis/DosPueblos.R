# Patrick Norton
# January 24 2023
# Dos Pueblos

rm(list=ls()) # clear the environment
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
#-------Import necessary packages here-------------------#
library(tidyverse)
library(dplyr)
#------ Uploading PERMID --------------------------------#
PERMID <- "4149092" #Type your PERMID with the quotation marks
PERMID <- as.numeric(gsub("\\D", "", PERMID)) #Don't touch
set.seed(PERMID) #Don't touch
#------- Answers ----------------------------------------#

# Question 1 
grades <- read_csv("my_local_HS_grades.csv")

my_local_HS_grades <- tibble(grades)
my_local_HS_grades <- my_local_HS_grades %>%
  mutate(grade_cat = case_when(
    grepl("^A", grade_given) ~ "A",
    grepl("^B", grade_given) ~ "B",
    grepl("^C", grade_given) ~ "C",
    grepl("^D", grade_given) ~ "D",
    grepl("^F", grade_given) ~ "F",
    TRUE ~ "Other"))

# Question 2 

overall_grade_share <- my_local_HS_grades %>%
  group_by(dept, grade_cat) %>%
  summarize(total_people = sum(sum_of_student_count)) %>%
  group_by(dept) %>%
  mutate(share = (total_people / sum(total_people)) * 100)

# Question 3

overall_grade_share %>%
  ggplot(aes(x = dept, y = share, fill = grade_cat)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme(panel.background = element_rect(fill = "white"))
overall_grade_share_plot <- overall_grade_share

# Question 4
Q4grade <- my_local_HS_grades %>%
  mutate(year = as.numeric(paste0("20", substr(quarter, start = 2, stop = 3))))
compsci_grades <- Q4grade %>%
  filter(dept == "CMPSC")
yearly_totals <- compsci_grades %>%
  group_by(year) %>%
  summarize(yearly_total = sum(sum_of_student_count))
all_combinations <- expand.grid(year = 2009:2022, grade_cat = unique(compsci_grades$grade_cat))
compsci_grade_over_time <- compsci_grades %>%
  group_by(year, grade_cat) %>%
  summarize(total_people = sum(sum_of_student_count)) %>%
  mutate(share = 100 * total_people / sum(total_people)) %>%
  mutate(year = as.numeric(year))
  
# Question 5
compsci_grade_over_time_plot <- compsci_grade_over_time %>%
   ggplot(aes(year, share, color = grade_cat)) +
   geom_line() +
   xlab("year") + ylab("share") 


# Question 6 
   all_courses_set_up <- my_local_HS_grades %>%
   mutate(year = as.numeric(paste0("20", substr(quarter, start = 2, stop = 3)))) %>%
   group_by(year,dept,grade_cat) %>%
   summarize(total_people = sum(sum_of_student_count)) %>%
   group_by(dept, year) %>%
   mutate(share = 100 * total_people / sum(total_people))
 all_courses_grade_over_time <- all_courses_set_up %>%
   group_by(year, dept)
   
 
 # Question 7 
 all_courses_grade_over_time %>%
   ggplot(aes(year, share, color = grade_cat)) +
   geom_line() +
   xlab("year") + ylab("share") +
   facet_wrap(vars(dept))
 all_courses_grade_over_time_plot <- all_courses_grade_over_time

   

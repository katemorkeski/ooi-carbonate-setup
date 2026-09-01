#load required packages 
library(tidyverse) 
library(httr)
library(readxl)
library(here)
library(janitor)

#set path to root of project
here("ooi-carbonate-setup")

## Access OOI data 

# read in URLs and get data files

# Papa 8 Sampling Log Version 1-00
log_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Station_Papa/Station_Papa-08_SKQ202111S_2021-07-18/Water_Sampling/Station_Papa-08_SKQ202111S_CTD_Sampling_Log_2021-08-25_Ver_1-00.xlsx')

# Papa 8 salinity data Version 1-00
sal_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Station_Papa/Station_Papa-08_SKQ202111S_2021-07-18/Water_Sampling/Station_Papa-08_SKQ202111S_Salinity_Sample_Data_2021-08-25_Ver_1-00.xlsx')

httr::GET(log_url, write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

httr::GET(sal_url, write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf

# assign files to data frames
log <- read_excel(logtf, 1L) 
sal <- read_excel(saltf, 1L) 

# count DICTA and pH bottles
n_distinct(log$`DIC/TA Bottle #`, na.rm = TRUE)
n_distinct(log$`pH Bottle #`, na.rm = TRUE)

log <- clean_names(log)

# format cruise ID and column headers
bottles <- log %>%
  rename(station = station_cast_number) %>%
  rename(niskin = niskin_number) %>%
  rename(PH_bottle = p_h_bottle_number) %>%
  rename(DICTA_bottle = dic_ta_bottle_number) %>%
  rename(salt_bottle = salts_bottle_number) |>
  rename(depth = trip_depth_m)

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)

headers <- c("cruise_id", "date", "station", "niskin", "depth", "PH_bottle", "DICTA_bottle", "salt_bottle")
bottles <- bottles[, headers]

sal <- sal %>%
  rename(station = "Station ID") %>%
  rename(niskin = "Niskin ID") %>%
  rename(salt_bottle = "Sample ID") %>%
  rename(salinity_psu = "Salinity [psu]")

sal$station <- as.numeric(sal$station)
sal$niskin <- as.numeric(sal$niskin)

# isolate carbonate rows
# check number of bottles
# match salinity to cruise log
bottles <- filter(bottles, PH_bottle != "NA" | DICTA_bottle != "NA")

n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)

bottles_sal <- left_join(bottles, sal, c("station", "niskin", "salt_bottle"))

# clean up salinity dataframe and write to csv
bottles_sal$salinity_psu <- as.numeric(bottles_sal$salinity_psu)

bottles_sal <- bottles_sal %>%
  mutate(salinity_psu = round(salinity_psu, 4))

headers <- c("cruise_id", "date", "station", "niskin", "depth", "PH_bottle", "DICTA_bottle","salt_bottle","salinity_psu")
bottles_sal <- bottles_sal[, headers]

write_csv(bottles_sal, "Papa_08_carbonate_bottle_salinity.csv")

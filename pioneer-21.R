## Access OOI data from OOI Raw Data Repository

# read in libraries
library(httr)
library(readxl)
library(tidyverse)


# read in leg A URLs and get data files  (-->  new repository)

# Sampling Log Leg A Version 1-00  
log_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Pioneer-MAB/Pioneer-21_AR87_2025-03-28/Water_Sampling/Pioneer-21_AR87A_CTD_Sampling_Log_2025-05-14_Ver_1-00.xlsx')

# salinity data Leg A Version 1-00   --> salinity data not uploaded yet
sal_url <- ('')



httr::GET(log_url, write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

#httr::GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))
httr::GET(sal_url, write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf

# assign leg A files to data frames
logA <- read_excel(logtf, 1L) 
salA <- read_excel(saltf, 1L) 



# read in leg B URLs and get data files

# Sampling Log Leg B Version 1-01  
log_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Pioneer-MAB/Pioneer-21_AR87_2025-03-28/Water_Sampling/Pioneer-21_AR87B_CTD_Sampling_Log_2025-05-19_Ver_1-00.xlsx')

# salinity data Leg B Version 1-00   --> salinity data not uploaded yet
sal_url <- ('')


#### Remember to increment cruise number for csv at end of script ####

#httr::GET(log_url, authenticate(creds, creds), write_disk(logtf <- tempfile(fileext = ".xlsx")))
httr::GET(log_url, write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

#httr::GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))
httr::GET(sal_url, write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf

# assign leg B files to data frames
logB <- read_excel(logtf, 1L) 
salB <- read_excel(saltf, 1L) 



# combine legs
log <- rbind(logA, logB)
sal <- rbind(salA, salB)

# count DICTA and pH bottles
n_distinct(log$`DIC/TA Bottle #`, na.rm = TRUE)
n_distinct(log$`pH Bottle #`, na.rm = TRUE)



# format cruise ID and column headers
bottles <- log %>%
  rename(Cruise_ID = "Cruise ID") %>%
  rename(station = "Station-Cast #") %>%
  rename(start_lat = "Start Latitude") %>%
  rename(start_lon = "Start Longitude") %>%
  rename(niskin = "Niskin #") %>%
  rename(trip_depth_m = "Trip Depth [m]") %>%
  rename(PH_bottle = "pH Bottle #") %>%
  rename(DICTA_bottle = "DIC/TA Bottle #") %>%
  rename(salt_bottle = "Salts Bottle #") 

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)

headers <- c("Cruise_ID", "station",  "start_lat", "start_lon", "niskin", "trip_depth_m", "Date", "PH_bottle", "DICTA_bottle", "salt_bottle")
bottles <- bottles[, headers]

sal <- sal %>%
  rename(Cruise_ID = "Cruise ID") %>%
  rename(station = "Station ID") %>%
  rename(niskin = "Niskin ID") %>%
  rename(salt_bottle = "Sample ID") %>%
  rename(salinity_psu = "Salinity [psu]")

sal$niskin <- as.numeric(sal$niskin)
sal$station <- as.numeric(sal$station)



# isolate carbonate rows
# check number of bottles
# match salinity to cruise log
bottles <- filter(bottles, PH_bottle != "NA" | DICTA_bottle != "NA")

n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)


bottles_sal <- left_join(bottles, sal, c("Cruise_ID","station", "niskin", "salt_bottle"))


# clean up salinity dataframe 
bottles_sal$salinity_psu <- as.numeric(bottles_sal$salinity_psu)

bottles_sal <- bottles_sal %>%
  mutate(salinity_psu = round(salinity_psu, 4))

# comment out to keep all parameters from bottle 
# headers <- c("Cruise_ID", "Date", "DICTA_bottle", "PH_bottle", "salinity_psu")
# bottles_sal <- bottles_sal[, headers]


# write salinity dataframe and write to csv
bottles_sal_21 <- bottles_sal
#write_csv(bottles_sal, "Pioneer_21_carbonate_bottle_salinity.csv")

# write bottle_sal with all parameters to csv
write_csv(bottles_sal_21, "Pioneer_21_carbonate_bottle_salinity_meta.csv")



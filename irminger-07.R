
#load required packages
library(tidyverse) 
library(httr)
library(readxl)
library(here)

#set path to root of project
here("ooi-carbonate-setup")

## Access OOI data from Alfresco

# read in URLs and get data files

# Irminger 7 Sampling Log Version 1-03
log_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Global%20Irminger%20Sea%20Array/Cruise%20Data/Irminger_Sea-07_AR46_2020-08-08/Ship%20Data/Water%20Sampling/Irminger_Sea-07_AR46_CTD_Sampling_Log_2022-01-13_Ver_1-03.xlsx')

# Irminger 7 salinity data Version 1-00
sal_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Global%20Irminger%20Sea%20Array/Cruise%20Data/Irminger_Sea-07_AR46_2020-08-08/Ship%20Data/Water%20Sampling/Irminger_Sea-07_AR46_Salinity_Sample_Data_2020-09-29_Ver_1-00.xlsx')


# Supply credentials for Alfresco
creds <- readr::read_file("authenticate.txt")



GET(log_url, authenticate(creds, creds), write_disk(logtf <- tempfile(fileext = ".xlsx")))

#logtf


GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))

#saltf


# assign files to data frames

log <- read_excel(logtf, 1L) 
sal <- read_excel(saltf, 1L) 


# count DICTA and pH bottles

n_distinct(log$`DIC/TA Bottle #`, na.rm = TRUE)
n_distinct(log$`pH Bottle #`, na.rm = TRUE)

# format cruise ID and column headers

bottles <- log %>%
  rename(Cruise_ID = "Cruise ID") %>%
  rename(station = "Station-Cast #") %>%
  rename(niskin = "Niskin #") %>%
  rename(depth = "Trip Depth [m]") %>%
  rename(PH_bottle = "pH Bottle #") %>%
  rename(DICTA_bottle = "DIC/TA Bottle #") %>%
  rename(salt_bottle = "Salts Bottle #") 

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)

headers <- c("Cruise_ID", "station", "niskin", "Date", "depth", "PH_bottle", "DICTA_bottle", "salt_bottle") 
bottles <- bottles[, headers]

sal <- sal %>%
  rename(station = "Station ID") %>%
  rename(niskin = "Niskin ID") %>%
  rename(salt_bottle = "Sample ID") %>%
  rename(salinity_psu = "Salinity [psu]")

sal$station <- as.numeric(sal$station)
sal$niskin <- as.numeric(sal$niskin)

# some rows with carbonate bottles have no salt bottles, but duplicate niskins have salt bottles
# rows with salt bottles
salt_bottles <- filter(bottles, salt_bottle != "NA") 
# isolate carbonate rows
bottles <- filter(bottles, PH_bottle != "NA" | DICTA_bottle != "NA")  %>%
  select(-salt_bottle)
# join carbonate bottles with salt bottles from matching depth
bottles <- left_join(bottles, salt_bottles, c("station", "depth"), keep = FALSE)
# can visually check data frame to confirm matching
# remove/rename redundant columns
bottles <- bottles %>%
 select(-c(Cruise_ID.y, Date.y, PH_bottle.y, DICTA_bottle.y)) %>%
 rename(niskin_dup = niskin.y)
colnames(bottles)<-(gsub(".x", "", colnames(bottles)))

bottles <- bottles %>%
  rename(depth_m = depth) 

bottles$depth_m <- replace(bottles$depth_m, is.na(bottles$depth_m), 1)

# check number of bottles
n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)

# join with bottle salinity

# are salinity IDs unique?
if(nrow(sal) == length(unique(sal$salt_bottle))){
  bottles_sal <- left_join(bottles, sal, c("station", "salt_bottle"))
}


#bottles_sal <- left_join(bottles, sal, c("station", "depth_m", "salt_bottle"))


# clean up salinity dataframe and write to csv

#bottles_sal$salinity_psu <- as.numeric(bottles_sal$salinity_psu)

bottles_sal <- bottles_sal %>%
  mutate(salinity_psu = round(salinity_psu, 4))

# headers for initial bottle analysis
#headers <- c("Cruise_ID", "Date", "DICTA_bottle", "PH_bottle", "salinity_psu")
#bottles_sal <- bottles_sal[, headers]
#write_csv(bottles_sal, "Irminger_07_carbonate_bottle_salinity.csv")

bottles_sal <- bottles_sal %>%
  select(-c("Cruise ID", niskin.y)) %>%
  rename(niskin = niskin.x)
write_csv(bottles_sal, "Irminger_07_carbonate_bottle_salinity_depth.csv")

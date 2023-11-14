## Access OOI data from Alfresco

# read in URLs and get data files

# Irminger 10 Sampling Log Version 1-00
log_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Global%20Irminger%20Sea%20Array/Cruise%20Data/Irminger_Sea-10_AR76-03_2023-08-27/Ship%20Data/Water%20Sampling/Irminger_Sea-10_AR76-03_CTD_Sampling_Log_2023-10-13_Ver_1-00.xlsx')

# Irminger 10 salinity data Version 1-00
sal_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Global%20Irminger%20Sea%20Array/Cruise%20Data/Irminger_Sea-10_AR76-03_2023-08-27/Ship%20Data/Water%20Sampling/Irminger_Sea-10_AR76-03_Salinity_Sample_Data_2023-10-04_Ver_1-00.xlsx')


# Supply credentials for Alfresco
creds <- read_file("authenticate.txt")

httr::GET(log_url, authenticate(creds, creds), write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

httr::GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf


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
  rename(PH_bottle = "pH Bottle #") %>%
  rename(DICTA_bottle = "DIC/TA Bottle #") %>%
  rename(salt_bottle = "Salts Bottle #") 

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)

headers <- c("Cruise_ID", "station", "niskin", "Date", "PH_bottle", "DICTA_bottle", "salt_bottle")
bottles <- bottles[, headers]

sal <- sal %>%
  rename(station = "Station ID") %>%
  rename(niskin = "Niskin ID") %>%
  rename(salt_bottle = "Sample ID") %>%
  rename(salinity_psu = "Salinity [psu]")

sal$station <- as.numeric(sal$station)
sal$niskin <- as.numeric(sal$niskin)

# match salinity to cruise log
# isolate carbonate rows
# check number of bottles
# join with salinity

bottles <- filter(bottles, PH_bottle != "NA" | DICTA_bottle != "NA")

n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)

bottles_sal <- left_join(bottles, sal, c("station", "niskin", "salt_bottle"))


# clean up salinity dataframe and write to csv

bottles_sal$salinity_psu <- as.numeric(bottles_sal$salinity_psu)

bottles_sal <- bottles_sal %>%
  mutate(salinity_psu = round(salinity_psu, 4))

headers <- c("Cruise_ID", "Date", "DICTA_bottle", "PH_bottle", "salinity_psu")
bottles_sal <- bottles_sal[, headers]

write_csv(bottles_sal, "Irminger_10_carbonate_bottle_salinity.csv")

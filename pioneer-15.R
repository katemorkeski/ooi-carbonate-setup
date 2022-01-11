
## Access OOI data from Alfresco

# read in leg A URLs and get data files

# Pioneer 15 Sampling Log Leg A Version 1-00
log_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Coastal%20Pioneer%20Array/Cruise%20Data/Pioneer-15_AR48_2020-10-28/Ship%20Data/Water%20Sampling/Pioneer-15_AR48A_CTD_Sampling_Log_2020-12-07_Ver_1-00.xlsx')

# Pioneer 15 salinity data Leg A Version 1-00
sal_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Coastal%20Pioneer%20Array/Cruise%20Data/Pioneer-15_AR48_2020-10-28/Ship%20Data/Water%20Sampling/Pioneer-15_AR48A_Salinity_Sample_Data_2020-12-07_Ver_1-00.xlsx')


# Supply credentials for Alfresco
creds <- read_file("authenticate.txt")

httr::GET(log_url, authenticate(creds, creds), write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

httr::GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf


# assign leg A files to data frames

logA <- read_excel(logtf, 1L) 
salA <- read_excel(saltf, 1L) 

# read in leg B URLs and get data files

# Pioneer 15 Sampling Log Leg B Version 1-00
log_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Coastal%20Pioneer%20Array/Cruise%20Data/Pioneer-15_AR48_2020-10-28/Ship%20Data/Water%20Sampling/Pioneer-15_AR48B_CTD_Sampling_Log_2020-12-07_Ver_1-00.xlsx')

# Pioneer 15 salinity data Leg B Version 1-00
sal_url <- ('https://alfresco.oceanobservatories.org/alfresco/webdav/OOI/Coastal%20Pioneer%20Array/Cruise%20Data/Pioneer-15_AR48_2020-10-28/Ship%20Data/Water%20Sampling/Pioneer-15_AR48B_Salinity_Sample_Data_2020-12-07_Ver_1-00.xlsx')


httr::GET(log_url, authenticate(creds, creds), write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

httr::GET(sal_url, authenticate(creds, creds), write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf


# assign leg B files to data frames

logB <- read_excel(logtf, 1L) 
salB <- read_excel(saltf, 1L) 

# combine legs
log <- rbind(logA, logB)
sal <- rbind(salA, salB)


# count DICTA and pH bottles

n_distinct(log$`DIC/TA Bottle #`, na.rm = TRUE)
n_distinct(log$`Ph Bottle #`, na.rm = TRUE)

# format cruise ID and column headers

bottles <- log %>%
  rename(Cruise_ID = "Cruise ID") %>%
  rename(station = "Station-Cast #") %>%
  rename(niskin = "Niskin #") %>%
  rename(PH_bottle = "Ph Bottle #") %>%
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

write_csv(bottles_sal, "Pioneer_15_carbonate_bottle_salinity.csv")

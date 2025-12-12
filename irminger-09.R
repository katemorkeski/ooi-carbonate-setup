
# read in URLs and get data files

# Irminger 9 Sampling Log Version 1-00
log_url <-("https://rawdata.oceanobservatories.org/files/cruise_data/Irminger_Sea/Irminger_Sea-09_AR69-01_2022-06-20/Water_Sampling/Irminger_Sea-09_AR69-01_CTD_Sampling_Log_2022-08-03_Ver_1-00.xlsx")   

# Irminger 9 salinity data Version 1-00
sal_url <- ("https://rawdata.oceanobservatories.org/files/cruise_data/Irminger_Sea/Irminger_Sea-09_AR69-01_2022-06-20/Water_Sampling/Irminger_Sea-09_AR69-01_Salinity_Sample_Data_2022-07-28_Ver_1-00.xlsx")

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

bottles <- clean_names(log)

# format cruise ID and column headers
bottles <- bottles %>%
  rename(station = station_cast_number) %>%
  rename(niskin = niskin_number) %>%
  rename(PH_bottle = p_h_bottle_number) %>%
  rename(DICTA_bottle = dic_ta_bottle_number) %>%
  rename(salt_bottle = salts_bottle_number) 

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)

bottles <- bottles %>% select(-oxygen_bottle_number, -nitrate_bottle_number, -chlorophyll_brown_bottle_number, -chlorophyll_brown_bottle_volume, -chlorophyll_filter_sample_number, -chlorophyll_ln_tube)
# isolate carbonate rows
# check number of bottles
bottles <- filter(bottles, PH_bottle != "NA" | DICTA_bottle != "NA")

n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)

# match salinity to cruise log
sal <- sal %>%
  rename(station = "Station ID") %>%
  rename(niskin = "Niskin ID") %>%
  rename(salt_bottle = "Sample ID") %>%
  rename(salinity_psu = "Salinity [psu]") |>
  select(-"...6")

sal$station <- as.numeric(sal$station)
sal$niskin <- as.numeric(sal$niskin)

# join log with salinity
bottles_sal <- left_join(bottles, sal, c("station", "niskin", "salt_bottle"))

# clean up salinity dataframe and write to csv
bottles_sal$salinity_psu <- as.numeric(bottles_sal$salinity_psu)

bottles_sal <- bottles_sal %>%
  mutate(salinity_psu = round(salinity_psu, 4)) |>
  select(-"Cruise ID") |>
  relocate(salinity_psu, .after = salt_bottle)

log_irm9 <- bottles_sal

#write_csv(bottles_sal, "Irminger_09_carbonate_bottle_salinity.csv")

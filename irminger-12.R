## Access OOI sampling logs

# read in URLs and get data files

# Sampling Log Version 1-01
log_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Irminger_Sea/Irminger_Sea-12_RR2505_2025-07-18/Water_Sampling/Irminger_Sea-12_RR2505_CTD_Sampling_Log_2025-11-24_Ver_1-01.xlsx')

# salinity data Version 1-00
sal_url <- ('https://rawdata.oceanobservatories.org/files/cruise_data/Irminger_Sea/Irminger_Sea-12_RR2505_2025-07-18/Water_Sampling/Irminger_Sea-12_RR2505_Salinity_Sample_Data_2025-09-05_Ver_1-00.xlsx')

httr::GET(log_url, write_disk(logtf <- tempfile(fileext = ".xlsx")))

logtf

httr::GET(sal_url, write_disk(saltf <- tempfile(fileext = ".xlsx")))

saltf

# assign files to data frames
log <- read_excel(logtf, 1L) 
sal <- read_excel( saltf, 1L)

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

bottles <- bottles |> select(cruise_id, station, target_station, start_latitude, start_longitude, start_date, start_time, bottom_depth_m, niskin, rosette_position, date, time, trip_depth_m, PH_bottle, DICTA_bottle, salt_bottle, comments)
#headers <- c("cruise_id", "station", "niskin", "date", "PH_bottle", "DICTA_bottle", "salt_bottle")
#bottles <- bottles[, headers]

sal <- clean_names(sal)

sal$station <- as.numeric(sal$station_id)
sal$niskin <- as.numeric(sal$niskin_id)
sal$salt_bottle <- sal$sample_id
sal <- select(sal, -cruise_id, -station_id, -niskin_id, -sample_id)

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
  mutate(salinity_psu = round(salinity_psu, 4)) |>
  select(-notes) |>
  relocate(salinity_psu, .after = salt_bottle)

#headers <- c("cruise_id", "date", "DICTA_bottle", "PH_bottle", "salinity_psu")
log_irm12 <- bottles_sal

write_csv(log_irm12, "Irminger_12_carbonate_bottle_salinity.csv")

log_irm080910 <- read_csv("Irminger_08_09_10_carbonate_bottle_metadata.csv")

log_irm08_12 <- rbind(log_irm080910, log_irm11, log_irm12)
write_csv(log_irm08_12, "Irminger_08-12_carbonate_bottle_metadata.csv")



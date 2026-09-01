
# Papa 9 salinity data: no salt bottles, use average of CTD salinity 1 and 2 from log file provided by Rebecca
bottles <- read_excel("Station_Papa-09_SKQ202208S_CTD_Sampling_Log_plusShipboardSalinity_2023-11-14_RGT.xlsx")

# count DICTA and pH bottles
n_distinct(bottles$`DIC/TA Bottle #`, na.rm = TRUE)
n_distinct(bottles$`pH Bottle #`, na.rm = TRUE)

# format columns
bottles <- bottles %>%
  rename(Cruise_ID = "Cruise ID") %>%
  rename(station = "Station-Cast #") %>%
  rename(niskin = "Niskin #") %>%
  rename(depth = "Trip Depth [m]") %>%
  rename(PH_bottle = "pH Bottle #") %>%
  rename(DICTA_bottle = "DIC/TA Bottle #") %>%
  rename(CTD_salinity_1 = "CTD Salinity 1") %>%
  rename(CTD_salinity_2 = "CTD Salinity 2") |>
  filter(PH_bottle != "NA" | DICTA_bottle != "NA")

bottles$station <- as.numeric(bottles$station)
bottles$niskin <- as.numeric(bottles$niskin)
bottles$CTD_salinity_1 <- as.numeric(bottles$CTD_salinity_1)
bottles$CTD_salinity_2 <- as.numeric(bottles$CTD_salinity_2)

bottles <- bottles %>%
  mutate(CTD_salinity_avg = (CTD_salinity_1 + CTD_salinity_2)/2) |>
  mutate(CTD_salinity_avg = round(CTD_salinity_avg, 4)) 
  
headers <- c("Cruise_ID", "station", "niskin", "depth", "Date", "PH_bottle", "DICTA_bottle", "CTD_salinity_1", "CTD_salinity_2", "CTD_salinity_avg")
bottles <- bottles[, headers]
# can use this for summary file after analysis

n_distinct(bottles$DICTA_bottle, na.rm = TRUE)
n_distinct(bottles$PH_bottle, na.rm = TRUE)

# clean up salinity dataframe and write to csv
#headers <- c("Cruise_ID", "Date", "station", "niskin", "depth", "DICTA_bottle", "PH_bottle", "CTD_salinity_avg")
#bottles <- bottles[, headers]

write_csv(bottles, "Papa_09_carbonate_bottle_salinity.csv")

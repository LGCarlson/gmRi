## ----setup, include = FALSE----------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE, fig.align = "center", eval = FALSE)

library(ncdf4)
library(sf)
library(raster)
library(stars)
library(tidyverse)
library(here)
library(patchwork)
library(rnaturalearth)
library(gmRi)

#Geographic boundaries
northeast <- ne_states("united states of america") %>% 
  st_as_sf() %>% 
  filter(region_sub %in% c("New England", "Middle Atlantic", "South Atlantic"))
canada <- ne_states("canada") %>% st_as_sf()

theme_set(theme_bw())

## ------------------------------------------------------------------------
#  
#  # Establish Desired Destination Path
#  oisst_path <- "/Users/akemberling/Documents/oisst_local"
#  oisst_path <- "/Users/akemberling/Documents/oisst_mainstays/full_period"
#  
#  
#  # Pull data from Thredds server
#  daily_sst_stack <- env_data_extract(data.set = "OISST",
#                                      dates = c("1982-01-01", "1984-12-31"),
#                                      #box = c(1, 359, -89, 89),
#                                      box = c(-77, -60, 35, 46),
#                                      out.dir = oisst_path,
#                                      mask = NULL)
#  
#  

## ------------------------------------------------------------------------
#  # Load data into R as Raster stack
#  daily_sst_stack <- raster::stack(str_c(oisst_path, "/", "OISST.grd"))

## ------------------------------------------------------------------------
#  #Set up the Breaks you want
#  season_breaks <- data.frame(
#    "breaks" = c("SPRING", "FALL"),
#    "start_date" = c(as.Date("1981-03-01"),
#                     as.Date("1981-09-01")),
#    "end_date" = c(as.Date("1984-05-31"),
#                   as.Date("1984-11-30"))
#  )
#  
#  
#  #Calculate Means
#  fall_spring_means <- oisst_period_means(stack_in = daily_sst_stack,
#                                          projection_crs = 4326,
#                                          time_res_df = season_breaks)

## ---- fig.height=8, fig.width=6------------------------------------------
#  # Plot them
#  p1 <- ggplot() +
#    geom_stars(data = st_as_stars(fall_spring_means$SPRING.1982)) +
#    geom_sf(data = northeast) +
#    geom_sf(data = canada) +
#    scale_fill_distiller(palette = "RdBu", na.value = "NA") +
#    guides(fill = guide_colorbar(title = "SST - Celsius")) +
#    coord_sf(xlim = c(-77, -60), ylim = c(35, 46), expand = FALSE) +
#    labs(x = NULL, y = NULL, caption = "Spring 1982")
#  
#  p2 <- ggplot() +
#    geom_stars(data = st_as_stars(fall_spring_means$FALL.1982)) +
#    geom_sf(data = northeast) +
#    geom_sf(data = canada) +
#    scale_fill_distiller(palette = "RdBu", na.value = "NA") +
#    guides(fill = guide_colorbar(title = "SST - Celsius")) +
#    coord_sf(xlim = c(-77, -60), ylim = c(35, 46), expand = FALSE) +
#    labs(x = NULL, y = NULL, caption = "Fall 1982")
#  
#  p1 / p2

## ------------------------------------------------------------------------
#  # Create spatial points object from station data
#  station_data <- read_csv("/Users/akemberling/Box/Adam Kemberling/Box_Projects/Convergence_ML/data/trawldat.csv")
#  trawl_sf <- st_as_sf(station_data, coords = c("DECDEG_BEGLON", "DECDEG_BEGLAT"), crs = 4326)
#  
#  # # Reproject if necessary
#  # project_utm <- 26919 #NAD1983 / UTM zone 19N got Maine
#  # trawl_sf_proj <- trawl_sf %>% st_transform(crs = project_utm)
#  # project_utm <- st_crs(trawl_sf_proj)
#  
#  
#  
#  # Format Date Column
#  trawl_sf <- trawl_sf %>%
#    mutate(DATE = lubridate::ymd_hms(str_c(EST_YEAR, "-", EST_MONTH, "-", EST_DAY, " 12:00:00")))

## ------------------------------------------------------------------------
#  #Single Year Test = Fall 1982
#  
#  #Test Raster
#  test_ras <- fall_spring_means$FALL.1982
#  
#  
#  #Test points = all stations all years
#  test_points <- bind_cols( lon = station_data$DECDEG_BEGLON, lat = station_data$DECDEG_BEGLAT)
#  test_points$sst <- raster::extract(test_ras, test_points)

## ---- fig.height=5, fig.width=5------------------------------------------
#  test_points <- st_as_sf(test_points, coords = c("lon", "lat"), crs = 4326)
#  
#  
#  #Test plot
#  ggplot() +
#    geom_sf(data = test_points, aes(color = sst)) +
#    geom_sf(data = northeast) +
#    geom_sf(data = canada) +
#    scale_color_distiller(palette = "RdBu", na.value = "NA") +
#    guides(fill = guide_colorbar(title = "SST - Celsius")) +
#    coord_sf(xlim = c(-72, -65), ylim = c(39.5, 45), expand = FALSE) +
#    labs(x = "", y = "", caption = "All station coordinates - Fall 1982 SST Layer")
#  

## ------------------------------------------------------------------------
#  
#  #Extracting all years from the brick
#  test_points <- dplyr::select(station_data, lon = DECDEG_BEGLON, lat = DECDEG_BEGLAT, year = EST_YEAR)
#  
#  #Extract specific to the sample year (or whatever the raster resolution is)
#  #Season is generated at random here because imported data does not contain that information
#  full_extraction <- test_points %>%
#    mutate(season = sample(c("SPRING", "FALL"), replace = T, size = 1),
#           raster_res = str_c(season, year, sep = ".")) %>%
#    split(.$raster_res) %>%
#    imap_dfr(function(df, resolution){
#  
#      # Build Brick layer ID
#      stack_id <- resolution
#  
#      # Build Raster Layer Index Number
#      layer_index <- which(names(fall_spring_means) == stack_id)
#  
#      # Return NA's if there's no layer that matches
#      if(length(layer_index) != 0){
#          df$sst <- raster::extract(fall_spring_means[[layer_index]], df[, c("lon", "lat")])
#        return(df) } else {
#          df$sst <- rep(NA, nrow(df))
#          return(df)
#        }
#  
#    })

## ---- fig.height=8, fig.width=6------------------------------------------
#  full_extraction <- st_as_sf(full_extraction, coords = c("lon", "lat"), crs = 4326)
#  
#  full_extraction %>%
#    filter(year %in% 1982:1984) %>%
#    ggplot() +
#      geom_sf(aes(color = sst)) +
#      geom_sf(data = northeast) +
#      geom_sf(data = canada) +
#      scale_color_distiller(palette = "RdBu", na.value = "NA") +
#      guides(fill = guide_colorbar(title = "SST - Celsius")) +
#      coord_sf(xlim = c(-72, -65), ylim = c(39.5, 45), expand = FALSE) +
#      labs(x = "", y = "", caption = "Seasonal Survey Stations Extracting Matching SST Means") +
#      facet_grid(year ~ season)

## ------------------------------------------------------------------------
#  


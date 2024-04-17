################################################################################
################ COMPUTING ACCESSIBILITY IN ANGOLA COMMUNITIES #################
################################################################################

pacman::p_load(osmdata, dplyr, data.table, sf, crsuggest, ggplot2,
               sfnetworks, tidygraph, dbscan, accessibility,
               doParallel, foreach)

#### write the cleaned network data into pbf format
network_dt <- readRDS("data-clean/clean_roadnetwork.RDS")

### read in the communities which will be the origins
community_dt <- readstata13::read.dta13("data-raw/microdata/Comunitario_Final.dta")

community_dt <-
  community_dt %>%
  mutate(S3_01__Latitude = as.numeric(as.character(S3_01__Latitude))) %>%
  mutate(S3_01__Longitude = as.numeric(as.character(S3_01__Longitude))) %>%
  select(c("interview__id", "interview__key", "S1_01", "S1_02", "S1_03",
           "S1_04a", "S1_05", "S3_01__Longitude", "S3_01__Latitude")) %>%
  filter(!is.na(S3_01__Longitude) & !is.na(S3_01__Latitude)) %>%
  st_as_sf(crs = 4326,
           agr = "constant",
           coords = c("S3_01__Longitude", "S3_01__Latitude"))

osmamenities_obj <- readRDS("data-raw/osm_raw/osmamenities_object.RDS")


markfin_dt <-
  osmamenities_obj$osm_points %>%
  filter(amenity %in% c("marketplace", "atm", "bank")) %>%
  select(c(osm_id, geometry))

### last minute prep the network for the estimation
network_dt <-
  network_dt %>%
  as_sfnetwork(directed = FALSE,
               length_as_weight = TRUE)

network_dt <-
  network_dt %>%
  activate("edges") %>%
  mutate(adj_speed = ifelse(is.na(time), 41.10, adj_speed)) %>%
  mutate(adj_speed = adj_speed * units::as_units("km/h")) %>%
  mutate(time = weight / adj_speed)

network_dt <-
  network_dt %>%
  activate("nodes") %>%
  filter(group_components() == 1)

### let us start computing
saveRDS(network_dt, "data-raw/transport_network/network_readyformatrix.RDS")



dt <- parallel_compnetaccess(cpus = 15,
                             lines_obj = network_dt,
                             origins_dt = community_dt[, c("interview__id")],
                             dest_dt = markfin_dt,
                             blend_obj = network_dt)

saveRDS(dt, "data-clean/marketplace/village_market_access.RDS")





















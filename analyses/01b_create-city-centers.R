################################################################################
############## ESTIMATE CITY CENTERS USING THE POPULATION DATA #################
################################################################################

pacman::p_load(raster, sf, data.table, tidyverse)

#### read in the population data

bld_raster <- raster("//esapov/esapov/AGO/GEO/BuildingFootprints/AGO_buildings_v1_1_count.tif")

shp_dt <- sf::st_read(dsn = "data-raw/boundary",
                      layer = "ago_admbnda_adm3_gadm_ine_ocha_20180904")

shp_dt <-
  shp_dt %>%
  mutate(area = units::set_units(st_area(.), "km^2"))


bld_dt <-
  bld_raster %>%
  rasterToPolygons() %>%
  st_as_sf()

joined_dt <- st_join(bld_dt %>%
                       st_centroid(),
                     shp_dt %>% st_as_sf(crs = st_crs(bld_dt)$wkt))

### extract the points with the highest number of buildings in each admin3 area
index_dt <-
joined_dt %>%
  as.data.table() %>%
  .[, .I[AGO_buildings_v1_1_count == max(AGO_buildings_v1_1_count, na.rm = TRUE)],
    by = ADM3_PCODE]


center_dt <- joined_dt[index_dt$V1,]

#### check to see if we can substitute the districts without markets with city
#### center by looking at where we have the highest building density within
#### each district as a the potential location of a market

center_dt <- center_dt[!is.na(center_dt$area), ]

saveRDS(center_dt, "data-clean/marketplace/district_centers.RDS")



















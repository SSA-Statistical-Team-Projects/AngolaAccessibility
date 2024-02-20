################################################################################
###################### EXPLORING THE GEOSPATIAL DATASETS #######################
################################################################################
sf::sf_use_s2(FALSE)

pacman::p_load(sf, data.table, dplyr, raster, exactextractr, )

#### read in the settlement footprint data

stlshp_dt <- sf::st_read(dsn = "data-raw/settlements",
                         layer = "Angola_Settlement_Extents_Version_02")


#### read in the shapefile
shp_dt <- sf::st_read(dsn = "data-raw/boundary",
                      layer = "ago_admbnda_adm3_gadm_ine_ocha_20180904")

### check the match between admin3 boundary shapefile and the settlement shapefile

unique(nchar(stlshp_dt$pcode)) ###### 13 chr alphanums (with 201 random ones with only 2)
unique(nchar(shp_dt$ADM3_PCODE)) #### contains only 10 digit values

#### intersect admin 3 boundary shapefile with settlement footprint
stlshpint_dt <- st_intersection(x = stlshp_dt,
                                y = shp_dt[, c("ADM3_EN", "ADM3_PCODE", "ADM3_REF",
                                               "ADM3ALT1EN", "ADM3ALT2EN", "ADM2_EN",
                                               "ADM2_PCODE", "ADM1_EN", "ADM1_PCODE",
                                               "ADM0_EN", "ADM0_PCODE")])

stlshpint_dt <-
  stlshpint_dt %>%
  mutate(int_area_km2 = units::set_units(st_area(.), "km^2"))


#### include population and building raster estimates
pop_raster <- raster::raster("data-raw/ago_ppp_2020_UNadj_constrained.tif")

stlshpint_dt <-
stlshpint_dt %>%
  mutate(settlement_id = 1:nrow(.)) %>%
  mutate(settlement_id = sprintf(paste0("%0",
                                        nchar(nrow(stlshpint_dt)),
                                        "d"),
                                 settlement_id))

# stlshpint_dt <-
#   stlshpint_dt %>%
#   mutate(population = exact_extract(x = pop_raster,
#                                     y = .,
#                                     fun = "sum"))
pop_dt <-
parallel_zonalext(shp_dt = stlshpint_dt[, c("settlement_id")],
                  raster_obj = pop_raster,
                  summary_fun = "sum",
                  cpus = 15,
                  parallel_mode = "socket")


pop_dt <- lapply(pop_dt,
                 function(x){

                   y <- x %>%
                     st_drop_geometry()

                   return(y)

                 })

pop_dt <- Reduce(f = "rbind",
                 x = pop_dt)

saveRDS(pop_dt, "data-clean/stladm_int_pop.RDS")

stlshpint_dt <-
  stlshpint_dt %>%
  merge(pop_dt)

colnames(stlshpint_dt)[colnames(stlshpint_dt) %in% "result"] <- "population"

### compute admin level population
shp_dt <-
  shp_dt %>%
  mutate(admin3pop = exact_extract(x = pop_raster,
                                   y = .,
                                   fun = "sum"))

### adjust populations to match admin 3 populations
stlshpint_dt <-
  stlshpint_dt %>%
  merge(shp_dt[, c("ADM3_PCODE", "admin3pop")] %>% st_drop_geometry()) %>%
  group_by(ADM3_PCODE) %>%
  mutate(adj_population = (population / sum(population, na.rm = TRUE)) * admin3pop)

saveRDS(stlshpint_dt, "data-raw/stladm_int_popadj.RDS")




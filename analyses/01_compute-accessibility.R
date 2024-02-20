################################################################################
################ COMPUTE ACCESSIBILITY AT THE SETTLEMENT LEVEL #################
################################################################################

pacman::p_load(osmdata, dplyr, data.table, sf, crsuggest, ggplot2, sfnetworks)

#### read in the settlement interesection with adm3 data with adjusted population
stl_dt <- readRDS("data-raw/stladm_int_popadj.RDS")

### create a bounding box of appropriate distance around Angola
bbox_dt <- create_query_bbox(shp_dt = stl_dt,
                             buffer_dist = rep(50000, 4))


### lets put together the amenities we are interested in
availamenity_dt <- available_tags("amenity")

osmamenities_obj <-
  bbox_dt %>%
  opq(timeout = 300, out = "body") %>%
  add_osm_feature(key = "amenity",
                  value = c("hospital","clinic","doctors","pharmacy",
                            "atm", "bank", "marketplace", "college",
                            "kindergaten", "school", "banks", "atm")) %>%
  osmdata_sf()

### get only the amenity points
saveRDS(osmamenities_obj, "data-raw/osm_raw/osmamenities_object.RDS")


### pull the streets data as well
osmstreets_obj <-
  bbox_dt %>%
  opq(timeout = 400, out = "body") %>%
  add_osm_feature("highway", c("motorway", "primary", "secondary", "tertiary",
                               "unclassified", "residential", "trunk","road",
                               "motorway_link","trunk_link", "primary_link",
                               "secondary_link", "tertiary_link")) %>%
  osmdata_sf()

saveRDS(osmstreets_obj, "data-raw/osm_raw/osmroads_object.RDS")


#### create speed dictionary
speed_dt <- data.frame(highway = c("trunk","secondary","tertiary", "residential",
                                   "unclassified","primary","trunk_link", "secondary_link",
                                   "primary_link","tertiary_link", "road"),
                       speed = c(90, 60, 55, 40, 50, 70, 70, 55, 60, 45, 50))

speedadj_dt <- data.frame(surface = c("asphalt", "unpaved", "concrete","cobblestone:flattened",
                                      "dirt/sand", "dirt", "paved", "sett", "ground",
                                      "gravel" ,  "cobblestone", "paving_stones",
                                      "compacted", "sand", "unhewn_cobblestone",
                                      "earth", "grass" , "unspecified" , "mud" ,
                                      "dust" ,  "wood", "concrete:plates",
                                      "concrete:lanes", "unpaved;dirt/sand"),
                          div_speed_by = c(1.00, 1.30, 1.10, 1.30, 1.30, 1.10, 1.10, 1.30,
                                           1.30, 1.30, 1.30, 1.30, 1.00, 1.30, 1.30, 1.30,
                                           1.30, 1.00, 1.30, 1.30, 1.30, 1.00, 1.00, 1.30))















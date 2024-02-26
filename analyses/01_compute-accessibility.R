################################################################################
################ COMPUTE ACCESSIBILITY AT THE SETTLEMENT LEVEL #################
################################################################################

pacman::p_load(osmdata, dplyr, data.table, sf, crsuggest, ggplot2,
               sfnetworks, tidygraph, dbscan, accessibility)

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
highway_type <- unique(osmstreets_obj$osm_lines$highway[!is.na(osmstreets_obj$osm_lines$highway)])

speed_dt <- data.frame(highway = highway_type,
                       speed = c(90, 70, 60, 55, 40, 50, 55,
                                 70, 60, 45, 50, 80, 90))

### quickly clean surface data
osmstreets_obj$osm_lines$surface[grepl(pattern = "asphaltFresh_",
                                       x = osmstreets_obj$osm_lines$surface)] <-
  "asphalt"

osmstreets_obj$osm_lines$surface[grepl(pattern = "groundRzeka_",
                                       x = osmstreets_obj$osm_lines$surface)] <-
  "ground"

osmstreets_obj$osm_lines$surface[grepl(pattern = "unpaved; ground",
                                       x = osmstreets_obj$osm_lines$surface)] <-
  "unpaved"

osmstreets_obj$osm_lines$surface[osmstreets_obj$osm_lines$surface %in%
                                   c(3, "add name", "d",
                                     "d7", "dd", "JOG")] <-
  NA

osmstreets_obj$osm_lines$surface[grepl(pattern = "fine_gravel",
                                       x = osmstreets_obj$osm_lines$surface)] <-
  "gravel"

surface_type <- unique(osmstreets_obj$osm_lines$surface[!is.na(osmstreets_obj$osm_lines$surface)])
surfadj_dt <- data.frame(surface = surface_type,
                         div_speed_by = c(1, 1.3, 1.1, 1.1, 1, 1.1, 1.3, 1.3, 1.3, 1.3, 1.3,
                                          1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.3, 1.5, 1.3))

network_dt <- clean_osmlines(streets_obj = osmstreets_obj,
                             speed_dt = speed_dt,
                             surfadj_dt = surfadj_dt)

### save the clean network data
saveRDS(network_dt, "data-clean/clean_roadnetwork.RDS")


### compute the distance to the nearest marketplace metrics

























################################################################################
################ COMPUTE ACCESSIBILITY AT THE SETTLEMENT LEVEL #################
################################################################################

pacman::p_load(osmdata, dplyr, data.table, sf, crsuggest, r5r)

sf::sf_use_s2(FALSE)
#### read in the settlement interesection with adm3 data with adjusted population
stl_dt <- readRDS("data-raw/stladm_int_popadj.RDS")


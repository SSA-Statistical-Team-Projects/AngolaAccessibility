################################################################################
################ COMPUTE ACCESSIBILITY AT THE SETTLEMENT LEVEL #################
################################################################################

pacman::p_load(osmdata, dplyr, data.table, sf, crsuggest, r5r)

sf::sf_use_s2(FALSE)

#### read in the shapefile
shp_dt <- sf::st_read(dsn = "data-raw/microdata/ago_shape",
                      layer = "ago_admbnda_adm3_gadm_ine_ocha_20180904")

base_dir <- "data-raw/microdata/Bases RAPP_Novo/Explorações Familiares/Bases Finais/FAMILIARES STATA"

dt_list <- lapply(paste0(base_dir, "/",
                         list.files(path = base_dir,
                                    pattern = ".dta")),
                  FUN = haven::read_dta)

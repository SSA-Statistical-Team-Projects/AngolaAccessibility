################################################################################
############### A SET OF UTILITY FUNCTIONS TO SUPPORT THE PROJECT ##############
################################################################################

#' A function to parallel compute zonal stats
#'
#' @details This function computes the zonal statistics for a shapefile, preferably a large
#' shapefile with over 200,000+ observations by extracting vector object of class
#' `raster`. The function splits the `sf`, `data.frame` polygon object into `cpus` number
#' of parts and each part is extracted into in parallel.
#'
#' @param shp_dt sf, data.frame polygon/multipolygon object
#' @param raster_obj object of class raster to be extracted from
#' @param summary_fun the function to be used in computing zonal statistics
#' @param cpus number of CPUs for parallelization
#' @param parallel_model see `parallelMap::parallelLapply()` for more details
#'
#' @export
#' @import parallelMap

parallel_zonalext <- function(shp_dt,
                              raster_obj,
                              summary_fun,
                              cpus,
                              parallel_mode = "multicore"){


  cpus <- min(cpus, parallel::detectCores())

  parallelMap::parallelStart(mode = parallel_mode,
                             cpus = cpus,
                             show.info = FALSE)

  if (parallel_mode == "socket") {
    parallel::clusterSetRNGStream()
  }

  ##### split shp_dt into equal parts
  shp_dt <- split(shp_dt, 1:cpus)

  compute_zonal_stats <- function(shp_dt,
                                  raster_obj,
                                  summary_fun){

    shp_dt$result <- exact_extract(x = raster_obj,
                                   y = shp_dt,
                                   fun = summary_fun)

    return(shp_dt)

  }

  parallelMap::parallelLibrary("exactextractr")

  result_dt <- parallelMap::parallelLapply(xs = shp_dt,
                                           fun = compute_zonal_stats,
                                           raster_obj = raster_obj,
                                           summary_fun = summary_fun)

  parallelMap::parallelStop()

  return(result_dt)

}

###############################################################################################

#' A function to create an osmdata package readable bounding box (bbox)
#' with a buffer distance
#'
#'
#' @export
#' @importFrom osmdata getbb
#' @importFrom sf st_bbox
#' @importFrom crsuggest suggest_crs
#' @importFrom raster extent
#' @import dplyr

create_query_bbox <- function(shp_dt = NULL,
                              area_name,
                              buffer_dist = c(0, 0, 0, 0),
                              metric_crs = FALSE,
                              osm_crs = 4326){

  if (is.null(shp_dt)){

    bbox_obj <- getbb(area_name)

    bbox_obj <- sf::st_bbox(raster::extent(bbox_obj),
                            crs = osm_crs)

    if (is.null(buffer_dist) == FALSE){

      ### convert to metric scale
      bbox_obj <- sf::st_as_sfc(x = bbox_obj,
                                crs = osm_crs)

      suggest_dt <- crsuggest::suggest_crs(bbox_obj, units = "m")

      bbox_obj <- st_transform(bbox_obj,
                               crs = as.numeric(suggest_dt$crs_code[1]))

      bbox_obj <- st_bbox(bbox_obj)

    }

  } else {

    if (metric_crs == FALSE) {

      suggest_dt <- crsuggest::suggest_crs(st_as_sfc(st_bbox(shp_dt)),
                                           units = "m")

      bbox_obj <- st_transform(st_as_sfc(st_bbox(shp_dt)),
                               crs = as.numeric(suggest_dt$crs_code[1]))
    }

    bbox_obj <- sf::st_bbox(bbox_obj)

  }

  #### add buffer dist
  if (is.null(buffer_dist) == FALSE){

    bbox_obj[1] <- bbox_obj[1] - buffer_dist[1]
    bbox_obj[2] <- bbox_obj[2] - buffer_dist[2]
    bbox_obj[3] <- bbox_obj[3] + buffer_dist[3]
    bbox_obj[4] <- bbox_obj[4] + buffer_dist[4]


    ### recreate an st_as_sfc readable object
    if (metric_crs == TRUE) {

      bbox_obj <- sf::st_bbox(raster::extent(bbox_obj),
                              crs = st_crs(shp_dt)$input)

    } else {

      bbox_obj <- sf::st_bbox(raster::extent(bbox_obj),
                              crs = as.numeric(suggest_dt$crs_code[1]))

    }

      bbox_obj <- st_as_sfc(bbox_obj)

      bbox_obj <- st_transform(bbox_obj,
                               crs = osm_crs)

      bbox_obj <- sf::st_bbox(bbox_obj)

      ## convert to osm_bbox type
      bbox_obj <- matrix(c(bbox_obj[[1]],
                           bbox_obj[[3]],
                           bbox_obj[[2]],
                           bbox_obj[[4]]),
                         ncol = 2,
                         byrow = TRUE)

      colnames(bbox_obj) <- c("min", "max")
      rownames(bbox_obj) <- c("x", "y")


  }

  return(bbox_obj)


}


#########################################################################################################################
#' A function to clean and prepare geospatial lines (road network) data for measuring cost matrices
#'

clean_osmlines <- function(streets_obj){

  ### closed road is treated as a polygon so first convert to lines
  if (is.null(streets_obj$osm_polygons) == FALSE){

    closed_dt <- sf::st_cast(streets_obj$osm_polygons, "LINESTRING")

    closed_dt <- closed_dt[, c("osm_id", "highway", "surface", "geometry")]

  }

  if (is.null(streets_obj$osm_polygons) == FALSE){

    add_dt <- sf::st_cast(streets_obj$osm_multipolygons, "LINESTRING")

    add_dt <- add_dt[, c("osm_id", "highway", "surface", "geometry")]
  }



}


























<!-- README.md is generated from README.Rmd. Please edit that file -->

# Measuring Market Access of the Villages in Angola

### Introduction

An important goal of development in areas of transportation and land use
policy is improving the accessibility of the poor to basic services.
Angola is a country with 35.9 million people (Bank 2016) spread over a
vast area of nearly half a million square kilometers. The country is one
of the largest within the continent and a significant proportion of its
people live in remote areas. In addition, the transportation
infrastructure within the country which makes reaching those in need to
provide access to services remains a development challenge.
Consequently, a significant proportion of rural communities have no
markets or financial services which makes participation in the economy
more difficult particularly for the poor.

In this study, we apply data from open street maps (OSM) (OpenStreetMap
contributors 2017) on the available road infrastructure and the
locations of all markets and financial services within Angola. We use
this to measure the expected travel times from each village community
within the country to markets and financial services. This allows us to
answer the following questions:

- What is the spatial distribution of markets and financial services
  within the country?
- What is the spatial allocation of roads within the country?
- How accessible is each village community from their nearest
  market/financial service?

### The Methodology & Data

In measuring the expected length of time it takes each village community
to arrive at the nearest market or financial service, we combine the
community geolocation data from the 2018 census with the road network
map and the location of all markets and financial services within the
country. Specifically, we apply the following steps:

1)  We obtain and clean the community geolocated data to ensure each
    location is within the country and remove all incorrectly geocoded
    communities.

The locations of the 23088 geolocated communities spread across the
country as follows:

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

2)  We create a query box within which the locations of all markets,
    ATMs and Banks as well as the road network map will be return from
    the Open Street Map server. The query box is based on the geospatial
    extent of the country i.e. the maximum and minimum coordinate values
    intersecting the country in a square shape. Angola shares a border
    with Zambia to the East, Namibia to the South and the Democratic
    Republic of Congo (DRC) to the North. Like many other countries,
    individuals and families living close to the border in Angola are
    able to skip across to satisfy their needs without recourse to any
    disallowing border policies. Consequently, we add an additional 50km
    (upon expert advice) to the border to query box previous described
    to account for access to services in the neighboring countries.

We apply an OSM database GET query to extract locations of all markets,
ATMs and Banks within Angola based on the aforementioned query
paremeters. One disadvantage of the OSM data is that it is often
incomplete. To control for this, proxy OSM’s missing markets by
including the center of activity within each district to the data. We
identify these centers of activity using the WorldPop building footprint
data (Dooley et al. 2021) to find the 100 square meter tile in each
district with the highest building count. The result of the OSM database
GET query and the centers of activity within each district amount to
1771 potential destinations.

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />
Note: The map shows community locations (in blue) and markets, financial
services & district centers (in red)

3)  Likewise, we use the same query system to extract the road network
    system data within the country. We filter for the lines or
    multi-lines data with the following classifications: “motorway”,
    “primary”, “secondary”, “tertiary”, “unclassified”, “residential”,
    “trunk”, “road”, “motorway_link”,“trunk_link”, “primary_link”,
    “secondary_link”, “tertiary_link”. We apply a cleaning process to
    the road network lines data performing the following operations:

- Due to a large number of missing speed limits within the road segment
  data, we create a speed dictionary assigning an expected speed to each
  type of road. We apply adjustments for the surface quality of each
  road.

$$v_{rtq} = E(v_t)*\lambda_s$$

where $E(v_t)$ represents the speed for each road type and $\lambda_s$
is the adjustment factor for the surface types i.e. surfaces that are
rougher and make roads less suited for traffic should reduce $v$ for a
road $r$. We can now compute travel times for each road segment, $r$, as
follows:

$$\pi_{r} = \frac{D_{r}} {v_{rtq}}$$

i.e. The length of a road (distance) $D_{r}$ is a product of travel time
$pi_{r}$ and the expected speed of travel $v_{rtq}$.

We make structural adjustments to the road geometries obtained from OSM
to create a more realistic picture. These changes include deleting
redundant edges and loops, assuming all roads to be bi-directional and
we snap edges i.e. any two road edges ends within 30m of each other are
snapped into one road. This is because OSM roads are often inputted
manually and two roads that form a junction might not be properly mapped
living a space between two edges. Leaving this unconnected, creates
origins and destinations that seem unconnected or increase the expected
distance/time to destination. We used the accessibility (Pereira and
Herszenhut 2023) and tidyR (Wickham, Vaughan, and Girlich 2023) R
packages to make these changes.

<img src="man/figures/README-unnamed-chunk-4-1.png" width="100%" />

4)  Next, we blend origins (community locations), road network and
    destinations (markets and financial services). This allows us to
    create origin-destination cost matrices i.e. estimate the travel
    times from each community location to all destinations. Select, the
    minimum travel time for each community location as the expected
    travel time for each community to their nearest destination.

### Estimation Results

Below is a map of the spatial distribution of access to markets and
financial services within the country. The median travel time to nearest
market/financial centers is about 21.5 mins with an average of 28.4. Of
the 23088 villages, 2779 villages (12.04%) take over 1 hour to reach
markets, financial services and the district economic hubs.

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

This analysis contains two major flaws. Firstly, our travel times assume
that all households have an equal means of transport. While flawed, this
has the advantage of allowing us to focus on how long it would take a
household to arrive at its nearest market or financial service of
interest while keeping all other factors constant. Finally (and perhaps
more importantly), the open street maps database can be incomplete in
remote areas. We have attempted to compensate for this by supplementing
the data with district centers

<img src="man/figures/README-unnamed-chunk-6-1.png" width="100%" />

### Appendix

#### Speed Dictionary

<img src="man/figures/README-unnamed-chunk-7-1.png" width="100%" />

#### Road Surface Adjustments

<img src="man/figures/README-unnamed-chunk-8-1.png" width="100%" />

References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-wdi" class="csl-entry">

Bank, World. 2016. *World Development Indicators 2016*. World Bank
Publications - Books 23969. The World Bank Group.
<https://ideas.repec.org/b/wbk/wbpubs/23969.html>.

</div>

<div id="ref-wpopbuilding" class="csl-entry">

Dooley, C. A., D. R. Leasure, G. Boo, and A. J. Tatem. 2021. “Gridded
Maps of Building Patterns Throughout Sub-Saharan Africa, Version 2.0.”
Southampton, UK: University of Southampton.
<https://doi.org/10.5258/SOTON/WP00712>.

</div>

<div id="ref-OpenStreetMap" class="csl-entry">

OpenStreetMap contributors. 2017. “<span class="nocase">Planet dump
retrieved from https://planet.osm.org
</span>.”<a href=" https://www.openstreetmap.org " class="uri">
https://www.openstreetmap.org</a>.

</div>

<div id="ref-access" class="csl-entry">

Pereira, Rafael H. M., and Daniel Herszenhut. 2023. *Accessibility:
Transport Accessibility Measures*.
<https://CRAN.R-project.org/package=accessibility>.

</div>

<div id="ref-tidyr" class="csl-entry">

Wickham, Hadley, Davis Vaughan, and Maximilian Girlich. 2023. *Tidyr:
Tidy Messy Data*. <https://CRAN.R-project.org/package=tidyr>.

</div>

</div>

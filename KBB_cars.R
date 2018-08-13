rm(list = ls())
source("presets.R") # loads requires packages and custom functions
makes <- c("subaru/?", "nissan/?", "toyota/?", "honda/?", "hyundai/?", "kia/?")
d.miles <<- 25
zips <- c(80303, # Boulder, CO, USA
          33128, # Miami, Florida
          44113, #cleveland ohio
          93650 # Fresno, California
        )

outputFile <- paste0("data/", gsub("/","_", gsub("/?","", makes, fixed = T), fixed = T))
years <- seq(lubridate::year(Sys.Date())-20,lubridate::year(Sys.Date()),1)

# -- begin
sapply(zips, function(j){
  print(paste("--- Zipcode --- ", j))
  sapply(1:length(makes), function(i){
    outputFile <- paste0(outputFile, "_zip_",j)
    try(scarpe.kbb2(makes[i], years, outputFile[i],d.miles, j))
  })
})

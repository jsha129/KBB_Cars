# KBB_Cars
A data science driven approach to determine which cars depreciate the least based on the information available on the website [Kelley Blue Book](www.kbb.com).

# What is the problem?
Several factors influence a decision of buying a used car. While conventional wisdom definately has its place, I wanted to search for evidence-based results in making my decision. One of the important criteria for me in buying a car was to look for its depreciation value over time. Specifically, I wanted to buy a car that depreciates the least for short-term use of less than 3 years. 

Here, I web scrape Kelley Blue Book (KBB), a reputable website for searching for used cars in the US, to investigate how car values depreciate in general and identify which car make and model depreciates the least. In addition, I also examined effect of a location (city) on cost of specific car makes. 

# Approach
1. Write an R script that mines KBB for major makes of cars from several locations for last 20 years.
2. Assemble a **clean** data frame (data wrangling) with all information.
3. Apply linear regression to model value of a car over years, predict depreciation rate for all makes. Furthermore, to test if it is better to buy specific car models from a different city than Boulder, CO, USA, and to drive it back to Boulder, if feasible. 

All scripts are functional as of August 13, 2018.

# Disclaimer
[Kelley Blue Book](www.kbb.com) reserves the rights to the data.

# Minimal working example
## 1. Web scraping
Web scraping of KBB is performed by two R scripts:  [KBB_cars.R](/KBB_cars.R) and [presets.R](/presets.R). [KBB_cars.R](/KBB_cars.R) provides details on which car makes and city zip codes to search for whereas the actual functions for web scraping can be found in [presets.R](/presets.R). 

### Setting up information in [KBB_cars.R](/KBB_cars.R)
Change makes of cars, zip codes and distance from each zip codes as follows.
```r 
makes <- c("subaru/?", "nissan/?", "toyota/?", "honda/?", "hyundai/?", "kia/?") # note the format:  car make followed by '/?'  
d.miles <<- 25 # distance to search from each zips below. 
zips <- c(80303, # Boulder, CO, USA
          33128, # Miami, Florida
          44113, #cleveland ohio
          93650 # Fresno, California)

```

The script searches for past 20 years of data. You can change this by following: 

```r
years <- seq(lubridate::year(Sys.Date())*-20*,lubridate::year(Sys.Date()),1)
```






## 2. Data wrangling 

## 3. Statistical modelling to estimate depreciation rates

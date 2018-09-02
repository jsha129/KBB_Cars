# KBB_Cars
A data science driven approach to determine which cars depreciate the least based on the information available on the website [Kelley Blue Book](www.kbb.com).

# What is the problem?
Several factors influence a decision of buying a used car. While conventional wisdom definately has its place, I wanted to search for evidence-based results in making my decision. One of the important criteria for me in buying a car was to look for its depreciation value over time.

Here, I web scrape Kelley Blue Book (KBB), a reputable website for searching for used cars in the US, to investigate how car values depreciate in general and identify which car make and model depreciates the least. Furthermore, I also test which car would provide best value for money in a given price range. 
# Approach

All scripts are functional as of August 13, 2018.
## 1. Gather data using web scraping.
This project uses web scraping in R using the `rvest` package with the goal of collecting data for major makes of cars (user defined) from several locations for last 20 years. A user defines parameters such as makes of the cars of interest, zip codes of the cities of the sales and distance from the zip code. By default, the scripts looks for data over last 20 years, but this can be changed too. 

All parameters are defined in [KBB_cars.R](/KBB_cars.R). 

## 2. Prepare a data frame
First, CSS tags for each field were identified from the webpage and parsed to the `rvest::html_text()` and `rvest::html_node()` for extracting values. Most CSS tags returned unstructured text, and meaningful information was extracted using regular expression or converting the text to JSON object. 

Main function: `scarpe.kbb2()` and `get.veh.details()` - both defined in [presets.R](/presets.R).

## 3. Apply linear regression to estimate depreciation rate. 
This is performed by [analysis.R](/analysis.R). The log-linear model was applied to estimate initial cost of a make and its depreciation rate. Summaries for each make  are plotted as boxplots in [car_depr_by_year_simple.pdf](/car_depr_by_year_simple.pdf). Estimated depreciation rates are exported in [depreciation_rates.csv](/depreciation_rates.csv). 


# Disclaimer
[Kelley Blue Book](www.kbb.com) reserves the rights to the data. Only summary of the data has been shown here. 

# Minimal working example
## 1. Web scraping
Web scraping of KBB is performed by two R scripts:  [KBB_cars.R](/KBB_cars.R) and [presets.R](/presets.R). 

[KBB_cars.R](/KBB_cars.R) provides details on which car makes and city zip codes to search for whereas the actual functions for web scraping can be found in [presets.R](/presets.R) and should not require any modifications. 

### Setting up information in [KBB_cars.R](/KBB_cars.R)
Change makes of cars, zip codes and distance from each zip codes as follows.
Note the format:  car make followed by '/?'. 

```r 
makes <- c("subaru/?", "nissan/?", "toyota/?", "honda/?", "hyundai/?", "kia/?") # note the format:  car make followed by '/?'  
d.miles <<- 25 # distance to search from each zips below. 
zips <- c(80303, # Boulder, CO, USA
          33128, # Miami, Florida
          44113, #cleveland ohio
          93650 # Fresno, California)

```

The script searches for past 20 years of data. You can change this modifying **-20** in following code: 

```r
years <- seq(lubridate::year(Sys.Date())-20,lubridate::year(Sys.Date()),1)
```

Rest should work fine. See [KBB_cars.log](/KBB_cars.log) for the log when I ran the script.

## 2. Data wrangling 
Functions for data wrangling can be found in [presets.R](/presets.R). 

Although the details of unstructured text is not printed, the raw text for each car upon scraping is as follow:
-----
"\n\t\n\t\t\n\t\t\tUsed 2015 Subaru Forester 2.5i Limited\n\t\t\n\t\n\t\n\t\t\n\t\t\t\n\t\t\t\t\n\t\t\t\t\t\n\n\t\t\t\t\t\n\t\t\t\n\t\t\n\t\t\n\t\t\t\n\t\t\t\t\n\t\t\t\t\t$17,999\n\t\t\t\t\n\n\t\t\t\n\n\n\t\t\t\n\t\t\t\t\n\t\t\t\t\t\n\t\t\t\t\t\t\tMileage: 108,208\n\t\t\t\t\t\t\t\t\t\t\t\t\tExterior: Blue\n\t\t\t\t\t\t\t\t\t\t\t\t\tInterior: Gray\n\n\t\t\t\t\t\tVictory Motors of Colorado\n\n\t\t\t\t\t\t\t\t\n\t\t\t14 miles away\n\t\t\n\n\t\t\t\t\t\n\t\t\t\t\n\t\t\t\n\t\t\n\t\t\n\n\t\t\n\t\t\n\t\t\t\tVictory Motors of Colorado\n\n\t\t\t\t\t\n\t\t\t14 miles away\n\t\t\n\n\n\n\t\t\n\t\n\t\n\t\t\n\t\t\t\t\n\t\t\t\t\t\n\t\t\t\t\t44\n\t\t\t\t\n\n\t\t\n\t\tSponsored\n\t\n\n\n\t
**{\n\t\t\"@context\": \"http://schema.org/\",\n\t\t\"@type\": \"Car\",\n\t\t\"name\": \"Used 2015 Subaru Forester 2.5i Limited\",\n\t\t\"image\": \"//atcimages.kbb.com/scaler/152/114/hn/c/4e5c1f4a4c8842bdb094595cfc400521.jpg\",\n\t\t\"offers\": {\n\t\t\t\"@type\": \"Offer\",\n\t\t\t\"priceCurrency\": \"USD\",\n\t\t\t\"price\": \"17999\",\n\t\t\t\"itemCondition\": \"http://schema.org/UsedCondition\",\n\t\t\t\"availability\": \"http://schema.org/InStock\"\n\t\t},\n\t\t\"description\": \"Clean Car Fax w/ zero accidents and only 1 local owner. Features a reliable 2.5L 4CYL with seamless CVT automatic transmission and AWD. The exterior is Quartz Blue with fog lights, fresh tires, premium wheels, over sized moon roof, tinted windows and fog lights. The interior includes Gray leather, all season floor mats, cargo tray, Harmon Kardon Premium Sound, LCD display, backup camera, steering wheel mounted controls, heated seats, power windows/locks and much more!\",\n\t\t\"vehicleIdentificationNumber\": \"JF2SJARC0FH542624\",\n\t\t\"brand\": \"Subaru\",\n\t\t\"mileageFromOdometer\": {\n\t\t\t\"@type\": \"QuantitativeValue\",\n\t\t\t\"value\": \"108208\"\n\t\t},\n\t\t\"color\": \"Blue\",\n\t\t\"vehicleInteriorColor\": \"Gray\",\n\t\t\"vehicleTransmission\": \"Continuously Variable Automatic\",\n\t\t\"vehicleEngine\": \"4-Cylinder\",\n\t\t\"bodyType\": \"Sport Utility\"\n\t}**\n"     

-----

Valuable information/fields were extracted using a combination of `rvest`, `purrr` packages, regular expression and converting string to JSON object. 

```r
get.veh.details <- function(webpage){
  # Main function, returns a data frame of results.
  require(rvest)
  require(purrr)
  
  # CSS Element names
  css.veh.name <- ".js-vehicle-name"# ".title-three.vehicle-name"
  css.veh.details <- ".js-used-listing" # unstructured text
  css.veh.price <- ".highlight"
  
  # webpage <- read_html(url)
  veh.full.name <- html_text(html_nodes(webpage, css.veh.name)) 
  veh.full.name <- cleanStr(veh.full.name) # Extracted text: Used 2015 Subaru Forester 2.5i Limited
  split.veh.name <- strsplit(veh.full.name," ")
  veh.submodel <- sapply(split.veh.name, function(i){ 
    if(length(i) > 4){ # Submodel is not always reported, using 'length' of the outcome of strsplit as condition
      return(paste0(i[5])) 
    }
    else{
      return(c(""))
    }
  })
  veh.price <- html_text(html_nodes(webpage, css.veh.price))
  veh.price <- as.numeric(gsub("$", "", cleanStr(veh.price), fixed = T))
  
  veh.details <- html_text(html_nodes(webpage,css.veh.details))
  # print(veh.details) # THIS IS THE TEXT SHOWN ABOVE.
  strTojson <- invisible(lapply(veh.details, function(i){ 
  # there was a hidden JSON object in the raw text. using 'rjson' package to convert it to list
    start_curly <- map_int(gregexpr("\\{.*\\}*", i),1)
    # print(start_curly)
    temp <- substr(i, start = start_curly, nchar(i))
    return(temp)
  }))
  
  ### REST OF THE FUNCTION IS NOT SHOWN
}
```

The final data looks as follow:
![](/DF_structure.png)

## 3. Statistical modelling to estimate depreciation rates
See [analysis.R](/analysis.R) for  complete code. 
### Modelling price of a car based on its age - an overview
I used exploratory data analysis (EDA) to visualise how age of a car affects its price for all makes and models. From the graph on left below, the price of a car, in general, seem to follow 'exponential decay model' in response to its age. I plotted the data after applying log 10 transformation, and the log-transformed price of a car and its age appear to follow a linear relationship. 

![](/car_depr_overview.png)
This relationship is mathematically represented as follow: 

<a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;\large&space;log&space;(Price)&space;=&space;\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\epsilon" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;\large&space;log&space;(Price)&space;=&space;\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\epsilon" title="\large log (Price) = \beta_0 + \beta_1 (Age) + \epsilon" /></a>

where log 10 (Price) is the response variable and age of a car is the predictor variable. B0 is a constant of the model, B1 is cofficient of Age (ie contribution of each year to a car's price) and e is error or unexplained variation of the model. 

Linear Model:

```r
fit.yearly.dep <- lm(log10(Price) ~ as.numeric(Age_year), df)
summary(fit.yearly.dep)

## OUTPUT
Call:
lm(formula = log10(Price) ~ as.numeric(Age_year), data = df)

Residuals:
     Min       1Q   Median       3Q      Max 
-1.25547 -0.09630 -0.00827  0.08752  0.84864 

Coefficients:
                       Estimate Std. Error t value Pr(>|t|)    
(Intercept)           4.3600791  0.0024445 1783.62   <2e-16 ***
as.numeric(Age_year) -0.0404717  0.0004103  -98.65   <2e-16 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Residual standard error: 0.147 on 11701 degrees of freedom
Multiple R-squared:  0.4541,	Adjusted R-squared:  0.454 
F-statistic:  9732 on 1 and 11701 DF,  p-value: < 2.2e-16

```
Note the intercept of 4.36. Since the data is Log10-transformed, we will need to reverse it by using 10^4.36 = 22908.68, which is initial price of cars when Age_year = 0. The coefficient for Age_year is -0.04; therefore, the model would estimate price of a 10 year old car to be 10^(4.4 - 10 x 0.04) = 10,000 USD. This analysis, of course, does not consider how a specific make and model of a car modify the estimate, which we will do next. 

We will be applying log-linear model for rest of the case study.

### Estimating depreciation rate for car makes and models
Currently, the data frame has separate columns for Make (ie Honda) and Models (Accord). We **could** use make and models as the predictor variables. However, this would imply that the model would use every perumtations of make and models to estimate the coefficients, which would be inaccurate in the real world because combinations such as 'Toyota Accord' and 'Honda Corolla' would not exist. To simplify  math and improve accuracy, I first create a variable 'ID' that is simply concatenation of make_model. 

EDA of each car make and model can be found in [car_depr_by_year_simple.pdf](/car_depr_by_year_simple.pdf)

Next, we add the 'ID' variable in the original linear model comprising of a car's age.

<a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;\large&space;log&space;(Price)&space;=&space;\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\beta_2&space;(ID)&plus;\epsilon" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;\large&space;log&space;(Price)&space;=&space;\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\beta_2&space;(ID)&plus;\epsilon" title="\large log (Price) = \beta_0 + \beta_1 (Age) + \beta_2 (ID)+\epsilon" /></a>

where B2 is coefficient for the ID variable, ie the depreciation rate for a specific car make and model.

Obviously, we will need to reverse the effect of Log 10 transformation when predicting the actual Price of a car on linear scale, which is given by following equation:

<a href="https://www.codecogs.com/eqnedit.php?latex=\fn_phv&space;\large&space;Price&space;=&space;10^{\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\beta_2&space;(ID)&plus;\epsilon}" target="_blank"><img src="https://latex.codecogs.com/gif.latex?\fn_phv&space;\large&space;Price&space;=&space;10^{\beta_0&space;&plus;&space;\beta_1&space;(Age)&space;&plus;&space;\beta_2&space;(ID)&plus;\epsilon}" title="\large Price = 10^{\beta_0 + \beta_1 (Age) + \beta_2 (ID)+\epsilon}" /></a>

```r
fit.yearly.dep <- lm(log10(Price) ~ ID + as.numeric(Age_year), df)
coeff <- summary(fit.yearly.dep)$coefficients
print(coeff[c(1:3, nrow(coeff)),])

## OUTPUT
                        Estimate   Std. Error     t value     Pr(>|t|)
(Intercept)           4.40367762 0.0038581329 1141.401214 0.000000e+00
IDHonda_Civic        -0.04989184 0.0050281548   -9.922496 4.107618e-23
IDHonda_CR-V          0.07200138 0.0052078311   13.825599 3.922797e-43
as.numeric(Age_year) -0.04896388 0.0002708975 -180.746897 0.000000e+00

Residual standard error: 0.08996 on 11605 degrees of freedom
Multiple R-squared:  0.7971,	Adjusted R-squared:  0.7954 
F-statistic:   470 on 97 and 11605 DF,  p-value: < 2.2e-16
```
First, compare the residual standard error of 0.08996 when adding ID compared to 0.147 from the previous model that only used Age_year as the predictor. A reduction in error suggests that ID improves the model.

The 'Estimate' column in the above table represents the depreciation rate (on Log 10 scale) **in addition** to the effect of age of a car. Because certain  car makes such as Kia_Rondo have incomplete data, they would have high 'Std. Error'. In addition, we have a total of 97 IDs, which will look data messy and hard to get a clear message. Here, I only select the IDs with  SEM <= median SEM (lowest 50% SEM) and colour-code them for clarity, but raw data of estimates and SEM can be found in [depreciation_rates.csv](/depreciation_rates.csv).


![Low_depriciating_cars.png](/Low_depriciating_cars.png)

In the graph above,  IDs with Depreciation rate >0 (or close to 0) filled with solid black bars would retain the value the most. Starting from the top, Toyota_Tacoma actually has a positive depreciation rate, suggesting that it could overcome the loss in value imposed by age of a car to a limit; however, as the age increase this advantage would be lost (age > 10 years or so). Subaru_Outback, Toyota_Rav_V, Honda_CR-V, Hyundai_Santa, Kia_Sorento and so on should be retain their values over time, according to the KBB data. Toyota_Camry and Honda_Civic also do well in the graph above (having low SEM), although they do present with a low, negative depreciation rate.

It is important to acknowledge the limitation of the data. IDs with low SEM may still not fit the data well. 

###  Which car in a given price range is less depreciated in a range of similarly priced car?

In the analysis using log-linear model above, the constant B0 is common to ALL car makes and models ('ID' variable). To estimate the B0 for each ID, I build a linear model for each ID using the R function `lapply()` and plot estimated cost of a new car on x axes versus depreciation rate on high confidence records.

```r
model.fit <- lapply(unique(df$ID), function(i){
  j <- subset(df, ID == i)
  j$Age_year <- as.numeric.factor(j$Age_year)
  fit <- lm (log10(Price) ~ Age_year, j) # one factor
  return(data.frame(ID=  i,
                    Gradient = fit$coefficients["Age_year"], 
                    R.squared = summary(fit)$r.squared,
                    Residual_Std_Error = summary(fit)$sigma,
                    Initial.Price = 10^fit$coefficients[1],
                    Year.history = length(unique(as.factor(j$Age_year)))))
})

yearly.dep <- Reduce(rbind,model.fit)
yearly.dep <- na.omit(yearly.dep)

# -- selecting only high confidence records below
yearly.dep <- subset(yearly.dep, R.squared >= 0.5 &
                       Initial.Price < 1E5 & Initial.Price >2E3 &
                       Year.history >= 10)
```
![](/yearly_dep_rate.png)



Let's say that someone wants to buy cars for $20,000. The graph above suggests that Hyndai_Sonata depreciates more than Toyota_Camry. To test whether above prediction is correct, I plot median price of each car over time to visually compared different cars and how they depreciate. 

![](/best_cars_3_price.png)

In the figure on left in above ($20,000), the blue line representing Toyota_Camry is above than 'red' and 'green', suggesting that Camry retains its value more and Hyundai_Sonata ('green' line) indeed depreciates more than other cars in the price range. 


I repeat this analysis for budget of $25,000 (Nissan_Frontier versus Kia_Sorento) and $40,000 (Toyota_4Runner versus Honda_Pilot; middle and right figure in above, respectively). In general, the prediction made from above holds true. Furthermore, it is consistent with the linear model (black and white bar graph above).

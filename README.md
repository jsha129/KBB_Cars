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
Web scraping of KBB is performed by two R scripts:  [KBB_cars.R](/KBB_cars.R) and [presets.R](/presets.R). [KBB_cars.R](/KBB_cars.R) provides details on which car makes and city zip codes to search for whereas the actual functions for web scraping can be found in [presets.R](/presets.R) and should not require any modifications. 

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

The script searches for past 20 years of data. You can change this modifying **-20** in following code: 

```r
years <- seq(lubridate::year(Sys.Date())-20,lubridate::year(Sys.Date()),1)
```

Rest should work fine. See [KBB_cars.log](/KBB_cars.log) for the log when I ran the script.

## 2. Data wrangling 

The final data looks as follow:
![](/DF_structure.png)

## 3. Statistical modelling to estimate depreciation rates
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

The 'Estimate' column in the above table represents the depreciation rate (on Log 10 scale). Because certain  car makes such as incomplete data, they would have high 'Std. Error' which we will use in the graph below for visualisation. 

![](/car_depr_rates.png)








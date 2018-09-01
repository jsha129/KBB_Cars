# KBB_Cars
A data science driven approach to determine which cars depreciate the least based on the information available on the website [Kelley Blue Book](www.kbb.com).

# What is the problem?
Several factors influence a decision of buying a used car. While conventional wisdom definately has its place, I wanted to search for evidence-based results in making my decision. One of the important criteria for me in buying a car was to look for its depreciation value over time.

Here, I web scrape Kelley Blue Book (KBB), a reputable website for searching for used cars in the US, to investigate how car values depreciate in general and identify which car make and model depreciates the least. Furthermore, I also test which car would provide best value for money in a given price range. 
# Approach
1. Write an R script that mines KBB for major makes of cars from several locations for last 20 years.
2. Assemble a **clean** data frame (data wrangling) with all information.
3. Apply linear regression to model value of a car over years, predict depreciation rate for all makes. 

All scripts are functional as of August 13, 2018.

# Disclaimer
[Kelley Blue Book](www.kbb.com) reserves the rights to the data. Only summary of the data has been shown here. 

# Minimal working example
## 1. Web scraping
Web scraping of KBB is performed by two R scripts:  [KBB_cars.R](/KBB_cars.R) and [presets.R](/presets.R). 

[KBB_cars.R](/KBB_cars.R) provides details on which car makes and city zip codes to search for whereas the actual functions for web scraping can be found in [presets.R](/presets.R) and should not require any modifications. 

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

The 'Estimate' column in the above table represents the depreciation rate (on Log 10 scale) **in addition** to the effect of age of a car. Because certain  car makes such as Kia_Rondo have incomplete data, they would have high 'Std. Error'. In addition, we have a total of 97 IDs, which will look data messy and hard to get a clear message. Here, I only select the IDs with  SEM <= median SEM (lowest 50% SEM) and colour-code them for clarity, but raw data of estimates and SEM can be found in [depreciation_rates.csv](/depreciation_rates.csv).


![Low_depriciating_cars.png](/Low_depriciating_cars.png)

In the graph above,  IDs with Depreciation rate >0 (or close to 0) filled with solid black bars would retain the value the most. Starting from the top, Toyota_Tacoma actually has a positive depreciation rate, suggesting that it could overcome the loss in value imposed by age of a car to a limit; however, as the age increase this advantage would be lost (age > 10 years or so). Subaru_Outback, Toyota_Rav_V, Honda_CR-V, Hyundai_Santa, Kia_Sorento and so on should be retain their values over time, according to the KBB data. Toyota_Camry and Honda_Civic also do well in the graph above (having low SEM), although they do present with a low, negative depreciation rate.

It is important to acknowledge the limitation of the data. IDs with low SEM may still not fit the data well. 

### Which car to buy in a given price range?
Question: Which car in a given price range is less depreciated in a range of similarly priced car?

In the analysis using log-linear model above, the constant B0 is generic to ALL car makes and models ('ID' variable). To estimate the B0 for each ID, I build a linear model for each ID using the R function `lapply()` and plot estimated cost of a new car on x axes versus depreciation rate on high confidence records.

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


I repeat this analysis for budget of $25,000 and $40,000 (middle and right figure in above, respectively). In general, the prediction made from above holds true. 


















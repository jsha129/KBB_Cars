# KBB_Cars
A data science driven approach to determine which cars depreciate the least based on the information available on the website [Kelley Blue Book](www.kbb.com).

# What is the problem?
Several factors influence a decision of buying a used car. While conventional wisdom definately has its place, I wanted to search for evidence-based results in making my decision. One of the important criteria for me in buying a car was to look for its depreciation value over time. Specifically, I wanted to buy a car that depreciates the least for short-term use of less than 3 years. 

Here, I web scrape Kelley Blue Book (KBB), a reputable website for searching for used cars in the US, to investigate how car values depreciate in general and identify which car make and model depreciates the least. In addition, I also examined effect of a location (city) on cost of specific car makes. 

# Approach
1. Write an R script that mines KBB for major makes of cars from several locations for last 20 years.
2. Assemble a **clean** data frame (data wrangling) with all information.
3. Apply linear regression to model value of a car over years, predict depreciation rate for all makes. Furthermore, to test if it is better to buy specific car models from a different city than Boulder, CO, USA, and to drive it back to Boulder, if feasible. 

# Disclaimer
[Kelley Blue Book](www.kbb.com) reserves the rights to the data.

# Minimal working example
## 1. Web scraping
Web scraping of KBB is performed by two R scripts:  'KBB_cars.R' and 'presets.R'. 

## 2. Data wrangling 

## 3. Statistical modelling to estimate depreciation rates

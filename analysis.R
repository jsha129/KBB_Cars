rm(list = ls())
source("presets.R")
### -- Merging all files into one and cleaning them
data_dir <- paste0(getwd(), "/data/")
files <- as.list(list.files(data_dir)[grep(".txt",list.files(data_dir))])
files2 <- lapply(files, function(i){
  read.delim(paste0(data_dir,i))
})
df <- Reduce(rbind, files2)
df$Age_year <- max(df$Year) - df$Year
df$Avg_annual_mileage <- ifelse(df$Age_year>=0, df$Mileage/df$Age_year, df$Mileage)
df$ID <- paste(df$Make, df$Model,sep = "_")

## cleaning up data: removing duplicates 
df <- dplyr::distinct(df)
df$UniqueID <-  paste(df$Year,df$Make, df$Model, df$Mileage, df$Price, sep = "_")
length(unique(df$UniqueID)) # dplyr::distinct cleans up data really well. subsetting by uniqueID is not required.
temp <- table(df$UniqueID)
temp <- sort(temp)
table(temp) # tells single, duplicated etc 
temp <- temp[which(temp  == 1)]
df <- subset(df, UniqueID %in% names(temp))
df <- subset(df, Mileage <=2E5 & Year >=1998)

## formating data for factors etc
df <- transform(df, 
                Year = as.factor(df$Year),
                Age_year = as.factor(df$Age_year),
                Zipcode = as.factor(df$Zipcode))


### -- Analysis 
## General pattern on how cars depreciate on linear scale for all models and makes
p_linear <- ggplot(subset(df, Price <= 50000), aes(x = Age_year, y= Price)) +
  geom_boxplot() +
  labs(title = "Modelling cost of a car - linear scale", x = "Age of a car, years", y = "Price, USD") +
  theme_bw()

p_log <- ggplot(subset(df, Price <= 50000), aes(x = Age_year, y= Price)) +
  geom_boxplot() +scale_y_log10(breaks = seq(0, 30000, 2000)) +
  labs(title = "Modelling cost of a car - log scale", x = "Age of a car, years", y = "Log10 (Price), USD") +
  theme_bw()
png("car_depr_overview.png", width = 8, height = 4, units = "in", res = 150)
print(ggarrange(plotlist = list(p_linear, p_log)))
dev.off()

## General Linear Model
fit.yearly.dep <- lm(log10(Price) ~ ID + as.numeric.factor(Age_year), df)
coeff <- summary(fit.yearly.dep)$coefficients
write.table(coeff,file = "depreciation_rates.csv", sep =",", row.names = T)
print(coeff[c(1:3, nrow(coeff)),]) # to show what they mean

coeff2 <- as.data.frame(coeff)
coeff2 <- coeff2[c(2:(nrow(coeff2)-1)),] # removes intercept and age
coeff2$ID <- gsub("ID", "", rownames(coeff2))
colnames(coeff2) <- c("Depreciation_rate", "SEM", "t-stat", "P_value", "ID")

coeff2 <- subset(coeff2, SEM <= quantile(SEM, 0.5)) # lowest 50% SEM
coeff2 <- coeff2[order(coeff2$Depreciation_rate),]
coeff2$ID <- factor(coeff2$ID, levels =coeff2$ID)
png("Low_depriciating_cars.png", width = 5, height = 6, units = "in", res = 150)
p <- ggplot(coeff2, aes(x = ID, y = Depreciation_rate, fill = SEM)) +
  geom_bar(stat = "identity") + 
  scale_fill_gradient(high = "white", low = "black") +
  coord_flip()
p
dev.off()

### Looping through each Make_Model to improve prediction
cars <- unique(df$ID)
# cars <-  c("Honda_Accord", "Toyota_Corolla", "")
# graph
pdf("car_depr_by_year_simple.pdf", width = 8, height = 4, onefile = T)
sapply(cars, function(i){
  j <- subset(df, ID == i)
  p_linear <- ggplot(j, aes (x= Age_year, y = Price)) +
    geom_boxplot() +
    labs(title = paste(i, "Linear scale", sep=" - "), x = "Age of a car, years", y = "Price, USD") +
    theme_bw()
  p_log <- ggplot(j, aes (x= Age_year, y = Price)) +
    geom_boxplot() + scale_y_log10(breaks = seq(0, 30000, 2000)) +
    labs(title = paste(i, "Log10 scale", sep=" - "), x = "Age of a car, years", y = "Log10 (Price), USD") +
    theme_bw()
  # print(p)
  print(ggarrange(plotlist = list(p_linear, p_log)))
})
dev.off()

## Modelling actual cost of an ID (Make_Model/Toyota_Yaris) by one factor, its age
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
yearly.dep <- subset(yearly.dep, R.squared >= 0.5 &
                       Initial.Price < 1E5 & Initial.Price >2E3 &
                       Year.history >= 10)


png("yearly_dep_rate.png", width = 8, height = 6, units = "in", res = 150)
p <- ggplot(yearly.dep, aes(x = Initial.Price, y = Gradient, colour = R.squared))+
  geom_point(size = 3) +
  labs(title ="", x = "Estimated cost of a new car (USD)", y="Depreciation rate" ) + 
  scale_colour_gradient(high = "black", low = "red") +
  geom_text_repel(aes(label = ID), size = 3)
p
dev.off()


### Plotting a few makes and cars
# select_cars <- c("Honda_Civic", "Toyota_Corolla", "Kia_Rio")
p1 <- plotMedianCost(cars = c("Toyota_Camry", "Honda_Civic", "Hyundai_Sonata"), "New car for $20,000")
p2 <- plotMedianCost(cars = c("Nissan_Frontier", "Toyota_RAV4", "Kia_Sorento", "Honda_CR-V"), "New car for $25,000")
p3 <- plotMedianCost(cars = c("Honda_Pilot", "Nissan_Armada", "Toyota_4Runner"), "New car for $40,000")
png("best_cars_3_price.png", width = 10, height = 4, units = "in", res = 150)
ggarrange(plotlist = list(p1,p2,p3), ncol =3 )
dev.off()

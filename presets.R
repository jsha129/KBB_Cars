### Required packages
list.of.packages <- c("rvest", "rjson", "purrr", "lubridate", 
                      "dplyr", "reshape2", "ggplot2", "ggrepel", "ggpubr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) {install.packages(new.packages)}

### -- Preset, loads all of above packages
lapply(list.of.packages, require, character.only = TRUE)

### -- functions

as.numeric.factor <- function(x) {as.numeric(levels(x))[x]} # converts factors -> numbers

returnJSONField <- function(list, field = "name"){
  # converts a string in JSON format to R list and returns desired field.
  result <- sapply(list, function(i){
    temp <- fromJSON(i)[[field]]
    # return(temp[[field]])
  })
  result
}
cleanStr <- function(text){
  # This functions removes unnecessary characters from a string
  original <- c("\"", "\n","&", "/",",", "\t")
  replacement <- c("","","", "","", "")
  
  for(i in 1:length(original)){
    text <- gsub(original[i], replacement[i] , text, fixed = T)
  }
  return(text)
}
extract.values <- function(text, searchTxt, endStr = "\r", type ="text"){
  # extracts value based on
  if(regexpr(searchTxt, text) < 0){
    value <- NA
  } else {
    start <- regexpr(searchTxt, text)[1] + nchar(searchTxt)
    end <- (start + regexpr("\r\n", substr(text, start, nchar(text)))[1])-2
    value <- gsub(" ", "", substr(text, start = start, stop = end))
    
    if(type == "number"){value <- as.numeric(gsub(",", "", value))}
  }
  
  return(value)
}
get.veh.details <- function(webpage){
  # Main function, returns a data frame of results.
  require(rvest)
  require(purrr)
  
  # CSS Element names
  css.veh.name <- ".js-vehicle-name"# ".title-three.vehicle-name"
  css.veh.details <- ".js-used-listing"
  css.veh.price <- ".highlight"
  
  # webpage <- read_html(url)
  veh.full.name <- html_text(html_nodes(webpage, css.veh.name))
  veh.full.name <- cleanStr(veh.full.name)
  split.veh.name <- strsplit(veh.full.name," ")
  veh.submodel <- sapply(split.veh.name, function(i){
    if(length(i) > 4){
      return(paste0(i[5]))
    }
    else{
      return(c(""))
    }
  })
  veh.price <- html_text(html_nodes(webpage, css.veh.price))
  veh.price <- as.numeric(gsub("$", "", cleanStr(veh.price), fixed = T))
  
  veh.details <- html_text(html_nodes(webpage,css.veh.details))
  strTojson <- invisible(lapply(veh.details, function(i){
    start_curly <- map_int(gregexpr("\\{.*\\}*", i),1)
    # print(start_curly)
    temp <- substr(i, start = start_curly, nchar(i))
    return(temp)
  }))
  
  df <- data.frame(Name = veh.full.name,
                   Make = map_chr(split.veh.name,3),
                   Model = map_chr(split.veh.name,4),
                   SubModel = veh.submodel,
                   Year = as.factor(map_chr(split.veh.name, 2)),
                   Price = veh.price,
                   Mileage = unlist(returnJSONField(strTojson, "mileageFromOdometer")["value",]),
                   Exterior = returnJSONField(strTojson, "color"),
                   Engine = returnJSONField(strTojson, "vehicleEngine"),
                   Zipcode = zip.code,
                   Distance = d.miles)
  
  return(df)
  
}
scarpe.kbb2 <- function(car.make,
                        years= seq(lubridate::year(Sys.Date())-20,lubridate::year(Sys.Date()),1), # default: 20 years from current year to present.
                        outputFile,
                        d.miles, 
                        zip.code){
  # web scraping function
  #  This version gets rid of loop for each year and uses a range of years in one instance. This is because the loop breaks when 0 cars are found in a given year.
  zip.code <<- zip.code
  print(car.make)
  years <- paste(min(years), max(years) , sep = "-")
  small.url <- paste0("https://www.kbb.com/cars-for-sale/cars/used-cars/",
                      car.make,
                      "distance=", d.miles,
                      "&nr=100",
                      "&p=1",
                      "&s=derivedpriceasc",
                      "&year=", years,
                      "&zipcode=", zip.code)
  # print(small.url)
  webpage <- read_html(small.url)
  desp <- html_text(html_nodes(webpage, ".filter-highlight")) # tells how many results returned
  # print(desp)
  n.cars <- as.numeric(gsub(",", "", strsplit(desp[1]," ")[[1]][1]))
  print(paste(n.cars," cars found in Year:", years))
  if(n.cars >= 0){
    cars.one.year <- lapply(1:ceiling(n.cars/100), function(i){
      print(paste("running page", i))
      small.url <- paste0("https://www.kbb.com/cars-for-sale/cars/used-cars/",
                          car.make,
                          "distance=", d.miles,
                          "&nr=100",
                          "&p=",i,
                          "&s=derivedpriceasc",
                          "&year=", years,
                          "&zipcode=", zip.code)
      # print(small.url)
      get.veh.details(read_html(small.url))
    })
  }
  massive.df <- Reduce(rbind, cars.one.year)
  
  
  final.df <- massive.df
  # write.table(final.df, file = paste0(outputFile,"_raw.txt"), row.names = F, sep ="\t")
  
  # Cleaning up
  final.df <- dplyr::distinct(final.df) # Removes duplicated values
  final.df <- transform(final.df, 
                        Mileage = as.numeric.factor(Mileage))
  # print(str(final.df))
  final.df <- final.df[!(is.na(final.df$Price) | is.na(final.df$Mileage)),] #removing NA
  final.df[final.df$Mileage < 500, "Mileage"] <- final.df[final.df$Mileage < 500, "Mileage"]*1000 # Multiplying by 1000 where Mileage are given in K, ie 180 instead of 180,000
  
  write.table(final.df, file = paste0(outputFile,".txt"), row.names = F, sep ="\t")
  
}
plotMedianCost <- function(cars, plottitle=""){
  select_df <- subset(df, ID %in% cars)
  # print(str(select_df))
  select_df_agg <- aggregate(select_df$Price, by = list(select_df$ID, select_df$Age_year), median)
  colnames(select_df_agg) <- c("ID", "Age_year", "Median_price")
  
  p <- ggplot(select_df_agg, aes(x = Age_year, y = Median_price, colour = ID, group = ID)) +
    geom_line() +
    geom_point(size = 2) + 
    labs(title = plottitle, x = "Age in years", y = "Median Price, USD") +
    guides(colour=guide_legend(ncol=1, title = NULL)) +
    theme(legend.position = "bottom")
  return(p)
}


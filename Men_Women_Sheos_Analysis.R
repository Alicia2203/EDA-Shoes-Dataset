# ANALYTICS ENGINEERING GROUP ASSIGNMENT

# load libraries
library(tidyverse)
library(ggplot2)
library(flextable)

# set working directory where the csv file located
setwd("C:/Users/User/Documents/My SAS Files/AE Assignment/Output")

# Read cleaned Women and Men shoes data set in csv format
WomenShoes = read.csv(file="WomenShoe_clean.csv", header=TRUE, sep=",")
MenShoes = read.csv(file="MenShoe_clean.csv", header=TRUE, sep=",")

# Convert price variable as numeric type
WomenShoes$price = as.numeric(WomenShoes$price)
MenShoes$price = as.numeric(MenShoes$price)

# Create variable Gender
WomenShoes$gender = "Women"
MenShoes$gender = "Men"

# Merge Women Shoes and Men Shoes data frame
all_shoes = rbind(WomenShoes,MenShoes)

# Structure of the data
glimpse(all_shoes)

# Compute Median price grouped by Brand and Gender
all_median_price = all_shoes %>%
  group_by(brand, gender) %>%
  summarise(price = median(price, na.rm =TRUE))

########################## Box Plot of Gender vs Price #######################

qplot(gender, price, data = all_median_price, 
      geom = "boxplot", fill = gender ) +
  labs(title="Box Plot of Gender vs Price")+
  labs(y="Price", x="Gender")


######### Bar chart for top most expensive brands (women and men) #############

# Top 20 most expensive brands (Women)
women_top20 = WomenShoes %>%
  group_by(brand) %>%
  summarise(price = median(price, rm.na=true)) %>%
  arrange(desc(price)) %>%
  top_n(20) %>%
  ggplot(mapping = aes(x=reorder(brand, price), y=price)) +
  geom_bar(stat = "identity", aes(fill=price)) +
  theme_light() +
  scale_colour_gradient() +
  coord_flip() +
  labs(title="Top 20 Expensive brands (Women)", 
       x="Brand", y="Median Price (USD)")
women_top20

# Top 20 most expensive brands (Men)
men_top20 = MenShoes %>%
  group_by(brand) %>%
  summarise(price = median(price, rm.na=true)) %>%
  arrange(desc(price)) %>%
  top_n(20) %>%
  ggplot(mapping = aes(x=reorder(brand, price), y=price)) +
  geom_bar(stat = "identity", aes(fill=price)) +
  theme_light() +
  scale_colour_gradient() +
  coord_flip() +
  labs(title="Top 20 Expensive brands (Men)", 
       x="Brand", y="Median Price (USD)")
men_top20

########### Kernel Density Plots for distrubution of price ##################### 

# Density Plot of Median Price (0-10000 USD)
all_median_price %>% 
  subset(price < 10000) %>% 
  ggplot(aes(x=price, fill=gender, colour=gender)) + geom_density(alpha=.3) +
  labs(title="Density Plot of Median Price (0-10000 USD)")+
  labs(y="Price", x="Density")

# Density Plot of Median Price with log ##
all_median_price %>% 
  ggplot(aes(x=log(price+1), fill=gender, colour=gender)) + 
  geom_density(alpha=.3) +
  labs(title="Density Plot of Median Price (after log transformation)")+
  labs(y="Price", x="Density")

################# Crete brand_group data frame ##############################

# Compute the frequency count for each brand by gender
Men_brandfreq = MenShoes %>% count(brand)
Women_brandfreq = WomenShoes %>% count(brand)

# Compute Median price grouped by Brand for WomenSheos and MenShoes
men_median_price = MenShoes %>%
  group_by(brand) %>%
  summarise(price = median(price, na.rm =TRUE))

women_median_price = WomenShoes %>%
  group_by(brand) %>%
  summarise(price = median(price, na.rm =TRUE))

# Create new data frame by combining the median price and frequency count 
Men_by_brand = cbind(men_median_price, count=Men_brandfreq$n)
Women_by_brand = cbind(women_median_price, count=Women_brandfreq$n)


# Merge both Women_by_brand and Men_by_brand data frame by brand
brand_group = merge(Men_by_brand,Women_by_brand,by="brand",all=TRUE)%>%
  rename(men_median_price = price.x,
         men_brand_count = count.x,
         women_median_price = price.y,
         women_brand_count = count.y)

# Find the percentage of shoes for each brand by gender
men_percent = brand_group$men_brand_count/
  (brand_group$men_brand_count+brand_group$women_brand_count)*100

women_percent = brand_group$women_brand_count/
  (brand_group$men_brand_count+brand_group$women_brand_count)*100

# Find the total count of shoes for each brand regardless of gender
total_count = brand_group$men_brand_count + brand_group$women_brand_count

# Find the price difference between men and women shoe median price 
median_price_diff = abs(brand_group$men_median_price - 
                          brand_group$women_median_price)

# Combine men_percent, women_percent and total_count with brand_group
brand_group = brand_group %>% cbind(men_percent = round(men_percent),
                                    women_percent = round(women_percent),
                                    total_count,median_price_diff)

############### Crete top20_brand dataframe ####################################

# Top 20 brand from brand_group based on brand total count
top20_brand = brand_group %>% 
  subset(brand != "UNBRANDED" & brand != "SUPERIOR GLOVE WORKS"
         & brand != "BERNE APPAREL" & brand != "FUSE LENSES") %>%
  arrange(desc(total_count)) %>%
  head(20)

# Crate rank variable 
top20_brand$rank = seq.int(nrow(top20_brand)) 

# reorder column in top20_brand
col_order =  c( "rank", "brand", "total_count", "men_brand_count",
                "women_brand_count","men_percent", "women_percent", 
                "men_median_price","women_median_price", 
                "median_price_diff")
top20_brand  =  top20_brand[, col_order]

###########  Create table of product listing percentage with flextable #########

flextable( data = top20_brand, col_keys = c("rank", "brand", "total_count",
                                            "men_percent","women_percent")) %>%
  
  # rename header labels
  set_header_labels(rank = "Rank",brand = "Brand Names",total_count = "Total Count",
                    men_percent = "Men (%)", women_percent = "Women (%)") %>%
  
  # apply conditional formatting to column men_percent and women_percent
  bg(~ men_percent > women_percent, bg = "#FC7676", ~ men_percent) %>%
  bg(~ men_percent < women_percent, bg = "#71CA97", ~ women_percent) %>% 
  
  # add titles in header 
  add_header_lines(values = "Percent of Product Listings for Men and Women 
                             for Popular Brand") %>%
  add_header_lines(values = "Gender Breakdown of Popular Brands") %>%
  
  # adjust alignment, add borders, bold columns and change fonts and fontsize
  autofit() %>%
  align(align = "center", part = "header") %>%
  align_nottext_col(align = "center") %>%
  border_outer(part="all") %>%
  bold(j = c("brand","men_percent", "women_percent"), bold = TRUE) %>%
  bold(bold = TRUE, part = "header") %>%
  font(fontname = "Courier", part = "all") %>%
  fontsize(i = 1, size = 12, part = "header") %>%
  fontsize(i = 2, size = 8, part = "header")

########### Create table of median price comparison with Flextable ############# 

flextable( data = top20_brand, col_keys = c("rank", "brand", "men_median_price",
                                            "women_median_price", 
                                            "median_price_diff")) %>%
  
  # rename header labels
  set_header_labels(rank = "Rank", brand = "Brand Names", 
                    men_median_price = "Men",
                    women_median_price = "Women", 
                    median_price_diff = "Difference") %>%
  
  # add 2nd header that displays "Median Price (USD)"
  add_header_row(values = c(" "," ","Median Price (USD)"), colwidths = c(1,1,3)) %>%
  
  bg(~ men_median_price > women_median_price, bg = "#FC7676", ~ men_median_price) %>%
  bg(~ men_median_price < women_median_price, bg = "#71CA97", ~ women_median_price) %>% 
  
  # add titles in header 
  add_header_lines(values = "Difference in Median Prices by Gender for the Most 
                             Popular Brands") %>%
  add_header_lines(values = "Difference between Men's and Women's Shoes Prices") %>%
  
  # adjust alignment, add borders, bold columns and change fonts and fontsize
  autofit() %>%
  align(align = "center", part = "header") %>%
  align_nottext_col(align = "center") %>%
  border_outer() %>%
  bold(bold = TRUE, part = "all") %>%
  font(fontname = "Courier", part = "all") %>%
  fontsize(i = 1, size = 12, part = "header") %>%
  fontsize(i = 2, size = 8, part = "header")






library(httr)
library(jsonlite)
library(dplyr)
library(RMariaDB)
library(purrr)

###### NOTE "sådan opdater man en database i git." ####### 

## 1 - IP adresse
# start, husk at ændre IP adressen på MySQL, con_salling og inde i terminalen den nye når man launcher instance.

## 2 - push fra R. terminal til linux 
# git add Salling.sql eller tryki toppen "hvor man gemmer" der er der et +- tegn 
# git commit -m "Tilføjet Salling.sql" 
# git push 

## 3 - pull i terminalen på mac 
# git pull
# ls -la for at se om den rigtige sql er der
# history  
# mysql -u root -p --database=Salling_store < Salling.sql - samme måde bruges til at lave en database i linux

## 4 - opdater MySQL 

####### Roskilde #######

url   <- "https://api.sallinggroup.com/v1/food-waste/?zip=4000"
token <- "SG_APIM_C353C47PX656P7RDXYJJBP5458RB7AHY93RFNEJ7G8N6NC70V27G" 

res <- GET(
  url,
  add_headers(Authorization = paste("Bearer", token))
)

status_code(res)   # skal være 200, ikke 401

raw <- content(res, "text", encoding = "UTF-8")
df  <- fromJSON(raw, flatten = TRUE)

df
offers = df$clearances

for (i in 1:length(offers)) {
  names(offers)[i]=df[i,2]
}

for (i in 1:length(offers)) {
  offers[[i]]$store_id <- names(offers)[i]
}
rownames(df_offer) <- NULL

df_offer <- do.call(rbind,offers)

rownames(df_offer) <- NULL

names(df)
str(df, max.level = 1)

stores <- df %>%
  select(store.id, store.name, store.address.street) %>%
  distinct()
stores

netto_roskilde <- df_offer %>%
  filter(store_id == "769204f1-d8e4-41fb-8b9c-0b8b8f885376")   
netto_roskilde

store_id <- "769204f1-d8e4-41fb-8b9c-0b8b8f885376"  # erstat med det rigtige id

url_store <- paste0("https://api.sallinggroup.com/v1/food-waste/", store_id)

res2 <- GET(
  url_store,
  add_headers(Authorization = paste("Bearer", token))
)

raw2 <- content(res2, "text", encoding = "UTF-8")
df_store <- fromJSON(raw2, flatten = TRUE)

df_store


####### SQL connection

con_salling <- dbConnect(
  MariaDB(),
  host = "13.53.212.33",
  dbname = "Salling_store",
  user = "dalremote",
  password = "Benja#1998"
)

df_stores_df1 <- stores_df %>%
  filter(store_id == "769204f1-d8e4-41fb-8b9c-0b8b8f885376")

View(df_stores_df1)

names(stores_df)

df_stores_df1 <- df_stores_df1 %>%
  select(
    store_id,
    brand,
    coordinates,
    hours,
    name,
    type,
    city,
    country,
    extra,
    street,
    zip
  ) %>%
  distinct() %>%
  mutate(
    across(
      where(is.list), 
      ~ jsonlite::toJSON(.x, auto_unbox = TRUE)
    )
  )

df_stores_df1 <- df_stores_df1 %>%
  mutate(
    hours = map_chr(hours, ~ jsonlite::toJSON(.x, pretty = TRUE, auto_unbox = TRUE)),
    coordinates = map_chr(coordinates, ~ jsonlite::toJSON(.x, pretty = TRUE, auto_unbox = TRUE))
  )

df_stores_df1

dbWriteTable(
  con_salling,
  name      = "sg_store",
  value     = df_stores_df1,   # eller stores_df med alle 6
  overwrite = TRUE,            # SMADR og genskab
  row.names = FALSE
)

clearance_df <- df_offer %>%
  distinct() %>%
  # 1) alle listekolonner -> JSON-tekst
  mutate(
    across(
      where(is.list),
      ~ map_chr(.x, ~ jsonlite::toJSON(.x, auto_unbox = TRUE))
    ),
    # 2) konverter tidspunkter fra "2025-11-27T05:59:43.000Z"
    offer_start = as.POSIXct(offer.startTime,
                             format = "%Y-%m-%dT%H:%M:%OSZ",
                             tz = "UTC"),
    offer_end   = as.POSIXct(offer.endTime,
                             format = "%Y-%m-%dT%H:%M:%OSZ",
                             tz = "UTC"),
    last_update = as.POSIXct(offer.lastUpdate,
                             format = "%Y-%m-%dT%H:%M:%OSZ",
                             tz = "UTC")
  ) %>%
  # 3) vælg de kolonner, der matcher din SQL-tabel
  transmute(
    store_id         = store_id,
    ean              = product.ean,
    currency         = offer.currency,
    new_price        = offer.newPrice,
    original_price   = offer.originalPrice,
    percent_discount = offer.percentDiscount,
    stock            = offer.stock,
    stock_unit       = offer.stockUnit,
    offer_start,
    offer_end,
    last_update
  )

sapply(clearance_df, class)

dbWriteTable(
  con_salling,
  name      = "clearance_offer",
  value     = clearance_df,   
  append    = TRUE,
  row.names = FALSE
)

dbGetQuery(con_salling, "SELECT DATABASE()")
dbGetQuery(con_salling, "SHOW TABLES")
dbGetQuery(con_salling, "DESC clearance_offer")


###### Jyllinge #######

url2   <- "https://api.sallinggroup.com/v1/food-waste/?zip=4040"
token <- "SG_APIM_C353C47PX656P7RDXYJJBP5458RB7AHY93RFNEJ7G8N6NC70V27G" 

res_jyllinge <- GET(
  url2,
  add_headers(Authorization = paste("Bearer", token))
)
res_jyllinge

status_code(res_jyllinge)   # skal være 200, ikke 401

raw2 <- content(res_jyllinge, "text", encoding = "UTF-8")
df2  <- fromJSON(raw2, flatten = TRUE)

df2

names(df2)
str(df2, max.level = 1)

stores_jyllinge <- df2 %>%
  select(store.id, store.name, store.address.street) %>%
  distinct()
stores_jyllinge

netto_jyllinge <- df %>%
  filter(store.id == "1b60951d-d8a0-4316-8c2a-f409ce96118b")   
netto_jyllinge

store_id <- "769204f1-d8e4-41fb-8b9c-0b8b8f885376"  # erstat med det rigtige id

url_store_jyllinge <- paste0("https://api.sallinggroup.com/v1/food-waste/", store_id)

res2_jyllinge <- GET(
  url_store,
  add_headers(Authorization = paste("Bearer", token))
)

raw2_jyllinge <- content(res2_jyllinge, "text", encoding = "UTF-8")
df_store_jyllinge <- fromJSON(raw2_jyllinge, flatten = TRUE)

df_store_jyllinge

clearances_df_jyllinge <- as.data.frame(df_store_jyllinge$clearances)

save.image("salling")

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

####### KONFIG #######
zip_code        <- "4000"
target_store_id <- "769204f1-d8e4-41fb-8b9c-0b8b8f885376"

api_token  <- "SG_APIM_C353C47PX656P7RDXYJJBP5458RB7AHY93RFNEJ7G8N6NC70V27G"      

url <- paste0("https://api.sallinggroup.com/v1/food-waste/?zip=", zip_code)

res <- GET(
  url,
  add_headers(Authorization = paste("Bearer", api_token))
)
raw <- content(res, "text", encoding = "UTF-8")

####### Roskilde #######

df  <- fromJSON(raw, flatten = TRUE)

offers <- df$clearances

for (i in 1:length(offers)) {
  names(offers)[i] <- df[i, 2]
}

for (i in 1:length(offers)) {
  offers[[i]]$store_id <- names(offers)[i]
}

df_offer <- do.call(rbind, offers)
rownames(df_offer) <- NULL

str(df, max.level = 1)

stores <- df %>%
  select(store.id, store.name, store.address.street) %>%
  distinct()

netto_roskilde <- df_offer %>%
  filter(store_id == target_store_id)

df_stores <- df[, c(
  "store.id",
  "store.brand",
  "store.coordinates",
  "store.hours",
  "store.name",
  "store.type",
  "store.address.city",
  "store.address.country",
  "store.address.extra",
  "store.address.street",
  "store.address.zip"
)]

df_stores <- df_stores %>%
  filter(store.id == target_store_id)

df_stores <- df_stores[, !names(df_stores) %in% c(
  "store.coordinates",
  "store.hours",
  "store.address.extra"
)]

####### SQL connection

con_salling <- dbConnect(
  MariaDB(),
  host     = "13.53.212.33",
  dbname   = "Salling_store",
  user     = "dalremote",
  password = "Benja#1998"
)

####### STORES – LAV REN DF_STORES FRA DF #######

df_stores <- df %>%
  filter(store.id == target_store_id) %>%
  transmute(
    store_id           = store.id,            # nyt navn
    store.brand,
    store.name,
    store.type,
    store.address.city,
    store.address.country,
    store.address.street,
    store.address.zip
  ) %>%
  distinct() %>%
  mutate(
    across(
      where(is.list),
      ~ jsonlite::toJSON(.x, auto_unbox = TRUE)
    )
  )


dbWriteTable(
  con_salling,
  name      = "sg_store",
  value     = df_stores,
  overwrite = TRUE,
  row.names = FALSE
)

####### CLEARANCE DATAFRAME – RENS + MATCH TIL SQL #######

clearance_df <- df_offer %>%
  distinct() %>%
  # 1) alle listekolonner -> JSON-tekst
  mutate(
    across(
      where(is.list),
      ~ map_chr(.x, ~ jsonlite::toJSON(.x, auto_unbox = TRUE))
    ),
    # 2) konverter tidspunkter fra "2025-11-27T05:59:43.000Z"
    offer_start = as.POSIXct(
      offer.startTime,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    ),
    offer_end = as.POSIXct(
      offer.endTime,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    ),
    last_update = as.POSIXct(
      offer.lastUpdate,
      format = "%Y-%m-%dT%H:%M:%OSZ",
      tz = "UTC"
    )
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

dbWriteTable(
  con_salling,
  name      = "clearance_offer",
  value     = clearance_df,   
  append    = TRUE,
  row.names = FALSE
)

library(httr)
library(jsonlite)
library(dplyr)
library(RMariaDB)
library(purrr)
library(DBI)

###### NOTE "sådan opdater man en database i git." ####### 

## 1 - IP adresse
# start, husk at ændre IP adressen på MySQL, con_salling og inde i terminalen den nye når man launcher instance.

## 2 - push fra R. terminal til linux 
# git add Salling.sql eller tryk i toppen "hvor man gemmer" der er der et +- tegn 
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

api_token  <- "SG_APIM_C353C47PX656P7RDXYJJBP5458RB7AHY93RFNEJ7G8N6NC70V27G"      # <- indsæt din rigtige token

url <- paste0("https://api.sallinggroup.com/v1/food-waste/?zip=", zip_code)

res <- GET(
  url,
  add_headers(Authorization = paste("Bearer", api_token))
)
stopifnot(status_code(res) == 200)

raw <- content(res, "text", encoding = "UTF-8")

####### HENT OG FLET DATA #######

df  <- fromJSON(raw, flatten = TRUE)

# liste med tilbud pr. butik
offers <- df$clearances

# brug store.id som navn på hvert liste-element
names(offers) <- df$`store.id`

# skriv store.id ind som kolonne i hver offers-tabel
for (i in seq_along(offers)) {
  offers[[i]]$`store.id` <- names(offers)[i]
}

# bind alle tilbud sammen til én dataframe
df_offer <- dplyr::bind_rows(offers)
rownames(df_offer) <- NULL

# lille oversigt over butikker (valgfri)
stores <- df %>%
  select(`store.id`, store.name, store.address.street) %>%
  distinct()

# kun tilbud fra én butik (valgfri)
netto_roskilde <- df_offer %>%
  filter(`store.id` == target_store_id)

####### SQL CONNECTION #######

con_salling <- dbConnect(
  MariaDB(),
  host     = "13.53.212.33",
  dbname   = "Salling_store",
  user     = "dalremote",
  password = "Benja#1998"   # <- indsæt dit rigtige password
)

####### SG_STORE – KUN ÉN BUTIK, KUN store.id #######

df_stores <- df %>%
  filter(`store.id` == target_store_id) %>%
  transmute(
    `store.id`,
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
  overwrite = TRUE,   # SMADR og genskab tabellen
  row.names = FALSE
)

####### CLEARANCE_DATAFRAME – MED store.id #######

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
    `store.id`,
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

dbDisconnect(con_salling)

DROP TABLE IF EXISTS clearance_offer;
DROP TABLE IF EXISTS sg_store;

CREATE TABLE sg_store (
  store_id CHAR(36) PRIMARY KEY,              -- store.id
  brand VARCHAR(50),                          -- store.brand
  name VARCHAR(255),                          -- store.name
  type VARCHAR(50),                           -- store.type
  coordinates VARCHAR(100),                   -- store.coordinates 
  hours TEXT,                                 -- store.hours (kompleks, så gemmes som text/JSON)
  city VARCHAR(100),                          -- store.address.city
  country VARCHAR(50),                        -- store.address.country
  extra VARCHAR(255),                         -- store.address.extra
  street VARCHAR(255),                        -- store.address.street
  zip VARCHAR(10),                            -- store.address.zip

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS clearance_offer;

CREATE TABLE clearance_offer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ean VARCHAR(20),
  currency VARCHAR(10),
  new_price DECIMAL(10,2),
  original_price DECIMAL(10,2),
  percent_discount DECIMAL(5,2),
  stock INT,
  stock_unit VARCHAR(20),
  offer_start DATETIME,
  offer_end DATETIME,
  last_update DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (store_id) REFERENCES sg_store(store_id)
);
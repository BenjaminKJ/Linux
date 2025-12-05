DROP TABLE IF EXISTS clearance_offer;
DROP TABLE IF EXISTS sg_store;
DROP TABLE IF EXISTS run;

CREATE TABLE sg_store (
  store_id CHAR(36) PRIMARY KEY,              -- store.id
  brand VARCHAR(50),                          -- store.brand
  name VARCHAR(255),                          -- store.name
  type VARCHAR(50),                           -- store.type
  city VARCHAR(100),                          -- store.address.city
  country VARCHAR(50),                        -- store.address.country
  street VARCHAR(255),                        -- store.address.street
  zip VARCHAR(10),                            -- store.address.zip

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS clearance_offer;

CREATE TABLE clearance_offer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  store_id CHAR(36),
  ean VARCHAR(20),
  currency VARCHAR(10),
  new_price DECIMAL(10,2),
  product_description VARCHAR(20),
  original_price DECIMAL(10,2),
  percent_discount DECIMAL(5,2),
  stock INT,
  stock_unit VARCHAR(20),
  offer_start DATETIME,
  offer_end DATETIME,
  last_update DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
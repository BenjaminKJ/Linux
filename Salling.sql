CREATE TABLE store (
  store_id CHAR(36) PRIMARY KEY,              -- store.id
  brand VARCHAR(50),                          -- store.brand
  name VARCHAR(255),                          -- store.name
  type VARCHAR(50),                           -- store.type
  coordinates VARCHAR(100),                   -- store.coordinates (fx "55.6,12.1")
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

CREATE TABLE run (
  run_id INT AUTO_INCREMENT PRIMARY KEY,
  run_time DATETIME NOT NULL,
  source VARCHAR(50),
  script_version VARCHAR(20),
  comment VARCHAR(255)
);

CREATE TABLE clearance_offer (
  id INT AUTO_INCREMENT PRIMARY KEY,
  run_id INT NOT NULL,
  store_id CHAR(36) NOT NULL,
  -- her kommer feltet "clearances" indhold – fx offer/product-felter,
  -- jeg viser bare de klassiske:
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

  CONSTRAINT fk_clearance_run
    FOREIGN KEY (run_id) REFERENCES run(run_id),
  CONSTRAINT fk_clearance_store
    FOREIGN KEY (store_id) REFERENCES store(store_id)
);
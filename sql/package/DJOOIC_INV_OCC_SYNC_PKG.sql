--------------------------------------------------------
--  DDL for Package DJOOIC_INV_OCC_SYNC_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_INV_OCC_SYNC_PKG" AS

    TYPE inventory_sync_result IS RECORD(
    item_number VARCHAR2(100),
    parent_catalog VARCHAR2(100),
    onhand_quantity NUMBER
    );

    TYPE inventory_sync_table IS TABLE OF inventory_sync_result;

      -- XX_INVENTORY_FETCH procedure
    PROCEDURE XX_INVENTORY_FETCH(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT inventory_sync_table,
    x_count OUT NUMBER
  );
  
    TYPE pricelist_record is RECORD(
    price_list_id VARCHAR2(1000),
    id VARCHAR2(1000),
    name VARCHAR2(100)
    );
    
    TYPE pricelist_array is table of pricelist_record;
    
    TYPE catalog_details_result IS RECORD(
    product_id VARCHAR2(100),
    pricelist_details pricelist_array
    );
    
    TYPE catalog_details_table is table of catalog_details_result;
    
    PROCEDURE XX_CATALOG_FETCH_1(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result          OUT catalog_details_table,
    x_count         OUT NUMBER
    );
  
/*
    TYPE pricelist_type IS RECORD (
    id VARCHAR2(100)
    );

    TYPE pricelist_array IS TABLE OF pricelist_type;

    TYPE item_pricelist_record IS RECORD (
    item_number VARCHAR2(100),
    pricelists pricelist_array
);*/

END DJOOIC_INV_OCC_SYNC_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_OCC_SYNC_PKG" TO "XXOIC";

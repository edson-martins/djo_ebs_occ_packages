--------------------------------------------------------
--  DDL for Package DJOOIC_QP_PRICELIST_SYNC_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_QP_PRICELIST_SYNC_PKG" AS
  -- Define a custom record type to represent the result structure

    TYPE pricelist_sync_result IS RECORD(
    price_list_name VARCHAR2(1000),
    currency_code VARCHAR2(100),
    product_id VARCHAR2(1000),
    part_number VARCHAR2(1000),
    method_code VARCHAR2(100),
    list_price NUMBER
    );

    TYPE pricelist_sync_table IS TABLE OF pricelist_sync_result;


  -- XX_INVOICE_SEARCH procedure
       PROCEDURE XX_PRICELIST_FETCH(
        p_counter       IN NUMBER,
        p_limit         IN NUMBER,
        x_status_code   OUT VARCHAR2,
        x_error_message OUT VARCHAR2,
        x_result        OUT pricelist_sync_table,
        x_count         OUT NUMBER
    ) ;


END DJOOIC_QP_PRICELIST_SYNC_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_QP_PRICELIST_SYNC_PKG" TO "XXOIC";

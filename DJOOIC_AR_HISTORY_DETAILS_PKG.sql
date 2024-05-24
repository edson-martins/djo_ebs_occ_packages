--------------------------------------------------------
--  DDL for Package DJOOIC_AR_HISTORY_DETAILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_AR_HISTORY_DETAILS_PKG" AS
  -- Define a custom record type to represent the result structure
  TYPE invoice_result IS RECORD (
    customer_trx_id NUMBER,
    trx_number VARCHAR2(50),
    ebs_order_number VARCHAR2(50),
    ebs_order_id NUMBER,
    class VARCHAR2(50),
    status VARCHAR2(50),
    trx_date DATE,
    due_date DATE,
    purchase_order VARCHAR2(50),
    item_total NUMBER,
    shipping_amount NUMBER,
    tax_amount NUMBER,
    invoice_total NUMBER,
    amount_due_remaining NUMBER,
    applied_amount NUMBER
  );

  -- Define a nested table type to hold multiple records
  TYPE invoice_result_table IS TABLE OF invoice_result;

  -- XX_INVOICE_SEARCH procedure
  PROCEDURE XX_INVOICE_SEARCH(
    p_account_id IN NUMBER,
    p_order_number IN VARCHAR2,
    p_purchase_order IN VARCHAR2,
    p_ship_to_account IN VARCHAR2,
    p_inv_num IN VARCHAR2,
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_page_number IN NUMBER,
    p_limit IN NUMBER,
    p_operator_code IN VARCHAR2,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT invoice_result_table
  );

 -- Define a custom record type to represent the result structure
  TYPE payment_result IS RECORD (
    receipt_number VARCHAR2(50),
    receipt_id NUMBER,
    organization_name VARCHAR2(100),
    receipt_date DATE,
    receipt_type VARCHAR2(50),
    receipt_amount VARCHAR2(50),
    unapplied_amount NUMBER,
    applied_amount NUMBER,
    receipt_status VARCHAR2(50),
    currency_code VARCHAR2(50),
    due_date DATE
  );

  -- Define a nested table type to hold multiple records
  TYPE payment_result_table IS TABLE OF payment_result;

  -- XX_PAYMENT_SEARCH procedure
  PROCEDURE XX_PAYMENT_SEARCH(
    p_account_id IN NUMBER,
    p_payment_number IN VARCHAR2,
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_page_number IN NUMBER,
    p_limit IN NUMBER,
    p_operator_code IN VARCHAR2,
    p_payment_amount IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT payment_result_table
  );

END DJOOIC_AR_HISTORY_DETAILS_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_AR_HISTORY_DETAILS_PKG" TO "XXOIC";

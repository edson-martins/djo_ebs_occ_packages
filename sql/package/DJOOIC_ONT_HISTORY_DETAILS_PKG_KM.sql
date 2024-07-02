--------------------------------------------------------
--  DDL for Package DJOOIC_ONT_HISTORY_DETAILS_PKG_KM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG_KM" AS
  -- Define a custom record type to represent the result structure
  TYPE order_header_details_result IS RECORD (
    header_id NUMBER,
    order_number VARCHAR2(50),
    alt_order_number VARCHAR2(50),
    ordered_date DATE,
    booked_date DATE,
    order_status VARCHAR2(50),
    po_number VARCHAR2(50),
    order_number_ship VARCHAR2(50),
    bill_party_name VARCHAR2(100),
    ship_party_name VARCHAR2(100),
    bill_email_address VARCHAR2(100),
    ship_email_address VARCHAR2(100),
    address_shipping VARCHAR2(500),
    address_billing VARCHAR2(500),
    shipping_method_code VARCHAR2(50),
    request_date DATE,
    shipment_priority_code VARCHAR2(50),
    freight_terms_code VARCHAR2(50),
    drop_ship_flag VARCHAR2(50),
    currency_code VARCHAR2(50),
    payment_terms VARCHAR2(50),
    cust_po_number VARCHAR2(50),
    payment_type_code VARCHAR2(50),
    third_party_account VARCHAR2(100),
    one_time_third_party_account VARCHAR2(100),
    order_total VARCHAR2(50),
    order_source VARCHAR2(50),
    sold_to_contact_id VARCHAR2(50),
    organization_code VARCHAR2(50),
    fob_point_code VARCHAR2(50),
    ooh_freight_terms_code VARCHAR2(50),
    contact_first_name VARCHAR2(50),
    contact_last_name VARCHAR2(50),
    contact_email_address VARCHAR2(50),
    hcp_email_address VARCHAR2(50)
  );

  -- Define a nested table type to hold multiple records
  TYPE order_header_details_result_table IS TABLE OF order_header_details_result;

  -- XX_ORDER_SEARCH procedure
  PROCEDURE XX_ORDER_HEADER_DETAILS(
    p_header_id IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT order_header_details_result_table
  );
  
--  TYPE account_fetch_result IS RECORD (
--    account_id NUMBER,
--    organization_name VARCHAR2(100),
--    frieght_terms VARCHAR2(50),
--    account_number VARCHAR2(50)
--  );
--
--  -- Define a nested table type to hold multiple records
--  TYPE account_fetch_result_table IS TABLE OF account_fetch_result;
--
--  -- XX_ORDER_SEARCH procedure
--  PROCEDURE XX_ACCOUNTS_FETCH(
--    p_counter IN NUMBER,
--    p_limit IN NUMBER,
--    x_count OUT NUMBER,
--    x_status_code OUT VARCHAR2,
--    x_error_message OUT VARCHAR2,
--    x_result OUT account_fetch_result_table
--  );
--  

TYPE account_fetch_result IS RECORD (
    account_id NUMBER,
    organization_name VARCHAR2(100),
    payment_terms VARCHAR2(50),
    frieght_terms VARCHAR2(50),
    account_number VARCHAR2(50)
  );

  -- Define a nested table type to hold multiple records
  TYPE account_fetch_result_table IS TABLE OF account_fetch_result;

  -- XX_ORDER_SEARCH procedure
  PROCEDURE XX_ACCOUNTS_FETCH(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT account_fetch_result_table
  );
  TYPE address_fetch_result IS RECORD (
    account_site_id NUMBER,
    account_id NUMBER,
    primary_flag VARCHAR2(50),
    site_use_code VARCHAR2(50),
    address1 VARCHAR2(50),
    address2 VARCHAR2(50),
    address3 VARCHAR2(50),
    city VARCHAR2(50),
    state_prov VARCHAR2(50),
    zipcode VARCHAR2(50),
    is_default_billing_addr VARCHAR2(50),
    is_default_shipping_addr VARCHAR2(50),
    country VARCHAR2(50),
    party_site_name VARCHAR2(50),
    third_party_accounts VARCHAR2(50),
    site_use_id NUMBER
  );

  -- Define a nested table type to hold multiple records
  TYPE address_fetch_result_table IS TABLE OF address_fetch_result;

  -- XX_ORDER_SEARCH procedure
  PROCEDURE XX_ADDRESS_FETCH(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT address_fetch_result_table
  );
  
  TYPE profile_fetch_result IS RECORD (
    contactid NUMBER,
    account_id NUMBER,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email_address VARCHAR2(50),
    phone_number VARCHAR2(50),
    role VARCHAR2(50),
    last_update_date DATE
    
  );

  -- Define a nested table type to hold multiple records
  TYPE profile_fetch_result_table IS TABLE OF profile_fetch_result;

  -- XX_ORDER_SEARCH procedure
  PROCEDURE XX_PROFILE_FETCH(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT profile_fetch_result_table
  );


END DJOOIC_ONT_HISTORY_DETAILS_PKG_km;

/

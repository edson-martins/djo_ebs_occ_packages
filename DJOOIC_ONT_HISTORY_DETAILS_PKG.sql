--------------------------------------------------------
--  DDL for Package DJOOIC_ONT_HISTORY_DETAILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG" AS
  -- Define a custom record type to represent the result structure
  TYPE order_search_result IS RECORD (
    occ_order_number VARCHAR2(50),
    order_id NUMBER,
    order_number VARCHAR2(50),
    flow_status_code VARCHAR2(50),
    ordered_date DATE,
    booked_date DATE,
    cust_po_number VARCHAR2(50)
  );

  -- Define a nested table type to hold multiple records
  TYPE order_search_result_table IS TABLE OF order_search_result;

  -- XX_ORDER_SEARCH procedure
  PROCEDURE XX_ORDER_SEARCH(
    p_org_id IN NUMBER,
    p_cust_account_id IN NUMBER,
    p_order_number IN VARCHAR2,
    p_order_status IN VARCHAR2,
    p_purchase_order IN VARCHAR2,
    p_ship_to_account IN VARCHAR2,
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_page_number IN NUMBER,
    p_limit IN NUMBER,
    p_operator_code IN VARCHAR2,
    p_part_number     IN VARCHAR2,
    p_tracking_number IN VARCHAR2,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT order_search_result_table
  );
  
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
  
    TYPE tracking_details_result IS RECORD (
  line_number NUMBER,
  tracking_number VARCHAR2(30),
  shiiped_quantity NUMBER,
  actual_ship_method VARCHAR2(100),
  actual_shipping_date DATE,
  delivery_id NUMBER
  );
  
  TYPE tracking_details_table IS TABLE OF tracking_details_result;
  
  TYPE order_line_details_result IS RECORD (
    line_number NUMBER,
    line_id NUMBER,
    header_id NUMBER,
    ordered_item VARCHAR2(50),
    order_number NUMBER,
    description VARCHAR2(240),
    flow_status_code VARCHAR2(50),
    ordered NUMBER,
    shipped NUMBER,
    ORDER_QUANTITY_UOM VARCHAR2(50),
    item_total NUMBER,
    item_price NUMBER,
    scheduled_ship_date DATE,
    tracking_details tracking_details_table
  );
  
  TYPE order_line_details_table IS TABLE OF order_line_details_result;
  
PROCEDURE xx_order_line_details(
        p_header_id       IN NUMBER,
        x_status_code     OUT VARCHAR2,
        x_error_message   OUT VARCHAR2,
        x_result          OUT order_line_details_table
    );

TYPE account_fetch_result IS RECORD (
    account_id NUMBER,
    organization_name VARCHAR2(100),
    payment_terms VARCHAR2(50),
    frieght_terms VARCHAR2(50),
    account_number VARCHAR2(50),
    payment_method VARCHAR2(1000),
    shipping_method VARCHAR2(1000),
    price_list VARCHAR2(1000),
    account_catalog VARCHAR2(1000),
    third_party_accounts VARCHAR2(4000),
    siteId VARCHAR2(1000)
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
  
   TYPE ship_to_contact_rec IS RECORD (
        contact_id  NUMBER,
        phone_number VARCHAR2(1000),
        first_name VARCHAR2(1000),
        last_name VARCHAR2(1000)
  );
  
  TYPE ship_to_contact_table IS TABLE OF ship_to_contact_rec;
  
  TYPE address_fetch_result IS RECORD (
    account_site_id NUMBER,
    account_id NUMBER,
    primary_flag VARCHAR2(50),
    site_use_code VARCHAR2(50),
    address1 VARCHAR2(1000),
    address2 VARCHAR2(1000),
    address3 VARCHAR2(1000),
    city VARCHAR2(1000),
    state_prov VARCHAR2(1000),
    zipcode VARCHAR2(1000),
    is_default_billing_addr VARCHAR2(50),
    is_default_shipping_addr VARCHAR2(50),
    country VARCHAR2(1000),
    party_site_name VARCHAR2(1000),
    third_party_accounts VARCHAR2(1000),
    site_use_id NUMBER,
    payment_terms VARCHAR2(1000),
    payment_method VARCHAR2(1000),
    ship_to_contacts ship_to_contact_table
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
  
      TYPE parent_org IS RECORD (
        parent_org_id number,
        role VARCHAR2(50)
  );
  
  TYPE parent_org_table IS TABLE OF parent_org;
  
  TYPE profile_fetch_result IS RECORD (
    contactid NUMBER,
    account_id NUMBER,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email_address VARCHAR2(50),
    phone_number VARCHAR2(50),
    role VARCHAR2(50),
    last_update_date DATE,
    parent_org_details parent_org_table
  );

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
    

END DJOOIC_ONT_HISTORY_DETAILS_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG" TO "XXOIC";

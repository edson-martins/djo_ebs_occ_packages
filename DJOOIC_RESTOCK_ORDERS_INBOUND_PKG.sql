--------------------------------------------------------
--  DDL for Package DJOOIC_RESTOCK_ORDERS_INBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" 
AS
    c_return_status_success        CONSTANT VARCHAR2 (1) := 'S';
    c_return_status_error          CONSTANT VARCHAR2 (1) := 'E';
    c_return_status_unexpected     CONSTANT VARCHAR2 (1) := 'U';
    g_created_by                            NUMBER := fnd_global.user_id;
    g_creation_date                         DATE := SYSDATE;
    g_last_update_date                      DATE := SYSDATE;
    g_last_updated_by                       NUMBER := fnd_global.user_id;
    g_last_update_login                     NUMBER := fnd_global.login_id;
    c_source_replenishment_order   CONSTANT VARCHAR2 (1) := '2';
    c_header_new               CONSTANT VARCHAR2(1) := '1';

    PROCEDURE fnd_debug (p_string VARCHAR2);

    TYPE type_rec_items IS RECORD
    (
        line_number         NUMBER,
        part_number         VARCHAR2 (1000),
        ordered_quantity    NUMBER
    );

    TYPE t_tab_items IS TABLE OF type_rec_items
        INDEX BY BINARY_INTEGER;

    PROCEDURE process_restock_orders (
        p_request_id VARCHAR2,
        p_associated_ctm_id                 NUMBER,
        p_date_created                      DATE,
        p_distributor_acct_number           VARCHAR2,
        p_need_by_date                      DATE,
        p_ship_to_name                      VARCHAR2,
        p_ship_to_attn                      VARCHAR2,
        p_ship_to_address                   VARCHAR2,
        p_ship_to_address2                  VARCHAR2,
        p_ship_to_city                      VARCHAR2,
        p_ship_to_state                     VARCHAR2,
        p_ship_to_zip_code                  VARCHAR2,
        p_shipping_method                   VARCHAR2,
        p_destination_org                   VARCHAR2,
        p_destination_subinv                VARCHAR2,
        p_alternate_deliver_to_loc_id       NUMBER,
        p_items                             t_tab_items,
        p_out_request_id                OUT NUMBER,
        p_status_flag                   OUT VARCHAR2,
        p_error_message                 OUT VARCHAR2
        );

    PROCEDURE create_location (p_distributor_acct_number       VARCHAR2,
                               p_ship_to_address               VARCHAR2,
                               p_ship_to_address2              VARCHAR2,
                               p_ship_to_city                  VARCHAR2,
                               p_ship_to_state                 VARCHAR2,
                               p_zip_code                      VARCHAR2,
                               p_ship_to_name                   VARCHAR2,
                               p_out_location_id OUT NUMBER,
                               p_out_site_use_id OUT NUMBER,
                               x_status_code               OUT VARCHAR2,
                               x_error_message             OUT VARCHAR2);

    FUNCTION derive_location (p_distributor_acct_number   VARCHAR2,
                              p_ship_to_address           VARCHAR2,
                              p_ship_to_address2          VARCHAR2,
                              p_ship_to_city              VARCHAR2,
                              p_ship_to_state             VARCHAR2,
                              p_zip_code                  VARCHAR2)
        RETURN NUMBER;
END DJOOIC_RESTOCK_ORDERS_INBOUND_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" TO "XXOIC";
  GRANT DEBUG ON "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" TO "XXOIC";

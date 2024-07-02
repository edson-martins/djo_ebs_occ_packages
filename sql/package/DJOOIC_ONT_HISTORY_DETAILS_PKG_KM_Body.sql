--------------------------------------------------------
--  DDL for Package Body DJOOIC_ONT_HISTORY_DETAILS_PKG_KM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG_KM" AS
  -- XX_ORDER_HEADER_DETAILS procedure
    PROCEDURE XX_ORDER_HEADER_DETAILS (
        p_header_id IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT order_header_details_result_table
    ) AS

        v_query         CLOB;
        v_query_count   CLOB;
        TYPE stagedatacursortype IS REF CURSOR;
        v_refcur        stagedatacursortype;
        lv_input_error EXCEPTION;
        lv_generic_error EXCEPTION;
        l_status_code   VARCHAR2(10);
        l_error_message VARCHAR2(4000);
        l_header_id     NUMBER;

          TYPE l_header_details_rec IS RECORD (
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
    hcp_email_address VARCHAR2(50));

    TYPE l_header_details_table IS TABLE OF l_header_details_rec;
    l_header_details l_header_details_table;

        cursor c_order_header(cp_header_id NUMBER)
        IS
        SELECT ooh.header_id                  order_id,
       ooh.order_number               ebs_order_number,
       NULL                           alt_order_number,
       ooh.ordered_date               ordered_date,
       ooh.booked_date                booked_date,
       ooh.flow_status_code           order_status,
       ooh.cust_po_number             po_number,
       ooh.order_number,
       hp_bill.party_name             Bill_Party_Name,
       hp_ship.party_name             Ship_Party_Name,
       hp_bill.email_address          Bill_customer_email,
       hp_ship.email_address          Ship_customer_email,
          hl_ship.address1
       || DECODE (hl_ship.address2, NULL, '', CHR (10))
       || hl_ship.address2
       || DECODE (hl_ship.address3, NULL, '', CHR (10))
       || hl_ship.address3
       || DECODE (hl_ship.address4, NULL, '', CHR (10))
       || hl_ship.address4
       || DECODE (hl_ship.city, NULL, '', CHR (10))
       || hl_ship.city
       || DECODE (hl_ship.state, NULL, '', ',')
       || hl_ship.state
       || DECODE (hl_ship.postal_code, '', ',')
       || hl_ship.postal_code         ship_to_address,
          hl_bill.address1
       || DECODE (hl_bill.address2, NULL, '', CHR (10))
       || hl_bill.address2
       || DECODE (hl_bill.address3, NULL, '', CHR (10))
       || hl_bill.address3
       || DECODE (hl_bill.address4, NULL, '', CHR (10))
       || hl_bill.address4
       || DECODE (hl_bill.city, NULL, '', CHR (10))
       || hl_bill.city
       || DECODE (hl_bill.state, NULL, '', ',')
       || hl_bill.state
       || DECODE (hl_bill.postal_code, '', ',')
       || hl_bill.postal_code         bill_to_address,
       fl_ship.meaning                shipping_method,
       ooh.request_date               requested_delivery_date,
       ooh.shipment_priority_code     shipment_priority,
       ol.meaning                     freight_terms,
       ooh.drop_ship_flag             drop_shipment,
       ooh.transactional_curr_code    currency_code,
       trm.name                       payment_terms,
       ooh.cust_po_number             purchase_order_number,
       ooh.payment_type_code          payment_method,
       NULL                           third_party_account,
       NULL                           one_time_third_party_account,
       NVL (apps.oe_totals_grp.get_order_total (ooh.header_id, NULL, 'ALL'),
            0)                        order_total,
       os.name                        order_source,
       ooh.sold_to_contact_id,
       mp.organization_code,
       ooh.fob_point_code,
       ooh.freight_terms_code,
       --
       sold_party.person_first_name contact_first_name,
       sold_party.person_last_name contact_last_name,
       sold_party.email_address contact_email_address,
       hcp.email_address
  FROM oe_order_headers_all    ooh,
       hz_cust_site_uses_all   hcs_ship,
       hz_cust_acct_sites_all  hca_ship,
       hz_party_sites          hps_ship,
       hz_parties              hp_ship,
       hz_locations            hl_ship,
       hz_cust_site_uses_all   hcs_bill,
       hz_cust_acct_sites_all  hca_bill,
       hz_party_sites          hps_bill,
       hz_parties              hp_bill,
       hz_locations            hl_bill,
       mtl_parameters          mp,
       --
       fnd_lookup_values_vl    fl_ship,
       oe_lookups              ol,
       apps.ra_terms           trm,
       apps.oe_order_sources   os,
       --
       apps.hz_cust_account_roles hcar, 
       apps.hz_relationships hr, 
       apps.hz_parties sold_party,
       apps.hz_contact_points hcp
WHERE     1 = 1
       AND order_number = p_header_id
       AND ooh.ship_to_org_id = hcs_ship.site_use_id
       AND hcs_ship.cust_acct_site_id = hca_ship.cust_acct_site_id
       AND hca_ship.party_site_id = hps_ship.party_site_id
       AND hps_ship.party_id = hp_ship.party_id
       AND hps_ship.location_id = hl_ship.location_id
       AND ooh.invoice_to_org_id = hcs_bill.site_use_id
       AND hcs_bill.cust_acct_site_id = hca_bill.cust_acct_site_id
       AND hca_bill.party_site_id = hps_bill.party_site_id
       AND hps_bill.party_id = hp_bill.party_id
       AND hps_bill.location_id = hl_bill.location_id
       AND mp.organization_id(+) = ooh.ship_from_org_id
       --
       AND fl_ship.enabled_flag(+) = 'Y'
       AND fl_ship.lookup_type(+) = 'SHIP_METHOD'
       AND fl_ship.lookup_code(+) = ooh.shipping_method_code
       AND fl_ship.view_application_id(+) = 3
       AND UPPER (ol.lookup_type) = 'FREIGHT_TERMS'
       AND ol.enabled_flag = 'Y'
       AND UPPER (ol.lookup_code) = UPPER (ooh.freight_terms_code)
       AND ooh.payment_term_id = trm.term_id
       AND ooh.order_source_id = os.order_source_id
       --
       AND hcar.role_type(+) = 'CONTACT'
       AND hcar.party_id(+) = hr.party_id
       AND hr.relationship_code(+) = 'CONTACT_OF'
       AND hr.subject_id = sold_party.party_id(+)
       AND hcar.cust_account_id(+) = hca_ship.cust_account_id 
       AND hcar.cust_account_role_id (+) = ooh.sold_to_contact_id--2042156 
       --
       AND hcp.owner_table_id = hcar.party_id
       AND hcp.owner_table_name = 'HZ_PARTIES' 
       AND hcp.contact_point_type = 'EMAIL';




    BEGIN
        l_status_code := 'S';
        l_error_message := '';

    -- validate input parameters
        IF p_header_id IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameter(s) missing';
            RAISE lv_input_error;
        END IF;

        l_header_id := p_header_id;


        OPEN c_order_header(l_header_id);


        FETCH c_order_header BULK COLLECT INTO l_header_details;
        CLOSE c_order_header;
        dbms_output.put_line(l_header_details.count);
        FOR i IN 1..l_header_details.count LOOP
            dbms_output.put_line(l_header_details(i).order_number);


            x_result(i).header_id := l_header_details(i).header_id;
            x_result(i).order_number := l_header_details(i).order_number;
            x_result(i).alt_order_number := l_header_details(i).alt_order_number;
            x_result(i).ordered_date  := l_header_details(i).ordered_date ;
            x_result(i).booked_date  := l_header_details(i).booked_date ;
            x_result(i).order_status  := l_header_details(i).order_status ;
            x_result(i).po_number  := l_header_details(i).po_number ;
            x_result(i).order_number_ship  := l_header_details(i).order_number_ship ;
            x_result(i).bill_party_name  := l_header_details(i).bill_party_name ;
            x_result(i).ship_party_name  := l_header_details(i).ship_party_name ;
            x_result(i).bill_email_address  := l_header_details(i).bill_email_address ;
            x_result(i).ship_email_address  := l_header_details(i).ship_email_address ;
            x_result(i).address_shipping  := l_header_details(i).address_shipping ;
            x_result(i).address_billing  := l_header_details(i).address_billing ;
            x_result(i).shipping_method_code  := l_header_details(i).shipping_method_code ;
            x_result(i).request_date  := l_header_details(i).request_date ;
            x_result(i).shipment_priority_code  := l_header_details(i).shipment_priority_code ;
            x_result(i).freight_terms_code  := l_header_details(i).freight_terms_code ;
            x_result(i).drop_ship_flag  := l_header_details(i).drop_ship_flag ;
            x_result(i).currency_code  := l_header_details(i).currency_code ;
            x_result(i).payment_terms  := l_header_details(i).payment_terms ;
            x_result(i).cust_po_number   := l_header_details(i).cust_po_number  ;
            x_result(i).payment_type_code   := l_header_details(i).payment_type_code  ;
            x_result(i).third_party_account   := l_header_details(i).third_party_account  ;
            x_result(i).one_time_third_party_account   := l_header_details(i).one_time_third_party_account  ;
            x_result(i).order_total   := l_header_details(i).order_total  ;
            x_result(i).order_source   := l_header_details(i).order_source  ;
            x_result(i).sold_to_contact_id   := l_header_details(i).sold_to_contact_id  ;
            x_result(i).organization_code   := l_header_details(i).organization_code  ;
            x_result(i).fob_point_code   := l_header_details(i).fob_point_code  ;
            x_result(i).ooh_freight_terms_code   := l_header_details(i).ooh_freight_terms_code  ;
            x_result(i).contact_first_name   := l_header_details(i).contact_first_name  ;
            x_result(i).contact_last_name   := l_header_details(i).contact_last_name  ;
            x_result(i).contact_email_address   := l_header_details(i).contact_email_address  ;
            x_result(i).hcp_email_address   := l_header_details(i).hcp_email_address  ;





        END LOOP;


        x_status_code := l_status_code;
        x_error_message := l_error_message;
    EXCEPTION
        WHEN lv_input_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN lv_generic_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN OTHERS THEN
            x_status_code := 'E';
            x_error_message := 'An error was encountered - '
                               || sqlcode
                               || ' -ERROR- '
                               || sqlerrm;
            dbms_output.put_line(x_error_message);

    END XX_ORDER_HEADER_DETAILS;
    
--    -- XX_ACCOUNTS_FETCH procedure
--    PROCEDURE XX_ACCOUNTS_FETCH_1 (
--    p_counter IN NUMBER,
--    p_limit IN NUMBER,
--    x_count OUT NUMBER,
--    x_status_code OUT VARCHAR2,
--    x_error_message OUT VARCHAR2,
--    x_result OUT account_fetch_result_table
--    ) AS
--
--        v_query         CLOB;
--        v_query_count   CLOB;
--        TYPE stagedatacursortype IS REF CURSOR;
--        v_refcur        stagedatacursortype;
--        lv_input_error EXCEPTION;
--        lv_generic_error EXCEPTION;
--        l_status_code   VARCHAR2(10);
--        l_error_message VARCHAR2(4000);
--        BEGIN
--    l_status_code := 'S';
--    l_error_message := '';
--    -- validate input parameters
--    IF p_counter IS NULL OR p_limit IS NULL THEN
--        l_status_code := 'E';
--        l_error_message := 'Input parameters missing';
--        RAISE lv_input_error;
--    END IF;
--    -- Initialize the dynamic SQL query
--    v_query := 'SELECT
--    account_id,
--    organization_name,
--    frieght_terms,
--    account_number
--  FROM
--    xxdjo.djoar_ebs_occ_acct
--  WHERE
--    occ_interfaced = ''I'' and account_id in(251970, 250874, 250883) order by (account_id) offset nvl(('
--           || p_counter
--           || '-1),0) * '
--           || p_limit
--           || ' rows FETCH NEXT '
--           || p_limit
--           || ' ROWS ONLY ';
--        
--OPEN v_refcur FOR v_query;
--
--    
--        FETCH v_refcur bulk collect into x_result ;
--        x_count := x_result.COUNT;
--
--    FOR i in 1..x_result.COUNT LOOP
--        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
--    END LOOP;
--
--        
--    EXCEPTION
--        WHEN lv_input_error THEN
--            x_status_code := l_status_code;
--            x_error_message := l_error_message;
--            dbms_output.put_line(x_error_message);
--        WHEN lv_generic_error THEN
--            x_status_code := l_status_code;
--            x_error_message := l_error_message;
--            dbms_output.put_line(x_error_message);
--        WHEN OTHERS THEN
--            x_status_code := 'E';
--            x_error_message := 'An error was encountered - '
--                               || sqlcode
--                               || ' -ERROR- '
--                               || sqlerrm;
--            dbms_output.put_line(x_error_message);
--
--    END XX_ACCOUNTS_FETCH_1;
    
       -- XX_ACCOUNTS_FETCH procedure
    PROCEDURE XX_ACCOUNTS_FETCH (
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT account_fetch_result_table
    ) AS

        v_query         CLOB;
        v_query_count   CLOB;
        TYPE stagedatacursortype IS REF CURSOR;
        v_refcur        stagedatacursortype;
        lv_input_error EXCEPTION;
        lv_generic_error EXCEPTION;
        l_status_code   VARCHAR2(10);
        l_error_message VARCHAR2(4000);
        BEGIN
    l_status_code := 'S';
    l_error_message := '';
    -- validate input parameters
    IF p_counter IS NULL OR p_limit IS NULL THEN
        l_status_code := 'E';
        l_error_message := 'Input parameters missing';
        RAISE lv_input_error;
    END IF;
    -- Initialize the dynamic SQL query
    v_query := 'SELECT
    account_id,
    organization_name,
    payment_terms
    frieght_terms,
    account_number
  FROM
    xxdjo.djoar_ebs_occ_acct
  WHERE
    occ_interfaced = ''I'' and account_id in(277590, 280673 , 277239) order by (account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
OPEN v_refcur FOR v_query;

    
        FETCH v_refcur bulk collect into x_result;
        x_count := x_result.COUNT;

    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
    END LOOP;
    
    x_status_code := l_status_code;
    x_error_message := l_error_message;
        
    EXCEPTION
        WHEN lv_input_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN lv_generic_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN OTHERS THEN
            x_status_code := 'E';
            x_error_message := 'An error was encountered - '
                               || sqlcode
                               || ' -ERROR- '
                               || sqlerrm;
            dbms_output.put_line(x_error_message);

    END XX_ACCOUNTS_FETCH;
    
    
      -- XX_ADDRESS_FETCH procedure
    PROCEDURE XX_ADDRESS_FETCH (
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT address_fetch_result_table
    ) AS

        v_query         CLOB;
        v_query_count   CLOB;
        TYPE stagedatacursortype IS REF CURSOR;
        v_refcur        stagedatacursortype;
        lv_input_error EXCEPTION;
        lv_generic_error EXCEPTION;
        l_status_code   VARCHAR2(10);
        l_error_message VARCHAR2(4000);
        BEGIN
    l_status_code := 'S';
    l_error_message := '';
    -- validate input parameters
    IF p_counter IS NULL OR p_limit IS NULL THEN
        l_status_code := 'E';
        l_error_message := 'Input parameters missing';
        RAISE lv_input_error;
    END IF;
    -- Initialize the dynamic SQL query
    v_query := 'SELECT
    account_site_id ,
    account_id ,
    primary_flag ,
    site_use_code ,
    address1 ,
    address2 ,
    address3 ,
    city ,
    state_prov ,
    zipcode ,
    CASE WHEN primary_flag = ''Y'' and site_use_code = ''BILL_TO'' THEN ''TRUE'' ELSE ''FALSE'' END  ,
    CASE WHEN primary_flag = ''Y'' and site_use_code = ''SHIP_TO'' THEN ''TRUE'' ELSE ''FALSE'' END ,
    country ,
    party_site_name ,
    third_party_accounts ,
    site_use_id 
FROM
    xxdjo.djoar_ebs_occ_acct_addr
WHERE
    
    occ_interfaced = ''I'' and account_id in(251970, 250874, 250883) order by (account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
OPEN v_refcur FOR v_query;

    
        FETCH v_refcur bulk collect into x_result;
        x_count := x_result.COUNT;

    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
    END LOOP;

        
    EXCEPTION
        WHEN lv_input_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN lv_generic_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN OTHERS THEN
            x_status_code := 'E';
            x_error_message := 'An error was encountered - '
                               || sqlcode
                               || ' -ERROR- '
                               || sqlerrm;
            dbms_output.put_line(x_error_message);

    END XX_ADDRESS_FETCH;
    
     -- XX_PROFILE_FETCH procedure
    PROCEDURE XX_PROFILE_FETCH (
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_count OUT NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT profile_fetch_result_table
    ) AS

        v_query         CLOB;
        v_query_count   CLOB;
        TYPE stagedatacursortype IS REF CURSOR;
        v_refcur        stagedatacursortype;
        lv_input_error EXCEPTION;
        lv_generic_error EXCEPTION;
        l_status_code   VARCHAR2(10);
        l_error_message VARCHAR2(4000);
        BEGIN
    l_status_code := 'S';
    l_error_message := '';
    -- validate input parameters
    IF p_counter IS NULL OR p_limit IS NULL THEN
        l_status_code := 'E';
        l_error_message := 'Input parameters missing';
        RAISE lv_input_error;
    END IF;
    -- Initialize the dynamic SQL query
    v_query := 'SELECT
    contactid,
    account_id,
    first_name,
    last_name,
    email_address,
    phone_number,
    role,
    last_update_date
FROM
    xxdjo.djoar_ebs_occ_acct_contacts
WHERE
    
    occ_interfaced = ''I'' and email_address IS NOT NULL and first_name IS NOT NULL and last_name IS NOT NULL and account_id in(251970, 250874, 250883) order by (account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
OPEN v_refcur FOR v_query;

    
        FETCH v_refcur bulk collect into x_result;
        x_count := x_result.COUNT;

    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
    END LOOP;

        
    EXCEPTION
        WHEN lv_input_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN lv_generic_error THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
            dbms_output.put_line(x_error_message);
        WHEN OTHERS THEN
            x_status_code := 'E';
            x_error_message := 'An error was encountered - '
                               || sqlcode
                               || ' -ERROR- '
                               || sqlerrm;
            dbms_output.put_line(x_error_message);

    END XX_PROFILE_FETCH;

END djooic_ont_history_details_pkg_km;

/

--------------------------------------------------------
--  DDL for Package Body DJOOIC_ONT_HISTORY_DETAILS_PKG_ABHI
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG_ABHI" AS
  -- XX_ORDER_SEARCH procedure
    PROCEDURE xx_order_search (
        p_org_id          IN NUMBER,
        p_cust_account_id IN NUMBER,
        p_order_number    IN VARCHAR2,
        p_order_status    IN VARCHAR2,
        p_purchase_order  IN VARCHAR2,
        p_ship_to_account IN VARCHAR2,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_page_number     IN NUMBER,
        p_limit           IN NUMBER,
        p_operator_code   IN VARCHAR2,
        x_count           OUT NUMBER,
        x_status_code     OUT VARCHAR2,
        x_error_message   OUT VARCHAR2,
        x_result          OUT order_search_result_table
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
        IF p_org_id IS NULL OR p_cust_account_id IS NULL OR p_page_number IS NULL OR p_limit IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameters missing';
            RAISE lv_input_error;
        END IF;
    
    
    
    -- Initialize the dynamic SQL query
        v_query := 'SELECT oha.ORIG_SYS_DOCUMENT_REF,oha.header_id,oha.order_number,oha.flow_status_code,oha.ordered_date,oha.booked_date,oha.cust_po_number '
        ;
        v_query_count := 'SELECT count(*) ';
        v_query := v_query || 'FROM apps.oe_order_headers_all   oha,apps.hz_cust_site_uses_all  hcsua_ship,apps.hz_cust_acct_sites_all hcasa_ship '
        ;
        v_query_count := v_query_count || 'FROM apps.oe_order_headers_all   oha,apps.hz_cust_site_uses_all  hcsua_ship,apps.hz_cust_acct_sites_all hcasa_ship '
        ;
        v_query := v_query || 'WHERE 1 = 1 AND hcsua_ship.site_use_id = oha.ship_to_org_id AND hcsua_ship.cust_acct_site_id = hcasa_ship.cust_acct_site_id AND oha.order_type_id <> 2512 '
        ;
        v_query_count := v_query_count || 'WHERE 1 = 1 AND hcsua_ship.site_use_id = oha.ship_to_org_id AND hcsua_ship.cust_acct_site_id = hcasa_ship.cust_acct_site_id and oha.order_type_id <> 2512 '
        ;

    -- Add conditions based on input parameters if they are not null or empty
        IF
            p_cust_account_id IS NOT NULL
        THEN
            v_query := v_query
                       || ' AND oha.sold_to_org_id = '
                       || p_cust_account_id;
            v_query_count := v_query_count
                       || ' AND oha.sold_to_org_id = '
                       || p_cust_account_id;
        END IF;
        
        IF p_order_number IS NOT NULL  THEN
       IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number)= '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) = '''|| p_order_number ||''')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) = '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) = '''|| p_order_number ||''')';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number) like ''%'|| p_order_number ||'%'' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like ''%'|| p_order_number ||'%'')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) like ''%'|| p_order_number ||'%'' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like ''%'|| p_order_number ||'%'')';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number) like '''|| p_order_number ||'%'' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like '''|| p_order_number ||'%'')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) like '''|| p_order_number ||'%'' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like '''|| p_order_number ||'%'')';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number)like ''%'|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like ''%'|| p_order_number ||''')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) like ''%'|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) like ''%'|| p_order_number ||''')';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number) < '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) < '''|| p_order_number ||''')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) < '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) < '''|| p_order_number ||''')';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number) > '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) > '''|| p_order_number ||''')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number) > '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) > '''|| p_order_number ||''')';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND (TO_CHAR(oha.order_number) != '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) != '''|| p_order_number ||''')';
         v_query_count := v_query_count || ' AND (TO_CHAR(oha.order_number)!= '''|| p_order_number ||''' OR TO_CHAR(oha.ORIG_SYS_DOCUMENT_REF) != '''|| p_order_number ||''')';

      END IF;

    END IF;


        IF
            p_order_status IS NOT NULL
        THEN
                       
            IF p_operator_code = 'IS' THEN
         v_query := v_query
                       || ' AND UPPER(oha.flow_status_code) = '''
                       || UPPER(p_order_status) ||'''';
         v_query_count := v_query_count
                       || ' AND oha.flow_status_code = '''
                       || p_order_status||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) like ''%'|| UPPER(p_order_status) ||'%''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) like ''%'|| UPPER(p_order_status) ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) like '''|| UPPER(p_order_status) ||'%''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) like '''|| UPPER(p_order_status) ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) like ''%'|| UPPER(p_order_status) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) like ''%'|| UPPER(p_order_status) ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) < '''|| UPPER(p_order_status) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) < '''|| UPPER(p_order_status) ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) > '''|| UPPER(p_order_status) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) > '''|| UPPER(p_order_status) ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND UPPER(oha.flow_status_code) != '''|| UPPER(p_order_status) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.flow_status_code) != '''|| UPPER(p_order_status) ||'''';

      END IF;
        END IF;

        IF
            p_purchase_order IS NOT NULL
        THEN
        IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) = '''|| UPPER(p_purchase_order) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) = '''|| UPPER(p_purchase_order) ||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) like ''%'|| UPPER(p_purchase_order) ||'%''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) like ''%'|| UPPER(p_purchase_order) ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) like '''|| UPPER(p_purchase_order) ||'%''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) like '''|| UPPER(p_purchase_order) ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) like ''%'|| UPPER(p_purchase_order) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) like ''%'|| UPPER(p_purchase_order) ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) < '''|| UPPER(p_purchase_order) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) < '''|| UPPER(p_purchase_order) ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) > '''|| UPPER(p_purchase_order) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) > '''|| UPPER(p_purchase_order) ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND UPPER(oha.cust_po_number) != '''|| UPPER(p_purchase_order) ||'''';
         v_query_count := v_query_count || ' AND UPPER(oha.cust_po_number) != '''||UPPER(p_purchase_order) ||'''';
    END IF;
END IF;

        IF
            p_ship_to_account IS NOT NULL
        THEN
            v_query := v_query
                       || ' AND hcasa_ship.cust_account_id =  '
                       || p_ship_to_account;
            v_query_count := v_query_count
                       || ' AND hcasa_ship.cust_account_id =  '
                       || p_ship_to_account;
        END IF;

        IF p_start_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(oha.ordered_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(oha.ordered_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
        END IF;

        IF p_end_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(oha.ordered_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(oha.ordered_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
        END IF;
        
        IF p_org_id IS NOT NULL AND p_org_id <> '' THEN
      v_query := v_query || 'AND oha.org_id = '||p_org_id ;
      v_query_count := v_query_count || 'AND oha.org_id = '||p_org_id ;
    END IF;
             
        v_query := v_query || ' ORDER BY (oha.ordered_date) DESC offset nvl(('||p_page_number||'-1),0) * '||p_limit||' rows FETCH NEXT '||p_limit||' ROWS ONLY';
       
    --v_query := v_query || ' AND <5';
       
        dbms_output.put_line(v_query);
        dbms_output.put_line(v_query_count);
        
        EXECUTE immediate v_query_count into x_count;
        
    -- Execute the dynamic query and populate the result into the p_result collection
        OPEN v_refcur FOR v_query;

        FETCH v_refcur
        BULK COLLECT INTO x_result;
        dbms_output.put_line(x_result.count);
        FOR i IN 1..x_result.count LOOP
            dbms_output.put_line(x_result(i).cust_po_number);
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
    END xx_order_search;

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



        cursor c_order_header(cp_header_id NUMBER)
        IS
SELECT ooh.header_id                  order_id,
       ooh.order_number               ebs_order_number,
       ooh.orig_sys_document_ref      alt_order_number,
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
       ooh.attribute4                 third_party_account,
       ooh.attribute6                 one_time_third_party_account,
       NVL (apps.oe_totals_grp.get_order_total (ooh.header_id, NULL, 'ALL'),
            0)                        order_total,
       os.name                        order_source,
       ooh.sold_to_contact_id,
       mp.organization_code,
       ooh.fob_point_code,
       ooh.freight_terms_code,
       --ooh.sold_to_contact_id,
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
       AND ooh.header_id = p_header_id -- 1590800
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
       AND ooh.payment_term_id(+) = trm.term_id
       AND ooh.order_source_id(+) = os.order_source_id
       --
       AND hcar.role_type(+) = 'CONTACT'
       AND hcar.party_id = hr.party_id(+)
       AND hr.relationship_code(+) = 'CONTACT_OF'
       AND hr.subject_id = sold_party.party_id(+)
       AND hcar.cust_account_id(+) = hca_ship.cust_account_id 
       AND hcar.cust_account_role_id (+) = ooh.sold_to_contact_id--2042156 
       --
       AND hcp.owner_table_id(+)= hcar.party_id
       AND hcp.owner_table_name(+) = 'HZ_PARTIES' 
       AND hcp.contact_point_type(+) = 'EMAIL';




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


        FETCH c_order_header BULK COLLECT INTO x_result;
        CLOSE c_order_header;
        dbms_output.put_line(x_result.count);
        FOR i IN 1..x_result.count LOOP
            dbms_output.put_line(x_result(i).order_number);

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
    
        PROCEDURE xx_order_line_details(
        p_header_id       IN NUMBER,
        x_status_code     OUT VARCHAR2,
        x_error_message   OUT VARCHAR2,
        x_result          OUT order_line_details_table
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
        l_tracking_details tracking_details_table;
        l_result       order_line_details_table := order_line_details_table();
        
          TYPE l_line_details_rec IS RECORD (
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
    item_price NUMBER);
    
    TYPE l_line_details_table IS TABLE OF l_line_details_rec;
    l_line_details l_line_details_table;
        
        cursor c_order_header(cp_header_id NUMBER)
        IS
        SELECT ola.line_id,
       ola.header_id,
       ola.ordered_item                                item_number,
       oha.order_number                                ebs_order_number,
       msi.description                                 item_name,
       ola.flow_status_code                            item_status,
       ola.ordered_quantity                            ordered,
       ola.shipped_quantity                            shipped,
       uom.unit_of_measure                          unit_of_measure,
       (ola.unit_selling_price * ordered_quantity)     item_total,
       ola.unit_selling_price                          item_price
  FROM apps.oe_order_headers_all  oha,
       apps.oe_order_lines_all    ola,
       apps.mtl_system_items_b    msi,
       apps.mtl_units_of_measure_tl   uom
 WHERE     oha.header_id = ola.header_id
       AND msi.segment1 = ola.ordered_item
       AND msi.organization_id = NVL(ola.SHIP_FROM_ORG_ID,82)
       and uom.UOM_CODE = ola.order_quantity_uom
       AND ola.header_id = cp_header_id
       and uom.language = 'E'
       order by 1;
       --AND oha.order_number = '3973563'
       
    CURSOR c_track_details(cp_header_id NUMBER, cp_line_id NUMBER)
    IS
    SELECT
        wdd.tracking_number TRACKING_NUMBER,
        wdd.shipped_quantity SHIPPED_QUANTITY,
        fl.meaning SHIPPING_METHOD,
        wnd.confirm_date SHIP_DATE,
        wda.delivery_id DELIVERY_ID
        FROM
        apps.wsh_delivery_details     wdd,
        apps.wsh_new_deliveries       wnd,
        apps.wsh_delivery_assignments wda,
        apps.fnd_lookup_values_vl fl
        WHERE
            wdd.source_header_id = cp_header_id
        AND wdd.source_line_id = cp_line_id
        AND wdd.delivery_detail_id = wda.delivery_detail_id
        AND wda.delivery_id = wnd.delivery_id
        AND fl.enabled_flag='Y'
        AND fl.LOOKUP_TYPE = 'SHIP_METHOD'
        and fl.VIEW_APPLICATION_ID = 3
        and fl.LOOKUP_CODE =  wdd.SHIP_METHOD_CODE
        and sysdate between fl.start_date_active and nvl(fl.end_date_active,sysdate);
        
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
    
            
            FETCH c_order_header BULK COLLECT INTO l_line_details;
            CLOSE c_order_header;
            dbms_output.put_line(l_line_details.count);
            FOR i IN 1..l_line_details.count LOOP
            dbms_output.put_line(l_line_details(i).order_number);
            
            l_result.EXTEND;
            l_result(i).line_id := l_line_details(i).line_id;
            l_result(i).header_id := l_line_details(i).header_id;
            l_result(i).ordered_item := l_line_details(i).ordered_item;
            l_result(i).order_number := l_line_details(i).order_number;
            l_result(i).description := l_line_details(i).description;
            l_result(i).flow_status_code := l_line_details(i).flow_status_code;
            l_result(i).ordered := l_line_details(i).ordered;
            l_result(i).shipped := l_line_details(i).shipped;
            l_result(i).ORDER_QUANTITY_UOM := l_line_details(i).ORDER_QUANTITY_UOM;
            l_result(i).item_total := l_line_details(i).item_total;
            l_result(i).item_price := l_line_details(i).item_price;
            
            dbms_output.put_line('line number'||l_line_details(i).line_id);
            dbms_output.put_line('After assignment');
           OPEN c_track_details(l_result(i).header_id,l_result(i).line_id);
            
            l_tracking_details := tracking_details_table();
            
            FETCH c_track_details BULK COLLECT INTO l_tracking_details;
            CLOSE c_track_details;
            
            
            /*LOOP
                l_tracking_details.extend;
                FETCH c_track_details INTO l_tracking_details;
                exit when c_track_details%notfound;
            
            END LOOP;*/
            
            l_result(i).tracking_details := l_tracking_details;
            
            
        END LOOP;
        
        x_result := l_result;
        

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
    END xx_order_line_details;
    
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
        l_third_party_accounts VARCHAR2(4000);
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
    acct.account_id,
    acct.organization_name,
    acct.payment_terms_id,
    acct.frieght_terms,
    acct.account_number,
    acct.acc_payment_method,
    acct.shipping_method,
    replace(NVL(addr.price_list,acct.price_list),'' '',''_'')||''_''||account_number,
    replace(NVL(addr.price_list,acct.price_list),'' '',''_'')||''_Filtered'',
    NULL,
    DECODE(addr.operating_unit,''US Operating Unit'',''siteUS'',''CA Operating Unit'',''100001'')
  FROM
    xxdjo.djoar_ebs_cust_acct acct, xxdjo.djoar_ebs_cust_acct_addr addr
  WHERE
    acct.interfaced_flag = ''I'' and addr.account_id = acct.account_id and addr.site_use_code = ''BILL_TO'' and addr.primary_flag = ''Y'' order by (acct.account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
        DBMS_OUTPUT.PUT_LINE(v_query);
OPEN v_refcur FOR v_query;

    
    FETCH v_refcur bulk collect into x_result;
        x_count := x_result.COUNT;

    FOR i in 1..x_result.COUNT LOOP
    
        SELECT
            LISTAGG(third_party_accounts, ',')
        INTO x_result(i).third_party_accounts
        FROM
            xxdjo.djoar_ebs_cust_acct_addr
        WHERE
            account_id = x_result(i).account_id
            AND site_use_code = 'BILL_TO';
            
        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
        DBMS_OUTPUT.PUT_LINE(x_result(i).third_party_accounts);
        
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
        l_ship_to_contacts ship_to_contact_table;
        
        
              
        TYPE l_address_details_rec IS RECORD (
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
            payment_method VARCHAR2(1000)
            );
    
    TYPE l_address_details_table IS TABLE OF l_address_details_rec;
    l_address_details l_address_details_table;
    l_result       address_fetch_result_table := address_fetch_result_table();
    
    CURSOR c_ship_to_contacts(cp_account_site_id NUMBER)
    IS
    SELECT
        contactid,
        phone_number,
        first_name,
        last_name
    FROM
        xxdjo.djoar_ebs_cust_acct_contacts
    WHERE
        account_site_id = cp_account_site_id
        and responsibility_type='SHIP_TO';
    
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
    NVL(address1,'''') ,
    NVL(address2,'''') ,
    NVL(address3,'''') ,
    city ,
    state_prov ,
    zipcode ,
    CASE WHEN primary_flag = ''Y'' and site_use_code = ''BILL_TO'' THEN ''true'' ELSE ''false'' END  ,
    CASE WHEN primary_flag = ''Y'' and site_use_code = ''SHIP_TO'' THEN ''true'' ELSE ''false'' END ,
    country ,
    party_site_name ,
    third_party_accounts ,
    site_use_id,
    payment_terms_id,
    SITE_PAYMENT_METHOD
FROM
    xxdjo.djoar_ebs_cust_acct_addr
WHERE
    
    interfaced_flag = ''I'' order by (account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
           
           DBMS_OUTPUT.PUT_LINE(v_query);
        
OPEN v_refcur FOR v_query;

     
    
    
    FETCH v_refcur bulk collect into l_address_details;
         x_count := l_address_details.COUNT;
        
    FOR i in 1..l_address_details.COUNT LOOP
    
        l_result.EXTEND;
        l_result(i).account_site_id := l_address_details(i).account_site_id;
        l_result(i).account_id := l_address_details(i).account_id;
        l_result(i).primary_flag := l_address_details(i).primary_flag;
        l_result(i).site_use_code := l_address_details(i).site_use_code;
        l_result(i).address1 := l_address_details(i).address1;
        l_result(i).address2 := l_address_details(i).address2;
        l_result(i).address3 := l_address_details(i).address3;
        l_result(i).city := l_address_details(i).city;
        l_result(i).state_prov := l_address_details(i).state_prov;
        l_result(i).zipcode := l_address_details(i).zipcode;
        l_result(i).is_default_billing_addr := l_address_details(i).is_default_billing_addr;
        l_result(i).is_default_shipping_addr := l_address_details(i).is_default_shipping_addr;
        l_result(i).country := l_address_details(i).country;
        l_result(i).party_site_name := l_address_details(i).party_site_name;
        l_result(i).third_party_accounts := l_address_details(i).third_party_accounts;
        l_result(i).site_use_id := l_address_details(i).site_use_id;
        l_result(i).payment_terms := l_address_details(i).payment_terms;
        l_result(i).payment_method := l_address_details(i).payment_method;
        
            
            dbms_output.put_line('After assignment');
           OPEN c_ship_to_contacts(l_result(i).account_site_id);
            
            l_ship_to_contacts := ship_to_contact_table();
            
            FETCH c_ship_to_contacts BULK COLLECT INTO l_ship_to_contacts;
            CLOSE c_ship_to_contacts;
            
            l_result(i).ship_to_contacts := l_ship_to_contacts;
        DBMS_OUTPUT.PUT_LINE(l_address_details(i).account_id);
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
        l_parent_org parent_org_table;
        
        TYPE l_profile_details_rec IS RECORD (
            contactid NUMBER,
            account_id NUMBER,
            first_name VARCHAR2(50),
            last_name VARCHAR2(50),
            email_address VARCHAR2(50),
            phone_number VARCHAR2(50),
            last_update_date DATE);
    
    TYPE l_profile_details_table IS TABLE OF l_profile_details_rec;
    l_profile_details l_profile_details_table;
    
    l_result profile_fetch_result_table := profile_fetch_result_table();
    
    CURSOR c_parent_org_details(cp_email_address NUMBER)
    IS
    SELECT
    account_id,
        role
    FROM
        xxdjo.djoar_ebs_cust_acct_contacts
    WHERE
        email_address = cp_email_address
        and account_site_id is null
        ;
        
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
    -- account_site_id 
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
    xxdjo.djoar_ebs_cust_acct_contacts
WHERE
    
    interfaced_flag = ''I'' and email_address IS NOT NULL and first_name IS NOT NULL and last_name IS NOT NULL and account_site_id is null order by (account_id) offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
OPEN v_refcur FOR v_query;

    
        FETCH v_refcur bulk collect into l_profile_details;
         x_count := l_profile_details.COUNT;
        

    FOR i in 1..l_profile_details.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).account_id);
        l_result.EXTEND;
        l_result(i).contactid := l_profile_details(i).contactid;
        l_result(i).account_id := l_profile_details(i).account_id;
        l_result(i).first_name := l_profile_details(i).first_name;
        l_result(i).last_name := l_profile_details(i).last_name;
        l_result(i).email_address := l_profile_details(i).email_address;
        l_result(i).phone_number := l_profile_details(i).phone_number;
        l_result(i).last_update_date := l_profile_details(i).last_update_date;
        
        dbms_output.put_line('After assignment');
        OPEN c_parent_org_details(l_result(i).email_address);
            
        l_parent_org := parent_org_table();
            
        FETCH c_parent_org_details BULK COLLECT INTO l_parent_org;
        CLOSE c_parent_org_details;
            
        l_result(i).parent_org_details := l_parent_org;


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

    END XX_PROFILE_FETCH;
    

    -- XX_INVENTORY_FETCH procedure
    PROCEDURE XX_INVENTORY_FETCH(
    p_counter IN NUMBER,
    p_limit IN NUMBER,
    x_status_code OUT VARCHAR2,
    x_error_message OUT VARCHAR2,
    x_result OUT inventory_sync_table,
    x_count OUT NUMBER
  )
     AS

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
    v_query := 'SELECT item,parent_catalog,onhand_quantity from(
    select item,DECODE(country,''US'',''usSiteInventory'',''CA'',''caSiteInventory'') as parent_catalog,sum(onhand) as onhand_quantity from xxdjo.djoinv_onhand_qty_details where country in (''US'',''CA'') group by item,country) order by item offset nvl(('
           || p_counter
           || '-1),0) * '
           || p_limit
           || ' rows FETCH NEXT '
           || p_limit
           || ' ROWS ONLY ';
        
        DBMS_OUTPUT.PUT_LINE(v_query);
    
OPEN v_refcur FOR v_query;

    --LOOP
        FETCH v_refcur bulk collect into x_result;
      --  EXIT WHEN v_refcur%NOTFOUND;

        --DBMS_OUTPUT.PUT_LINE(x_result.count);
    --END LOOP;

    x_count := x_result.COUNT;
    
    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).item_number || ':'|| x_result(i).parent_catalog || ':'|| x_result(i).onhand_quantity);
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

    END XX_INVENTORY_FETCH;
    
    
END djooic_ont_history_details_pkg_abhi;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_ONT_HISTORY_DETAILS_PKG_ABHI" TO "XXOIC";

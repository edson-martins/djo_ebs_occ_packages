--------------------------------------------------------
--  DDL for Package Body DJOOIC_AR_HISTORY_DETAILS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_AR_HISTORY_DETAILS_PKG" AS
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
    IF p_account_id IS NULL OR p_page_number IS NULL OR p_limit IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameters missing';
            RAISE lv_input_error;
    END IF;
    -- Initialize the dynamic SQL query
    v_query := 'SELECT  txa.customer_trx_id,
    txa.trx_number,
    txa.interface_header_attribute1                          ebs_order_number,
    ooh.header_id ebs_order_id,
    paya.class,
    paya.status,
    txa.trx_date,
    paya.due_date,
    txa.purchase_order,
    paya.amount_line_items_original,
    paya.freight_original,
    paya.tax_original,
    paya.amount_due_original,
    paya.amount_due_remaining,
    ( paya.amount_due_original - paya.amount_due_remaining ) applied_amount ';

    v_query_count := 'SELECT count(*) ';

    v_query := v_query || 'FROM apps.ra_customer_trx_all      txa,
    apps.ar_payment_schedules_all paya,
    apps.hz_cust_accounts         hz_bt,
    apps.hr_operating_units       hr,
    apps.hz_cust_accounts         hz_st,
    apps.oe_order_headers_all ooh ';

     v_query_count := v_query_count || 'FROM apps.ra_customer_trx_all      txa,
    apps.ar_payment_schedules_all paya,
    apps.hz_cust_accounts         hz_bt,
    apps.hr_operating_units       hr,
    apps.hz_cust_accounts         hz_st,
    apps.oe_order_headers_all ooh ';

    v_query := v_query || 'WHERE paya.class=''INV'' AND paya.customer_trx_id = txa.customer_trx_id AND txa.org_id = hr.organization_id AND txa.bill_to_customer_id = hz_bt.cust_account_id AND txa.ship_to_customer_id = hz_st.cust_account_id AND txa.interface_header_attribute1=ooh.order_number ';
    v_query_count := v_query_count || 'WHERE paya.class=''INV'' AND paya.customer_trx_id = txa.customer_trx_id AND txa.org_id = hr.organization_id AND txa.bill_to_customer_id = hz_bt.cust_account_id AND txa.ship_to_customer_id = hz_st.cust_account_id AND txa.interface_header_attribute1=ooh.order_number ';

    -- Add conditions based on input parameters if they are not null or empty
    IF p_account_id IS NOT NULL  THEN
      v_query := v_query || 'AND hz_bt.cust_account_id = '||p_account_id||'' ;
      v_query_count := v_query_count || 'AND hz_bt.cust_account_id =  '||p_account_id||'' ;

    END IF;

    IF p_order_number IS NOT NULL  THEN
       IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) = '''|| p_order_number ||'''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) = '''|| p_order_number ||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) like ''%'|| p_order_number ||'%''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) like ''%'|| p_order_number ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) like '''|| p_order_number ||'%''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) like '''|| p_order_number ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) like ''%'|| p_order_number ||'''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) like ''%'|| p_order_number ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) < '''|| p_order_number ||'''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) < '''|| p_order_number ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) > '''|| p_order_number ||'''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) > '''|| p_order_number ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND TO_CHAR(txa.interface_header_attribute1) != '''|| p_order_number ||'''';
         v_query_count := v_query_count || ' AND TO_CHAR(txa.interface_header_attribute1) != '''|| p_order_number ||'''';

      END IF;

    END IF;

    IF p_purchase_order IS NOT NULL  THEN

      IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND txa.purchase_order = '''|| p_purchase_order ||'''';
         v_query_count := v_query_count || ' AND txa.purchase_order = '''|| p_purchase_order ||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND txa.purchase_order like ''%'|| p_purchase_order ||'%''';
         v_query_count := v_query_count || ' AND txa.purchase_order like ''%'|| p_purchase_order ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND txa.purchase_order like '''|| p_purchase_order ||'%''';
         v_query_count := v_query_count || ' AND txa.purchase_order like '''|| p_purchase_order ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND txa.purchase_order like ''%'|| p_purchase_order ||'''';
         v_query_count := v_query_count || ' AND txa.purchase_order like ''%'|| p_purchase_order ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND txa.purchase_order < '''|| p_purchase_order ||'''';
         v_query_count := v_query_count || ' AND txa.purchase_order < '''|| p_purchase_order ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND txa.purchase_order > '''|| p_purchase_order ||'''';
         v_query_count := v_query_count || ' AND txa.purchase_order > '''|| p_purchase_order ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND txa.purchase_order != '''|| p_purchase_order ||'''';
         v_query_count := v_query_count || ' AND txa.purchase_order != '''||p_purchase_order ||'''';
    END IF;
END IF;

    IF p_ship_to_account IS NOT NULL  THEN

      IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND hz_st.account_number =  '''|| p_ship_to_account ||'''';
         v_query_count := v_query_count || ' AND hz_st.account_number =  '''|| p_ship_to_account ||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND hz_st.account_number like ''%'|| p_ship_to_account ||'%''';
         v_query_count := v_query_count || ' AND hz_st.account_number like ''%'|| p_ship_to_account ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND hz_st.account_number like '''|| p_ship_to_account ||'%''';
         v_query_count := v_query_count || ' AND hz_st.account_number like '''|| p_ship_to_account ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND hz_st.account_number like ''%'|| p_ship_to_account ||'''';
         v_query_count := v_query_count || ' AND hz_st.account_number like '' % ' || p_ship_to_account || '''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND hz_st.account_number < '''|| p_ship_to_account ||'''';
         v_query_count := v_query_count || ' AND hz_st.account_number < '''|| p_ship_to_account ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND hz_st.account_number > '''|| p_ship_to_account ||'''';
         v_query_count := v_query_count || ' AND hz_st.account_number > '''|| p_ship_to_account ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND hz_st.account_number != '''|| p_ship_to_account ||'''';
         v_query_count := v_query_count || ' AND hz_st.account_number != '''|| p_ship_to_account ||'''';
    END IF;
    END IF;

    IF p_inv_num IS NOT NULL  THEN

      IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND txa.trx_number =  '''||p_inv_num||'''';
         v_query_count := v_query_count || ' AND txa.trx_number =  '''||p_inv_num||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND txa.trx_number like ''%'|| p_inv_num ||'%''';
         v_query_count := v_query_count || ' AND txa.trx_number like ''%'|| p_inv_num ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND txa.trx_number like '''|| p_inv_num ||'%''';
         v_query_count := v_query_count || ' AND txa.trx_number like '''|| p_inv_num ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND txa.trx_number like ''%'|| p_inv_num ||'''';
         v_query_count := v_query_count || ' AND txa.trx_number like ''%'|| p_inv_num ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND txa.trx_number < '''|| p_inv_num ||'''';
         v_query_count := v_query_count || ' AND txa.trx_number < '''|| p_inv_num ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND txa.trx_number > '''|| p_inv_num ||'''';
         v_query_count := v_query_count || ' AND txa.trx_number > '''|| p_inv_num ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND txa.trx_number != '''|| p_inv_num ||'''';
         v_query_count := v_query_count || ' AND txa.trx_number != '''|| p_inv_num ||'''';
    END IF;
   END IF;

    IF p_start_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(txa.trx_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(txa.trx_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
    END IF;

    IF p_end_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(txa.trx_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(txa.trx_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
    END IF;

    --v_query := v_query || ' AND <5';
    v_query := v_query || ' ORDER BY (txa.trx_date) DESC offset nvl(('||p_page_number||'-1),0) * '||p_limit||' rows FETCH NEXT '||p_limit||' ROWS ONLY';
    dbms_output.put_line(v_query);
    dbms_output.put_line(v_query_count);

    EXECUTE immediate v_query_count into x_count;
    -- Execute the dynamic query and populate the result into the p_result collection
    OPEN v_refcur FOR v_query;

    LOOP
        FETCH v_refcur bulk collect into x_result limit 100;
        EXIT WHEN v_refcur%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(x_result.count);
    END LOOP;

    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).customer_trx_id);
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

    END XX_INVOICE_SEARCH;
    

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
    IF p_account_id IS NULL OR p_page_number IS NULL OR p_limit IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameters missing';
            RAISE lv_input_error;
    END IF;
    -- Initialize the dynamic SQL query
    v_query := 'SELECT  arc.receipt_number,
    arc.cash_receipt_id                                                              receipt_id,
    hp.party_name,
    arc.receipt_date                                                                 receipt_date,
    arc.type                                                                         payment_type,
    arc.amount                                                                       receipt_amount,
    abs(apsa.amount_due_remaining)                          unapplied_amount,
    arc.amount-abs(apsa.amount_due_remaining)               applied_amount, 
    decode(arc.status, ''APP'', ''Applied'', ''UNAPP'', ''Unapplied'',
           ''UNID'', ''Unidentified'', ''REV'', ''Reversed'', ''NSF'',
           ''Reversed Due to Insufficient Funds'', ''STOP'', ''Reversed by Stop Payment'') receipt_status,
    arc.currency_code,
    apsa.due_date    ';

    v_query_count := 'SELECT count(*) ';

    v_query := v_query || 'FROM apps.ar_cash_receipts_all     arc,
    apps.ar_payment_schedules_all apsa,
    apps.hz_cust_accounts         hca,
    apps.hz_parties               hp ';

     v_query_count := v_query_count || 'FROM apps.ar_cash_receipts_all     arc,
    apps.ar_payment_schedules_all apsa,
    apps.hz_cust_accounts         hca,
    apps.hz_parties               hp ';

    v_query := v_query || 'WHERE  1 = 1
    AND apsa.cash_receipt_id = arc.cash_receipt_id
    AND hca.cust_account_id = arc.pay_from_customer
    AND hca.party_id = hp.party_id ';
    v_query_count := v_query_count || 'WHERE  1 = 1
    AND apsa.cash_receipt_id = arc.cash_receipt_id
    AND hca.cust_account_id = arc.pay_from_customer
    AND hca.party_id = hp.party_id ';

    -- Add conditions based on input parameters if they are not null or empty
    IF p_account_id IS NOT NULL  THEN
      v_query := v_query || 'AND hca.cust_account_id  = '||p_account_id||'' ;
      v_query_count := v_query_count || 'AND hca.cust_account_id  = '||p_account_id||'' ;

    END IF;

    IF p_payment_number IS NOT NULL  THEN
       IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND arc.receipt_number = '''|| p_payment_number ||'''';
         v_query_count := v_query_count || ' AND arc.receipt_number = '''|| p_payment_number ||'''';

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND arc.receipt_number like ''%'|| p_payment_number ||'%''';
         v_query_count := v_query_count || ' AND arc.receipt_number like ''%'|| p_payment_number ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND arc.receipt_number like '''|| p_payment_number ||'%''';
         v_query_count := v_query_count || ' AND arc.receipt_number like '''|| p_payment_number ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND arc.receipt_number like ''%'|| p_payment_number ||'''';
         v_query_count := v_query_count || ' AND arc.receipt_number like ''%'|| p_payment_number ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND arc.receipt_number < '''|| p_payment_number ||'''';
         v_query_count := v_query_count || ' AND arc.receipt_number < '''|| p_payment_number ||'''';

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND arc.receipt_number > '''|| p_payment_number ||'''';
         v_query_count := v_query_count || ' AND arc.receipt_number > '''|| p_payment_number ||'''';

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND arc.receipt_number != '''|| p_payment_number ||'''';
         v_query_count := v_query_count || ' AND arc.receipt_number != '''|| p_payment_number ||'''';

      END IF;

    END IF;
    
    IF p_payment_amount IS NOT NULL  THEN
       IF p_operator_code = 'IS' THEN
         v_query := v_query || ' AND arc.amount = '|| p_payment_amount ;
         v_query_count := v_query_count || ' AND arc.amount = '|| p_payment_amount;

       ELSIF p_operator_code = 'CONTAIN' THEN
         v_query := v_query || ' AND arc.amount like ''%'|| p_payment_amount ||'%''';
         v_query_count := v_query_count || ' AND arc.amount like ''%'|| p_payment_amount ||'%''';

       ELSIF p_operator_code = 'STARTS' THEN
         v_query := v_query || ' AND arc.amount like '''|| p_payment_amount ||'%''';
         v_query_count := v_query_count || ' AND arc.amount like '''|| p_payment_amount ||'%''';

       ELSIF p_operator_code = 'ENDS' THEN
         v_query := v_query || ' AND arc.amount like ''%'|| p_payment_amount ||'''';
         v_query_count := v_query_count || ' AND arc.amount like ''%'|| p_payment_amount ||'''';

       ELSIF p_operator_code = 'LESS' THEN
         v_query := v_query || ' AND arc.amount < '|| p_payment_amount ;
         v_query_count := v_query_count || ' AND arc.amount < '|| p_payment_amount ;

       ELSIF p_operator_code = 'GREATER' THEN
         v_query := v_query || ' AND arc.amount > '|| p_payment_amount ;
         v_query_count := v_query_count || ' AND arc.amount > '|| p_payment_amount ;

       ELSIF p_operator_code = 'NOT' THEN
         v_query := v_query || ' AND arc.amount != '|| p_payment_amount;
         v_query_count := v_query_count || ' AND arc.amount != '|| p_payment_amount;

      END IF;

    END IF;


    IF p_start_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(arc.receipt_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(arc.receipt_date,''DD-MON-YYYY'') >= TO_DATE('''
                       || p_start_date || ''',''DD-MON-YYYY'')';
    END IF;

    IF p_end_date IS NOT NULL THEN
            v_query := v_query
                       || ' AND TO_DATE(arc.receipt_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
            v_query_count := v_query_count
                       || ' AND TO_DATE(arc.receipt_date,''DD-MON-YYYY'') <= TO_DATE('''
                       || p_end_date || ''',''DD-MON-YYYY'')';
    END IF;

    --v_query := v_query || ' AND <5';
    v_query := v_query || ' ORDER BY (arc.receipt_date) DESC offset nvl(('||p_page_number||'-1),0) * '||p_limit||' rows FETCH NEXT '||p_limit||' ROWS ONLY';
    dbms_output.put_line(v_query);
    dbms_output.put_line(v_query_count);

    EXECUTE immediate v_query_count into x_count;
    -- Execute the dynamic query and populate the result into the p_result collection
    OPEN v_refcur FOR v_query;

    LOOP
        FETCH v_refcur bulk collect into x_result limit 100;
        EXIT WHEN v_refcur%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(x_result.count);
    END LOOP;

    FOR i in 1..x_result.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(x_result(i).receipt_date);
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

    END XX_PAYMENT_SEARCH;

END DJOOIC_AR_HISTORY_DETAILS_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_AR_HISTORY_DETAILS_PKG" TO "XXOIC";

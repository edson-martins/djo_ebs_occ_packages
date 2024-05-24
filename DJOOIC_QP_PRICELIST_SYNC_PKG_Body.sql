--------------------------------------------------------
--  DDL for Package Body DJOOIC_QP_PRICELIST_SYNC_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_QP_PRICELIST_SYNC_PKG" AS
  -- XX_INVOICE_SEARCH procedure
      PROCEDURE XX_PRICELIST_FETCH(
        p_counter       IN NUMBER,
        p_limit         IN NUMBER,
        x_status_code   OUT VARCHAR2,
        x_error_message OUT VARCHAR2,
        x_result        OUT pricelist_sync_table,
        x_count         OUT NUMBER
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
        v_query := 'SELECT replace(price_book.price_list, '' '',''_'')|| ''_''|| price_book.account_number occ_price_list_name, price_book.currency_code curr_code,price_list.product_id, price_book.part_number item_number, ''UNIT_PRICE'' method_code, price_book.unit_selling_price list_price   
        FROM DJOQP_PRICEBOOK_STG price_book, djoqp_pricelist_tbl price_list
WHERE     1=1
       AND price_list.price_list_name = price_book.price_list
       AND price_list.item_number = price_book.part_number
       AND price_list.country = price_book.country
       and product_id is not null and price_book.account_number != ''647123'' and price_book.price_list != ''LIST1 PL'' and price_book.country is not null order by occ_price_list_name,item_number offset nvl(('
                   || p_counter
                   || '-1),0) * '
                   || p_limit
                   || ' rows FETCH NEXT '
                   || p_limit
                   || ' ROWS ONLY ';

        dbms_output.put_line(v_query);
        OPEN v_refcur FOR v_query;

    --LOOP
        FETCH v_refcur
        BULK COLLECT INTO x_result;
      --  EXIT WHEN v_refcur%NOTFOUND;

        --DBMS_OUTPUT.PUT_LINE(x_result.count);
    --END LOOP;

        x_count := x_result.count;
        FOR i IN 1..x_result.count LOOP
            dbms_output.put_line(x_result(i).part_number
                                 || ':'
                                 || x_result(i).price_list_name
                                 || ':'
                                 || x_result(i).product_id);
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

    END XX_PRICELIST_FETCH;

END DJOOIC_QP_PRICELIST_SYNC_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_QP_PRICELIST_SYNC_PKG" TO "XXOIC";

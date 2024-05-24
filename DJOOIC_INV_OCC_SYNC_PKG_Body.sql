--------------------------------------------------------
--  DDL for Package Body DJOOIC_INV_OCC_SYNC_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_INV_OCC_SYNC_PKG" AS


    -- XX_INVENTORY_FETCH procedure
    PROCEDURE xx_inventory_fetch (
        p_counter       IN NUMBER,
        p_limit         IN NUMBER,
        x_status_code   OUT VARCHAR2,
        x_error_message OUT VARCHAR2,
        x_result        OUT inventory_sync_table,
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
        v_query := 'SELECT item,parent_catalog,onhand_quantity from(
    select item,DECODE(country,''US'',''usSiteInventory'',''CA'',''caSiteInventory'') as parent_catalog,sum(onhand) as onhand_quantity from xxdjo.djoinv_onhand_qty_details where country in (''US'',''CA'') and ORDERABLE_ON_WEB_FLAG = ''Y'' group by item,country) order by item offset nvl(('
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
            dbms_output.put_line(x_result(i).item_number
                                 || ':'
                                 || x_result(i).parent_catalog
                                 || ':'
                                 || x_result(i).onhand_quantity);
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
    END xx_inventory_fetch;

    PROCEDURE xx_catalog_fetch_1 (
        p_counter       IN NUMBER,
        p_limit         IN NUMBER,
        x_status_code   OUT VARCHAR2,
        x_error_message OUT VARCHAR2,
        x_result        OUT catalog_details_table,
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
        l_header_id     NUMBER;
        l_result        catalog_details_table := catalog_details_table();
        l_pricelists    pricelist_array;
        TYPE product_array IS
            TABLE OF VARCHAR2(30);
        product_ids    product_array;
        CURSOR c_pricelist_details (
            cp_product_id VARCHAR2
        ) IS
        SELECT distinct
            replace(price_list_name,' ','_')||'_Filtered' price_list_id,
            replace(price_list_name,' ','_') id,
            price_list_name
        FROM
            apps.djoqp_pricelist_tbl
        WHERE
            product_id = cp_product_id
        union
        SELECT DECODE(country,'US','usCatalogFiltered','CA','caCatalogFiltered') price_list_id,
        DECODE(country,'US','usCatalogFiltered','CA','caCatalogFiltered') id,
        DECODE(country,'US','usCatalogFiltered','CA','caCatalogFiltered') price_list_name
        FROM
            apps.djoqp_pricelist_tbl
        WHERE
            product_id = cp_product_id
        AND country in ('US','CA')
        ;
       --AND oha.order_number = '3973563'


    BEGIN
        l_status_code := 'S';
        l_error_message := '';
        v_query := 'SELECT distinct product_id FROM apps.DJOQP_PRICELIST_TBL where product_id is not null order by product_id offset nvl(('
                   || p_counter
                   || '-1),0) * '
                   || p_limit
                   || ' rows FETCH NEXT '
                   || p_limit
                   || ' ROWS ONLY ';
                   

    -- validate input parameters
        IF p_counter IS NULL OR p_limit IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameter(s) missing';
            RAISE lv_input_error;
        END IF;
        
        dbms_output.put_line(v_query);
        
        OPEN v_refcur FOR v_query;

        FETCH v_refcur
        BULK COLLECT INTO product_ids;
        CLOSE v_refcur;
        FOR i IN 1..product_ids.count LOOP
            dbms_output.put_line(product_ids(i));
            l_result.extend;
            l_result(i).product_id := product_ids(i);
            OPEN c_pricelist_details(product_ids(i));
            FETCH c_pricelist_details
            BULK COLLECT INTO l_pricelists;
            CLOSE c_pricelist_details;
            l_result(i).pricelist_details := l_pricelists;
        END LOOP;

        
        x_result := l_result;
        x_status_code := l_status_code;
        x_error_message := l_error_message;
        x_count := x_result.count;
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
    END xx_catalog_fetch_1;
    
    -- XX_CATALOG_FETCH procedure
    PROCEDURE xx_catalog_fetch (
        p_counter       IN NUMBER,
        p_limit         IN NUMBER,
        x_status_code   OUT VARCHAR2,
        x_error_message OUT VARCHAR2,
        x_result        OUT inventory_sync_table,
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
        v_query := 'SELECT item,parent_catalog,onhand_quantity from(
    select item_number,''['' || LISTAGG(''{'' || ''id : '' || price_list_id || ''}'', '', '') WITHIN GROUP (ORDER BY price_list_id) ||'']'' AS pricelists FROM apps.DJOQP_PRICELIST_TBL where rownum<5 GROUP BY item_number) order by item offset nvl(('
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
            dbms_output.put_line(x_result(i).item_number
                                 || ':'
                                 || x_result(i).parent_catalog
                                 || ':'
                                 || x_result(i).onhand_quantity);
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
    END xx_catalog_fetch;

END djooic_inv_occ_sync_pkg;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_OCC_SYNC_PKG" TO "XXOIC";

--------------------------------------------------------
--  DDL for Package Body DJOOIC_IBE_INV_EMAIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_IBE_INV_EMAIL_PKG" AS


    -- XX_INV_EMAIL procedure
    PROCEDURE XX_INV_EMAIL(
    p_trx_number IN NUMBER,
    p_org_id IN NUMBER,
    p_email_list IN VARCHAR2,
    x_return_message OUT VARCHAR2,
    x_status_code OUT VARCHAR2
    ) AS

        lv_input_error EXCEPTION;
        lv_generic_error EXCEPTION;
        l_status_code   VARCHAR2(10);
        l_error_message VARCHAR2(4000);
        l_email VARCHAR2(100);
        l_trx_number NUMBER;
        l_org_id NUMBER;
        l_request_id NUMBER;
        l_status VARCHAR2(100);
        l_user_id NUMBER;
    BEGIN
        l_status_code := 'S';
        l_error_message := 'Request processed successfully';
        
        BEGIN
            SELECT user_id 
            INTO l_user_id
            FROM apps.fnd_user 
            WHERE user_name = 'REQUEST';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_user_id := -1;
        END;
    --fnd_global.apps_initialize (fnd_profile.VALUE ('USER_ID'), 50654, 222);
    fnd_global.apps_initialize (l_user_id, 50654, 222);
    
    -- validate input parameters
        IF p_trx_number IS NULL OR p_org_id IS NULL OR p_email_list IS NULL THEN
            l_status_code := 'E';
            l_error_message := 'Input parameters missing';
            RAISE lv_input_error;
        END IF;
        
        FOR i IN 1..REGEXP_COUNT(p_email_list, ',') + 1 LOOP
            l_email := REGEXP_SUBSTR(p_email_list, '[^,]+', 1, i);
      -- call 
            DBMS_OUTPUT.PUT_LINE(l_email);
            
            djoibe_select_inv_print(
            p_trx_number => l_trx_number,
            p_org_id => l_org_id,
            p_email => l_email,
            p_request_id => l_request_id,
            p_status => l_status
            );
            
            IF l_status = 'Failed' THEN
                l_status_code := 'E';
                l_error_message := 'Error while calling djoibe_select_inv_print procedure';
                RAISE lv_generic_error;
            END IF;
            
        END LOOP;

        dbms_output.put_line('Execution Successful');
  
        x_status_code := l_status_code;
        x_return_message := l_error_message;
    EXCEPTION
        WHEN lv_input_error THEN
            x_status_code := l_status_code;
            x_return_message := l_error_message;
            dbms_output.put_line(x_return_message);
        WHEN lv_generic_error THEN
            x_status_code := l_status_code;
            x_return_message := l_error_message;
            dbms_output.put_line(x_return_message);
        WHEN OTHERS THEN
            x_status_code := 'E';
            x_return_message := 'An error was encountered - '
                               || sqlcode
                               || ' -ERROR- '
                               || sqlerrm;
            dbms_output.put_line(x_return_message);
    END XX_INV_EMAIL;

END DJOOIC_IBE_INV_EMAIL_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_IBE_INV_EMAIL_PKG" TO "XXOIC";

--------------------------------------------------------
--  DDL for Package Body DJOOIC_SHIPMENTS_OUTBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_SHIPMENTS_OUTBOUND_PKG" 
IS
    /**************************************************************************************
    *    Copyright (c) DJO
    *     All rights reserved
    ***************************************************************************************
    *
    *   HEADER
    *   Package Body
    *
    *   PROGRAM NAME
    *   DJOOIC_SHIPMENTS_OUTBOUND_PKG.pkb
    *
    *   DESCRIPTION
    *   Creation Script of Package Body for ImplantBase shipments outbound interface
    *
    *   USAGE
    *   To create Package Body of the package DJOOIC_SHIPMENTS_OUTBOUND_PKG
    *
    *   PARAMETERS
    *   ==========
    *   NAME                DESCRIPTION
    *   ----------------- ------------------------------------------------------------------
    *   NA
    *
    *   DEPENDENCIES
    *
    *
    *   CALLED BY
    *
    *
    *   HISTORY
    *   =======
    *
    *   VERSION  DATE        AUTHOR(S)           DESCRIPTION
    *   -------  ----------- ---------------     ---------------------------------------------
    *   1.0      11-APR-2023 Venkata Suresh Babu              Creation
    ***************************************************************************************/
    ------------------------------------------------------------------------------
    -- Private Global variables
    L_MAX_RECORD   NUMBER := 5000;

    /*
    Keep data in staging TABLE
    if staging is empty insert all extracted records
    if staging contain records
       same records exists in extract and staging
       check if any attribute changes
          yes replace staging records
       no do nothing
       new record insert into staging
     */
    ------------------------------------------------------------------------------
    PROCEDURE debug (p_string VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_string   VARCHAR2 (4000) := p_string;
        l_id       NUMBER;
    BEGIN
        l_id := TO_NUMBER (TO_CHAR (SYSDATE, 'YYMMDDHH24MISS'));

        INSERT INTO xxdjo.djooic_be_debug_log_tmp (id, text)
             VALUES (l_id, l_string);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END debug;

    PROCEDURE fnd_debug (p_string VARCHAR2)
    IS
        l_string   VARCHAR2 (4000) := p_string;
        l_id       VARCHAR2 (50);
    BEGIN
        l_id := TO_CHAR (SYSDATE, 'YYMMDDHH24MISS');
        fnd_log.string (fnd_log.level_statement,
                        'DJOOIC_MST_IMPB_OUTBOUND_PKG.extract_hospitals',
                        l_id || ': ' || l_string);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_log.string (fnd_log.level_statement,
                            'DJOOIC_MST_IMPB_OUTBOUND_PKG.extract_hospitals',
                            l_id || ': ' || SQLERRM);
    END fnd_debug;



    PROCEDURE change_shipments_dtls_record (
        p_shipments_dtls_rec   IN     XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG%ROWTYPE,
        p_type                 IN     VARCHAR2,
        x_error_code              OUT VARCHAR2,
        x_error_msg               OUT VARCHAR2)
    IS
        l_shipments_dtls_rec   XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG%ROWTYPE
                                   := p_shipments_dtls_rec;
        l_type                 VARCHAR2 (5) := p_type;
        l_error_code           VARCHAR2 (10) := 'SUCCESS';
    BEGIN
        IF l_type = 'R'
        THEN
            UPDATE XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG
               SET shipment_id = l_shipments_dtls_rec.shipment_id,
                   PART_NUMBER = l_shipments_dtls_rec.PART_NUMBER,
                   LINE_STATUS = l_shipments_dtls_rec.LINE_STATUS,
                   SHIPPED_QUANTITY = l_shipments_dtls_rec.SHIPPED_QUANTITY,
                   LOT_NUMBER = l_shipments_dtls_rec.LOT_NUMBER,
                   TO_SERIAL_NUMBER = l_shipments_dtls_rec.TO_SERIAL_NUMBER,
                   LOT_EXPIRY_DATE = l_shipments_dtls_rec.LOT_EXPIRY_DATE,
                   created_by = 1516,
                   creation_date = SYSDATE,
                   last_updated_by = 1516,
                   last_update_date = SYSDATE,
                   last_update_login = 0,
                   PROCEDURE_PICK_FLAG =
                       l_shipments_dtls_rec.procedure_pick_flag
             WHERE shipment_id = l_shipments_dtls_rec.shipment_id;
        ELSE
            INSERT INTO XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG (
                            SHIPMENT_ID,
                            PART_NUMBER,
                            LINE_STATUS,
                            SHIPPED_QUANTITY,
                            LOT_NUMBER,
                            TO_SERIAL_NUMBER,
                            LOT_EXPIRY_DATE,
                            CREATED_BY,
                            CREATION_DATE,
                            LAST_UPDATED_BY,
                            LAST_UPDATE_DATE,
                            LAST_UPDATE_LOGIN,
                            PROCEDURE_PICK_FLAG)
                 VALUES (l_shipments_dtls_rec.shipment_id,
                         l_shipments_dtls_rec.PART_NUMBER,
                         l_shipments_dtls_rec.LINE_STATUS,
                         l_shipments_dtls_rec.SHIPPED_QUANTITY,
                         l_shipments_dtls_rec.LOT_NUMBER,
                         l_shipments_dtls_rec.TO_SERIAL_NUMBER,
                         l_shipments_dtls_rec.LOT_EXPIRY_DATE,
                         1516,
                         SYSDATE,
                         1516,
                         SYSDATE,
                         0,
                         l_shipments_dtls_rec.procedure_pick_flag);
        END IF;

        COMMIT;
        x_error_code := l_error_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_code := 'ERROR';
            x_error_msg := SQLERRM;
            debug (DBMS_UTILITY.format_error_backtrace || ':' || x_error_msg);
    END change_shipments_dtls_record;

    PROCEDURE change_shipments_stag_record (
        p_shipments_rec   IN     DJOOIC_OE_SHIPMENTS_STG%ROWTYPE,
        p_type            IN     VARCHAR2,
        x_error_code         OUT VARCHAR2,
        x_error_msg          OUT VARCHAR2)
    IS
        l_shipments_rec   DJOOIC_OE_SHIPMENTS_STG%ROWTYPE := p_shipments_rec;
        l_type            VARCHAR2 (5) := p_type;
        l_error_code      VARCHAR2 (10) := 'SUCCESS';
    BEGIN
        IF l_type = 'R'
        THEN
            UPDATE DJOOIC_OE_SHIPMENTS_STG
               SET shipment_id = l_shipments_rec.shipment_id,
                   IMPLANTBASE_REQ_ID = l_shipments_rec.IMPLANTBASE_REQ_ID,
                   TRACKING_NUMBER = l_shipments_rec.TRACKING_NUMBER,
                   DATE_SHIPPED = l_shipments_rec.DATE_SHIPPED,
                   DIST_ACCOUNT_NUMBER = l_shipments_rec.DIST_ACCOUNT_NUMBER,
                   SHIPPING_METHOD = l_shipments_rec.SHIPPING_METHOD,
                   STATUS = l_shipments_rec.STATUS,
                   MANUFACTURER_NUMBER = l_shipments_rec.MANUFACTURER_NUMBER,
                   PART_NUMBER = l_shipments_rec.PART_NUMBER,
                   LINE_STATUS = l_shipments_rec.LINE_STATUS,
                   SHIPPED_QUANTITY = l_shipments_rec.SHIPPED_QUANTITY,
                   LOT_NUMBER = l_shipments_rec.LOT_NUMBER,
                   TO_SERIAL_NUMBER = l_shipments_rec.TO_SERIAL_NUMBER,
                   LOT_EXPIRY_DATE = l_shipments_rec.LOT_EXPIRY_DATE,
                   ERROR_CODE = 'SUCCESS',
                   error_message = NULL,
                   oic_status = 'N',
                   oic_error_message = NULL,
                   Interface_Identifier = 'IMPB_SURG',
                   created_by = 1516,
                   creation_date = SYSDATE,
                   last_updated_by = 1516,
                   last_update_date = SYSDATE,
                   last_update_login = 0
             WHERE shipment_id = l_shipments_rec.shipment_id;
        ELSE
            INSERT INTO DJOOIC_OE_SHIPMENTS_STG (shipment_id,
                                                 IMPLANTBASE_REQ_ID,
                                                 TRACKING_NUMBER,
                                                 DATE_SHIPPED,
                                                 DIST_ACCOUNT_NUMBER,
                                                 SHIPPING_METHOD,
                                                 STATUS,
                                                 MANUFACTURER_NUMBER,
                                                 PART_NUMBER,
                                                 LINE_STATUS,
                                                 SHIPPED_QUANTITY,
                                                 LOT_NUMBER,
                                                 TO_SERIAL_NUMBER,
                                                 LOT_EXPIRY_DATE,
                                                 ERROR_CODE,
                                                 ERROR_MESSAGE,
                                                 OIC_STATUS,
                                                 OIC_ERROR_MESSAGE,
                                                 INTERFACE_IDENTIFIER,
                                                 CREATED_BY,
                                                 CREATION_DATE,
                                                 LAST_UPDATED_BY,
                                                 LAST_UPDATE_DATE,
                                                 LAST_UPDATE_LOGIN,
                                                 PROCEDURE_PICK_FLAG)
                 VALUES (l_shipments_rec.shipment_id,
                         l_shipments_rec.IMPLANTBASE_REQ_ID,
                         l_shipments_rec.TRACKING_NUMBER,
                         l_shipments_rec.DATE_SHIPPED,
                         l_shipments_rec.DIST_ACCOUNT_NUMBER,
                         l_shipments_rec.SHIPPING_METHOD,
                         l_shipments_rec.STATUS,
                         l_shipments_rec.MANUFACTURER_NUMBER,
                         l_shipments_rec.PART_NUMBER,
                         l_shipments_rec.LINE_STATUS,
                         l_shipments_rec.SHIPPED_QUANTITY,
                         l_shipments_rec.LOT_NUMBER,
                         l_shipments_rec.TO_SERIAL_NUMBER,
                         l_shipments_rec.LOT_EXPIRY_DATE,
                         'SUCCESS',
                         NULL,
                         'N',
                         NULL,
                         'IMPB_SURG',
                         1516,
                         SYSDATE,
                         1516,
                         SYSDATE,
                         0,
                         l_shipments_rec.PROCEDURE_PICK_FLAG);
        END IF;

        COMMIT;
        x_error_code := l_error_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_code := 'ERROR';
            x_error_msg := SQLERRM;
            debug (DBMS_UTILITY.format_error_backtrace || ':' || x_error_msg);
    END change_shipments_stag_record;

    /**************************************************************************************
    *
    *   PROCEDURE
    *     extract_distributors
    *
    *   DESCRIPTION
    *   Load data into djoinv_cdm_items table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/

---**********************************************************************---
-- This procedure will be called in the business events code to insert into the staging tables
---**********************************************************************---

    PROCEDURE extract_shipments (p_shipment_id IN NUMBER)
    IS
        ----------------------------------------------------------------------------------
        -- Cursor to get shipments information
        ----------------------------------------------------------------------------------
        CURSOR cur_shipments (p_shipment_id IN NUMBER)
        IS
            SELECT wnd.delivery_id
                       shipment_id,
                   --ooha.orig_sys_document_ref
                   (SELECT PACKING_INSTRUCTION
                      FROM djo_auto_repl_consign_stgn_hdr
                     WHERE     iso_header_id = wdd.SOURCE_HEADER_ID
                           AND ROWNUM = 1)
                       implantbase_req_id,
                   wdd.tracking_number,
                   NVL (oola.actual_shipment_date, TRUNC (SYSDATE))
                       date_shipped,
                   hca.account_number
                       dist_account_number,
                   (SELECT UNIQUE SHIP_METHOD_MEANING
                      FROM WSH_CARRIER_SERVICES
                     WHERE ship_method_code = wdd.ship_method_code)
                       shipping_method,
                   DECODE (wdd.released_status,
                           'X', 'Not Applicable',
                           'N', 'Not Ready for Release',
                           'R', 'Ready for Release',
                           'S', 'Submitted to Warehouse',
                           'Y', 'Staged',
                           'B', 'Backordered',
                           'C', 'Shipped',
                           'D', 'Cancelled',
                           'Nothing')
                       status,
                   wnd.delivery_id
                       manufacturer_number,
                   oola.ordered_item
                       part_number,
                   oola.flow_status_code
                       line_status,
                   wdd.SHIPPED_QUANTITY,
                   wdd.lot_number,
                   nvl(wdd.serial_number,wsn.to_serial_number) to_serial_number,
                   NULL
                       lot_expiry_date,
                   'N'
                       Procedure_pick_flag
              FROM oe_order_headers_all      ooha,
                   oe_order_lines_all        oola,
                   wsh_delivery_details      wdd,
                   wsh_delivery_assignments  wda,
                   wsh_new_deliveries        wnd,
                   hz_cust_accounts          hca,
                   wsh_serial_numbers        wsn,
                   mtl_lot_numbers           mln
             WHERE     ooha.header_id = oola.header_id
                   AND oola.line_id = wdd.source_line_id
                   AND wdd.delivery_detail_id = wda.delivery_detail_id
                   AND ooha.header_id = wdd.source_header_id      -- added new
                   AND wda.delivery_id = wnd.delivery_id(+)
                   AND hca.cust_account_id = ooha.sold_to_org_id
                   AND wdd.delivery_detail_id = wsn.delivery_detail_id(+)
                   AND wdd.lot_number = mln.lot_number(+)
                   AND wnd.delivery_id = p_shipment_id
                   AND wdd.organization_id = mln.organization_id(+) -- added new
                   AND EXISTS
                           (SELECT 1
                              FROM mtl_parameters
                             WHERE     organization_id = wdd.organization_id
                                   AND organization_code = 'AUS')
                   --AND ooha.order_number = 707171488
                   AND EXISTS
                           (SELECT 1
                              FROM djo_auto_repl_consign_stgn_hdr
                             WHERE     iso_header_id = wdd.SOURCE_HEADER_ID
                                   AND interface_source_code = 2
                                   AND consignment_unit = 'Surgical')
                   AND ROWNUM = 1/* AND EXISTS
                                          (select 1 from
                                                  djo_auto_repl_consign_stgn_hdr hdr,
                                                  oe_order_headers_all oeh,
                                                  oe_order_Sources oos
                                                  where hdr.source_order=oeh.orig_sys_document_ref
                                                  and oeh.order_source_id=oos.order_source_id
                                                  and oos.name='ImplantBase')*/
                                 ;

        CURSOR cur_shipments_details (p_shipment_id IN NUMBER)
        IS
            SELECT wnd.delivery_id           shipment_id,
                   oola.ordered_item         part_number,
                   oola.flow_status_code     line_status,
                   nvl(wsn.quantity,wdd.SHIPPED_QUANTITY) shipped_quantity,
                   wdd.lot_number,
                    nvl(wdd.serial_number,wsn.to_serial_number) to_serial_number,
                   NULL                      lot_expiry_date,
                   fnd_global.user_id        CREATED_BY,
                   SYSDATE                   CREATION_DATE,
                   fnd_global.user_id        LAST_UPDATED_BY,
                   SYSDATE                   LAST_UPDATE_DATE,
                   fnd_global.login_id       LAST_UPDATE_LOGIN
              FROM oe_order_headers_all      ooha,
                   oe_order_lines_all        oola,
                   wsh_delivery_details      wdd,
                   wsh_delivery_assignments  wda,
                   wsh_new_deliveries        wnd,
                   hz_cust_accounts          hca,
                   wsh_serial_numbers        wsn,
                   mtl_lot_numbers           mln
             WHERE     ooha.header_id = oola.header_id
                   AND oola.line_id = wdd.source_line_id
                   AND wdd.delivery_detail_id = wda.delivery_detail_id
                   AND ooha.header_id = wdd.source_header_id      -- added new
                   AND wda.delivery_id = wnd.delivery_id(+)
                   AND hca.cust_account_id = ooha.sold_to_org_id
                   AND wdd.delivery_detail_id = wsn.delivery_detail_id(+)
                   AND wdd.lot_number = mln.lot_number(+)
                   AND wnd.delivery_id = p_shipment_id
                   AND wdd.organization_id = mln.organization_id(+) -- added new
                   AND EXISTS
                           (SELECT 1
                              FROM mtl_parameters
                             WHERE     organization_id = wdd.organization_id
                                   AND organization_code = 'AUS')
                   --AND ooha.order_number = 707171488
                   AND EXISTS
                           (SELECT 1
                              FROM djo_auto_repl_consign_stgn_hdr
                             WHERE     iso_header_id = wdd.SOURCE_HEADER_ID
                                   AND interface_source_code = 2
                                   AND consignment_unit = 'Surgical')/* AND EXISTS
                                                                              (select 1 from
                                                                                      djo_auto_repl_consign_stgn_hdr hdr,
                                                                                      oe_order_headers_all oeh,
                                                                                      oe_order_Sources oos
                                                                                      where hdr.source_order=oeh.orig_sys_document_ref
                                                                                      and oeh.order_source_id=oos.order_source_id
                                                                                      and oos.name='ImplantBase')*/
                                                                     ;

        ----------------------------------------------------------------------------------
        -- Cursor to get surgeons information from staging
        ----------------------------------------------------------------------------------
        CURSOR cur_stag_shipments (p_shipment_id IN NUMBER)
        IS
            SELECT shipment_id,
                   IMPLANTBASE_REQ_ID,
                   TRACKING_NUMBER,
                   DATE_SHIPPED,
                   DIST_ACCOUNT_NUMBER,
                   SHIPPING_METHOD,
                   STATUS,
                   MANUFACTURER_NUMBER,
                   PART_NUMBER,
                   LINE_STATUS,
                   SHIPPED_QUANTITY,
                   LOT_NUMBER,
                   TO_SERIAL_NUMBER,
                   LOT_EXPIRY_DATE,
                   ERROR_CODE,
                   ERROR_MESSAGE,
                   OIC_STATUS,
                   OIC_ERROR_MESSAGE,
                   INTERFACE_IDENTIFIER,
                   CREATED_BY,
                   CREATION_DATE,
                   LAST_UPDATED_BY,
                   LAST_UPDATE_DATE,
                   LAST_UPDATE_LOGIN,
                   PROCEDURE_PICK_FLAG
              FROM DJOOIC_OE_SHIPMENTS_STG
             WHERE shipment_id = p_shipment_id;

        --------------------------------------------------------------------------
        -- Private Variables
        --------------------------------------------------------------------------
        l_record_count              NUMBER := 0;
        l_stag_shipments            cur_stag_shipments%ROWTYPE;
        l_stag_shipment_dtls        xxdjo.djooic_oe_shipments_dtl_stg%ROWTYPE;
        l_error_code                VARCHAR2 (10);
        l_error_msg                 VARCHAR2 (2000);
        l_stag_count                NUMBER := 0;
        l_shipment_id               NUMBER := p_shipment_id;

        TYPE djooic_shipments_dtls_tbl_type
            IS TABLE OF cur_shipments_details%ROWTYPE
            INDEX BY BINARY_INTEGER;

        TYPE djooic_shipments_tbl_type IS TABLE OF cur_shipments%ROWTYPE
            INDEX BY BINARY_INTEGER;

        djooic_shipments_dtls_tbl   djooic_shipments_dtls_tbl_type;
        djooic_shipments_tbl        djooic_shipments_tbl_type;
        djooic_shipments_tmp        djooic_shipments_tbl_type;
    BEGIN
        debug ('Fetching Records: ');

        BEGIN
            OPEN cur_shipments (l_shipment_id);

            FETCH cur_shipments BULK COLLECT INTO djooic_shipments_tbl;

            IF djooic_shipments_tbl.COUNT = 0
            THEN
                debug ('No Records');
            END IF;                         -- IF cdm_items_tbl.COUNT = 0 THEN

            l_record_count := djooic_shipments_tbl.COUNT;
            debug ('Records: ' || l_record_count);

            CLOSE cur_shipments;
        EXCEPTION
            WHEN OTHERS
            THEN
                debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;

        BEGIN
            OPEN cur_shipments_details (l_shipment_id);

            FETCH cur_shipments_details
                BULK COLLECT INTO djooic_shipments_dtls_tbl;

            IF djooic_shipments_dtls_tbl.COUNT = 0
            THEN
                debug ('No Records in Details');
            END IF;                         -- IF cdm_items_tbl.COUNT = 0 THEN

            l_record_count := djooic_shipments_dtls_tbl.COUNT;
            debug ('Detail Records: ' || l_record_count);

            CLOSE cur_shipments_details;
        EXCEPTION
            WHEN OTHERS
            THEN
                debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;

        debug ('Check count details: ' || djooic_shipments_dtls_tbl.COUNT);


        --- Shipment Headers

        FOR i IN djooic_shipments_tbl.FIRST .. djooic_shipments_tbl.LAST
        LOOP
            OPEN cur_stag_shipments (djooic_shipments_tbl (i).shipment_id);

            --debug('Processing record with party Id: '||djooic_hospital_tbl(i).party_id);
            FETCH cur_stag_shipments INTO l_stag_shipments;

            l_stag_count := cur_stag_shipments%ROWCOUNT;

            CLOSE cur_stag_shipments;

            --IF l_stag_count = 0
            -- THEN
            BEGIN
                debug (
                       'Inserting record with shipment Id: '
                    || djooic_shipments_tbl (i).shipment_id);
                l_stag_shipments.shipment_id :=
                    djooic_shipments_tbl (i).shipment_id;
                l_stag_shipments.IMPLANTBASE_REQ_ID :=
                    djooic_shipments_tbl (i).IMPLANTBASE_REQ_ID;
                l_stag_shipments.TRACKING_NUMBER :=
                    djooic_shipments_tbl (i).TRACKING_NUMBER;
                l_stag_shipments.DATE_SHIPPED :=
                    djooic_shipments_tbl (i).DATE_SHIPPED;
                l_stag_shipments.DIST_ACCOUNT_NUMBER :=
                    djooic_shipments_tbl (i).DIST_ACCOUNT_NUMBER;
                l_stag_shipments.SHIPPING_METHOD :=
                    djooic_shipments_tbl (i).SHIPPING_METHOD;
                l_stag_shipments.STATUS := djooic_shipments_tbl (i).STATUS;
                l_stag_shipments.MANUFACTURER_NUMBER :=
                    djooic_shipments_tbl (i).MANUFACTURER_NUMBER;
                l_stag_shipments.PART_NUMBER :=
                    djooic_shipments_tbl (i).PART_NUMBER;
                l_stag_shipments.LINE_STATUS :=
                    djooic_shipments_tbl (i).LINE_STATUS;
                l_stag_shipments.SHIPPED_QUANTITY :=
                    djooic_shipments_tbl (i).SHIPPED_QUANTITY;
                l_stag_shipments.LOT_NUMBER :=
                    djooic_shipments_tbl (i).LOT_NUMBER;
                l_stag_shipments.TO_SERIAL_NUMBER :=
                    djooic_shipments_tbl (i).TO_SERIAL_NUMBER;
                l_stag_shipments.LOT_EXPIRY_DATE :=
                    djooic_shipments_tbl (i).LOT_EXPIRY_DATE;
                l_stag_shipments.ERROR_CODE := 'SUCCESS';
                l_stag_shipments.error_message := NULL;
                l_stag_shipments.oic_status := 'N';
                l_stag_shipments.oic_error_message := NULL;
                l_stag_shipments.Interface_Identifier := 'SHIPMENTS_OUTBOUND';
                l_stag_shipments.created_by := 1516;
                l_stag_shipments.creation_date := SYSDATE;
                l_stag_shipments.last_updated_by := 1516;
                l_stag_shipments.last_update_date := SYSDATE;
                l_stag_shipments.last_update_login := 0;
                l_stag_shipments.PROCEDURE_PICK_FLAG :=
                    djooic_shipments_tbl (i).PROCEDURE_PICK_FLAG;
                change_shipments_stag_record (
                    p_shipments_rec   => l_stag_shipments,
                    p_type            => 'I',
                    x_error_code      => l_error_code,
                    x_error_msg       => l_error_msg);
            EXCEPTION
                WHEN OTHERS
                THEN
                    debug (
                        DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
                    debug ('IF l_stag_count = 0');
            END;
        /*ELSE
             BEGIN
                 IF
                     (l_stag_shipments.IMPLANTBASE_REQ_ID !=
                        djooic_shipments_tbl (i).IMPLANTBASE_REQ_ID)
                    OR (l_stag_shipments.TRACKING_NUMBER !=
                        djooic_shipments_tbl (i).TRACKING_NUMBER)
                    OR (l_stag_shipments.DATE_SHIPPED !=
                        djooic_shipments_tbl (i).DATE_SHIPPED)
                    OR (l_stag_shipments.DIST_ACCOUNT_NUMBER !=
                        djooic_shipments_tbl (i).DIST_ACCOUNT_NUMBER)
                    OR (l_stag_shipments.SHIPPING_METHOD !=
                        djooic_shipments_tbl (i).SHIPPING_METHOD)
                    OR (l_stag_shipments.MANUFACTURER_NUMBER !=
                        djooic_shipments_tbl (i).MANUFACTURER_NUMBER)
                    OR (l_stag_shipments.PART_NUMBER !=
                        djooic_shipments_tbl (i).PART_NUMBER)
                    OR (l_stag_shipments.SHIPPED_QUANTITY !=
                        djooic_shipments_tbl (i).SHIPPED_QUANTITY)
                    OR (l_stag_shipments.LOT_NUMBER !=
                        djooic_shipments_tbl (i).LOT_NUMBER)
                    OR (l_stag_shipments.TO_SERIAL_NUMBER !=
                        djooic_shipments_tbl (i).TO_SERIAL_NUMBER)
                 THEN
                     debug (
                            'Updating record with delivery Id: '
                         || djooic_shipments_tbl (i).shipment_id);
                     l_stag_shipments.shipment_id :=
                         djooic_shipments_tbl (i).shipment_id;
                     l_stag_shipments.IMPLANTBASE_REQ_ID :=
                         djooic_shipments_tbl (i).IMPLANTBASE_REQ_ID;
                     l_stag_shipments.TRACKING_NUMBER :=
                         djooic_shipments_tbl (i).TRACKING_NUMBER;
                     l_stag_shipments.DATE_SHIPPED :=
                         djooic_shipments_tbl (i).DATE_SHIPPED;
                     l_stag_shipments.DIST_ACCOUNT_NUMBER :=
                         djooic_shipments_tbl (i).DIST_ACCOUNT_NUMBER;
                     l_stag_shipments.SHIPPING_METHOD :=
                         djooic_shipments_tbl (i).SHIPPING_METHOD;
                     l_stag_shipments.STATUS :=
                         djooic_shipments_tbl (i).STATUS;
                     l_stag_shipments.MANUFACTURER_NUMBER :=
                         djooic_shipments_tbl (i).MANUFACTURER_NUMBER;
                     l_stag_shipments.PART_NUMBER :=
                         djooic_shipments_tbl (i).PART_NUMBER;
                     l_stag_shipments.LINE_STATUS :=
                         djooic_shipments_tbl (i).LINE_STATUS;
                     l_stag_shipments.SHIPPED_QUANTITY :=
                         djooic_shipments_tbl (i).SHIPPED_QUANTITY;
                     l_stag_shipments.LOT_NUMBER :=
                         djooic_shipments_tbl (i).LOT_NUMBER;
                     l_stag_shipments.TO_SERIAL_NUMBER :=
                         djooic_shipments_tbl (i).TO_SERIAL_NUMBER;
                     l_stag_shipments.LOT_EXPIRY_DATE :=
                         djooic_shipments_tbl (i).LOT_EXPIRY_DATE;
                     l_stag_shipments.ERROR_CODE := 'SUCCESS';
                     l_stag_shipments.error_message := NULL;
                     l_stag_shipments.oic_status := 'N';
                     l_stag_shipments.oic_error_message := NULL;
                     l_stag_shipments.Interface_Identifier :=
                         'SHIPMENTS_OUTBOUND';
                     l_stag_shipments.created_by := 1516;
                     l_stag_shipments.creation_date := SYSDATE;
                     l_stag_shipments.last_updated_by := 1516;
                     l_stag_shipments.last_update_date := SYSDATE;
                     l_stag_shipments.last_update_login := 0;
                     change_shipments_stag_record (
                         p_shipments_rec   => l_stag_shipments,
                         p_type           => 'R',
                         x_error_code     => l_error_code,
                         x_error_msg      => l_error_msg);
                 END IF;
             EXCEPTION
                 WHEN OTHERS
                 THEN
                     debug (
                            DBMS_UTILITY.format_error_backtrace
                         || ':'
                         || SQLERRM);
                     debug ('IF l_stag_count = 0--ELSE');
             END;
         END IF;*/
        END LOOP;

        --- Shipment Details


        FOR i IN djooic_shipments_dtls_tbl.FIRST ..
                 djooic_shipments_dtls_tbl.LAST
        LOOP
            --IF l_stag_count = 0
            -- THEN
            BEGIN
                debug (
                       'Inserting record with shipment Id: '
                    || djooic_shipments_dtls_tbl (i).shipment_id);
                l_stag_shipment_dtls.shipment_id :=
                    djooic_shipments_dtls_tbl (i).shipment_id;
                l_stag_shipment_dtls.PART_NUMBER :=
                    djooic_shipments_dtls_tbl (i).PART_NUMBER;
                l_stag_shipment_dtls.LINE_STATUS :=
                    djooic_shipments_dtls_tbl (i).LINE_STATUS;
                l_stag_shipment_dtls.SHIPPED_QUANTITY :=
                    djooic_shipments_dtls_tbl (i).SHIPPED_QUANTITY;
                l_stag_shipment_dtls.LOT_NUMBER :=
                    djooic_shipments_dtls_tbl (i).LOT_NUMBER;
                l_stag_shipment_dtls.TO_SERIAL_NUMBER :=
                    djooic_shipments_dtls_tbl (i).TO_SERIAL_NUMBER;
                l_stag_shipment_dtls.LOT_EXPIRY_DATE :=
                    djooic_shipments_dtls_tbl (i).LOT_EXPIRY_DATE;
                l_stag_shipment_dtls.created_by := 1516;
                l_stag_shipment_dtls.creation_date := SYSDATE;
                l_stag_shipment_dtls.last_updated_by := 1516;
                l_stag_shipment_dtls.last_update_date := SYSDATE;
                l_stag_shipment_dtls.last_update_login := 0;
                l_stag_shipment_dtls.PROCEDURE_PICK_FLAG := 'N';
                change_shipments_dtls_record (
                    p_shipments_dtls_rec   => l_stag_shipment_dtls,
                    p_type                 => 'I',
                    x_error_code           => l_error_code,
                    x_error_msg            => l_error_msg);
            EXCEPTION
                WHEN OTHERS
                THEN
                    debug (
                        DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
                    debug ('IF l_stag_count = 0');
            END;
        END LOOP;

        debug (l_record_count || ' record(s) processed.');
    EXCEPTION
        WHEN OTHERS
        THEN
            debug (
                'Error occurred while populating Table djooic_hz_distributors_stg');
            debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
    END extract_shipments;

    /**************************************************************************************
    *
    *   PROCEDURE
    *     exec_main_pr
    *
    *   DESCRIPTION
    *   Call the procedure to process data
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   NA
    *
    **************************************************************************************/
    PROCEDURE exec_main_pr (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2)
    IS
    BEGIN
        --extract_hospitals (1);
        NULL;
    EXCEPTION
        WHEN OTHERS
        THEN
            p_errbuf := SQLERRM;
            p_retcode := 1;
    END EXEC_MAIN_PR;

    /*
    Trx must be completed by end user manually

    oracle.apps.ar.hz.PartySite.create
    oracle.apps.ar.hz.PartySite.update
    oracle.apps.ar.hz.PartySiteUse.create
    oracle.apps.ar.hz.PartySiteUse.update
    oracle.apps.ar.hz.Person.create
    oracle.apps.ar.hz.Person.update
    oracle.apps.inv.itemCreate
    oracle.apps.inv.itemUpdate
    oracle.apps.inv.acctAliasIssue
    oracle.apps.inv.acctIssue
    oracle.apps.inv.acctReceipt
    oracle.apps.inv.miscIssue
    oracle.apps.inv.miscReceipt
    oracle.apps.inv.subinvTransfer
    oracle.apps.wsh.delivery.gen.shipconfirmed
    */
    FUNCTION exec_main_fun (p_subscription_guid   IN            RAW,
                            p_event               IN OUT NOCOPY wf_event_t)
        RETURN VARCHAR2
    IS
        l_param_list    wf_parameter_list_t;
        l_param_name    VARCHAR2 (240);
        l_param_value   VARCHAR2 (2000);
        l_event_name    VARCHAR2 (2000);
        l_event_key     VARCHAR2 (2000);
        l_event_data    VARCHAR2 (4000);
        l_party_id      NUMBER;
        l_item_id       NUMBER;
    BEGIN
        l_param_list := p_event.getparameterlist;
        l_event_name := p_event.geteventname ();
        l_event_key := p_event.geteventkey ();
        l_event_data := p_event.geteventdata ();
        debug ('EVENT NAME: ' || l_event_name);
        debug ('EVENT KEY: ' || l_event_key);
        debug ('EVENT DATA: ' || l_event_data);

        IF l_param_list IS NOT NULL
        THEN
            FOR i IN l_param_list.FIRST .. l_param_list.LAST
            LOOP
                l_param_name := l_param_list (i).getname;
                l_param_value := l_param_list (i).getvalue;
                debug (l_param_name || ': ' || l_param_value);
            END LOOP;
        END IF;

        IF l_event_name IN
               ('oracle.apps.ar.hz.Organization.create',
                'oracle.apps.ar.hz.Organization.update',
                'oracle.apps.ar.hz.Location.update')
        THEN                                          -- Hospital, Distributor
            l_party_id := p_event.getvalueforparameter ('PARTY_ID');
            DEBUG ('PARTY_ID: ' || l_party_id);
        --extract_hospitals (l_party_id);
        ELSIF l_event_name IN
                  ('oracle.apps.ar.hz.Person.create',
                   'oracle.apps.ar.hz.Person.update')
        THEN                                                        --Surgeons
            NULL;
        ELSIF l_event_name IN
                  ('oracle.apps.inv.itemCreate', 'oracle.apps.inv.itemUpdate')
        THEN                                                           --Parts
            l_item_id := p_event.getvalueforparameter ('INVENTORY_ITEM_ID');
            DEBUG ('INVENTORY_ITEM_ID: ' || l_item_id);
        ELSIF l_event_name IN
                  ('oracle.apps.inv.acctAliasReceipt',
                   'oracle.apps.inv.acctAliasIssue',
                   'oracle.apps.inv.subinvTransfer')
        THEN                                           --inventory transaction
            NULL;
        END IF;

        RETURN 'SUCCESS';
    EXCEPTION
        WHEN OTHERS
        THEN
            wf_core.CONTEXT (pkg_name    => 'DJOOIC_MST_IMPB_OUTBOUND_PKG',
                             proc_name   => 'exec_main_fun',
                             arg1        => p_event.geteventname (),
                             arg2        => p_event.geteventkey (),
                             arg3        => p_subscription_guid);
            --
            --Retrieves error information from the error stack and sets it into the event message.
            --
            wf_event.seterrorinfo (p_event => p_event, p_type => 'ERROR');
            --
            RETURN 'ERROR';
    END exec_main_fun;

---**********************************************************************---
-- This procedure will be called in OIC to ge the shipment details
---**********************************************************************---

    PROCEDURE get_shipment_details (
        p_shipment_id           IN     NUMBER,
        p_implantbase_req_id       OUT VARCHAR2,
        p_tracking_number          OUT VARCHAR2,
        p_date_shipped             OUT DATE,
        p_dist_account_number      OUT VARCHAR2,
        p_shipping_method          OUT VARCHAR2,
        p_status                   OUT VARCHAR2,
        p_manufacturer_number      OUT VARCHAR2,
        p_tab_parts_info           OUT t_tab_parts_info)
    IS
        CURSOR c_part_info IS
            SELECT part_number,
                   line_number,
                   line_status,
                   shipped_quantity,
                   lot_number,
                   to_serial_number,
                   lot_expiry_date
              FROM XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG
             WHERE shipment_id = p_shipment_id AND procedure_pick_flag = 'N';

        --  TYPE part_info_tbl_type IS TABLE OF c_part_info%ROWTYPE
        --   INDEX BY BINARY_INTEGER;
        -- part_info_tbl   part_info_tbl_type;
        l_record_count   NUMBER;
    BEGIN
        SELECT implantbase_req_id,                
               tracking_number,
               date_shipped,
               dist_account_number,
               shipping_method,
               status,
               manufacturer_number
          INTO p_implantbase_req_id,
               p_tracking_number,
               p_date_shipped,
               p_dist_account_number,
               p_shipping_method,
               p_status,
               p_manufacturer_number
          FROM DJOOIC_OE_SHIPMENTS_STG
         WHERE SHIPMENT_ID = p_shipment_id;

        BEGIN
            OPEN c_part_info;

            FETCH c_part_info BULK COLLECT INTO p_tab_parts_info;

            IF p_tab_parts_info.COUNT = 0
            THEN
                debug ('No Records');
            END IF;                         -- IF cdm_items_tbl.COUNT = 0 THEN

            l_record_count := p_tab_parts_info.COUNT;
            debug ('Records: ' || l_record_count);

            CLOSE c_part_info;
            UPDATE  XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG SET procedure_pick_flag = 'Y'
             WHERE shipment_id = p_shipment_id ;
             commit;
        EXCEPTION
            WHEN OTHERS
            THEN
                debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;
    END get_shipment_details;
END DJOOIC_SHIPMENTS_OUTBOUND_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_SHIPMENTS_OUTBOUND_PKG" TO "XXOIC";

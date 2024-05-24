--------------------------------------------------------
--  DDL for Package DJOOIC_SHIPMENTS_OUTBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_SHIPMENTS_OUTBOUND_PKG" 
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
    *   DJOOIC_SHIPMENTS_OUTBOUND_PKG.pks
    *
    *   DESCRIPTION
    *   Creation Script of Package Specification for ImplantBase Shipments Outbound
    *
    *   USAGE
    *   To create Package Specification of the package DJOOIC_SHIPMENTS_OUTBOUND_PKG
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
    *   1.0      11-Apr-2023 Venkata Suresh               Creation
    ***************************************************************************************/
    ------------------------------------------------------------------------------
    TYPE type_rec_parts_info IS RECORD
    (
        PART_NUMBER         VARCHAR2 (2000),
        LINE_NUMBER         VARCHAR2(100),
        LINE_STATUS         VARCHAR2 (30),
        SHIPPED_QUANTITY    NUMBER,
        LOT_NUMBER          VARCHAR2 (80),
        TO_SERIAL_NUMBER    VARCHAR2 (30),
        LOT_EXPIRY_DATE     DATE
    );

    TYPE t_tab_parts_info IS TABLE OF type_rec_parts_info;


    PROCEDURE exec_main_pr (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2);

    FUNCTION exec_main_fun (p_subscription_guid   IN            RAW,
                            p_event               IN OUT NOCOPY wf_event_t)
        RETURN VARCHAR2;

    PROCEDURE extract_shipments (p_shipment_id IN NUMBER);

    PROCEDURE get_shipment_details (
        p_shipment_id           IN     NUMBER,
        p_implantbase_req_id       OUT VARCHAR2,
        p_tracking_number          OUT VARCHAR2,
        p_date_shipped             OUT DATE,
        p_dist_account_number      OUT VARCHAR2,
        p_shipping_method          OUT VARCHAR2,
        p_status                   OUT VARCHAR2,
        p_manufacturer_number      OUT VARCHAR2,
        p_tab_parts_info           OUT t_tab_parts_info);
END DJOOIC_SHIPMENTS_OUTBOUND_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_SHIPMENTS_OUTBOUND_PKG" TO "XXOIC";

--------------------------------------------------------
--  DDL for Package DJOOIC_IBE_INV_EMAIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_IBE_INV_EMAIL_PKG" AS

    -- XX_INV_EMAIL procedure
    PROCEDURE XX_INV_EMAIL(
    p_trx_number IN NUMBER,
    p_org_id IN NUMBER,
    p_email_list IN VARCHAR2,
    x_return_message OUT VARCHAR2,
    x_status_code OUT VARCHAR2
    );

END DJOOIC_IBE_INV_EMAIL_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_IBE_INV_EMAIL_PKG" TO "XXOIC";

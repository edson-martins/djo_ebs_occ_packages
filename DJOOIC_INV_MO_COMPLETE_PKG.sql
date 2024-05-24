--------------------------------------------------------
--  DDL for Package DJOOIC_INV_MO_COMPLETE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_INV_MO_COMPLETE_PKG" IS
/**************************************************************************************
*    Copyright (c) DJO
*     All rights reserved
***************************************************************************************
*
*   HEADER
*   Package Specification
*
*   PROGRAM NAME
*   DJOOIC_INV_MO_COMPLETE_PKG.pks
*
*   DESCRIPTION
*   Creation Script of Package Specification for ImplantBase Inventory Adjustment API
*
*   USAGE
*   To create Package Specification of the package DJOOIC_INV_MO_COMPLETE_PKG
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
*   1.0      27-Jul-2023 Santosh               Creation
***************************************************************************************/
------------------------------------------------------------------------------
	PROCEDURE main (errbuf	OUT VARCHAR2,
	                errcod	OUT NUMBER);

  	PROCEDURE insert_staging (p_header_id IN NUMBER);

  	PROCEDURE update_mo_line(p_line_id  IN NUMBER);

END DJOOIC_INV_MO_COMPLETE_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_MO_COMPLETE_PKG" TO "XXOIC";

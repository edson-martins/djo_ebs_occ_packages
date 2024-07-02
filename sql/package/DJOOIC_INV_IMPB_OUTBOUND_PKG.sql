--------------------------------------------------------
--  DDL for Package DJOOIC_INV_IMPB_OUTBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_INV_IMPB_OUTBOUND_PKG" IS
/**************************************************************************************
*    Copyright (c) DJO
*     All rights reserved
***************************************************************************************
*
*   HEADER
*   Package Specification
*
*   PROGRAM NAME
*   DJOOIC_INV_IMPB_OUTBOUND_PKG.pks
*
*   DESCRIPTION
*   Creation Script of Package Specification for ImplantBase Inventory Adjustment API
*
*   USAGE
*   To create Package Specification of the package DJOOIC_INV_IMPB_OUTBOUND_PKG
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
*   1.0      20-Mar-2023 Samir               Creation
***************************************************************************************/
------------------------------------------------------------------------------
  PROCEDURE exec_main_pr( p_errbuf     OUT VARCHAR2
	                     ,p_retcode    OUT VARCHAR2
                        )
  ;
  FUNCTION exec_main_fun(p_subscription_guid IN RAW, 
                         p_event             IN OUT NOCOPY wf_event_t) 
  RETURN VARCHAR2;
  PROCEDURE master_items_pr( p_item_id            IN NUMBER
	                        ,p_organization_id    IN NUMBER
                          )
  ;
  PROCEDURE inv_transactions_pr(p_transaction_id		 IN NUMBER
                                   ,p_item_id            IN NUMBER
	                               ,p_organization_id    IN NUMBER
                                  )
  ;
END DJOOIC_INV_IMPB_OUTBOUND_PKG;

/

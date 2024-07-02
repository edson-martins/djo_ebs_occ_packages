--------------------------------------------------------
-- Copyright (c) 2024, Oracle Corp.  All rights reserved.
-- Project: DJO-Enovis
--------------------------------------------------------


----------------------------------------------------------------------------
--  	ATTENTION: This script DOES NOT preserve data.
--
--	The customer DBA is responsible to review this script to ensure
--	data is preserved as desired.
--
----------------------------------------------------------------------------
--	Table Added: 		 DJOQP_PRICING_SYNC_STG
----------------------------------------------------------------------------

--------------------------------------
--       Creating Table
--------------------------------------
PROMPT Creating Table 'DJOQP_PRICING_SYNC_STG'
CREATE TABLE DJOQP_PRICING_SYNC_STG
(
  PG_ID VARCHAR(240) NOT NULL,
  ACCOUNT_NUMBER VARCHAR2(50) NOT NULL,
  INTERFACED_FLAG CHAR(1),
  LAST_PRICE_SYNC_DATE DATE NOT NULL
 )

/

COMMENT ON TABLE DJOQP_PRICING_SYNC_STG is 'This table stores the state of Price syncs.'
/

COMMENT ON COLUMN DJOQP_PRICING_SYNC_STG.PG_ID is 'This column holds the price group ids.'
/

COMMENT ON COLUMN DJOQP_PRICING_SYNC_STG.ACCOUNT_NUMBER is 'This column holds the account number'
/

COMMENT ON COLUMN DJOQP_PRICING_SYNC_STG.INTERFACED_FLAG is 'This column holds Y or N to indicates prices for this price group were interfaced for current sync.'
/

COMMENT ON COLUMN DJOQP_PRICING_SYNC_STG.LAST_PRICE_SYNC_DATE is 'This column holds the date prices for the price group were last synced to OCC.'
/

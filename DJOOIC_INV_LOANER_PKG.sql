--------------------------------------------------------
--  DDL for Package DJOOIC_INV_LOANER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_INV_LOANER_PKG" AS 
/**************************************************************************************
*    Copyright (c) DJO
*     All rights reserved
***************************************************************************************
*
*   HEADER
*   Package Specification
*
*   PROGRAM NAME
*   DJOOIC_INV_LOANER_PKG.pks
*
*   DESCRIPTION
*   Creation Script of Package Specification for ImplantBase Inventory Loaner API
*
*   USAGE
*   To create Package Specification of the package DJOOIC_INV_LOANER_PKG
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
*   1.0      19-May-2023 Samir               Creation
*   1.1      02-Nov-2023 Samir               Change logic for multiple lines in Move Order
***************************************************************************************/
    --Global variables
	g_location_type            VARCHAR2(60) := 'Storage Locator';
	g_status_code              VARCHAR2(60) := 'Active';
	g_moveorder_type           NUMBER       := INV_GLOBALS.G_MOVE_ORDER_REQUISITION;
	g_mo_transaction_type_id   NUMBER       := INV_GLOBALS.G_TYPE_TRANSFER_ORDER_SUBXFR;
	g_mo_header_status         NUMBER       := INV_Globals.G_TO_STATUS_PREAPPROVED;
	--Move Order line record type
	TYPE lot_serial_rec IS RECORD(
		 lot_number       VARCHAR2(60),
		 serial_number    VARCHAR2(60)
		 );
	TYPE lot_serial_tab IS TABLE OF lot_serial_rec;
	TYPE move_ord_line_rec IS RECORD(
	     source_mo_line_num VARCHAR2(10),
		 item               VARCHAR2(30),
	   	 from_subinv_code   VARCHAR2(30),
		 from_locator       VARCHAR2(100),
		 to_subinv_code     VARCHAR2(30),
		 to_locator         VARCHAR2(30),
		 quantity           NUMBER,	
         lot_serial         lot_serial_tab		 
    );
	--Move Order line table type
	TYPE djooic_move_ord_line_tbl IS TABLE OF move_ord_line_rec;
	TYPE serial_rec IS RECORD(
		 serial_number    VARCHAR2(60)
		 );

	TYPE djooic_serial_number_type IS TABLE OF serial_rec;
	--Procedures and functions
    PROCEDURE create_locator(p_organization_code IN  VARCHAR2,
							 p_subinv_code       IN  VARCHAR2,
							 p_locator           IN  VARCHAR2,
							 p_description       IN  VARCHAR2,
                             p_locator_type      IN  VARCHAR2 DEFAULT g_location_type,
							 p_status_code       IN  VARCHAR2 DEFAULT g_status_code,
                             x_transaction_id    OUT NUMBER,
							 x_error_code        OUT VARCHAR2,
							 x_error_msg         OUT VARCHAR2
							 );
	PROCEDURE check_locator(p_organization_code IN  VARCHAR2,
							p_subinv_code       IN  VARCHAR2,
							p_locator           IN  VARCHAR2,
                            x_transaction_id    OUT NUMBER,
							x_error_code        OUT VARCHAR2,
							x_error_msg         OUT VARCHAR2
							);
	PROCEDURE get_onhand(p_organization_code IN  VARCHAR2,
						 p_subinv_code       IN  VARCHAR2,
						 p_locator           IN  VARCHAR2,
						 p_item              IN  VARCHAR2,
						 p_quantity          IN  NUMBER,
						 x_transaction_id    OUT NUMBER,
						 x_locator           OUT VARCHAR2,
						 x_lot_number        OUT VARCHAR2,
						 x_serial_number     OUT djooic_serial_number_type,
						 x_error_code        OUT VARCHAR2,
						 x_error_msg         OUT VARCHAR2
						 );
	PROCEDURE ProcessMoveOrder(p_source_mo_number    IN  VARCHAR2,
	                           p_organization_code   IN  VARCHAR2,
						       p_move_order_line_tbl IN djooic_move_ord_line_tbl,
							   x_transaction_id      OUT NUMBER,
						       x_error_code          OUT VARCHAR2,
						       x_error_msg           OUT VARCHAR2
						       );
	PROCEDURE allocateMoveOrder(p_request_number    IN   VARCHAR2 DEFAULT NULL,
                                p_request_line_num  IN   VARCHAR2 DEFAULT NULL,
							    p_mo_header_id      IN   NUMBER DEFAULT NULL,
							    p_mo_line_id        IN   NUMBER DEFAULT NULL,
							    x_transaction_id    OUT  NUMBER,
						        x_error_code        OUT  VARCHAR2,
						        x_error_msg         OUT  VARCHAR2
                                );
	PROCEDURE TransactMoveOrder(p_request_number    IN   VARCHAR2,
                                p_request_line_num  IN   VARCHAR2,
							    x_transaction_id    OUT  NUMBER,
						        x_error_code        OUT  VARCHAR2,
						        x_error_msg         OUT  VARCHAR2
						        );
END DJOOIC_INV_LOANER_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_LOANER_PKG" TO "XXOIC";

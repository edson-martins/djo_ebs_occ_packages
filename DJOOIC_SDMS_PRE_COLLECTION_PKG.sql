--------------------------------------------------------
--  DDL for Package DJOOIC_SDMS_PRE_COLLECTION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_SDMS_PRE_COLLECTION_PKG" AS
/*************************************************************************************
*	Copyright (c) DJO
* 		All rights reserved
***************************************************************************************
*
* HEADER
*
*
* PROGRAM NAME
*
*	 APPS.DJOOIC_SDMS_PRE_COLLECTION_PKG
*
* DESCRIPTION
* 	Package containing procedures used in the concurrent program "DJO OIC Pre-collection Program"
*
* USAGE
*
* PARAMETERS
* ==========
* NAME 	 DESCRIPTION
* ---------------- ------------------------------------------------------
* NA
*
* DEPENDENCIES
* 	NA
* CALLED BY
*
* HISTORY
* =======
* VERSION	DATE			AUTHOR(S) 			DESCRIPTION
* -------	-----------	--------------- 	---------------------------------------------------
* 1.0		12-Mar-2010	Sivaram				Initial
* 2.0 27-Oct-2010 Charles Harding Add item class and item family to select of djo_non_rev_brand_info.
* 3.0 09-Mar-2011 Saranya Nerella Changes from Krishna
* 4.0 16-Oct-2012 Dik Ahuja SR# 41161 Changes for Stocking Account Tracings
******************************************************************************************/

/*Procedure which does the main validations*/
PROCEDURE validate_precollection_data (o_errbuf 				OUT VARCHAR2
						 	 ,o_retcode 				OUT VARCHAR2
						 	 ,p_start_period_name 	IN VARCHAR2
						 	 ,p_end_period_name 	IN VARCHAR2
		 								 );

/*The procedure returns Item Group, Item Class, Item Family and Item Model for a given Item and Organization.*/
PROCEDURE get_item_details(p_inventory_item_id IN mtl_item_categories.inventory_item_id%TYPE
 ,p_organization_id IN mtl_item_categories.organization_id%TYPE
 ,x_item_group OUT mtl_categories_b.segment1%TYPE
 ,x_item_class OUT mtl_categories_b.segment2%TYPE
 ,x_item_family OUT mtl_categories_b.segment3%TYPE
 ,x_item_model		 OUT mtl_categories_b.segment4%TYPE
 ,x_return_message	 OUT	VARCHAR2 );

/*The procedure returns Business Unit, Product Brand and Product Group for a given Item and Organization.*/
PROCEDURE get_djo_brand_categories(p_inventory_item_id IN mtl_item_categories.inventory_item_id%TYPE
											 ,p_organization_id IN mtl_item_categories.organization_id%TYPE
											 ,x_business_unit OUT mtl_categories_b.segment1%TYPE
											 ,x_product_brand OUT mtl_categories_b.segment2%TYPE
											 ,x_product_group	 OUT mtl_categories_b.segment3%TYPE
 ,x_product_brand_name OUT mtl_categories_b.segment4%TYPE --Added by Anantha on 03-23-2012 for Incident # 199262
											 ,x_return_message	OUT VARCHAR2 );

/*The procedure returns the Anatomy category value for a given Item and Organization*/
PROCEDURE get_djo_anatomy(p_inventory_item_id IN mtl_item_categories.inventory_item_id%TYPE
								 ,p_organization_id IN mtl_item_categories.organization_id%TYPE
								 ,x_anatomy OUT mtl_categories_b.segment1%TYPE
								 ,x_return_message	 OUT VARCHAR2 );

/*The procedure returns the End Customer Information such as End Customer Name and End Customer Address */
PROCEDURE get_djo_customer( p_cust_acc_number 	 IN 	hz_cust_accounts.account_number%TYPE
									,x_cust_name				OUT	hz_parties.party_name%TYPE
									,x_cust_address			OUT	hz_parties.address1%TYPE
									,x_cust_city				OUT	hz_parties.city%TYPE
									,x_cust_zip					OUT	hz_parties.postal_code%TYPE
									,x_cust_state				OUT	hz_parties.state%TYPE
									,x_return_message	 		OUT 	VARCHAR2);

/* This Procedure is used to insert duplicate record for the primary sales rep */
PROCEDURE insert_secondary_rep(p_ebs_trc_trx_id			IN			NUMBER
										--,p_sdms_file_number		IN			VARCHAR2
										,p_trx_type					IN			VARCHAR2
										--,p_sdms_trx_number		IN			VARCHAR2
										--,p_sdms_trx_id				IN			VARCHAR2
										--,p_company_code			IN			VARCHAR2
										,p_processed_date			IN			DATE
										--,p_invoice_date			IN			DATE
										,p_sdms_dist_num			IN			VARCHAR2
										,p_customer_number		IN			VARCHAR2
										,p_item_number				IN			VARCHAR2
										--,p_salesrep_id				IN			NUMBER
										,p_secondary_rep_num		IN			VARCHAR2
										,p_quantity					IN			NUMBER
										,p_actual_sales_amt		IN			NUMBER
										,p_extended_cost_amt		IN			NUMBER
										,p_extended_price_amt	IN NUMBER
										,p_profit_margin_amt		IN			NUMBER
										,p_end_customer_num		IN			VARCHAR2
										,p_end_customer_name		IN			VARCHAR2
										,p_street_address			IN			VARCHAR2
										,p_city						IN			VARCHAR2
										,p_state						IN			VARCHAR2
										,p_zip						IN			VARCHAR2
										,p_customer_name			IN			VARCHAR2
 ,p_customer_category IN VARCHAR2
										,p_business_segment		IN			VARCHAR2
										,p_item_group				IN			VARCHAR2
										,p_item_class				IN			VARCHAR2
										,p_order_type				IN			VARCHAR2
										,p_brand						IN			VARCHAR2
										,p_item_family				IN			VARCHAR2
										,p_anatomy					IN			VARCHAR2
										,p_reporting_center		IN			VARCHAR2
										,p_collection_status		IN			VARCHAR2
										,p_error_message			IN			VARCHAR2
										,p_product_brand			IN			VARCHAR2
										,p_product_group			IN			VARCHAR2
										,p_item_model				IN			VARCHAR2
										,p_creation_date			IN			DATE
										,p_created_by				IN			NUMBER
										,p_last_update_date		IN			DATE
										,p_last_updated_by		IN			NUMBER
 ,p_gpo_name IN VARCHAR2 -- Added by saranya on 7/28/2016
										);

/* This Procedure is used to get the Non Revenue Brand for the Secondary sales rep */
PROCEDURE get_non_revenue_brand(p_item_group 		 IN mtl_categories_b.segment1%TYPE
								,p_brand			 IN	 VARCHAR2
 ,p_item_class IN mtl_categories_b.segment2%TYPE --v2.0 Charles Harding
 ,p_item_family IN mtl_categories_b.segment3%TYPE --v2.0 Charles Harding
 ,p_product_group IN mtl_categories_b.segment3%TYPE --Added by Anantha on 03-23-2012 for Incident # 199262
 ,p_product_brand_name IN mtl_categories_b.segment4%TYPE --Added by Anantha on 03-23-2012 for Incident # 199262
		 ,x_non_revenue_brand OUT VARCHAR2
 ,x_officecare_flag OUT VARCHAR2 );

/* This Procedure is used to get the Reporting center for Distribution. */
PROCEDURE get_reporting_center ( p_product_brand		IN		mtl_categories_b.segment2%TYPE
											,x_reporting_center	OUT	VARCHAR2 );
/*The procedure returns the Stocking Distributor Customer Category information */
PROCEDURE get_dist_customer_category( p_customer_number	 IN 	hz_cust_accounts.account_number%TYPE
									,p_salesrep_id				IN	jtf_rs_salesreps.salesrep_id%TYPE
									,x_dist_customer_category			OUT	VARCHAR2);

/* This Procedure is used to get the number of records based on the collection status */
PROCEDURE get_count_records(p_collection_status		IN		VARCHAR2
									,p_start_period_name 	IN 	VARCHAR2
						 ,p_end_period_name 		IN 	VARCHAR2
									,x_count_record			OUT	NUMBER);

/*This procedure checks the conditions for Ver 3.0 and swaps the revenue rep and npn revenue rep*/
--PROCEDURE check_rep_swap (p_ebs_trc_trx_id IN NUMBER); --Added by Saranya on 9th Mar, 2011


END DJOOIC_SDMS_PRE_COLLECTION_PKG; --Package End

/

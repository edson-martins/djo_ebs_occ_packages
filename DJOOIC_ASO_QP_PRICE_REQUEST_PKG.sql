--------------------------------------------------------
--  DDL for Package DJOOIC_ASO_QP_PRICE_REQUEST_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_ASO_QP_PRICE_REQUEST_PKG" 
AS
-- Package name     : DJOOIC_ASO_QP_PRICE_REQUEST_PKG
-- Purpose          : Fetching Price Lists
-- Preparer Name	: Praveen Gorja
--
--   This package contains specification for pl/sql records and tables and the
--   Public API of Order Capture
  -- g_debug                      BOOLEAN                  := true;
  -- g_trace                      BOOLEAN                  := true;
   g_debug             BOOLEAN         := TRUE;
   g_trace             BOOLEAN         := TRUE;

--  Header record type
   TYPE header_rec_type IS RECORD(
      account_number    VARCHAR2(30)
     ,order_type        VARCHAR2(20)
     ,po_number         VARCHAR2(50)
     ,ib_order_number   VARCHAR2(240)
     ,case_start_date   VARCHAR2(240)
   );

   g_miss_header_rec   header_rec_type;

   TYPE line_rec_type IS RECORD(
      line_number         NUMBER
     ,part_number         VARCHAR2(40)
     ,quantity            NUMBER
     ,unit_list_price     NUMBER
     ,unit_sell_price     NUMBER
     ,organization_code   VARCHAR2(15)
     ,price_list_name     VARCHAR2(240)
     ,modifier            VARCHAR2(240)
   );

   g_miss_line_rec     line_rec_type;

   TYPE line_tbl_type IS TABLE OF line_rec_type
      INDEX BY BINARY_INTEGER;

   g_miss_line_tbl     line_tbl_type;

   PROCEDURE print_debug(
      p_msg     IN   VARCHAR2
     ,p_debug   IN   BOOLEAN DEFAULT g_debug);

   PROCEDURE populate_staging(
      p_price_check_rec   IN   DJOOIC_QP_PRICECHECK_IMPBS_STG%ROWTYPE);

   PROCEDURE apps_initilzation(
      ip_username                 VARCHAR2
     ,ip_responsibility           VARCHAR2
     ,ip_application_name         VARCHAR2
     ,op_status             OUT   VARCHAR2
     ,op_message            OUT   VARCHAR2);

   PROCEDURE price_check(
      p_header_rec       IN              header_rec_type := g_miss_header_rec
     ,p_lines_rec        IN              line_rec_type := g_miss_line_rec
     ,x_lines_rec        OUT             line_rec_type
     ,x_transaction_id   OUT             NUMBER
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);

   PROCEDURE update_quote(
      p_quote_header_id     IN              NUMBER
     ,p_organization_id     IN              NUMBER
     ,p_inventory_item_id   IN              NUMBER
     ,p_quantity            IN              NUMBER
     ,x_qte_lines_tbl       OUT NOCOPY      aso_quote_pub.qte_line_tbl_type
     ,x_return_status       OUT NOCOPY      VARCHAR2
     ,x_return_message      OUT NOCOPY      VARCHAR2);
END djooic_aso_qp_price_request_pkg;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_ASO_QP_PRICE_REQUEST_PKG" TO "XXOIC";

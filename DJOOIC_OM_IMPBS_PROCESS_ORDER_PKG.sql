--------------------------------------------------------
--  DDL for Package DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" 
AS
   -- Start of Comments
-- Package name     : test_OE_ORDER_PKG
-- Purpose          :
--   This package contains specification for pl/sql records and tables and the
--   Public API of Order Capture
  -- g_debug                      BOOLEAN                  := true;
  -- g_trace                      BOOLEAN                  := true;
   g_debug            BOOLEAN                    := TRUE;
   g_trace            BOOLEAN                    := TRUE;

--Jagan
   TYPE djooic_om_impbs_header_rec IS RECORD(
      inv_org_code                    VARCHAR2(10)
     ,case_start_date                 DATE
     ,order_type                      VARCHAR2(30)
     ,order_source                    VARCHAR2(30)
     ,po_number                       VARCHAR2(50)
     ,order_number                 VARCHAR2(50)
     ,original_order_number        VARCHAR2(50)
     ,payment_type                    VARCHAR2(30)
     ,ccnumber                        NUMBER
     ,ccexpdate                       DATE
     ,cccvv                           NUMBER
     ,cardholder_name                 VARCHAR2(30)
     ,avs_address                     VARCHAR2(30)
     ,avs_city                        VARCHAR2(30)
     ,avs_state                       VARCHAR2(30)
     ,avs_zipcode                     NUMBER
     ,patient_name                    VARCHAR2(250)
     ,hospital_account_number         VARCHAR2(30)
     ,surgeon_account_number          VARCHAR2(30)
     ,revision_surgery                VARCHAR2(250)
     ,revised_djo_oti_product         VARCHAR2(250)
     ,shipto_address1                 VARCHAR2(250)
     ,shipto_address2                 VARCHAR2(250)
     ,shipto_address3                 VARCHAR2(250)
     ,shipto_address4                 VARCHAR2(250)
     ,shipto_country                  VARCHAR2(250)
     ,shipto_state_province           VARCHAR2(250)
     ,shipto_city                     VARCHAR2(250)
     ,shipto_postal_code              VARCHAR2(250)
     ,shipto_contact_first_name       VARCHAR2(250)
     ,shipto_contact_last_name        VARCHAR2(250)
     ,shipto_contact_phone            VARCHAR2(250)
     ,shipto_contact_ext              VARCHAR2(250)
     ,shipto_contact_email            VARCHAR2(250)
     ,deliver_to_address1             VARCHAR2(250)
     ,deliver_to_address2             VARCHAR2(250)
     ,deliver_to_address3             VARCHAR2(250)
     ,deliver_to_address4             VARCHAR2(250)
     ,deliver_to_country              VARCHAR2(250)
     ,deliver_to_state_province       VARCHAR2(250)
     ,deliver_to_city                 VARCHAR2(250)
     ,deliver_to_postal_code          VARCHAR2(250)
     ,deliver_to_contact_first_name   VARCHAR2(250)
     ,deliver_to_contact_last_name    VARCHAR2(250)
     ,deliver_to_contact_phone        VARCHAR2(250)
     ,deliver_to_contact_ext          VARCHAR2(250)
     ,deliver_to_contact_email        VARCHAR2(250)
   );

   TYPE djooic_om_impbs_line_rec IS RECORD(
      part_number                 VARCHAR2(30)
     ,quantity                    NUMBER
     ,line_number                 NUMBER
     ,case_price                  NUMBER
     ,calculate_price_flag        VARCHAR2(1)
     ,include_in_construct_flag   VARCHAR2(1)
     ,line_type                   VARCHAR2(250)
     ,return_reference_type       VARCHAR2(30)
     ,return_reference_number     VARCHAR2(30)
     ,return_reference_line       VARCHAR2(20)
     ,reason_code                 VARCHAR2(50)
     ,reservation_subinventory    VARCHAR2(250)
     ,reservation_locator         VARCHAR2(250)
     ,lot_number                  VARCHAR2(80)
     ,from_serial_number          VARCHAR2(30)
     ,to_serial_number            VARCHAR2(30)
   );

   TYPE header_rec_type IS RECORD(
      account_number    VARCHAR2(30)
     ,order_type        VARCHAR2(20)
     ,po_number         VARCHAR2(50)
     ,order_number   VARCHAR2(240)
     ,case_start_date   VARCHAR2(240)
   );

   /*TYPE order_rec_type IS RECORD(
      order_number         NUMBER
     ,order_header_id      NUMBER
     ,order_total_amount   NUMBER
     ,order_status         VARCHAR2(100)
   ); */

   -- Lines table def
   TYPE djooic_om_impbs_line_tbl IS TABLE OF djooic_om_impbs_line_rec  ;--                                     INDEX BY BINARY_INTEGER;

-- hdr variable for record type
   hder_rec           djooic_om_impbs_header_rec;
-- Line Variable for lines record
   line_rec           djooic_om_impbs_line_rec;
-- Lines table variable for Lines table
   line_tbl           djooic_om_impbs_line_tbl;

-- Jagan
   TYPE order_rec_type IS RECORD(
      order_number         NUMBER
     ,order_header_id      NUMBER
     ,order_total_amount   NUMBER
     ,order_status         VARCHAR2(100)
   );

   g_miss_order_rec   order_rec_type;

   PROCEDURE print_debug(
      p_msg     IN   VARCHAR2
     ,p_debug   IN   BOOLEAN DEFAULT g_debug);

   PROCEDURE populate_staging(
      p_process_order_rec   IN   djooic_om_impbs_process_order_stg%ROWTYPE);

   PROCEDURE apps_initilzation(
      ip_username                 VARCHAR2
     ,ip_responsibility           VARCHAR2
     ,ip_application_name         VARCHAR2
     ,op_status             OUT   VARCHAR2
     ,op_message            OUT   VARCHAR2);

   PROCEDURE create_person(
      p_cust_account_number    IN       VARCHAR2
     ,p_contact_first_name     IN       VARCHAR2
     ,p_contact_last_name      IN       VARCHAR2
     ,p_contact_phone          IN       VARCHAR2
     ,p_phone_extension        IN       VARCHAR2
     ,p_contact_email          IN       VARCHAR2
     ,p_cust_account_site_id   IN       NUMBER
     ,x_contact_point_id       OUT      NUMBER);

   PROCEDURE create_cust_site(
      p_cust_account_number   IN              VARCHAR2
     ,p_site_use_code         IN              VARCHAR2
     ,p_address1              IN              VARCHAR2
     ,p_address2              IN              VARCHAR2
     ,p_address3              IN              VARCHAR2
     ,p_address4              IN              VARCHAR2
     ,p_country               IN              VARCHAR2
     ,p_state                 IN              VARCHAR2
     ,p_city                  IN              VARCHAR2
     ,p_postal_code           IN              VARCHAR2
     ,p_org_id                IN              NUMBER
     ,x_party_site_id         OUT NOCOPY      NUMBER                                                                                   --new
     ,x_return_status         OUT NOCOPY      VARCHAR2
     ,x_return_message        OUT NOCOPY      VARCHAR2);

   PROCEDURE update_reservation(
      p_header_id        IN              NUMBER
     ,p_lines_tbl        IN              oe_order_pub.line_tbl_type
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);


   PROCEDURE release_hold(
      p_header_id        IN              NUMBER
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);


   PROCEDURE update_so(
      p_so_header_rec    IN              djooic_om_impbs_header_rec
     ,p_so_header_id     IN              NUMBER
     ,p_so_lines_tbl     IN              djooic_om_impbs_line_tbl
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);

   PROCEDURE create_ref_rma(
      p_so_header_rec    IN              oe_order_pub.header_rec_type
     ,p_so_lines_tbl     IN              oe_order_pub.line_tbl_type
     ,p_x_header_rec     OUT             oe_order_pub.header_rec_type
     ,p_x_line_tbl       OUT             oe_order_pub.line_tbl_type
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);

   PROCEDURE create_order(
      p_header_rec       IN              djooic_om_impbs_header_rec
     ,p_lines_tbl        IN              djooic_om_impbs_line_tbl
     ,x_order_rec        OUT             order_rec_type
     ,x_transaction_id   OUT             NUMBER
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2);
END djooic_om_impbs_process_order_pkg;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" TO "XXOIC";
  GRANT DEBUG ON "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" TO "XXOIC";

--------------------------------------------------------
--  DDL for Package Body DJOOIC_ASO_QP_PRICE_REQUEST_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_ASO_QP_PRICE_REQUEST_PKG" 
AS
--
-- Preparer Name: Praveen Gorja
-- For fetching price lists
--
   PROCEDURE apps_initilzation(
      ip_username                 VARCHAR2
     ,ip_responsibility           VARCHAR2
     ,ip_application_name         VARCHAR2
     ,op_status             OUT   VARCHAR2
     ,op_message            OUT   VARCHAR2)
   IS
      l_test_init      NUMBER;
      l_error_msg      VARCHAR2(1000);
      l_user_id        fnd_user.user_id%TYPE;
      l_resp_id        fnd_responsibility_tl.responsibility_id%TYPE;
      l_resp_appl_id   fnd_responsibility_tl.application_id%TYPE;
   BEGIN
      op_message := NULL;

      BEGIN
         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE UPPER(user_name) = UPPER(ip_username);
      EXCEPTION
         WHEN OTHERS THEN
            op_status := 'E';
            op_message := 'FND User ' || ip_username || ' not found.' || SQLERRM;
      END;

      BEGIN
         SELECT responsibility_id
           INTO l_resp_id
           FROM fnd_responsibility_tl
          WHERE UPPER(responsibility_name) = UPPER(ip_responsibility)
            AND LANGUAGE = USERENV('LANG');
      EXCEPTION
         WHEN OTHERS THEN
            op_status := 'E';
            op_message := 'Responsibility ' || ip_responsibility || ' not found.' || SQLERRM;
      END;

      BEGIN
         SELECT application_id
           INTO l_resp_appl_id
           FROM fnd_application_tl
          WHERE UPPER(application_name) = UPPER(ip_application_name)                                                                   --661
            AND LANGUAGE = USERENV('LANG');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            op_status := 'E';
            op_message := 'Application: ' || ip_application_name || ' not found.' || SQLERRM;
      END;

      SELECT fnd_global.user_id
        INTO l_test_init
        FROM DUAL;

      IF l_test_init = -1 THEN
         fnd_global.apps_initialize(l_user_id
                                   ,l_resp_id
                                   ,l_resp_appl_id);
         op_status := 'S';
         op_message := 'Initialize sucess';
      ELSE
         fnd_global.apps_initialize(0
                                   ,0
                                   ,0);
         fnd_global.apps_initialize(l_user_id
                                   ,l_resp_id
                                   ,l_resp_appl_id);
         op_status := 'S';
         op_message := 'Initialize sucess';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         l_error_msg := 'Error: ' || SQLERRM || '-' || DBMS_UTILITY.format_error_backtrace();
         op_status := 'E';
         op_message := op_message || 'exception when apps initilization: ' || l_error_msg;
   END apps_initilzation;

   /**************************************************************************************
    *
    *   PROCEDURE
    *     print_debug
    *
    *   DESCRIPTION
    *   Procedure to print debug message
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_msg              IN        Message
    *   p_debug            IN        Debug Flag
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   price_request
    *
    **************************************************************************************/
   PROCEDURE print_debug(
      p_msg     IN   VARCHAR2
     ,p_debug   IN   BOOLEAN DEFAULT g_debug)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF p_debug = TRUE THEN
         DBMS_OUTPUT.put_line(p_msg);

         INSERT INTO price_debug
              VALUES (p_msg);

         COMMIT;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.put_line(SQLERRM);
   END print_debug;

   /**************************************************************************************
   *
   *   PROCEDURE
   *     populate_staging
   *
   *   DESCRIPTION
   *   Procedure to insert data into pricing staging table
   *
   *   PARAMETERS
   *   ==========
   *   NAME               TYPE      DESCRIPTION
   *   -----------------  --------  -----------------------------------------------
   *   p_pricereq          IN       Staging table record type
   *
   *   RETURN VALUE
   *   NA
   *
   *   PREREQUISITES
   *   NA
   *
   *   CALLED BY
   *   price_request
   *
   **************************************************************************************/
   PROCEDURE populate_staging(
      p_price_check_rec   IN   DJOOIC_QP_PRICECHECK_IMPBS_STG%ROWTYPE)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_price_check_rec   DJOOIC_QP_PRICECHECK_IMPBS_STG%ROWTYPE   := p_price_check_rec;
   BEGIN
      INSERT INTO DJOOIC_QP_PRICECHECK_IMPBS_STG
           VALUES (l_price_check_rec.transaction_id
                  ,l_price_check_rec.item
                  ,l_price_check_rec.customer
                  ,l_price_check_rec.pricing_date
                  ,l_price_check_rec.ib_order_number
                  ,l_price_check_rec.price_list_name
                  ,l_price_check_rec.list_price
                  ,l_price_check_rec.selling_price
                  ,l_price_check_rec.ERROR_CODE
                  ,l_price_check_rec.error_message
                  ,l_price_check_rec.oic_status
                  ,l_price_check_rec.oic_error_message
                  ,l_price_check_rec.interface_identifier
                  ,l_price_check_rec.created_by
                  ,l_price_check_rec.creation_date
                  ,l_price_check_rec.last_updated_by
                  ,l_price_check_rec.last_update_date
                  ,l_price_check_rec.last_update_login);

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         DBMS_OUTPUT.put_line(SQLERRM);
   END populate_staging;

--price_check
--++++++++++++++++++++++++++++++++++++++++++++++++++++
   PROCEDURE price_check(
      p_header_rec       IN              header_rec_type := g_miss_header_rec
     ,p_lines_rec        IN              line_rec_type := g_miss_line_rec
     ,x_lines_rec        OUT             line_rec_type
     ,x_transaction_id   OUT             NUMBER
     ,x_return_status    OUT NOCOPY      VARCHAR2
     ,x_return_message   OUT NOCOPY      VARCHAR2)
   IS
      l_control_rec                aso_quote_pub.control_rec_type;
      l_qte_header_rec             aso_quote_pub.qte_header_rec_type;
      l_qte_line_rec               aso_quote_pub.qte_line_rec_type;
      l_qte_line_tbl               aso_quote_pub.qte_line_tbl_type;
      l_qte_line_dtl_tbl           aso_quote_pub.qte_line_tbl_type;
      l_hd_sales_credit_tbl        aso_quote_pub.sales_credit_tbl_type      := aso_quote_pub.g_miss_sales_credit_tbl;
      l_ln_sales_credit_tbl        aso_quote_pub.sales_credit_tbl_type      := aso_quote_pub.g_miss_sales_credit_tbl;
      lx_hd_shipment_tbl           aso_quote_pub.shipment_tbl_type;
      lx_hd_freight_charge_tbl     aso_quote_pub.freight_charge_tbl_type;
      lx_hd_attr_ext_tbl           aso_quote_pub.line_attribs_ext_tbl_type;
      lx_line_rltship_tbl          aso_quote_pub.line_rltship_tbl_type;
      --lx_price_adj_rltship_tbl   aso_quote_pub.price_adj_rltship_tbl_type;
      lx_hd_sales_credit_tbl       aso_quote_pub.sales_credit_tbl_type;
      lx_quote_party_tbl           aso_quote_pub.quote_party_tbl_type;
      lx_ln_sales_credit_tbl       aso_quote_pub.sales_credit_tbl_type;
      lx_ln_quote_party_tbl        aso_quote_pub.quote_party_tbl_type;
      --lx_ln_price_attr_tbl       aso_quote_pub.price_attributes_tbl_type;
      --lx_ln_payment_tbl          aso_quote_pub.payment_tbl_type;
      --lx_ln_shipment_tbl         aso_quote_pub.shipment_tbl_type;
      --lx_ln_freight_charge_tbl   aso_quote_pub.freight_charge_tbl_type;
     -- lx_ln_tax_detail_tbl       aso_quote_pub.tax_detail_tbl_type;
-- l_qte_line_dtl_tbl ASO_QUOTE_PUB.Qte_Line_Dtl_Tbl_Type;
-- l_hd_Price_Attr_Tbl ASO_QUOTE_PUB.Price_Attributes_Tbl_Type;
      l_hd_payment_tbl             aso_quote_pub.payment_tbl_type;
      l_payment_rec                aso_quote_pub.payment_rec_type;
      l_hd_shipment_rec            aso_quote_pub.shipment_rec_type;
-- l_hd_freight_charge_tbl ASO_QUOTE_PUB.Freight_Charge_Tbl_Type;
      l_hd_tax_detail_tbl          aso_quote_pub.tax_detail_tbl_type;
      l_tax_detail_rec             aso_quote_pub.tax_detail_rec_type;
      l_tax_control_rec            aso_tax_int.tax_control_rec_type;
      l_line_attr_ext_tbl          aso_quote_pub.line_attribs_ext_tbl_type;
      l_line_rltship_tbl           aso_quote_pub.line_rltship_tbl_type;
      l_price_adjustment_tbl       aso_quote_pub.price_adj_tbl_type;
      l_price_adj_attr_tbl         aso_quote_pub.price_adj_attr_tbl_type;
      l_price_adj_rltship_tbl      aso_quote_pub.price_adj_rltship_tbl_type;
      l_ln_price_attr_tbl          aso_quote_pub.price_attributes_tbl_type;
      l_ln_payment_tbl             aso_quote_pub.payment_tbl_type;
      l_ln_shipment_tbl            aso_quote_pub.shipment_tbl_type;
      l_ln_freight_charge_tbl      aso_quote_pub.freight_charge_tbl_type;
      l_ln_tax_detail_tbl          aso_quote_pub.tax_detail_tbl_type;
      lx_qte_header_rec            aso_quote_pub.qte_header_rec_type;
      lx_qte_line_rec              aso_quote_pub.qte_line_rec_type;
      lx_qte_line_tbl              aso_quote_pub.qte_line_tbl_type;
      lx_qte_lines_tbl             aso_quote_pub.qte_line_tbl_type;
      lx_qte_line_dtl_tbl          aso_quote_pub.qte_line_dtl_tbl_type;
      lx_hd_price_attr_tbl         aso_quote_pub.price_attributes_tbl_type;
      lx_hd_payment_tbl            aso_quote_pub.payment_tbl_type;
      lx_hd_shipment_rec           aso_quote_pub.shipment_rec_type;
      lx_hd_tax_detail_tbl         aso_quote_pub.tax_detail_tbl_type;
      lx_line_attr_ext_tbl         aso_quote_pub.line_attribs_ext_tbl_type;
      lx_price_adjustment_tbl      aso_quote_pub.price_adj_tbl_type;
      lx_price_adj_attr_tbl        aso_quote_pub.price_adj_attr_tbl_type;
      lx_price_adj_rltship_tbl     aso_quote_pub.price_adj_rltship_tbl_type;
      lx_ln_price_attr_tbl         aso_quote_pub.price_attributes_tbl_type;
      lx_ln_payment_tbl            aso_quote_pub.payment_tbl_type;
      lx_ln_shipment_tbl           aso_quote_pub.shipment_tbl_type;
      lx_ln_freight_charge_tbl     aso_quote_pub.freight_charge_tbl_type;
      lx_ln_tax_detail_tbl         aso_quote_pub.tax_detail_tbl_type;
      lx_return_status             VARCHAR2(1);
      lx_msg_count                 NUMBER;
      lx_msg_data                  VARCHAR2(2000);
      my_message                   VARCHAR2(2000);
      l_file                       VARCHAR2(2000);
      l_org_id                     NUMBER;
      l_userenv_lang               VARCHAR2(100);
      l_master_org_code            VARCHAR2(10);
      lx_init_status               VARCHAR2(10);
      lx_init_message              VARCHAR2(2000);
      l_commit                     VARCHAR2(1);
      l_cust_account_id            NUMBER;
      l_party_id                   NUMBER;
      l_price_list_id              NUMBER;
      l_invoice_to_party_site_id   NUMBER;
      l_shipto_cust_account_id     NUMBER;
      l_shipto_party_site_id       NUMBER;
      l_payment_terms_id           NUMBER;
      l_transaction_type_id        NUMBER;
      op_status                    VARCHAR2(1);
      op_message                   VARCHAR2(2400);
      l_error_msg                  VARCHAR2(2400);
      l_return_status              VARCHAR2(1);
      l_validation_status          VARCHAR2(1)                              := 'S';
      l_val_error_msg              VARCHAR2(2400);
      l_currency_code              VARCHAR2(4);
      l_header_rec                 header_rec_type;
      l_lines_tbl                  line_tbl_type                            := g_miss_line_tbl;
      lx_lines_tbl                 line_tbl_type                            := g_miss_line_tbl;
      l_lines_rec                  line_rec_type                            := g_miss_line_rec;
      lx_lines_rec                 line_rec_type                            := g_miss_line_rec;
      l_inventory_item_id          NUMBER;
      l_inventory_org_id           NUMBER;
      lx_update_return_status      VARCHAR2(1);
      lx_update_error_msg          VARCHAR2(2400);
      lx_order_header_id           NUMBER;
      lx_order_number              NUMBER;
      lx_submit_return_status      VARCHAR2(1);
      lx_submit_error_msg          VARCHAR2(2400);
      l_order_total_amount         NUMBER;
      l_so_basic_tot               NUMBER;
      l_so_discount                NUMBER;
      l_so_charges                 NUMBER;
      l_so_tax                     NUMBER;
      l_username                   VARCHAR2(40);
      l_responsibility             VARCHAR2(240);
      l_application_name           VARCHAR2(240);
      l_flow_status_code           VARCHAR2(30);
      l_data_valid_excep           EXCEPTION;
      l_apps_init_execp            EXCEPTION;
      l_instance_name              v$instance.instance_name%TYPE;
      l_price_list                 qp_list_headers.NAME%TYPE;
      l_price_check_rec            DJOOIC_QP_PRICECHECK_IMPBS_STG%ROWTYPE;
      l_transaction_id             NUMBER;
      l_ib_ref_num_cnt             NUMBER;
      l_quote_header_id            NUMBER;
      l_curr_cust_account_id       NUMBER;
      lx_crt_ln_return_status      VARCHAR2(1);
      lx_crt_ln_error_msg          VARCHAR2(2400);
      l_list_price                 NUMBER;
      lv_user_name                 VARCHAR2(1000);
      lv_resp_name                 VARCHAR2(1000);
      lv_application_name          VARCHAR2(1000);
      lv_org_name                  VARCHAR2(1000);
      lc_last_update_date          DATE;
      x_cnt                        NUMBER                                   := 1;
   BEGIN
      l_username := 'SYSADMIN';
      l_responsibility := 'Order Management Super User';
      --l_responsibility := 'Order Management Super User, Vision Operations (USA)';
      l_application_name := 'Order Management';

      BEGIN
         SELECT DJOOIC_QP_PRICECHECK_IMPBS_S.NEXTVAL
           --SELECT DBMS_RANDOM.NORMAL
         INTO   l_transaction_id
           FROM DUAL;

         x_transaction_id := l_transaction_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_transaction_id := 0;
      END;

      BEGIN
         SELECT SUBSTR(instance_name
                      ,1
                      ,4)
           INTO l_instance_name
           FROM v$instance;
      EXCEPTION
         WHEN OTHERS THEN
            l_instance_name := 'DJOP';
      END;

-- Ref Note: 209185.1 (How To Set the Applications Context..)
      IF     l_instance_name != 'DJOP'
         AND g_trace THEN
         aso_debug_pub.debug_on;
         aso_debug_pub.initialize;
         l_file := aso_debug_pub.set_debug_mode('FILE');
         aso_debug_pub.setdebuglevel(10);
         aso_debug_pub.ADD('create Quote'
                          ,1
                          ,'Y');
         print_debug('File :' || l_file);
      END IF;

      apps_initilzation(ip_username              => l_username
                       ,ip_responsibility        => l_responsibility
                       ,ip_application_name      => l_application_name
                       ,op_status                => lx_init_status
                       ,op_message               => lx_init_message);

      IF lx_init_status = 'E' THEN
         x_return_status := lx_init_status;
         x_return_message := lx_init_message;
         RAISE l_apps_init_execp;
      END IF;

      l_header_rec := p_header_rec;
      l_lines_rec := p_lines_rec;
      l_commit := fnd_api.g_true;
    
      BEGIN
      print_debug('org id before begin - ' || l_org_id);
       print_debug('l_lines_rec.organization_code before begin - ' || l_lines_rec.organization_code); 
         SELECT DISTINCT operating_unit
                    INTO l_org_id
                    FROM org_organization_definitions
                   WHERE organization_code = l_lines_rec.organization_code;
                   print_debug('org id after begin - ' || l_org_id);
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := l_val_error_msg || '...Error in fetching operating unit -->' || SQLERRM;
      END;

      l_userenv_lang := USERENV('LANG');
      BEGIN
      mo_global.init('ASO');
      mo_global.set_org_context(l_org_id
                               ,NULL
                               ,'ASO');
        EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := l_val_error_msg || '...Error in fetching MO Org Context -->' || SQLERRM;
        END;
      BEGIN
      mo_global.set_policy_context('S', l_org_id);
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := l_val_error_msg || '...Error in fetching policy context -->' || SQLERRM;
            END;
      print_debug('begin_0');
      print_debug('before begin cust_account_id query - ' || l_header_rec.account_number);

      BEGIN
         l_cust_account_id := NULL;
         l_party_id := NULL;
         l_price_list_id := NULL;
         l_currency_code := NULL;

         SELECT cust_account_id
               ,party_id
               ,hca.price_list_id
               ,qlb.currency_code
           INTO l_cust_account_id
               ,l_party_id
               ,l_price_list_id
               ,l_currency_code
           FROM hz_cust_accounts hca
               ,qp_list_headers_b qlb
          WHERE hca.price_list_id = qlb.list_header_id(+)
            AND account_number = l_header_rec.account_number;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := l_val_error_msg || '...Error in fetching account number -->' || SQLERRM;
      END;

      BEGIN
         l_price_list := NULL;

         SELECT TO_CHAR(NAME)
           INTO l_price_list
           FROM qp_list_headers
          WHERE list_header_id = l_price_list_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := l_val_error_msg || '...INVALID PRICE LIST -->' || SQLERRM;
      END;

      BEGIN
         l_payment_terms_id := NULL;

         SELECT hcp.standard_terms
           INTO l_payment_terms_id
           FROM hz_cust_accounts hca
               ,hz_customer_profiles hcp
          WHERE hcp.cust_account_id = hca.cust_account_id
            AND NVL(hcp.status, 'A') = 'A'
            AND hcp.site_use_id IS NULL
            AND hca.cust_account_id = l_cust_account_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || 'Error in fetching payment terms -->' || SQLERRM;
      END;

      BEGIN
         l_invoice_to_party_site_id := NULL;

         SELECT DISTINCT hps.party_site_id
                    INTO l_invoice_to_party_site_id
                    FROM apps.hz_cust_site_uses_all hcsu
                        ,apps.hz_cust_acct_sites_all hcas
                        ,apps.hz_cust_accounts hca
                        ,apps.hz_party_sites hps
                   WHERE 1 = 1
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcas.cust_account_id = hca.cust_account_id
                     AND hcas.party_site_id = hps.party_site_id
                     AND hca.cust_account_id = l_cust_account_id
                     AND hcsu.site_use_code = 'BILL_TO'
                     AND NVL(hcsu.status, 'A') = 'A'
                     AND NVL(hca.status, 'A') = 'A'
                     AND NVL(hcas.status, 'A') = 'A'
                     AND NVL(hps.status, 'A') = 'A'
                     AND hcsu.primary_flag = 'Y'
                     AND hcas.org_id = l_org_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || 'Error in fetching Invoice TO to party site id -->' || SQLERRM;
      END;

      BEGIN
         l_shipto_cust_account_id := NULL;
         l_shipto_party_site_id := NULL;

         SELECT DISTINCT hca.cust_account_id
                        ,hps.party_site_id
                    INTO l_shipto_cust_account_id
                        ,l_shipto_party_site_id
                    FROM apps.hz_cust_site_uses_all hcsu
                        ,apps.hz_cust_acct_sites_all hcas
                        ,apps.hz_cust_accounts hca
                        ,apps.hz_party_sites hps
                   WHERE 1 = 1
                     AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                     AND hcas.cust_account_id = hca.cust_account_id
                     AND hcas.party_site_id = hps.party_site_id
                     AND hca.account_number = l_header_rec.account_number
                     AND hcsu.site_use_code = 'SHIP_TO'
                     AND NVL(hcsu.status, 'A') = 'A'
                     AND NVL(hca.status, 'A') = 'A'
                     AND NVL(hcas.status, 'A') = 'A'
                     AND NVL(hps.status, 'A') = 'A'
                     AND hcsu.primary_flag = 'Y'
                     AND hcas.org_id = l_org_id;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || 'Error in fetching Ship to account number -->' || SQLERRM;
      END;

      BEGIN
        SELECT ott.transaction_type_id
           INTO l_transaction_type_id
           FROM oe_transaction_types_all ott
               ,oe_transaction_types_tl ottl
          WHERE 1 = 1
            AND ott.transaction_type_id = ottl.transaction_type_id
            AND ottl.LANGUAGE = USERENV('LANG')
            AND ottl.NAME =
                   DECODE(l_org_id
                         ,'81', 'AUS CONSUMPTION ORDER'
                         ,'129', 'UK STANDARD ORDER'
                         ,'103', 'BE STANDARD ORDER'
                         ,'104', 'SE STANDARD ORDER'
                         ,'106', 'ES STANDARD ORDER'
                         ,'134', 'IT STANDARD ORDER'
                         ,'101', 'FR STANDARD ORDER'
                         ,'133', 'CA STANDARD ORDER'
                         ,'105', 'DE STANDARD ORDER')
            AND TRUNC(NVL(ott.end_date_active, SYSDATE)) >= TRUNC(SYSDATE);
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || 'Error in fetching Order Type-->' || SQLERRM;
      END;

      print_debug('assigning values to l_control_rec');
      l_control_rec.calculate_tax_flag := 'Y';
-- l_control_rec.CALCULATE_FREIGHT_CHARGE := 'Y';
      l_control_rec.calculate_freight_charge_flag := 'Y';
      l_control_rec.pricing_request_type := 'ASO';
      l_control_rec.header_pricing_event := 'BATCH';
      l_control_rec.last_update_date := SYSDATE;
      print_debug('assigning values to l_qte_header_rec');
      l_qte_header_rec.quote_name := l_header_rec.po_number;
      l_qte_header_rec.original_system_reference := l_header_rec.ib_order_number;
-- l_qte_header_rec.quote_number := 1;
-- l_qte_header_rec.quote_expiration_date := sysdate-1;
      l_qte_header_rec.quote_source_code := 'ASO';
      l_qte_header_rec.currency_code := l_currency_code;
      l_qte_header_rec.party_id := l_party_id;
      l_qte_header_rec.cust_account_id := l_cust_account_id;
      l_qte_header_rec.automatic_price_flag := 'Y';
      l_qte_header_rec.automatic_tax_flag := 'Y';
      l_qte_header_rec.recalculate_flag := 'Y';
-- l_qte_header_rec.invoice_to_cust_account_id := 48147;
-- l_qte_header_rec.invoice_to_party_id := 1001;
      l_qte_header_rec.invoice_to_party_site_id := l_invoice_to_party_site_id;
-- l_qte_header_rec.quote_status_id := 6;
      l_qte_header_rec.order_type_id := l_transaction_type_id;
      l_qte_header_rec.price_list_id := l_price_list_id;
      --l_qte_header_rec.employee_person_id := 692;
      l_qte_header_rec.resource_id := 1;                                                                                        --102784780;
      --l_qte_header_rec.resource_id := l_header_rec.resource_id;
      l_qte_header_rec.attribute18 := l_header_rec.case_start_date;
   ---- SHIPPING details
-- l_hd_shipment_rec.ship_to_party_id := 5843;
      print_debug('assigning values to l_hd_shipment_rec');
      l_hd_shipment_rec.ship_to_party_site_id := l_shipto_party_site_id;
      l_hd_shipment_rec.ship_to_cust_account_id := l_shipto_cust_account_id;
      --+++++++++++++++++++++ PAYMENT details (for example default a payment term) ++++++++++++++++++++++++++
      print_debug('assigning values to l_hd_payment_tb');
      l_hd_payment_tbl(1).operation_code := 'CREATE';
      l_hd_payment_tbl(1).payment_term_id := l_payment_terms_id;
      --l_hd_payment_tbl(1).cust_po_number := l_header_rec.po_number;
-- NOTE: payment term id can be determined as follows:
-- select term_id from ra_terms where name = 'Net 60' and sysdate between start_date_active and nvl(end_date_active, sysdate)
--++++++++----------------------------
      -- l_hd_tax_detail_tbl(1).OPERATION_CODE := 'CREATE';
-- l_hd_tax_detail_tbl(1).TAX_EXEMPT_FLAG := 'E';
-- l_hd_tax_detail_tbl(1).TAX_EXEMPT_REASON_CODE := 'RESALE';

      --++++++++++++++++++++++++LINES ++++++++++++++++++++++++
      print_debug('assigning values to l_lines_tbl  ->' || l_lines_tbl.COUNT);

--            --+++++++++ Inv item details ++++++++++++
      BEGIN
         l_inventory_item_id := NULL;
         l_inventory_org_id := NULL;

         SELECT msib.inventory_item_id
               ,msib.organization_id
           INTO l_inventory_item_id
               ,l_inventory_org_id
           FROM mtl_system_items_b msib
               ,mtl_parameters mp
          WHERE 1 = 1
            AND mp.organization_code = l_lines_rec.organization_code
            AND msib.organization_id = mp.organization_id
            AND msib.segment1 = l_lines_rec.part_number;
      EXCEPTION
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg :=
                          '...' || l_val_error_msg || '...' || 'Error in Inventory Item--> ' || l_lines_rec.part_number || '...' || SQLERRM;
      END;

      l_qte_line_tbl(x_cnt).organization_id := l_inventory_org_id;
      l_qte_line_tbl(x_cnt).operation_code := 'CREATE';
      l_qte_line_tbl(x_cnt).inventory_item_id := l_inventory_item_id;
      l_qte_line_tbl(x_cnt).quantity := NVL(l_lines_rec.quantity, 1);
      l_qte_line_tbl(x_cnt).org_id := l_org_id;
      l_qte_line_tbl(x_cnt).recalculate_flag := 'Y';

      SELECT aso.aso_quote_lines_s.NEXTVAL
        INTO l_qte_line_tbl(x_cnt).quote_line_id
        FROM DUAL;

      print_debug('l_qte_line_tbl(x_cnt).organization_id -->' || l_qte_line_tbl(x_cnt).organization_id);
      print_debug('l_qte_line_tbl(x_cnt).operation_code -->' || l_qte_line_tbl(x_cnt).operation_code);
      print_debug('l_qte_line_tbl(x_cnt).inventory_item_id -->' || l_qte_line_tbl(x_cnt).inventory_item_id);
      print_debug('l_qte_line_tbl(x_cnt).quantity -->' || l_qte_line_tbl(x_cnt).quantity);
      print_debug('l_qte_line_tbl(x_cnt).org_id -->' || l_qte_line_tbl(x_cnt).org_id);
      print_debug('l_qte_line_tbl(x_cnt).quote_line_id -->' || l_qte_line_tbl(x_cnt).quote_line_id);

      BEGIN
         l_curr_cust_account_id := NULL;
         l_quote_header_id := NULL;

         SELECT max(quote_header_id)
                        ,max(cust_account_id)
                    INTO l_quote_header_id
                        ,l_curr_cust_account_id
                    FROM aso_quote_headers_all
                   WHERE NVL(original_system_reference, 'YYY') = NVL(l_header_rec.ib_order_number, 'YYY')
                     AND cust_account_id = l_cust_account_id;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_quote_header_id := NULL;
         WHEN TOO_MANY_ROWS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || 'multiple quotes exists with this reference';
         WHEN OTHERS THEN
            l_validation_status := 'E';
            l_val_error_msg := '...' || l_val_error_msg || '...' || ' Error while fetching the quote header ' || SQLERRM;
      END;

      IF l_validation_status = 'E' THEN
         x_return_status := 'E';
         x_return_message := l_val_error_msg;
         RAISE l_data_valid_excep;
      END IF;

      IF (    (NVL(l_quote_header_id, -1) <> -1)
          AND (NVL(l_curr_cust_account_id, -1) = NVL(l_cust_account_id, -2))) THEN
         print_debug('Before creating the line');
         update_quote(p_quote_header_id        => l_quote_header_id
                        ,p_organization_id        => l_qte_line_tbl(1).organization_id
                        ,p_inventory_item_id      => l_qte_line_tbl(1).inventory_item_id
                        ,p_quantity               => l_qte_line_tbl(1).quantity
                        ,x_qte_lines_tbl          => lx_qte_line_tbl
                        ,x_return_status          => lx_return_status
                        ,x_return_message         => lx_crt_ln_error_msg);
         lx_qte_line_rec := lx_qte_line_tbl(1);
         print_debug('Count' || lx_qte_lines_tbl.COUNT);
         print_debug('lx_return_status for update - ' || lx_return_status);
         print_debug('lx_return_message for update - ' || lx_crt_ln_error_msg);
         x_return_status := lx_return_status;
         l_list_price := lx_qte_line_rec.line_list_price;

         IF lx_return_status = 'S' THEN
            BEGIN
               SELECT msib.segment1
                 INTO lx_lines_rec.part_number
                 FROM mtl_system_items_b msib
                WHERE 1 = 1
                  AND msib.inventory_item_id = lx_qte_line_rec.inventory_item_id
                  AND organization_id = lx_qte_line_rec.organization_id;
            EXCEPTION
               WHEN OTHERS THEN
                  print_debug('Error in Inventory part number-->' || SQLERRM);
            END;

            -- Fetching Modifier group name applied to the quote
            BEGIN
               SELECT DISTINCT ml.group_number
                          INTO lx_lines_rec.modifier
                          FROM aso_pvt_hdr_price_adj_ui_v mh
                              ,aso_pvt_line_price_adj_ui_v ml
                         WHERE 1 = 1
                           AND ml.applied_flag = 'Y'
                           AND mh.quote_header_id = l_quote_header_id
                           AND ml.quote_line_id = lx_qte_line_rec.quote_line_id;
            EXCEPTION
               WHEN OTHERS THEN
                  print_debug('Error in Fetching Modifier-->' || SQLERRM);
            END;

            --+++++++++ Inv item details ++++++++++++
            print_debug('lx_qte_line_tbl(x).LINE_NUMBER :' || lx_qte_line_rec.line_number);
            print_debug('lx_qte_line_tbl(x).UI_LINE_NUMBER :' || lx_qte_line_rec.ui_line_number);
            print_debug('lx_qte_line_tbl(x).INVENTORY_ITEM_ID :' || lx_qte_line_rec.inventory_item_id);
            print_debug('lx_lines_rec.part_number' || lx_lines_rec.part_number);
            print_debug('lx_qte_line_tbl(x).QUANTITY :' || lx_qte_line_rec.quantity);
            print_debug('l_list_price :' || l_list_price);
            print_debug('lx_qte_line_tbl(x).LINE_QUOTE_PRICE :' || ROUND(lx_qte_line_rec.line_quote_price, 2));
            print_debug('lx_qte_line_tbl(x).l_price_list :' || l_price_list);
            print_debug('lx_qte_line_tbl(x).LINE_ADJUSTED_AMOUNT :' || ROUND(lx_qte_line_rec.line_adjusted_amount, 2));
            print_debug('lx_lines_rec.MODIFIER' || lx_lines_rec.modifier);
            lx_lines_rec.line_number := lx_qte_line_rec.line_number;
            lx_lines_rec.quantity := lx_qte_line_rec.quantity;
            lx_lines_rec.unit_list_price := lx_qte_line_rec.line_list_price;
            lx_lines_rec.unit_sell_price := lx_qte_line_rec.line_quote_price;
            lx_lines_rec.price_list_name := l_price_list;
            x_lines_rec := lx_lines_rec;
         ELSE
            lx_lines_rec := g_miss_line_rec;
            x_lines_rec := lx_lines_rec;
         END IF;

         x_return_message := lx_crt_ln_error_msg;
         l_price_check_rec.transaction_id := l_transaction_id;
         l_price_check_rec.item := l_lines_rec.part_number;
         l_price_check_rec.customer := l_header_rec.account_number;
         l_price_check_rec.pricing_date := SYSDATE;
         l_price_check_rec.ib_order_number := l_header_rec.ib_order_number;
         l_price_check_rec.price_list_name := lx_lines_rec.price_list_name;
         l_price_check_rec.list_price := lx_lines_rec.unit_list_price;
         l_price_check_rec.selling_price := lx_lines_rec.unit_sell_price;
         l_price_check_rec.ERROR_CODE := x_return_status;
         l_price_check_rec.error_message := lx_crt_ln_error_msg;
         l_price_check_rec.oic_status := 'N';
         l_price_check_rec.oic_error_message := NULL;
         l_price_check_rec.interface_identifier := 'IMPBS';
         l_price_check_rec.created_by := '-1';
         l_price_check_rec.creation_date := SYSDATE;
         l_price_check_rec.last_update_date := SYSDATE;
         l_price_check_rec.last_updated_by := '-1';
         l_price_check_rec.last_update_login := NULL;
         populate_staging(l_price_check_rec);
         print_debug('end of Add line price check proc');
      ELSE
         l_error_msg := NULL;
         l_return_status := NULL;
         lx_msg_count := NULL;

         BEGIN
            print_debug('l_control_rec.calculate_tax_flag --> ' || l_control_rec.calculate_tax_flag);
            print_debug('l_control_rec.calculate_freight_charge_flag --> ' || l_control_rec.calculate_freight_charge_flag);
            print_debug('l_control_rec.pricing_request_type --> ' || l_control_rec.pricing_request_type);
            print_debug('l_control_rec.header_pricing_event --> ' || l_control_rec.header_pricing_event);
            print_debug('l_qte_header_rec.quote_name --> ' || l_qte_header_rec.quote_name);
            print_debug('l_qte_header_rec.original_system_reference --> ' || l_qte_header_rec.original_system_reference);
            print_debug('l_qte_header_rec.quote_source_code --> ' || l_qte_header_rec.quote_source_code);
            print_debug('l_qte_header_rec.currency_code --> ' || l_qte_header_rec.currency_code);
            print_debug('l_qte_header_rec.party_id  --> ' || l_qte_header_rec.party_id);
            print_debug('l_qte_header_rec.cust_account_id --> ' || l_qte_header_rec.cust_account_id);
            print_debug('l_qte_header_rec.automatic_price_flag --> ' || l_qte_header_rec.automatic_price_flag);
            print_debug('l_qte_header_rec.automatic_tax_flag --> ' || l_qte_header_rec.automatic_tax_flag);
            print_debug('l_qte_header_rec.automatic_price_flag --> ' || l_qte_header_rec.automatic_price_flag);
            print_debug('l_qte_header_rec.recalculate_flag --> ' || l_qte_header_rec.recalculate_flag);
            print_debug('l_qte_header_rec.invoice_to_party_site_id --> ' || l_qte_header_rec.invoice_to_party_site_id);
            print_debug('l_qte_header_rec.order_type_id --> ' || l_qte_header_rec.order_type_id);
            print_debug('l_qte_header_rec.price_list_id --> ' || l_qte_header_rec.price_list_id);
            print_debug('l_qte_header_rec.resource_id --> ' || l_qte_header_rec.resource_id);
            print_debug('l_qte_header_rec.attribute18 --> ' || l_qte_header_rec.attribute18);
            print_debug(' l_hd_shipment_rec.ship_to_party_site_id--> ' || l_hd_shipment_rec.ship_to_party_site_id);
            print_debug(' l_hd_shipment_rec.ship_to_cust_account_id--> ' || l_hd_shipment_rec.ship_to_cust_account_id);
            print_debug('l_hd_payment_tbl(1).operation_code --> ' || l_hd_payment_tbl(1).operation_code);
            print_debug('l_hd_payment_tbl(1).payment_term_id --> ' || l_hd_payment_tbl(1).payment_term_id);
            print_debug('l_hd_payment_tbl(1).cust_po_number --> ' || l_hd_payment_tbl(1).cust_po_number);

            IF l_qte_line_tbl.COUNT > 0 THEN
               FOR x IN l_qte_line_tbl.FIRST .. l_qte_line_tbl.LAST LOOP
                  print_debug('l_qte_line_tbl(' || x || ').organization_id -->' || l_qte_line_tbl(x).organization_id);
                  print_debug('l_qte_line_tbl(' || x || ').operation_code -->' || l_qte_line_tbl(x).operation_code);
                  print_debug('l_qte_line_tbl(' || x || ').inventory_item_id -->' || l_qte_line_tbl(x).inventory_item_id);
                  print_debug('l_qte_line_tbl(' || x || ').quantity -->' || l_qte_line_tbl(x).quantity);
                  print_debug('l_qte_line_tbl(' || x || ').org_id -->' || l_qte_line_tbl(x).org_id);
                  print_debug('l_qte_line_tbl(' || x || ').quote_line_id -->' || l_qte_line_tbl(x).quote_line_id);
               END LOOP;
            END IF;

            SELECT fnd_global.user_name
                  ,fnd_global.resp_name
                  ,fnd_global.application_name
                  ,fnd_global.org_name
              INTO lv_user_name
                  ,lv_resp_name
                  ,lv_application_name
                  ,lv_org_name
              FROM DUAL;

            print_debug('lv_user_name -->' || lv_user_name);
            print_debug('lv_resp_name -->' || lv_resp_name);
            print_debug('lv_application_name -->' || lv_application_name);
            print_debug('lv_org_name -->' || lv_org_name);
            ---
            print_debug('Before aso_quote_pub.create_quote');
            aso_quote_pub.create_quote(p_api_version_number           => 1.0
                                      ,p_init_msg_list                => fnd_api.g_true
                                      ,p_commit                       => l_commit
                                      ,p_control_rec                  => l_control_rec
                                      ,p_qte_header_rec               => l_qte_header_rec
                                      ,p_qte_line_tbl                 => l_qte_line_tbl
                                      ,p_hd_payment_tbl               => l_hd_payment_tbl
                                      ,p_hd_shipment_rec              => l_hd_shipment_rec
                                      ,p_hd_tax_detail_tbl            => l_hd_tax_detail_tbl
                                      ,x_qte_header_rec               => lx_qte_header_rec
                                      ,x_qte_line_tbl                 => lx_qte_line_tbl
                                      ,x_qte_line_dtl_tbl             => lx_qte_line_dtl_tbl
                                      ,x_hd_price_attributes_tbl      => lx_hd_price_attr_tbl
                                      ,x_hd_payment_tbl               => lx_hd_payment_tbl
                                      ,x_hd_shipment_rec              => lx_hd_shipment_rec
                                      ,x_hd_freight_charge_tbl        => lx_hd_freight_charge_tbl
                                      ,x_hd_tax_detail_tbl            => lx_hd_tax_detail_tbl
                                      ,x_line_attr_ext_tbl            => lx_line_attr_ext_tbl
                                      ,x_line_rltship_tbl             => lx_line_rltship_tbl
                                      ,x_price_adjustment_tbl         => lx_price_adjustment_tbl
                                      ,x_price_adj_attr_tbl           => lx_price_adj_attr_tbl
                                      ,x_price_adj_rltship_tbl        => lx_price_adj_rltship_tbl
                                      ,x_ln_price_attributes_tbl      => lx_ln_price_attr_tbl
                                      ,x_ln_payment_tbl               => lx_ln_payment_tbl
                                      ,x_ln_shipment_tbl              => lx_ln_shipment_tbl
                                      ,x_ln_freight_charge_tbl        => lx_ln_freight_charge_tbl
                                      ,x_ln_tax_detail_tbl            => lx_ln_tax_detail_tbl
                                      ,x_return_status                => l_return_status
                                      ,x_msg_count                    => lx_msg_count
                                      ,x_msg_data                     => l_error_msg);
            print_debug('After creating quote.. API status: ' || l_return_status);
            print_debug('Quote Header Id -' || lx_qte_header_rec.quote_header_id || '...Quote Number: ' || lx_qte_header_rec.quote_number
                        || '...Quote Version: ' || lx_qte_header_rec.quote_version);
         EXCEPTION
            WHEN OTHERS THEN
               print_debug('Exception creating quote API block: ' || SQLERRM || '...' || DBMS_UTILITY.format_error_backtrace());
               COMMIT;
         END;

         x_return_status := l_return_status;

         IF l_return_status = 'S' THEN
            IF lx_qte_line_tbl.COUNT > 0 THEN
               FOR x IN lx_qte_line_tbl.FIRST .. lx_qte_line_tbl.LAST LOOP
                  --+++++++++ Inv item details ++++++++++++
                  BEGIN
                     SELECT line_list_price
                           ,line_adjusted_amount
                           ,line_adjusted_percent
                           ,line_quote_price
                           ,priced_price_list_id
                           ,line_category_code
                       INTO lx_qte_line_tbl(x).line_list_price
                           ,lx_qte_line_tbl(x).line_adjusted_amount
                           ,lx_qte_line_tbl(x).line_adjusted_percent
                           ,lx_qte_line_tbl(x).line_quote_price
                           ,lx_qte_line_tbl(x).priced_price_list_id
                           ,lx_qte_line_tbl(x).line_category_code
                       FROM aso_quote_lines_all
                      WHERE 1 = 1
                        AND quote_line_id = lx_qte_line_tbl(x).quote_line_id
                        AND quote_header_id = lx_qte_header_rec.quote_header_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        print_debug('price_check..fetching list price,quote price ..when others message:' || SQLERRM);
                  END;

                  BEGIN
                     SELECT msib.segment1
                       INTO lx_lines_rec.part_number
                       FROM mtl_system_items_b msib
                      WHERE 1 = 1
                        AND msib.inventory_item_id = lx_qte_line_tbl(x).inventory_item_id
                        AND organization_id = lx_qte_line_tbl(x).organization_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        print_debug('Error in Inventory part number-->' || SQLERRM);
                  END;

                  -- Fetching Modifier group name applied to the quote
                  BEGIN
                     SELECT DISTINCT ml.group_number
                                INTO lx_lines_rec.modifier
                                FROM aso_pvt_hdr_price_adj_ui_v mh
                                    ,aso_pvt_line_price_adj_ui_v ml
                               WHERE 1 = 1
                                 AND ml.applied_flag = 'Y'
                                 AND mh.quote_header_id = lx_qte_header_rec.quote_header_id
                                 AND ml.quote_line_id = lx_qte_line_tbl(x).quote_line_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        print_debug('Error in Fetching Modifier-->' || SQLERRM);
                  END;

                  print_debug('lines out --record number :' || x);
                  print_debug('lx_qte_line_tbl(x).quote_line_id :' || lx_qte_line_tbl(x).quote_line_id);
                  print_debug('lx_qte_line_tbl(x).LINE_NUMBER :' || lx_qte_line_tbl(x).line_number);
                  print_debug('lx_qte_line_tbl(x).UI_LINE_NUMBER :' || lx_qte_line_tbl(x).ui_line_number);
                  print_debug('lx_qte_line_tbl(x).INVENTORY_ITEM_ID :' || lx_qte_line_tbl(x).inventory_item_id);
                  print_debug('lx_lines_tbl(X).PART NUMBER :' || lx_lines_rec.part_number);
                  print_debug('lx_qte_line_tbl(x).QUANTITY :' || lx_qte_line_tbl(x).quantity);
                  print_debug('lx_qte_line_tbl(x).LINE_LIST_PRICE :' || ROUND(lx_qte_line_tbl(x).line_list_price, 2));
                  print_debug('lx_qte_line_tbl(x).LINE_QUOTE_PRICE :' || ROUND(lx_qte_line_tbl(x).line_quote_price, 2));
                  print_debug('lx_qte_line_tbl(x).l_price_list :' || l_price_list);
                  print_debug('lx_qte_line_tbl(x).LINE_ADJUSTED_AMOUNT :' || ROUND(lx_qte_line_tbl(x).line_adjusted_amount, 2));
                  print_debug('lx_lines_rec.MODIFIER :' || lx_lines_rec.modifier);
                  lx_lines_rec.line_number := lx_qte_line_tbl(x).line_number;
                  lx_lines_rec.quantity := lx_qte_line_tbl(x).quantity;
                  lx_lines_rec.unit_list_price := lx_qte_line_tbl(x).line_list_price;
                  lx_lines_rec.unit_sell_price := lx_qte_line_tbl(x).line_quote_price;
                  lx_lines_rec.price_list_name := l_price_list;
               END LOOP;

               x_lines_rec := lx_lines_rec;
            ELSE
               lx_lines_rec := g_miss_line_rec;
               x_lines_rec := lx_lines_rec;
            END IF;
         END IF;

         fnd_msg_pub.count_and_get(p_encoded      => 'F'
                                  ,p_count        => lx_msg_count
                                  ,p_data         => l_error_msg);
         print_debug('no. of FND messages :' || lx_msg_count);

         FOR k IN 1 .. lx_msg_count LOOP
            l_error_msg := fnd_msg_pub.get(p_msg_index      => k, p_encoded => 'F');
            print_debug('Error msg: ' || SUBSTR(l_error_msg
                                               ,1
                                               ,240));
         END LOOP;

         x_return_message := l_error_msg;
         l_price_check_rec.transaction_id := l_transaction_id;
         l_price_check_rec.item := lx_lines_rec.part_number;
         l_price_check_rec.customer := l_header_rec.account_number;
         l_price_check_rec.pricing_date := SYSDATE;
         l_price_check_rec.ib_order_number := l_header_rec.ib_order_number;
         l_price_check_rec.price_list_name := lx_lines_rec.price_list_name;
         l_price_check_rec.list_price := lx_lines_rec.unit_list_price;
         l_price_check_rec.selling_price := lx_lines_rec.unit_sell_price;
         l_price_check_rec.ERROR_CODE := x_return_status;
         l_price_check_rec.error_message := x_return_message;
         l_price_check_rec.oic_status := 'N';
         l_price_check_rec.oic_error_message := NULL;
         l_price_check_rec.interface_identifier := 'IMPBS';
         l_price_check_rec.created_by := '-1';
         l_price_check_rec.creation_date := SYSDATE;
         l_price_check_rec.last_update_date := SYSDATE;
         l_price_check_rec.last_updated_by := '-1';
         l_price_check_rec.last_update_login := NULL;
         populate_staging(l_price_check_rec);
         print_debug('end of price check proc');
      END IF;
   EXCEPTION
      WHEN l_data_valid_excep THEN
         print_debug('Validation Status Code: ' || x_return_status);
         print_debug('Validation error message -->: ' || x_return_message);
         l_price_check_rec.transaction_id := l_transaction_id;
         l_price_check_rec.item := l_lines_rec.part_number;
         l_price_check_rec.customer := l_header_rec.account_number;
         l_price_check_rec.pricing_date := SYSDATE;
         l_price_check_rec.ib_order_number := l_header_rec.ib_order_number;
         l_price_check_rec.price_list_name := l_price_list;
         l_price_check_rec.list_price := NULL;
         l_price_check_rec.selling_price := NULL;
         l_price_check_rec.ERROR_CODE := x_return_status;
         l_price_check_rec.error_message := x_return_message;
         l_price_check_rec.oic_status := 'N';
         l_price_check_rec.oic_error_message := NULL;
         l_price_check_rec.interface_identifier := 'IMPBS';
         l_price_check_rec.created_by := '-1';
         l_price_check_rec.creation_date := SYSDATE;
         l_price_check_rec.last_update_date := SYSDATE;
         l_price_check_rec.last_updated_by := '-1';
         l_price_check_rec.last_update_login := NULL;
         populate_staging(l_price_check_rec);
      WHEN l_apps_init_execp THEN
         print_debug('Status Code: ' || x_return_status);
         print_debug('Apps Initialization error: ' || x_return_message);
         l_price_check_rec.transaction_id := l_transaction_id;
         l_price_check_rec.item := l_lines_rec.part_number;
         l_price_check_rec.customer := l_header_rec.account_number;
         l_price_check_rec.pricing_date := SYSDATE;
         l_price_check_rec.ib_order_number := l_header_rec.ib_order_number;
         l_price_check_rec.price_list_name := NULL;
         l_price_check_rec.list_price := NULL;
         l_price_check_rec.selling_price := NULL;
         l_price_check_rec.ERROR_CODE := x_return_status;
         l_price_check_rec.error_message := x_return_message;
         l_price_check_rec.oic_status := 'N';
         l_price_check_rec.oic_error_message := NULL;
         l_price_check_rec.interface_identifier := 'IMPBS';
         l_price_check_rec.created_by := '-1';
         l_price_check_rec.creation_date := SYSDATE;
         l_price_check_rec.last_update_date := SYSDATE;
         l_price_check_rec.last_updated_by := '-1';
         l_price_check_rec.last_update_login := NULL;
         populate_staging(l_price_check_rec);
      WHEN OTHERS THEN
         l_error_msg := 'when others error: ' || SQLERRM || '...' || DBMS_UTILITY.format_error_backtrace();
         print_debug(l_error_msg);
         x_return_status := 'E';
         x_return_message := l_error_msg;
         l_price_check_rec.transaction_id := l_transaction_id;
         l_price_check_rec.item := l_lines_rec.part_number;
         l_price_check_rec.customer := l_header_rec.account_number;
         l_price_check_rec.pricing_date := SYSDATE;
         l_price_check_rec.ib_order_number := l_header_rec.ib_order_number;
         l_price_check_rec.price_list_name := NULL;
         l_price_check_rec.list_price := NULL;
         l_price_check_rec.selling_price := NULL;
         l_price_check_rec.ERROR_CODE := x_return_status;
         l_price_check_rec.error_message := x_return_message;
         l_price_check_rec.oic_status := 'N';
         l_price_check_rec.oic_error_message := NULL;
         l_price_check_rec.interface_identifier := 'IMPBS';
         l_price_check_rec.created_by := '-1';
         l_price_check_rec.creation_date := SYSDATE;
         l_price_check_rec.last_update_date := SYSDATE;
         l_price_check_rec.last_updated_by := '-1';
         l_price_check_rec.last_update_login := NULL;
         populate_staging(l_price_check_rec);
   END price_check;

   PROCEDURE update_quote(
      p_quote_header_id     IN              NUMBER
     ,p_organization_id     IN              NUMBER
     ,p_inventory_item_id   IN              NUMBER
     ,p_quantity            IN              NUMBER
     ,x_qte_lines_tbl       OUT             aso_quote_pub.qte_line_tbl_type
     ,x_return_status       OUT NOCOPY      VARCHAR2
     ,x_return_message      OUT NOCOPY      VARCHAR2)
   AS
      l_control_rec              aso_quote_pub.control_rec_type;
      l_qte_header_rec           aso_quote_pub.qte_header_rec_type;
      l_qte_line_tbl             aso_quote_pub.qte_line_tbl_type;
      l_qte_line_rec             aso_quote_pub.qte_line_rec_type;
      l_qte_line_dtl_tbl         aso_quote_pub.qte_line_dtl_tbl_type;
      l_hd_price_attr_tbl        aso_quote_pub.price_attributes_tbl_type;
      l_hd_payment_tbl           aso_quote_pub.payment_tbl_type;
      l_hd_shipment_tbl          aso_quote_pub.shipment_tbl_type;
      l_hd_freight_charge_tbl    aso_quote_pub.freight_charge_tbl_type;
      l_hd_tax_detail_tbl        aso_quote_pub.tax_detail_tbl_type;
      l_line_attr_ext_tbl        aso_quote_pub.line_attribs_ext_tbl_type;
      l_line_rltship_tbl         aso_quote_pub.line_rltship_tbl_type;
      l_price_adjustment_tbl     aso_quote_pub.price_adj_tbl_type;
      l_price_adj_attr_tbl       aso_quote_pub.price_adj_attr_tbl_type;
      l_price_adj_rltship_tbl    aso_quote_pub.price_adj_rltship_tbl_type;
      l_ln_price_attr_tbl        aso_quote_pub.price_attributes_tbl_type;
      l_ln_payment_tbl           aso_quote_pub.payment_tbl_type;
      l_ln_shipment_tbl          aso_quote_pub.shipment_tbl_type;
      l_ln_freight_charge_tbl    aso_quote_pub.freight_charge_tbl_type;
      l_ln_tax_detail_tbl        aso_quote_pub.tax_detail_tbl_type;
      l_hd_sales_credit_tbl      aso_quote_pub.sales_credit_tbl_type      := aso_quote_pub.g_miss_sales_credit_tbl;
      l_ln_sales_credit_tbl      aso_quote_pub.sales_credit_tbl_type      := aso_quote_pub.g_miss_sales_credit_tbl;
      lx_qte_header_rec          aso_quote_pub.qte_header_rec_type;
      lx_qte_line_tbl            aso_quote_pub.qte_line_tbl_type;
      lx_qte_line_dtl_tbl        aso_quote_pub.qte_line_dtl_tbl_type;
      lx_hd_price_attr_tbl       aso_quote_pub.price_attributes_tbl_type;
      lx_hd_payment_tbl          aso_quote_pub.payment_tbl_type;
      lx_hd_shipment_tbl         aso_quote_pub.shipment_tbl_type;
      lx_hd_freight_charge_tbl   aso_quote_pub.freight_charge_tbl_type;
      lx_hd_tax_detail_tbl       aso_quote_pub.tax_detail_tbl_type;
      lx_hd_attr_ext_tbl         aso_quote_pub.line_attribs_ext_tbl_type;
      lx_line_attr_ext_tbl       aso_quote_pub.line_attribs_ext_tbl_type;
      lx_line_rltship_tbl        aso_quote_pub.line_rltship_tbl_type;
      lx_price_adjustment_tbl    aso_quote_pub.price_adj_tbl_type;
      lx_price_adj_attr_tbl      aso_quote_pub.price_adj_attr_tbl_type;
      lx_price_adj_rltship_tbl   aso_quote_pub.price_adj_rltship_tbl_type;
      lx_hd_sales_credit_tbl     aso_quote_pub.sales_credit_tbl_type;
      lx_quote_party_tbl         aso_quote_pub.quote_party_tbl_type;
      lx_ln_sales_credit_tbl     aso_quote_pub.sales_credit_tbl_type;
      lx_ln_quote_party_tbl      aso_quote_pub.quote_party_tbl_type;
      lx_ln_price_attr_tbl       aso_quote_pub.price_attributes_tbl_type;
      lx_ln_payment_tbl          aso_quote_pub.payment_tbl_type;
      lx_ln_shipment_tbl         aso_quote_pub.shipment_tbl_type;
      lx_ln_freight_charge_tbl   aso_quote_pub.freight_charge_tbl_type;
      lx_ln_tax_detail_tbl       aso_quote_pub.tax_detail_tbl_type;
      lx_return_status           VARCHAR2(1);
      lx_msg_count               NUMBER;
      lx_msg_data                VARCHAR2(2000);
      l_payment_rec              aso_quote_pub.payment_rec_type;
      l_shipment_rec             aso_quote_pub.shipment_rec_type;
      l_tax_detail_rec           aso_quote_pub.tax_detail_rec_type;
      quote                      NUMBER;
      qte_lin                    NUMBER;
      my_message                 VARCHAR2(2000);
      l_file                     VARCHAR2(2000);

      CURSOR c_quote(
         c_qte_header_id   NUMBER)
      IS
         SELECT last_update_date
           FROM aso_quote_headers_all
          WHERE quote_header_id = c_qte_header_id;

      lc_last_update_date        DATE;
   BEGIN
      /*fnd_global.apps_initialize(0
                                ,21623
                                ,660);
      mo_global.init('ASO');
      mo_global.set_policy_context('S', 81);
      aso_debug_pub.setdebuglevel(10);
      aso_debug_pub.initialize;
      l_file := aso_debug_pub.set_debug_mode('FILE');
      aso_debug_pub.debug_on;
      aso_debug_pub.ADD('Update Quote'
                       ,1
                       ,'Y');
      DBMS_OUTPUT.put_line('File :' || l_file);*/
      l_qte_header_rec.quote_header_id := p_quote_header_id;

      OPEN c_quote(l_qte_header_rec.quote_header_id);

      FETCH c_quote
       INTO lc_last_update_date;

      CLOSE c_quote;

      l_qte_line_tbl(1).operation_code := 'CREATE';
      l_qte_line_tbl(1).organization_id := p_organization_id;
      l_qte_line_tbl(1).inventory_item_id := p_inventory_item_id;
      l_qte_line_tbl(1).quantity := p_quantity;
      l_qte_line_tbl(1).quote_header_id := p_quote_header_id;
      l_qte_line_tbl(1).recalculate_flag := 'Y';
      l_control_rec.price_mode := 'QUOTE_LINE';
      l_qte_header_rec.last_update_date := lc_last_update_date;
      l_control_rec.last_update_date := lc_last_update_date;
      l_control_rec.pricing_request_type := 'ASO';
      l_control_rec.header_pricing_event := 'BATCH';
      aso_quote_pub.update_quote(p_api_version_number           => 1.0
                                ,p_init_msg_list                => fnd_api.g_true
                                ,p_commit                       => fnd_api.g_true
                                ,p_control_rec                  => l_control_rec
                                ,p_qte_header_rec               => l_qte_header_rec
                                ,p_qte_line_tbl                 => l_qte_line_tbl
                                ,p_qte_line_dtl_tbl             => l_qte_line_dtl_tbl
                                ,p_hd_tax_detail_tbl            => l_hd_tax_detail_tbl
                                ,p_ln_payment_tbl               => l_ln_payment_tbl
                                ,p_hd_sales_credit_tbl          => l_hd_sales_credit_tbl
                                ,p_ln_sales_credit_tbl          => l_ln_sales_credit_tbl
                                ,p_ln_shipment_tbl              => l_ln_shipment_tbl
                                ,x_qte_header_rec               => lx_qte_header_rec
                                ,x_qte_line_tbl                 => lx_qte_line_tbl
                                ,x_qte_line_dtl_tbl             => lx_qte_line_dtl_tbl
                                ,x_hd_price_attributes_tbl      => lx_hd_price_attr_tbl
                                ,x_hd_payment_tbl               => lx_hd_payment_tbl
                                ,x_hd_shipment_tbl              => lx_hd_shipment_tbl
                                ,x_hd_freight_charge_tbl        => lx_hd_freight_charge_tbl
                                ,x_hd_tax_detail_tbl            => lx_hd_tax_detail_tbl
                                ,x_hd_attr_ext_tbl              => lx_hd_attr_ext_tbl
                                ,x_hd_sales_credit_tbl          => lx_hd_sales_credit_tbl
                                ,x_hd_quote_party_tbl           => lx_quote_party_tbl
                                ,x_line_attr_ext_tbl            => lx_line_attr_ext_tbl
                                ,x_line_rltship_tbl             => lx_line_rltship_tbl
                                ,x_price_adjustment_tbl         => lx_price_adjustment_tbl
                                ,x_price_adj_attr_tbl           => lx_price_adj_attr_tbl
                                ,x_price_adj_rltship_tbl        => lx_price_adj_rltship_tbl
                                ,x_ln_price_attributes_tbl      => lx_ln_price_attr_tbl
                                ,x_ln_payment_tbl               => lx_ln_payment_tbl
                                ,x_ln_shipment_tbl              => lx_ln_shipment_tbl
                                ,x_ln_freight_charge_tbl        => lx_ln_freight_charge_tbl
                                ,x_ln_tax_detail_tbl            => lx_ln_tax_detail_tbl
                                ,x_ln_sales_credit_tbl          => lx_ln_sales_credit_tbl
                                ,x_ln_quote_party_tbl           => lx_ln_quote_party_tbl
                                ,x_return_status                => lx_return_status
                                ,x_msg_count                    => lx_msg_count
                                ,x_msg_data                     => lx_msg_data);
      fnd_msg_pub.count_and_get(p_encoded      => 'F'
                               ,p_count        => lx_msg_count
                               ,p_data         => lx_msg_data);
      DBMS_OUTPUT.put_line('no. of FND messages :' || lx_msg_count);

      FOR k IN 1 .. lx_msg_count LOOP
         lx_msg_data := fnd_msg_pub.get(p_msg_index      => k, p_encoded => 'F');
         DBMS_OUTPUT.put_line('Error msg: ' || SUBSTR(lx_msg_data
                                                     ,1
                                                     ,240));
      END LOOP;

      DBMS_OUTPUT.put_line('aso_quote_pub.update_quote lx_return_status: ' || lx_return_status);
      DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).quote_line_id after update - ' || lx_qte_line_tbl(1).quote_line_id);
      DBMS_OUTPUT.put_line('p_quote_header_id after update  - ' || p_quote_header_id);

      IF lx_return_status = 'S' THEN
         BEGIN
            SELECT line_list_price
                  ,line_adjusted_amount
                  ,line_adjusted_percent
                  ,line_quote_price
                  ,priced_price_list_id
                  ,line_category_code
              INTO lx_qte_line_tbl(1).line_list_price
                  ,lx_qte_line_tbl(1).line_adjusted_amount
                  ,lx_qte_line_tbl(1).line_adjusted_percent
                  ,lx_qte_line_tbl(1).line_quote_price
                  ,lx_qte_line_tbl(1).priced_price_list_id
                  ,lx_qte_line_tbl(1).line_category_code
              FROM aso_quote_lines_all
             WHERE 1 = 1
               AND quote_line_id = lx_qte_line_tbl(1).quote_line_id
               AND quote_header_id = p_quote_header_id
--AND QUOTE_NUMBER ='17076'
            ;

            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).line_list_price after update  - ' || lx_qte_line_tbl(1).line_list_price);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).line_adjusted_amount after update  - ' || lx_qte_line_tbl(1).line_adjusted_amount);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).line_adjusted_percent after update  - ' || lx_qte_line_tbl(1).line_adjusted_percent);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).line_quote_price after update  - ' || lx_qte_line_tbl(1).line_quote_price);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).priced_price_list_id after update  - ' || lx_qte_line_tbl(1).priced_price_list_id);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).line_category_code after update  - ' || lx_qte_line_tbl(1).line_category_code);
            DBMS_OUTPUT.put_line('lx_qte_line_tbl(1).quote_line_id after update  - ' || lx_qte_line_tbl(1).quote_line_id);
            DBMS_OUTPUT.put_line('p_quote_header_id after update  - ' || p_quote_header_id);
         EXCEPTION
            WHEN OTHERS THEN
               print_debug('update quote ..fetching list price ..when others message:' || SQLERRM);
         END;
      END IF;

      x_qte_lines_tbl := lx_qte_line_tbl;
      x_return_status := lx_return_status;
      x_return_message := lx_msg_data;
      DBMS_OUTPUT.put_line(lx_return_status);
      DBMS_OUTPUT.put_line(TO_CHAR(lx_msg_count));
      DBMS_OUTPUT.put_line(lx_msg_data);
      DBMS_OUTPUT.put_line('qte_header_id: ' || TO_CHAR(lx_qte_header_rec.quote_header_id));
      DBMS_OUTPUT.put_line('qte_line_id: ' || TO_CHAR(lx_qte_line_tbl(1).quote_line_id));
      DBMS_OUTPUT.put_line('end');
   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         DBMS_OUTPUT.put_line('Error Line number=>' || DBMS_UTILITY.format_error_backtrace());
         x_return_message := 'update_quote_status : update quote order.. when others..' || SQLERRM;
   END update_quote;
--++++++++++++++++++++++++++++
END djooic_aso_qp_price_request_pkg;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_ASO_QP_PRICE_REQUEST_PKG" TO "XXOIC";

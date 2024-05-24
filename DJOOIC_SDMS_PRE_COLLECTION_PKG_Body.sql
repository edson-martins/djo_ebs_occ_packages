--------------------------------------------------------
--  DDL for Package Body DJOOIC_SDMS_PRE_COLLECTION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_SDMS_PRE_COLLECTION_PKG" 
AS
    /**************************************************************************
    *
    * PROCEDURE
    * validate_precollection_data
    *
    * DESCRIPTION
    * Main procedure which is used to validate the precollection data and set the collection status
    *
    * When a new record is entered in the custom table from SOA, it is created with a collection status of NEW.
    * 1) If the record passes all the validations, the collection status = UNLOADED.
    * 2) If the record fails atleast one validation, the collection status = ERROR.
    *
    * An warning counter variable is defined which tracks all the warnings. Its initial value is always 0 and is incremented by 1
    * whenever an warning occurs.
    *
    * An error counter variable is defined which tracks all the errors. Its initial value is always 0 and is incremented by 1
    * whenever an error occurs.
    *
    * If the error counter is 0 and warning counter is 0, set collection status as UNLOADED. Else, set collection status appropriately
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * o_errbuf OUT Error Buffer
    * o_retcode OUT Ret Code
    * p_start_period_name IN Start Period Name
    * p_end_period_name IN End Period Name
    *
    *
    * RETURN VALUE
    * NA
    * PREREQUISITES
    *
    * CALLED BY
    * Main procedure used in the concurrent program
    *
    **************************************************************************/

    /*Procedure which does the main validations*/
    PROCEDURE validate_precollection_data (
        o_errbuf                 OUT VARCHAR2,
        o_retcode                OUT VARCHAR2,
        p_start_period_name   IN     VARCHAR2,
        p_end_period_name     IN     VARCHAR2)
    AS
        /*Variable Declaration*/
        l_error_counter                NUMBER;
        l_warning_counter              NUMBER;
        l_error_message                VARCHAR2 (10000);
        l_item_exists                  VARCHAR2 (5);
        l_dist_customer_exists         hz_parties.orig_system_reference%TYPE;
        l_dist_customer_number         hz_cust_accounts.account_number%TYPE;
        l_dist_customer_name           hz_cust_accounts.account_name%TYPE;
        l_primary_salesrep_id          jtf_rs_salesreps.salesrep_id%TYPE;
        l_secondary_salesrep_id        jtf_rs_salesreps.salesrep_id%TYPE;
        l_salesrep_number              VARCHAR2 (20);
        l_collection_status            VARCHAR2 (30);
        l_inventory_item_id            NUMBER;
        l_last_update_date             DATE := SYSDATE;
        l_last_updated_by              NUMBER := fnd_global.login_id;
        l_creation_date                DATE := SYSDATE;
        l_created_by                   NUMBER := fnd_global.user_id;
        l_item_group                   mtl_categories_b.segment1%TYPE;
        l_item_class                   mtl_categories_b.segment2%TYPE;
        l_item_family                  mtl_categories_b.segment3%TYPE;
        l_item_model                   mtl_categories_b.segment4%TYPE;
        l_product_brand                mtl_categories_b.segment2%TYPE;
        l_product_group                mtl_categories_b.segment3%TYPE;
        l_product_brand_name           mtl_categories_b.segment4%TYPE; --Added by Anantha on 03-23-2012 for Incident # 199262
        l_business_unit                mtl_categories_b.segment1%TYPE;
        l_anatomy                      mtl_categories_b.segment1%TYPE;
        l_revenue_type                 VARCHAR2 (30);
        l_reporting_center             VARCHAR2 (30);
        l_order_type                   VARCHAR2 (30);
        l_organization_id              NUMBER;
        l_non_revenue_brand            VARCHAR2 (60);
        l_officecare_flag              VARCHAR2 (1) := NULL;
        l_product_return_message       VARCHAR2 (60);
        l_brand_return_message         VARCHAR2 (60);
        l_anatomy_return_message       VARCHAR2 (60);
        l_customer_return_message      VARCHAR2 (60);
        l_count                        NUMBER;
        l_count_unloaded               NUMBER;
        l_count_warning                NUMBER;
        l_count_error                  NUMBER;
        l_cust_name                    VARCHAR2 (500);
        l_cust_address                 VARCHAR2 (1000);
        l_cust_city                    VARCHAR2 (60);
        l_cust_zip                     VARCHAR2 (60);
        l_cust_state                   VARCHAR2 (60);
        l_trx_type                     VARCHAR2 (10);
        l_sec_salesrep_number          jtf_rs_salesreps.salesrep_number%TYPE;
        l_primary_salesrep_number      jtf_rs_salesreps.salesrep_number%TYPE;
        l_order_type_exits             VARCHAR2 (1) := 'N';
        --V3.0 Saranya Nerella
        --Added for VASCULAR brand group on 12-14-11 by Rohan
        l_vascular_call                VARCHAR2 (1) := 'N';
        l_nonrev_chk                   NUMBER; --added by Anantha Reddy on 03-26-2012 for incident # 199262
        l_rev_chk                      NUMBER; --added by Anantha Reddy on 03-26-2012 for incident # 199262
        l_dist_customer_category       VARCHAR2 (80);              -- SR#41161
        l_alt_dist_customer_category   VARCHAR2 (80);
        l_gpo_name                     VARCHAR2 (60); -- Added by Saranya on 7/28/2016

        /*Main cursor which is used to process the SDMS Sales Data*/
        CURSOR cur_sdms_sales
        IS
              SELECT ebs_trc_trx_id               --populated from the trigger
                                   --,sdms_file_number
                                   ,
                     trx_type                               --,sdms_trx_number
                                                                --,sdms_trx_id
                                                               --,company_code
                     ,
                     processed_date                            --,invoice_date
                                   ,
                     sdms_dist_num,
                     item_number,
                     salesrep_number                            --,salesrep_id
                                    ,
                     order_type                         --V3.0 Saranya Nerella
                               ,
                     secondary_rep_num,
                     quantity,
                     actual_sales_amt,
                     extended_cost_amt,
                     profit_margin_amt,
                     extended_price_amt,
                     gpo_name                 -- Added by Saranya on 7/28/2016
                --,end_customer_num
                FROM djooic_sdms_sales
               WHERE     collection_status IN ('NEW', 'ERROR')
                     AND processed_date BETWEEN (SELECT start_date
                                                   FROM cn_periods
                                                  WHERE period_name =
                                                        p_start_period_name)
                                            AND (SELECT end_date
                                                   FROM cn_periods
                                                  WHERE period_name =
                                                        p_end_period_name)
            ORDER BY ebs_trc_trx_id;

        --FOR UPDATE;

        /*Cursor which is used to display in the log file*/
        CURSOR cur_display_log_info
        IS
              SELECT ebs_trc_trx_id, collection_status, error_message
                FROM djooic_sdms_sales
               WHERE     collection_status IN ('WARNING', 'ERROR')
                     AND processed_date BETWEEN (SELECT start_date
                                                   FROM cn_periods
                                                  WHERE period_name =
                                                        p_start_period_name)
                                            AND (SELECT end_date
                                                   FROM cn_periods
                                                  WHERE period_name =
                                                        p_end_period_name)
            ORDER BY ebs_trc_trx_id;                      --collection_status;
    BEGIN                                                    --Procedure Begin
        mo_global.set_policy_context ('S', fnd_global.org_id);

        BEGIN
            SELECT organization_id
              INTO l_organization_id
              FROM mtl_parameters
             WHERE organization_code = 'MST';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_organization_id := NULL;
            WHEN OTHERS
            THEN
                l_organization_id := NULL;
        END;

        fnd_file.put_line (fnd_file.LOG,
                           'Organization Id:' || l_organization_id);
        l_count := 0;

        FOR rec_sdms_sales IN cur_sdms_sales
        LOOP
            l_count := l_count + 1;
            l_error_counter := 0;
            l_warning_counter := 0;
            l_error_message := NULL;
            l_collection_status := NULL;
            l_primary_salesrep_number := NULL;
            l_item_exists := NULL;
            l_inventory_item_id := NULL;
            l_dist_customer_exists := NULL;
            l_dist_customer_number := NULL;
            l_dist_customer_name := NULL;
            l_primary_salesrep_id := NULL;
            l_secondary_salesrep_id := NULL;
            l_sec_salesrep_number := NULL;
            l_product_return_message := NULL;
            l_item_group := NULL;
            l_item_class := NULL;
            l_item_family := NULL;
            l_item_model := NULL;
            l_business_unit := NULL;
            l_product_brand := NULL;
            l_product_group := NULL;
            l_anatomy := NULL;
            l_product_return_message := NULL;
            l_brand_return_message := NULL;
            l_anatomy_return_message := NULL;
            l_customer_return_message := NULL;
            l_cust_name := NULL;
            l_cust_address := NULL;
            l_cust_city := NULL;
            l_cust_zip := NULL;
            l_cust_state := NULL;
            l_revenue_type := NULL;
            l_reporting_center := NULL;
            l_non_revenue_brand := NULL;
            l_gpo_name := rec_sdms_sales.gpo_name; --Added by Saranya on 7/28/2016

            --fnd_file.put_line(fnd_file.log,'Inside the loop');
            --fnd_file.put_line(fnd_file.log,'ebs_trc_trx_id:'||rec_sdms_sales.ebs_trc_trx_id);
            --Begin of validations
            /*Validate whether the item has been defined or not */
            BEGIN
                SELECT 'Y', inventory_item_id
                  INTO l_item_exists, l_inventory_item_id
                  FROM mtl_system_items_b
                 WHERE     segment1 = rec_sdms_sales.item_number
                       --<Material_Dim_Id> from SDMS
                       AND organization_id = l_organization_id; --<organization_id>
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_warning_counter := l_warning_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Item '
                        || rec_sdms_sales.item_number
                        || ' not defined.';
                WHEN OTHERS
                THEN
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Others - Validation of Item '
                        || SQLERRM;
            END;

            --fnd_file.put_line(fnd_file.log,'l_inventory_item_id-l_item_exists'||l_inventory_item_id||'-'||l_item_exists);

            /*Validate whether the Distribution Customer Number exists or not */
            BEGIN
                SELECT 'Y', hca.account_number, hp.party_name
                  INTO l_dist_customer_exists,
                       l_dist_customer_number,
                       l_dist_customer_name
                  FROM hz_parties hp, hz_cust_accounts hca
                 WHERE     hp.party_id = hca.party_id
                       AND hca.orig_system_reference =
                           rec_sdms_sales.sdms_dist_num;
            --Customer_Dim_Id from SDMS
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    BEGIN
                        SELECT 'Y', hca.account_number, hp.party_name
                          INTO l_dist_customer_exists,
                               l_dist_customer_number,
                               l_dist_customer_name
                          FROM hz_parties hp, hz_cust_accounts hca
                         WHERE     hp.party_id = hca.party_id
                               AND hca.account_number =
                                   rec_sdms_sales.sdms_dist_num; --Added by Saranya on 2/8/2018
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            l_warning_counter := l_warning_counter + 1;
                            l_error_message :=
                                   l_error_message
                                || ' Distribution Customer Number '
                                || rec_sdms_sales.sdms_dist_num
                                || ' not defined.';
                    END;
                WHEN OTHERS
                THEN
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Others - Validation of Distribution Customer Number '
                        || rec_sdms_sales.sdms_dist_num
                        || SQLERRM;
            END;

            --fnd_file.put_line(fnd_file.log,'l_dist_customer_exists-l_dist_customer_number'||l_dist_customer_exists||'-'||l_dist_customer_number);

            /*Validate whether the Primary Sales rep is defined or not */
            BEGIN
                SELECT salesrep_id, salesrep_number
                  INTO l_primary_salesrep_id, l_primary_salesrep_number
                  FROM jtf_rs_salesreps
                 WHERE     salesrep_number = rec_sdms_sales.salesrep_number
                       --Employee_Owner_Com1_Dim_Id from SDMS
                       AND status = 'A'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                       AND NVL (end_date_active, SYSDATE);
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_warning_counter := l_warning_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Primary Sales rep number '
                        || rec_sdms_sales.salesrep_number
                        || ' not defined.';
                WHEN OTHERS
                THEN
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Others - Validation of Primary Sales Rep Number '
                        || SQLERRM;
            END;

            --fnd_file.put_line(fnd_file.log,'l_primary_salesrep_id'||l_primary_salesrep_id);
            --fnd_file.put_line(fnd_file.log,l_error_message);

            /*Validate whether the Secondary Sales rep is defined or not */
            BEGIN
                SELECT salesrep_id, salesrep_number
                  INTO l_secondary_salesrep_id, l_sec_salesrep_number
                  FROM jtf_rs_salesreps
                 WHERE     salesrep_number = rec_sdms_sales.secondary_rep_num
                       --Employee_Owner_Alt_Com1_Dim_Id from SDMS
                       AND status = 'A'
                       AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                       AND NVL (end_date_active, SYSDATE);
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    l_warning_counter := l_warning_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Secondary Sales rep number '
                        || rec_sdms_sales.secondary_rep_num
                        || ' not defined.';
                WHEN OTHERS
                THEN
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                           l_error_message
                        || ' Others - Validation of Secondary Sales Rep Number '
                        || SQLERRM;
            END;

            --fnd_file.put_line(fnd_file.log,'l_secondary_salesrep_id'||l_secondary_salesrep_id);
            --fnd_file.put_line(fnd_file.log,l_error_message);

            /* Change by K Ayalavarapu on 12/16/10 based on discussion with Dik Ahuja and Kris K, for invalid/not found sales rep handling*/
            IF (l_primary_salesrep_number IS NULL)
            THEN
                l_primary_salesrep_number := rec_sdms_sales.salesrep_number;
            END IF;

            IF (l_sec_salesrep_number IS NULL)
            THEN
                l_sec_salesrep_number := rec_sdms_sales.secondary_rep_num;
            END IF;

            -- Handle error Pranav's email 11-Feb-2018--Basu--starts
            IF l_primary_salesrep_number IS NULL
            THEN
                --
                l_error_counter := l_error_counter + 1;
                l_error_message :=
                    l_error_message || ' Primary salesrep is NULL.';
            --
            END IF; -- IF l_primary_salesrep_number IS NULL OR l_sec_salesrep_number IS NULL

            -- Handle error Pranav's email 11-Feb-2018--Basu--ends
            /* Change by K Ayalavarapu on 12/16/10 based on discussion with Dik Ahuja, for invalid/not found sales rep handling ends here*/
            --fnd_file.put_line(fnd_file.log,l_salesrep_number);
            IF (l_item_exists = 'Y')
            THEN
                /*Get the Item Group, Item Class, Item Family and Item Model details*/
                get_item_details (
                    p_inventory_item_id   => l_inventory_item_id,
                    p_organization_id     => l_organization_id,
                    x_item_group          => l_item_group,
                    x_item_class          => l_item_class,
                    x_item_family         => l_item_family,
                    x_item_model          => l_item_model,
                    x_return_message      => l_product_return_message);

                /* Incase Material_Dim_Id is a valid Item Number in eBS and any Product Category segment is missing,
                then update collection_status as ERROR; Error_message column with the appropriate exception
                This check is done here so that the error counter can be tracked at the same place. */
                IF (l_product_return_message IS NULL)
                THEN
                    IF (l_item_group IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Item Group for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;

                    IF (l_item_class IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Item Class for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;

                    IF (l_item_family IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Item Family for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;

                    IF (l_item_model IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Item Model for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;
                ELSE
                    --fnd_file.put_line(fnd_file.log,'l_product_return_message is not null');
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                        l_error_message || l_product_return_message;
                END IF;

                --fnd_file.put_line(fnd_file.log,'After get_item_details call'||l_error_message);

                /* Get the brand information */
                get_djo_brand_categories (
                    p_inventory_item_id    => l_inventory_item_id,
                    p_organization_id      => l_organization_id,
                    x_business_unit        => l_business_unit,
                    x_product_brand        => l_product_brand,
                    x_product_group        => l_product_group,
                    x_product_brand_name   => l_product_brand_name, --Added by Anantha on 03-23-2012 for Incident # 199262
                    x_return_message       => l_brand_return_message);

                IF (l_brand_return_message IS NULL)
                THEN
                    IF (l_business_unit IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Business Unit for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;

                    IF (l_product_brand IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Product Brand for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;

                    IF (l_product_group IS NULL)
                    THEN
                        l_error_counter := l_error_counter + 1;
                        l_error_message :=
                               l_error_message
                            || ' Product Group for the Item Number '
                            || rec_sdms_sales.item_number
                            || ' not available.';
                    END IF;
                ELSE
                    --fnd_file.put_line(fnd_file.log,'l_brand_return_message is not null for ebs_trc_trx_id'||rec_sdms_sales.ebs_trc_trx_id||'-'||l_brand_return_message);
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                        l_error_message || l_brand_return_message;
                END IF;

                --fnd_file.put_line(fnd_file.log,'After get_djo_brand_categories call.Error message is:'||l_error_message);

                /* Get the anatomy information */
                get_djo_anatomy (
                    p_inventory_item_id   => l_inventory_item_id,
                    p_organization_id     => l_organization_id,
                    x_anatomy             => l_anatomy,
                    x_return_message      => l_anatomy_return_message);

                IF (l_anatomy_return_message IS NOT NULL)
                THEN
                    l_error_counter := l_error_counter + 1;
                    l_error_message :=
                        l_error_message || l_anatomy_return_message;
                --fnd_file.put_line(fnd_file.log,'l_anatomy_return_message is not null for ebs_trc_trx_id'||rec_sdms_sales.ebs_trc_trx_id||'-'||l_anatomy_return_message);
                END IF;
            --fnd_file.put_line(fnd_file.log,'After get_djo_anatomy call.Error message is:'||l_error_message);
            END IF;

            /*IF(l_dist_customer_exists = 'Y') THEN
            Gets the End Customer Information such as End Customer Name and End Customer Address
            get_DJO_Customer( --p_cust_acc_number => rec_sdms_sales.end_customer_num (Commented by Siva on Apr 20th 2010 and added the below condition)
            p_cust_acc_number => l_dist_customer_number
            ,x_cust_name => l_cust_name
            ,x_cust_address => l_cust_address
            ,x_cust_city => l_cust_city
            ,x_cust_zip => l_cust_zip
            ,x_cust_state => l_cust_state
            ,x_return_message => l_customer_return_message);
            END IF;
            */
            /*Setting the collection status based on the warning counter and error counter*/
            IF (l_warning_counter <> 0 AND l_error_counter <> 0)
            THEN
                l_collection_status := 'ERROR';
            ELSIF (l_warning_counter <> 0 AND l_error_counter = 0)
            THEN
                l_collection_status := 'WARNING';
            ELSIF (l_warning_counter = 0 AND l_error_counter <> 0)
            THEN
                l_collection_status := 'ERROR';
            ELSIF (l_warning_counter = 0 AND l_error_counter = 0)
            THEN
                l_collection_status := 'UNLOADED';
            END IF;

            --fnd_file.put_line(fnd_file.log,'Collection Status :'||l_collection_status);
            --fnd_file.put_line(fnd_file.log,'Error message is:'||l_error_message);

            /*
            If the error counter and Warning counter is 0, set collection status as UNLOADED.Else, set collection status appropriately
            */
            IF (l_error_counter = 0)
            THEN
                /*
                Set the revenue type for Primary Sales Rep
                For Primary Sales Rep, Revenue type = 'REVENUE'
                */
                IF (l_primary_salesrep_number IS NOT NULL)
                THEN
                    l_revenue_type := 'REVENUE';
                END IF;

                l_trx_type := 'TRC';
                l_order_type := 'VST DISTRIBUTION';
                /* This Procedure is used to get the Reporting center for Distribution */
                get_reporting_center (
                    p_product_brand      => l_product_brand,
                    x_reporting_center   => l_reporting_center);

                get_dist_customer_category (
                    p_customer_number          => l_dist_customer_number,
                    p_salesrep_id              => l_primary_salesrep_id,
                    x_dist_customer_category   => l_dist_customer_category);


                /* Update the table with the derived data */
                UPDATE djooic_sdms_sales                   --djooic_sdms_sales
                   SET end_customer_num = customer_number,    --For TRC change
                       customer_number = l_dist_customer_number,
                       end_customer_name =
                           DECODE (trx_type,
                                   'TRC', end_customer_name,
                                   l_cust_name),              --For TRC change
                       customer_name = l_dist_customer_name,
                       customer_category = l_dist_customer_category,
                       trx_type = l_trx_type,
                       -- end_customer_num = l_dist_customer_number,  For TRC change
                       street_address =
                           DECODE (trx_type,
                                   'TRC', street_address,
                                   l_cust_address),           --For TRC change
                       city = DECODE (trx_type, 'TRC', city, l_cust_city), --For TRC change
                       state = DECODE (trx_type, 'TRC', state, l_cust_state), --For TRC change
                       zip = DECODE (trx_type, 'TRC', zip, l_cust_zip), --For TRC change
                       business_segment = l_business_unit,
                       item_group = l_item_group,
                       item_class = l_item_class,
                       order_type = l_order_type,
                       brand = l_product_brand,
                       item_family = l_item_family,
                       product_brand = l_product_brand,
                       salesrep_number = l_primary_salesrep_number,
                       anatomy = l_anatomy,
                       reporting_center = l_reporting_center,
                       revenue_type = l_revenue_type,
                       attribute1 = NULL,
                       attribute2 = NULL,
                       product_group = l_product_group,
                       item_model = l_item_model,
                       collection_status = l_collection_status,
                       error_message = l_error_message,
                       last_update_date = l_last_update_date,
                       last_updated_by = l_last_updated_by
                 WHERE ebs_trc_trx_id = rec_sdms_sales.ebs_trc_trx_id;

                /*Calling the procedure which inserts data for secondary sales rep number*/
                /* Change by K Ayalavarapu on 12/16/10 based on discussion with Dik Ahuja and Kris K, to ignore secondary rep=0*/
                /*Changed By Rohan Manik 2/8/2012 based on discussion with Dik Ahuja, to includ secondary rep as varchar*/
                --In the below IF condition l_primary_salesrep_number <> '0' is added by Saranya N on 6th March, 2012 taking Dik's advice (SR#34760)
                IF (    l_primary_salesrep_number <> '0'
                    AND l_sec_salesrep_number <> '0'
                    AND (l_primary_salesrep_number <> l_sec_salesrep_number))
                THEN
                    /* Change by K Ayalavarapu on 12/16/10 based on discussion with Dik Ahuja and Kris K, to ignore secondary rep=0 ends here*/

                    ---
                    BEGIN --added product brand group by Anantha Reddy on 03-26-2012 for incident # 199262
                        SELECT 1
                          INTO l_nonrev_chk
                          FROM jtf_rs_groups_vl         jg,
                               jtf_rs_group_members_vl  jm,
                               jtf_rs_defresroles_vl    jr,
                               Fnd_Lookup_Values_Vl     Flv,
                               jtf_rs_salesreps         jrs
                         WHERE     jg.GROUP_ID = jm.GROUP_ID
                               AND NVL (jm.delete_flag, 'N') = 'N'
                               AND jm.group_member_id = jr.role_Resource_id
                               AND NVL (jr.delete_flag, 'N') = 'N'
                               AND NVL (res_rl_end_date, SYSDATE) > = SYSDATE
                               AND flv.lookup_type =
                                   'DJO_NON_REVENUE_SALES_REP_EXCL'
                               AND flv.enabled_flag = 'Y'
                               AND NVL (Flv.End_Date_Active, SYSDATE) >=
                                   SYSDATE
                               AND Jm.Resource_Id = Jrs.Resource_Id
                               AND jrs.salesrep_id = l_secondary_salesrep_id
                               AND Jrs.Org_Id = Fnd_Global.Org_Id
                               AND UPPER (flv.meaning) =
                                   UPPER (jg.group_name);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            l_nonrev_chk := -99;
                    END;

                    BEGIN
                        SELECT 1
                          INTO l_rev_chk
                          FROM jtf_rs_groups_vl         jg,
                               jtf_rs_group_members_vl  jm,
                               jtf_rs_defresroles_vl    jr,
                               Fnd_Lookup_Values_Vl     Flv,
                               jtf_rs_salesreps         jrs
                         WHERE     jg.GROUP_ID = jm.GROUP_ID
                               AND NVL (jm.delete_flag, 'N') = 'N'
                               AND jm.group_member_id = jr.role_Resource_id
                               AND NVL (jr.delete_flag, 'N') = 'N'
                               AND NVL (res_rl_end_date, SYSDATE) > = SYSDATE
                               AND flv.lookup_type =
                                   'DJO_NON_REVENUE_SALES_REP_EXCL'
                               AND flv.enabled_flag = 'Y'
                               AND NVL (flv.end_Date_active, SYSDATE) >=
                                   SYSDATE
                               AND Jm.Resource_Id = Jrs.Resource_Id
                               AND jrs.salesrep_id = l_primary_salesrep_id
                               AND Jrs.Org_Id = Fnd_Global.Org_Id
                               AND UPPER (Flv.Meaning) =
                                   UPPER (Jg.Group_Name);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            l_rev_chk := -101;
                    END;


                    IF l_nonrev_chk = l_rev_chk
                    THEN
                        NULL;
                    ELSE --added product brand group by Anantha Reddy on 03-26-2012 for incident # 199262
                        /*This Procedure is used to get the non revenue brand for the secondary sales rep*/
                        ---
                        get_non_revenue_brand (
                            p_item_group           => l_item_group,
                            p_brand                => l_product_brand,
                            p_item_class           => l_item_class --v2.0 Charles Harding
                                                                  ,
                            p_item_family          => l_item_family --v2.0 Charles Harding
                                                                   ,
                            p_product_group        => l_product_group, --Added by Anantha on 03-23-2012 for Incident # 199262
                            p_product_brand_name   => l_product_brand_name, --Added by Anantha on 03-23-2012 for Incident # 199262
                            x_non_revenue_brand    => l_non_revenue_brand,
                            x_officecare_flag      => l_officecare_flag);

                        /*Below Select added by Saranya Nerella on 9th March, 2011 for V3.0*/
                        --Start
                        BEGIN
                            l_order_type_exits := 'N';

                            IF l_officecare_flag = 'Y'
                            THEN
                                SELECT 'Y'
                                  INTO l_order_type_exits
                                  FROM fnd_lookup_values_vl
                                 WHERE     lookup_type =
                                           'DJO_OIC_OC_ORDER_TYPES'
                                       AND meaning =
                                           rec_sdms_sales.order_type;
                            END IF;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                l_order_type_exits := 'N';
                        END;

                        --End
                        --Evaluate if second call is needed for VENAFLOW system by Rohan
                        BEGIN
                            SELECT 'Y'
                              INTO l_vascular_call
                              FROM fnd_lookup_values_vl
                             WHERE     lookup_type =
                                       'DJOCN_VASCULAR_BRAND_GROUPS'
                                   AND meaning = l_product_group;
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                l_vascular_call := 'N';
                        END;

                        -- ended by Rohan on 1-20-2011
                        /* This Procedure is used to insert duplicate record for the primary sales rep */
                        IF (   l_non_revenue_brand IS NOT NULL
                            OR l_vascular_call = 'Y')
                        THEN
                            IF (    l_officecare_flag = 'Y'
                                AND l_order_type_exits != 'Y')
                            THEN
                                NULL;         --Added by Siva on Apr 15th 2010
                            ELSE
                                get_dist_customer_category (
                                    p_customer_number =>
                                        l_dist_customer_number,
                                    p_salesrep_id =>
                                        l_secondary_salesrep_id,
                                    x_dist_customer_category =>
                                        l_alt_dist_customer_category);

                                insert_secondary_rep (
                                    p_ebs_trc_trx_id =>
                                        rec_sdms_sales.ebs_trc_trx_id --,p_sdms_file_number => rec_sdms_sales.sdms_file_number
                                                                     ,
                                    p_trx_type =>
                                        l_trx_type --,p_sdms_trx_number => rec_sdms_sales.sdms_trx_number
                                                  --,p_sdms_trx_id => rec_sdms_sales.sdms_trx_id
                                                  --,p_company_code => rec_sdms_sales.company_code
                                                  ,
                                    p_processed_date =>
                                        rec_sdms_sales.processed_date --,p_invoice_date => rec_sdms_sales.invoice_date
                                                                     ,
                                    p_sdms_dist_num =>
                                        rec_sdms_sales.sdms_dist_num,
                                    p_customer_number =>
                                        l_dist_customer_number,
                                    p_item_number =>
                                        rec_sdms_sales.item_number --,p_salesrep_id => rec_sdms_sales.salesrep_id
                                                                  ,
                                    p_secondary_rep_num =>
                                        l_sec_salesrep_number,
                                    p_quantity =>
                                        rec_sdms_sales.quantity,
                                    p_actual_sales_amt =>
                                        rec_sdms_sales.actual_sales_amt,
                                    p_extended_cost_amt =>
                                        rec_sdms_sales.extended_cost_amt,
                                    p_profit_margin_amt =>
                                        rec_sdms_sales.profit_margin_amt --Added by Siva on April 20th 2010
                                                                        ,
                                    p_extended_price_amt =>
                                        rec_sdms_sales.extended_price_amt,
                                    p_end_customer_num =>
                                        l_dist_customer_number --rec_sdms_sales.end_customer_num --Modified by Siva on April 20th 2010
                                                              ,
                                    p_end_customer_name =>
                                        l_cust_name,
                                    p_street_address =>
                                        l_cust_address,
                                    p_city =>
                                        l_cust_city,
                                    p_state =>
                                        l_cust_state,
                                    p_zip =>
                                        l_cust_zip,
                                    p_customer_name =>
                                        l_dist_customer_name,
                                    p_customer_category =>
                                        l_alt_dist_customer_category,
                                    p_business_segment =>
                                        l_business_unit,
                                    p_item_group =>
                                        l_item_group,
                                    p_item_class =>
                                        l_item_class,
                                    p_order_type =>
                                        l_order_type,
                                    p_brand =>
                                        l_non_revenue_brand,
                                    p_item_family =>
                                        l_item_family,
                                    p_anatomy =>
                                        l_anatomy,
                                    p_reporting_center =>
                                        l_reporting_center,
                                    p_collection_status =>
                                        l_collection_status,
                                    p_error_message =>
                                        l_error_message,
                                    p_product_brand =>
                                        l_product_brand,
                                    p_product_group =>
                                        l_product_group,
                                    p_item_model =>
                                        l_item_model,
                                    p_creation_date =>
                                        l_creation_date,
                                    p_created_by =>
                                        l_created_by,
                                    p_last_update_date =>
                                        l_last_update_date,
                                    p_last_updated_by =>
                                        l_last_updated_by,
                                    p_gpo_name =>
                                        l_gpo_name --Added by Saranya on 7/28/2016
                                                  );
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSE
                /*In case of WARNING and ERROR, update the collection_status appropriately along with error_message*/
                --fnd_file.put_line(fnd_file.log,'In else - l_error_count: '|| l_error_count ||'and l_warning_counter: '||l_warning_counter.||'Updating collection sttaus to :'||l_collection_status);
                --fnd_file.put_line(fnd_file.log,'In else - l_error_counter: '|| l_error_counter ||' and l_warning_counter: '||l_warning_counter||'.Updating collection sttaus to :'||l_collection_status);
                BEGIN
                    UPDATE djooic_sdms_sales               --djooic_sdms_sales
                       SET customer_number = l_dist_customer_number,
                           customer_name = l_dist_customer_name,
                           customer_category = l_dist_customer_category,
                           trx_type = l_trx_type,
                           end_customer_num = l_dist_customer_number,
                           end_customer_name = DECODE (trx_type,
                                   'TRC', end_customer_name,
                                   l_cust_name),
                           street_address = l_cust_address,
                           city = DECODE (trx_type,'TRC', city, l_cust_city) ,
                           state = DECODE (trx_type,'TRC', state, l_cust_state),
                           zip = DECODE (trx_type,'TRC', zip, l_cust_zip),
                           salesrep_number = l_primary_salesrep_number,
                           business_segment = l_business_unit,
                           item_group = l_item_group,
                           item_class = l_item_class,
                           order_type = l_order_type,
                           brand = l_product_brand,
                           item_family = l_item_family,
                           product_brand = l_product_brand,
                           anatomy = l_anatomy,
                           reporting_center = l_reporting_center,
                           revenue_type = l_revenue_type,
                           attribute1 = NULL,
                           attribute2 = NULL,
                           product_group = l_product_group,
                           item_model = l_item_model,
                           collection_status = l_collection_status,
                           error_message = l_error_message,
                           last_update_date = l_last_update_date,
                           last_updated_by = l_last_updated_by
                     WHERE ebs_trc_trx_id = rec_sdms_sales.ebs_trc_trx_id;
                --commit;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        --fnd_file.put_line(fnd_file.log,'Exception when updating the table when there are warnings or errors'||sqlerrm);
                        l_error_message :=
                               l_error_message
                            || 'Exception when updating the table when there are warnings or errors : '
                            || SQLERRM;

                        UPDATE djooic_sdms_sales           --djooic_sdms_sales
                           SET collection_status = l_collection_status --'ERROR'
                                                                      ,
                               error_message = l_error_message,
                               customer_number = l_dist_customer_number,
                               customer_name = l_dist_customer_name,
                               customer_category = l_dist_customer_category,
                               trx_type = l_trx_type,
                               end_customer_num = l_dist_customer_number,
                               end_customer_name = l_cust_name,
                               street_address = l_cust_address,
                               city = l_cust_city,
                               state = l_cust_state,
                               zip = l_cust_zip,
                               salesrep_number = l_primary_salesrep_number,
                               business_segment = l_business_unit,
                               item_group = l_item_group,
                               item_class = l_item_class,
                               order_type = l_order_type,
                               brand = l_product_brand,
                               item_family = l_item_family,
                               product_brand = l_product_brand,
                               anatomy = l_anatomy,
                               reporting_center = l_reporting_center,
                               revenue_type = l_revenue_type,
                               attribute1 = NULL,
                               attribute2 = NULL,
                               product_group = l_product_group,
                               item_model = l_item_model,
                               last_update_date = l_last_update_date,
                               last_updated_by = l_last_updated_by
                         WHERE ebs_trc_trx_id = rec_sdms_sales.ebs_trc_trx_id;
                END;
            END IF;
        -- check_rep_swap(rec_sdms_sales.ebs_trc_trx_id); --Added by Saranya on 9th Mar, 2011
        END LOOP;

        COMMIT;
        /*To print the total number of records in the log file*/
        fnd_file.put_line (
            fnd_file.LOG,
            'The total number of records processed are ' || l_count);
        /* Procedure to get the count for the records in Unloaded status and print in the log file */
        /*get_count_records( p_collection_status => 'UNLOADED'
        ,p_start_period_name => p_start_period_name
        ,p_end_period_name => p_end_period_name
        ,x_count_record => l_count_unloaded);
        fnd_file.put_line(fnd_file.log,'The Number of Records in Unloaded Status are '||l_count_unloaded);*/

        /* Procedure to get the count for the records in WARNING status and print in the log file */
        get_count_records (p_collection_status   => 'WARNING',
                           p_start_period_name   => p_start_period_name,
                           p_end_period_name     => p_end_period_name,
                           x_count_record        => l_count_warning);
        fnd_file.put_line (
            fnd_file.LOG,
            'The Number of Records in Warning Status are ' || l_count_warning);
        /* Procedure to get the count for the records in ERROR status and print in the log file */
        get_count_records (p_collection_status   => 'ERROR',
                           p_start_period_name   => p_start_period_name,
                           p_end_period_name     => p_end_period_name,
                           x_count_record        => l_count_error);
        fnd_file.put_line (
            fnd_file.LOG,
            'The Number of Records in Error Status are ' || l_count_error);
        fnd_file.put_line (
            fnd_file.LOG,
            '+---------------------------------------------------------------------------+');
        fnd_file.put_line (fnd_file.LOG, 'List of Warning and Error Records');
        fnd_file.put_line (
            fnd_file.LOG,
            '+---------------------------------------------------------------------------+');
        fnd_file.put_line (
            fnd_file.LOG,
               'EBS TRC TRX ID'
            || ' '
            || 'Collection Status'
            || ' '
            || 'Error Message');
        fnd_file.put_line (
            fnd_file.LOG,
            '+---------------------------------------------------------------------------+');

        FOR rec_display_log_info IN cur_display_log_info
        LOOP
            /*Displays the Error Message and the Collection Status for a Transaction ID */
            fnd_file.put_line (
                fnd_file.LOG,
                   rec_display_log_info.ebs_trc_trx_id
                || ' '
                || rec_display_log_info.collection_status
                || ' '
                || rec_display_log_info.error_message);
        END LOOP;

        COMMIT;

		/* Added by SreevidyaaMohan on 19-Jan-2022 for CHG0216543 */
		UPDATE djooic_sdms_sales
            SET collection_status = 'LOADED'
        WHERE collection_status IN ('UNLOADED', 'WARNING')
        AND source_num IS NOT NULL;

        COMMIT;
		/* Added by SreevidyaaMohan on 19-Jan-2022 for CHG0216543 */

    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Exception error in procedure ' || SQLERRM);
            NULL;
    END validate_precollection_data;                           --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_item_details
    *
    * DESCRIPTION
    * Procedure is used to identify the Item Group, Item Class, Item Family and Item Model for a given Item and Organization.
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_inventory_item_id IN Inventory Item ID
    * p_organization_id IN Organization ID
    * x_item_group OUT Item Group
    * x_item_class OUT Item Class
    * x_item_family OUT Item Family
    * x_item_model OUT Item Model
    * x_return_message OUT Return Message
    *
    * RETURN VALUE
    * Returns Item Group, Item Class, Item Family and Item Model for a given Item and Organization.
    *
    * PREREQUISITES
    * Need to pass the inventory item id and organization id.
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_item_details (
        p_inventory_item_id   IN     mtl_item_categories.inventory_item_id%TYPE,
        p_organization_id     IN     mtl_item_categories.organization_id%TYPE,
        x_item_group             OUT mtl_categories_b.segment1%TYPE,
        x_item_class             OUT mtl_categories_b.segment2%TYPE,
        x_item_family            OUT mtl_categories_b.segment3%TYPE,
        x_item_model             OUT mtl_categories_b.segment4%TYPE,
        x_return_message         OUT VARCHAR2)
    IS
    BEGIN
        SELECT mc.segment1,
               mc.segment2,
               mc.segment3,
               mc.segment4
          INTO x_item_group,
               x_item_class,
               x_item_family,
               x_item_model
          FROM mtl_category_sets    mcs,
               mtl_item_categories  mic,
               mtl_categories_b     mc
         WHERE     mcs.category_set_name LIKE '%Products'
               AND mcs.category_set_id = mic.category_set_id
               AND mic.inventory_item_id = p_inventory_item_id
               AND mic.organization_id = p_organization_id
               AND mc.category_id = mic.category_id
               AND mc.enabled_flag = 'Y'
               AND NVL (mc.disable_date, SYSDATE + 1) > SYSDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_item_group := NULL;
            x_item_class := NULL;
            x_item_family := NULL;
            x_item_model := NULL;
            x_return_message :=
                ' Product Category Segment values not defined.';
        WHEN OTHERS
        THEN
            x_item_group := NULL;
            x_item_class := NULL;
            x_item_family := NULL;
            x_item_model := NULL;
            x_return_message :=
                ' In Others - Product Category Segment values ' || SQLERRM;
    END get_item_details;                                      --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_djo_brand_categories
    *
    * DESCRIPTION
    * The procedure returns the Business Unit, Product Brand and Product Group for a given Item and Organization.
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_inventory_item_id IN Inventory Item ID
    * p_organization_id IN Organization ID
    * x_business_unit OUT Business Unit
    * x_product_brand OUT Product Brand
    * x_product_group OUT Product Group
    * x_return_message OUT Return Message
    *
    * RETURN VALUE
    * Returns Business Unit, Product Brand and Product Group for a given Item and Organization.
    *
    * PREREQUISITES
    * Need to pass the inventory item id and organization id.
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_djo_brand_categories (
        p_inventory_item_id    IN     mtl_item_categories.inventory_item_id%TYPE,
        p_organization_id      IN     mtl_item_categories.organization_id%TYPE,
        x_business_unit           OUT mtl_categories_b.segment1%TYPE,
        x_product_brand           OUT mtl_categories_b.segment2%TYPE,
        x_product_group           OUT mtl_categories_b.segment3%TYPE,
        x_product_brand_name      OUT mtl_categories_b.segment4%TYPE, --Added by Anantha on 03-23-2012 for Incident # 199262
        x_return_message          OUT VARCHAR2)
    IS
    BEGIN
        SELECT mc.segment1,
               mc.segment2,
               mc.segment3,
               mc.segment4 --Added by Anantha on 03-23-2012 for Incident # 199262
          INTO x_business_unit,
               x_product_brand,
               x_product_group,
               x_product_brand_name --Added by Anantha on 03-23-2012 for Incident # 199262
          FROM mtl_category_sets    mcs,
               mtl_item_categories  mic,
               mtl_categories_b     mc
         WHERE     mcs.category_set_name LIKE '%Brand'
               AND mcs.category_set_id = mic.category_set_id
               AND mic.inventory_item_id = p_inventory_item_id
               AND mic.organization_id = p_organization_id
               AND mc.category_id = mic.category_id
               AND mc.enabled_flag = 'Y'
               AND NVL (mc.disable_date, SYSDATE + 1) > SYSDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_business_unit := NULL;
            x_product_brand := NULL;
            x_product_group := NULL;
            x_return_message := ' Brand Category Segment values not defined.';
        WHEN OTHERS
        THEN
            x_business_unit := NULL;
            x_product_brand := NULL;
            x_product_group := NULL;
            x_return_message :=
                ' In Others - Brand Category Segment values' || SQLERRM;
    END get_djo_brand_categories;                              --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_djo_anatomy
    *
    * DESCRIPTION
    * The procedure returns the Anatomy for a given Item and Organization.
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_inventory_item_id IN Inventory Item ID
    * p_organization_id IN Organization ID
    * x_anatomy OUT Anatomy Value
    * x_return_message OUT Return Message
    *
    * RETURN VALUE
    * Returns the Anatomy category value for a given Item and Organization.
    *
    * PREREQUISITES
    * Need to pass the Inventory Item ID and Organization ID.
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_djo_anatomy (
        p_inventory_item_id   IN     mtl_item_categories.inventory_item_id%TYPE,
        p_organization_id     IN     mtl_item_categories.organization_id%TYPE,
        x_anatomy                OUT mtl_categories_b.segment1%TYPE,
        x_return_message         OUT VARCHAR2)
    IS
    BEGIN
        SELECT mc.segment1
          INTO x_anatomy
          FROM mtl_category_sets    mcs,
               mtl_item_categories  mic,
               mtl_categories_b     mc
         WHERE     mcs.category_set_name LIKE '%Anatomy'
               AND mcs.category_set_id = mic.category_set_id
               AND mic.inventory_item_id = p_inventory_item_id
               AND mic.organization_id = p_organization_id
               AND mc.category_id = mic.category_id
               AND mc.enabled_flag = 'Y'
               AND NVL (mc.disable_date, SYSDATE + 1) > SYSDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_anatomy := NULL;
            x_return_message :=
                ' Anatomy Category Segment value is not defined.';
        WHEN OTHERS
        THEN
            x_anatomy := NULL;
            x_return_message :=
                ' In Others - Anatomy Category Segment value' || SQLERRM;
    END get_djo_anatomy;                                       --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_djo_customer
    *
    * DESCRIPTION
    * The procedure returns the End Customer Information such as End Customer Name and End Customer Address
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_cust_acc_number IN Customer Account Number
    * x_cust_name OUT Customer Name
    * x_cust_address OUT Customer Address
    * x_cust_city OUT Customer City
    * x_cust_zip OUT Customer Zip
    * x_cust_state OUT Customer State
    * x_return_message OUT Return Message
    *
    * RETURN VALUE
    * Returns the End Customer Information such as End Customer Name and End Customer Address for a given Customer Number.
    *
    * PREREQUISITES
    * Need to pass the Customer Number.
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_djo_customer (
        p_cust_acc_number   IN     hz_cust_accounts.account_number%TYPE,
        x_cust_name            OUT hz_parties.party_name%TYPE,
        x_cust_address         OUT hz_parties.address1%TYPE,
        x_cust_city            OUT hz_parties.city%TYPE,
        x_cust_zip             OUT hz_parties.postal_code%TYPE,
        x_cust_state           OUT hz_parties.state%TYPE,
        x_return_message       OUT VARCHAR2)
    IS
    BEGIN
        SELECT hp.party_name
                   customer_name,
               (   hp.address1
                || ','
                || hp.address2
                || ','
                || hp.address3
                || ','
                || hp.address4)
                   street_address,
               hp.city,
               hp.postal_code,
               hp.state
          INTO x_cust_name,
               x_cust_address,
               x_cust_city,
               x_cust_zip,
               x_cust_state
          FROM hz_parties hp, hz_cust_accounts hca
         --,hz_party_sites HPS
         --,hz_locations HL
         WHERE     hp.party_id = hca.party_id
               --AND HP.party_id = HPS.party_id
               --AND HPS.location_id = HL.location_id
               AND hca.account_number = p_cust_acc_number;
    --<SDMS_End_Customer_Number> Customer Account Number from SDMS
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_cust_name := NULL;
            x_cust_address := NULL;
            x_cust_city := NULL;
            x_cust_zip := NULL;
            x_cust_state := NULL;
            x_return_message := ' Customer Information is not defined';
        WHEN OTHERS
        THEN
            x_cust_name := NULL;
            x_cust_address := NULL;
            x_cust_city := NULL;
            x_cust_zip := NULL;
            x_cust_state := NULL;
            x_return_message :=
                ' In Others - Customer Information ' || SQLERRM;
    END get_djo_customer;                                      --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * insert_secondary_rep
    *
    * DESCRIPTION
    * This Procedure is used to insert the secondary sales rep record
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_ebs_trc_trx_id IN EBS Transaction ID
    * p_sdms_file_number IN SDMS File Number
    * p_trx_type IN Transaction Type
    * p_sdms_trx_number IN SDMS Transaction Number
    * p_sdms_trx_id IN SDMS Transaction ID
    * p_company_code IN Company Code
    * p_processed_date IN Processed Date
    * p_invoice_date IN Invoice Date
    * p_sdms_dist_num IN SDMS Dist Num
    * p_customer_number IN Customer Number
    * p_item_number IN Item Number
    * p_salesrep_id IN Sales Rep ID
    * p_secondary_rep_num IN Secondary Rep Number
    * p_quantity IN Quantity
    * p_actual_sales_amt IN Actual Sales Amount
    * p_extended_cost_amt IN Extended Cost Amount
    * p_extended_price_amt IN Extended Price Amount
    * p_profit_margin_amt IN Profit Margin Amount
    * p_end_customer_num IN End Customer Number
    * p_end_customer_name IN End Customer Name
    * p_street_address IN Street Address
    * p_city IN City
    * p_state IN State
    * p_zip IN Zip
    * p_customer_name IN Customer Name
    * p_business_segment IN Business Segment
    * p_item_group IN Item Group
    * p_item_class IN Item Class
    * p_order_type IN Order Type
    * p_brand IN Brand
    * p_item_family IN Item Family
    * p_anatomy IN Anatomy
    * p_reporting_center IN Reporting Center
    * p_collection_status IN Collection Status
    * p_error_message IN Error Message
    * p_product_brand IN Product Brand
    * p_product_group IN Product Group
    * p_item_model IN Item Model
    * p_creation_date IN Creation Date
    * p_created_by IN Created By
    * p_last_update_date IN Last Update Date
    * p_last_updated_by IN Last Updated By
    *
    * RETURN VALUE
    * NA
    *
    * PREREQUISITES
    * NA
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE insert_secondary_rep (p_ebs_trc_trx_id       IN NUMBER --,p_sdms_file_number IN VARCHAR2
                                                                    ,
                                    p_trx_type             IN VARCHAR2 --,p_sdms_trx_number IN VARCHAR2
                                                                      --,p_sdms_trx_id IN VARCHAR2
                                                                      --,p_company_code IN VARCHAR2
                                                                      ,
                                    p_processed_date       IN DATE --,p_invoice_date IN DATE
                                                                  ,
                                    p_sdms_dist_num        IN VARCHAR2,
                                    p_customer_number      IN VARCHAR2,
                                    p_item_number          IN VARCHAR2 --,p_salesrep_id IN NUMBER
                                                                      ,
                                    p_secondary_rep_num    IN VARCHAR2,
                                    p_quantity             IN NUMBER,
                                    p_actual_sales_amt     IN NUMBER,
                                    p_extended_cost_amt    IN NUMBER,
                                    p_extended_price_amt   IN NUMBER,
                                    p_profit_margin_amt    IN NUMBER,
                                    p_end_customer_num     IN VARCHAR2,
                                    p_end_customer_name    IN VARCHAR2,
                                    p_street_address       IN VARCHAR2,
                                    p_city                 IN VARCHAR2,
                                    p_state                IN VARCHAR2,
                                    p_zip                  IN VARCHAR2,
                                    p_customer_name        IN VARCHAR2,
                                    p_customer_category    IN VARCHAR2,
                                    p_business_segment     IN VARCHAR2,
                                    p_item_group           IN VARCHAR2,
                                    p_item_class           IN VARCHAR2,
                                    p_order_type           IN VARCHAR2,
                                    p_brand                IN VARCHAR2,
                                    p_item_family          IN VARCHAR2,
                                    p_anatomy              IN VARCHAR2,
                                    p_reporting_center     IN VARCHAR2,
                                    p_collection_status    IN VARCHAR2,
                                    p_error_message        IN VARCHAR2,
                                    p_product_brand        IN VARCHAR2,
                                    p_product_group        IN VARCHAR2,
                                    p_item_model           IN VARCHAR2,
                                    p_creation_date        IN DATE,
                                    p_created_by           IN NUMBER,
                                    p_last_update_date     IN DATE,
                                    p_last_updated_by      IN NUMBER,
                                    p_gpo_name             IN VARCHAR2 --Added by Saranya on 7/28/2016
                                                                      )
    IS
        l_ebs_trc_trx_id    NUMBER;
        l_revenue_type      VARCHAR2 (30);
        l_sdms_trx_number   VARCHAR2 (60);
        l_attribute1        VARCHAR2 (150);
        l_attribute2        VARCHAR2 (150);
    BEGIN
        SELECT xxdjo.djooic_sdms_sales_s.NEXTVAL
          INTO l_ebs_trc_trx_id
          FROM DUAL;

        /*
        Set the revenue type for Secondary Sales Rep
        For Secondary Sales Rep, Revenue type = 'NONREVENUE'
        */
        IF (p_secondary_rep_num IS NOT NULL)
        THEN
            l_revenue_type := 'NONREVENUE';
        END IF;

        /*Commented out on Apr20th since the sdms_trx_number is not in the select query
        and is also not derived*/
        --IF(p_sdms_trx_number IS NOT NULL) THEN
        -- l_sdms_trx_number := p_sdms_trx_number||'-1';
        --END IF;
        l_attribute1 := p_ebs_trc_trx_id;
        l_attribute2 := 'CLONED';

        INSERT INTO djooic_sdms_sales (ebs_trc_trx_id      --,SDMS_FILE_NUMBER
                                                     ,
                                       trx_type             --,SDMS_TRX_NUMBER
                                                                --,SDMS_TRX_ID
                                                               --,COMPANY_CODE
                                       ,
                                       processed_date          --,INVOICE_DATE
                                                     ,
                                       sdms_dist_num,
                                       customer_number,
                                       item_number,
                                       salesrep_number          --,SALESREP_ID
                                                      ,
                                       secondary_rep_num,
                                       quantity,
                                       actual_sales_amt,
                                       extended_cost_amt,
                                       extended_price_amt,
                                       profit_margin_amt,
                                       end_customer_num,
                                       end_customer_name,
                                       street_address,
                                       city,
                                       state,
                                       zip,
                                       customer_name,
                                       customer_category,
                                       business_segment,
                                       item_group,
                                       item_class,
                                       order_type,
                                       brand,
                                       item_family,
                                       anatomy,
                                       reporting_center,
                                       revenue_type,
                                       collection_status,
                                       attribute1,
                                       attribute2,
                                       product_brand,
                                       product_group,
                                       item_model,
                                       error_message,
                                       creation_date,
                                       created_by,
                                       last_update_date,
                                       last_updated_by,
                                       gpo_name /*p_gpo_name added by Saranya on 7/28/2016*/
                                               )
             VALUES (l_ebs_trc_trx_id                    --,p_sdms_file_number
                                     ,
                     p_trx_type                           --,l_sdms_trx_number
                                                              --,p_sdms_trx_id
                                                             --,p_company_code
                     ,
                     p_processed_date                        --,p_invoice_date
                                     ,
                     p_sdms_dist_num,
                     p_customer_number,
                     p_item_number,
                     p_secondary_rep_num                      --,p_salesrep_id
                                        ,
                     NULL                                --p_secondary_rep_num
                         ,
                     p_quantity,
                     p_actual_sales_amt,
                     p_extended_cost_amt,
                     p_extended_price_amt,
                     p_profit_margin_amt,
                     p_end_customer_num,
                     p_end_customer_name,
                     p_street_address,
                     p_city,
                     p_state,
                     p_zip,
                     p_customer_name,
                     p_customer_category,
                     p_business_segment,
                     p_item_group,
                     p_item_class,
                     p_order_type,
                     p_brand,
                     p_item_family,
                     p_anatomy,
                     p_reporting_center,
                     l_revenue_type,
                     p_collection_status,
                     l_attribute1,
                     l_attribute2,
                     p_product_brand,
                     p_product_group,
                     p_item_model,
                     p_error_message,
                     p_creation_date,
                     p_created_by,
                     p_last_update_date,
                     p_last_updated_by,
                     p_gpo_name   /*p_gpo_name added by Saranya on 7/28/2016*/
                               );
    END insert_secondary_rep;                                  --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_non_revenue_brand
    *
    * DESCRIPTION
    * This Procedure is used to get the non revenue brand for the secondary sales rep.
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_item_group IN Item Group
    * p_brand IN Revenue Brand
    * p_item_class IN Item Class
    * p_item_family IN Item Family
    * x_non_revenue_brand OUT Non Revenue Brand
    *
    * RETURN VALUE
    * Returns Non Revenue Brand for a given Item Group and Revenue Brand
    *
    * PREREQUISITES
    * Need to pass the inventory Item Group, Revenue Brand, item_class, and item_family
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_non_revenue_brand (
        p_item_group           IN     mtl_categories_b.segment1%TYPE,
        p_brand                IN     VARCHAR2,
        p_item_class           IN     mtl_categories_b.segment2%TYPE --v2.0 Charles Harding
                                                                    ,
        p_item_family          IN     mtl_categories_b.segment3%TYPE --v2.0 Charles Harding
                                                                    ,
        p_product_group        IN     mtl_categories_b.segment3%TYPE, --Added by Anantha on 03-23-2012 for Incident # 199262
        p_product_brand_name   IN     mtl_categories_b.segment4%TYPE, --Added by Anantha on 03-23-2012 for Incident # 199262
        x_non_revenue_brand       OUT VARCHAR2,
        x_officecare_flag         OUT VARCHAR2)
    IS
    BEGIN
        SELECT non_revenue_brand, officecare_flag
          INTO x_non_revenue_brand, x_officecare_flag
          FROM djo_non_rev_brand_info
         WHERE     item_group = p_item_group
               AND revenue_brand = p_brand
               -- Begin v2.0 Charles Harding
               AND NVL (item_class, '-1') = NVL (p_item_class, '-1')
               AND NVL (item_family, '-1') = NVL (p_item_family, '-1')
               AND NVL (product_brand_group, p_product_group) =
                   p_product_group --Added by Anantha on 03-23-2012 for Incident # 199262
               AND NVL (product_brand_name, p_product_brand_name) =
                   p_product_brand_name --Added by Anantha on 03-23-2012 for Incident # 199262
               AND TRUNC (effective_from_date) <= TRUNC (SYSDATE)
               AND TRUNC (NVL (effective_to_date, SYSDATE + 1)) >
                   TRUNC (SYSDATE)
               -- AND NVL(officecare_flag,'X') = 'Y' --v3.0 Saranya Nerella
               AND org_id = fnd_global.org_id;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            BEGIN
                SELECT non_revenue_brand, officecare_flag
                  INTO x_non_revenue_brand, x_officecare_flag
                  FROM djo_non_rev_brand_info
                 WHERE     revenue_brand = p_brand
                       AND item_group = p_item_group
                       AND NVL (item_class, '-1') = NVL (p_item_class, '-1')
                       AND item_family IS NULL
                       AND NVL (product_brand_group, p_product_group) =
                           p_product_group --Added by Anantha on 03-23-2012 for Incident # 199262
                       AND NVL (product_brand_name, p_product_brand_name) =
                           p_product_brand_name --Added by Anantha on 03-23-2012 for Incident # 199262
                       AND TRUNC (effective_from_date) <= TRUNC (SYSDATE)
                       AND TRUNC (NVL (effective_to_date, SYSDATE + 1)) >
                           TRUNC (SYSDATE)
                       -- AND NVL(officecare_flag,'X') = 'Y' --v3.0 Saranya Nerella
                       AND org_id = fnd_global.org_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    BEGIN
                        SELECT non_revenue_brand, officecare_flag
                          INTO x_non_revenue_brand, x_officecare_flag
                          FROM djo_non_rev_brand_info
                         WHERE     revenue_brand = p_brand
                               AND item_group = p_item_group
                               AND item_class IS NULL
                               AND item_family IS NULL
                               AND NVL (product_brand_group, p_product_group) =
                                   p_product_group --Added by Anantha on 03-23-2012 for Incident # 199262
                               AND NVL (product_brand_name,
                                        p_product_brand_name) =
                                   p_product_brand_name --Added by Anantha on 03-23-2012 for Incident # 199262
                               AND TRUNC (effective_from_date) <=
                                   TRUNC (SYSDATE)
                               AND TRUNC (
                                       NVL (effective_to_date, SYSDATE + 1)) >
                                   TRUNC (SYSDATE)
                               -- AND NVL(officecare_flag,'X') = 'Y' v3.0 Saranya Nerella
                               AND org_id = fnd_global.org_id;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            x_non_revenue_brand := NULL;
                            x_officecare_flag := 'N';
                    END;
                WHEN OTHERS
                THEN
                    x_non_revenue_brand := NULL;
                    x_officecare_flag := 'N';
            END;
        --EXCEPTION
        -- WHEN NO_DATA_FOUND THEN
        -- x_non_revenue_brand :=NULL;
        -- End v2.0 Charles Harding
        WHEN OTHERS
        THEN
            x_non_revenue_brand := NULL;
    END get_non_revenue_brand;                                 --Procedure End

    --Added by Saranya on 9th Mar, 2011
    --Start
    /* Below procedure checks the conditions for Ver 3.0 and flips the primary and secondary sales reps where applicable*/
    /*PROCEDURE check_rep_swap(p_ebs_trc_trx_id IN NUMBER) IS

    l_flip VARCHAR2(1) := 'N';
    rev_salesrep_number DJOOIC_SDMS_SALES.salesrep_number%Type;
    rev_secondary_rep_num DJOOIC_SDMS_SALES.secondary_rep_num%Type;
    nonrev_salesrep_number DJOOIC_SDMS_SALES.salesrep_number%Type;
    nonrev_secondary_rep_num DJOOIC_SDMS_SALES.secondary_rep_num%Type;
    nonrev_attribute1 DJOOIC_SDMS_SALES.attribute1%Type;
    nonrev_attribute2 DJOOIC_SDMS_SALES.attribute2%Type;
    nonrev_ebs_trc_trx_id DJOOIC_SDMS_SALES.ebs_trc_trx_id%Type;

    CURSOR rev_rep IS
     SELECT order_type, brand, item_group, item_class, item_family, ebs_trc_trx_id
     FROM djooic_sdms_sales
     WHERE ebs_trc_trx_id = p_ebs_trc_trx_id;

    BEGIN
     FOR i IN rev_rep LOOP
     --The below select validates for the order type and brand values
     SELECT 'Y'
     INTO l_flip
     FROM fnd_lookup_values
     WHERE lookup_type = 'DJO_OIC_OC_ORDER_TYPES' AND meaning = i.order_type AND i.brand IN ('PROCARE','AIRCAST');

     --The below select looks for the officecare flag match
     SELECT 'Y'
     INTO l_flip
     FROM djo_non_rev_brand_info
     WHERE item_group = i.item_group
     AND revenue_brand = i.brand
     AND NVL(item_class,'-1') = NVL(i.item_class,'-1')
     AND NVL(item_family,'-1') = NVL(i.item_family,'-1')
     AND TRUNC(effective_from_date) <= TRUNC(sysdate)
     AND TRUNC(NVL(effective_to_date, sysdate + 1)) > TRUNC(sysdate)
     AND NVL(officecare_flag,'X') = 'Y'
     AND org_id = fnd_global.org_id;
     END LOOP;

     IF l_flip = 'Y' THEN
     SELECT salesrep_number, secondary_rep_num
     INTO rev_salesrep_number, rev_secondary_rep_num
     FROM djooic_sdms_sales
     WHERE ebs_trc_trx_id = p_ebs_trc_trx_id;

     SELECT salesrep_number, secondary_rep_num, attribute1, attribute2, ebs_trc_trx_id
     INTO nonrev_salesrep_number, nonrev_secondary_rep_num, nonrev_attribute1, nonrev_attribute2, nonrev_ebs_trc_trx_id
     FROM djooic_sdms_sales
     WHERE attribute1 = p_ebs_trc_trx_id;

     UPDATE djooic_sdms_sales
     SET attribute1 = nonrev_ebs_trc_trx_id,
     attribute2 = nonrev_attribute2,
     salesrep_number = nonrev_salesrep_number,
     secondary_rep_num = NULL,
     revenue_type = 'NONREVENUE'
     WHERE ebs_trc_trx_id = p_ebs_trc_trx_id;

     UPDATE djooic_sdms_sales
     SET attribute1 = NULL,
     attribute2 = NULL,
     salesrep_number = nonrev_salesrep_number,
     secondary_rep_num = nonrev_secondary_rep_num,
     revenue_type = 'REVENUE'
     WHERE attribute1 = p_ebs_trc_trx_id;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
     NULL;
    END check_rep_swap; */
    --End

    /**************************************************************************
   *
   * PROCEDURE
   * get_reporting_center
   *
   * DESCRIPTION
   * This Procedure is used to get the Reporting center for Distribution.
   *
   * PARAMETERS
   * ==========
   * NAME TYPE DESCRIPTION
   * --------------------- -------- ---------------------------------
   * p_product_brand IN Item Group
   * x_reporting_center OUT Reporting Center
   *
   *
   * RETURN VALUE
   * Returns Reporting Center for a given Product Brand
   *
   * PREREQUISITES
   * Need to pass the Product Brand A
   *
   * CALLED BY
   * This Procedure is called in the procedure validate_precollection_data
   *
   **************************************************************************/
    PROCEDURE get_reporting_center (
        p_product_brand      IN     mtl_categories_b.segment2%TYPE,
        x_reporting_center      OUT VARCHAR2)
    IS
    BEGIN
        SELECT meaning
          INTO x_reporting_center
          FROM fnd_lookup_values_vl
         WHERE     lookup_type = 'DJOCN_SALES_TRC_REPORTING_CTR'
               AND attribute1 = UPPER (p_product_brand);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_reporting_center := NULL;
        WHEN OTHERS
        THEN
            x_reporting_center := NULL;
    END get_reporting_center;                                  --Procedure End

    /**************************************************************************
    *
    * PROCEDURE
    * get_count_records
    *
    * DESCRIPTION
    * This Procedure is used to get the number of records based on the collection status
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_collection_status IN Collection Status
    * x_count_record OUT Record Count
    *
    * RETURN VALUE
    * Returns the record count for a given Collection Status
    *
    * PREREQUISITES
    * Need to pass the Collection Status
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    **************************************************************************/
    PROCEDURE get_count_records (p_collection_status   IN     VARCHAR2,
                                 p_start_period_name   IN     VARCHAR2,
                                 p_end_period_name     IN     VARCHAR2,
                                 x_count_record           OUT NUMBER)
    IS
    BEGIN
        SELECT COUNT (1)
          INTO x_count_record
          FROM djooic_sdms_sales                         ----djooic_sdms_sales
         WHERE     collection_status = p_collection_status
               AND processed_date BETWEEN (SELECT start_date
                                             FROM cn_periods
                                            WHERE period_name =
                                                  p_start_period_name)
                                      AND (SELECT end_date
                                             FROM cn_periods
                                            WHERE period_name =
                                                  p_end_period_name);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_count_record := 0;
        WHEN OTHERS
        THEN
            x_count_record := 0;
    END get_count_records;                                     --Procedure End

    /********************************************************************************
    *
    * PROCEDURE
    * get_dist_customer_category
    *
    * DESCRIPTION
    * This Procedure is used to get the Stocking Distributor's Customer Category to
    * decide if Sales are Non-Commissionable or Not. Please refer to SR #41161
    *
    * PARAMETERS
    * ==========
    * NAME TYPE DESCRIPTION
    * --------------------- -------- ---------------------------------
    * p_customer_number IN Customer Number
    * x_dist_customer_category OUT Distributor Customer Category
    *
    *
    * RETURN VALUE
    * Returns Customer Category for Stocking Distributor based on Lookup
    *
    * PREREQUISITES
    * Need to pass Customer Account Number and Salesrep Id
    *
    * CALLED BY
    * This Procedure is called in the procedure validate_precollection_data
    *
    ********************************************************************************/
    PROCEDURE get_dist_customer_category (
        p_customer_number          IN     hz_cust_accounts.account_number%TYPE,
        p_salesrep_id              IN     jtf_rs_salesreps.salesrep_id%TYPE,
        x_dist_customer_category      OUT VARCHAR2)
    IS
        l_stocking_acct_exists   VARCHAR2 (1);
        l_group_id               NUMBER;
    BEGIN
        SELECT jg.GROUP_ID
          INTO l_group_id
          FROM jtf_rs_groups_vl         jg,
               jtf_rs_group_members_vl  jm,
               jtf_rs_defresroles_vl    jr,
               jtf_rs_salesreps         jrs
         WHERE     jg.GROUP_ID = jm.GROUP_ID
               AND NVL (jm.delete_flag, 'N') = 'N'
               AND jm.group_member_id = jr.role_Resource_id
               AND NVL (jr.delete_flag, 'N') = 'N'
               AND NVL (res_rl_end_date, SYSDATE) >= SYSDATE
               AND Jm.Resource_Id = Jrs.Resource_Id
               AND jrs.salesrep_id = p_salesrep_id
               AND Jrs.Org_Id = Fnd_Global.Org_Id;


        BEGIN
            SELECT 'Y'
              INTO l_stocking_acct_exists
              FROM fnd_lookup_values_vl
             WHERE     lookup_type = 'DJOCN_TRACING_STOCKING_ACCT'
                   AND attribute1 = l_group_id
                   AND attribute2 = p_customer_number
                   AND enabled_flag = 'Y'
                   AND NVL (end_Date_active, SYSDATE) >= SYSDATE;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_stocking_acct_exists := 'N';
        END;

        IF l_stocking_acct_exists = 'Y'
        THEN
            x_dist_customer_category := 'STOCKING ACCOUNT';
        ELSE
            x_dist_customer_category := 'STOCKING DISTRIBUTOR';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_dist_customer_category := NULL;
        WHEN OTHERS
        THEN
            x_dist_customer_category := NULL;
    END get_dist_customer_category;                            --Procedure End
END djooic_sdms_pre_collection_pkg;                             -- Package End

/

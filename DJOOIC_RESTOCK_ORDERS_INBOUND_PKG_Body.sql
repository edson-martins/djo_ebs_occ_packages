--------------------------------------------------------
--  DDL for Package Body DJOOIC_RESTOCK_ORDERS_INBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" 
AS
    PROCEDURE fnd_debug (p_string VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_string   VARCHAR2 (4000) := p_string;
        l_id       NUMBER;
    BEGIN
        l_id := TO_NUMBER (TO_CHAR (SYSDATE, 'YYMMDDHH24MISS'));

        INSERT INTO xxdjo.djooic_be_debug_log_tmp (id, text)
             VALUES (l_id, l_string);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END fnd_debug;

    FUNCTION derive_location (p_distributor_acct_number   VARCHAR2,
                              p_ship_to_address           VARCHAR2,
                              p_ship_to_address2          VARCHAR2,
                              p_ship_to_city              VARCHAR2,
                              p_ship_to_state             VARCHAR2,
                              p_zip_code                  VARCHAR2)
        RETURN NUMBER
    IS
        lv_location_id   NUMBER;
    BEGIN
        SELECT site_use.site_use_id
          INTO lv_location_id
          FROM hz_locations            hl,
               hz_party_sites          hps,
               hz_cust_acct_sites_all  hcas,
               hr_operating_units      ou,
               hz_timezones            ht,
               hz_cust_accounts        hca,
                 hz_cust_site_uses_all site_use
         WHERE     hl.location_id = hps.location_id
               AND hps.party_site_id = hcas.party_site_id
               AND ou.organization_id = hcas.org_id
               AND hca.cust_account_id = hcas.cust_account_id
               AND ht.timezone_id(+) = hl.timezone_id
               AND hps.status != 'M'
               AND site_use.site_use_code = 'DELIVER_TO'
                AND site_use.status = 'A'
               AND hcas.cust_acct_site_id = site_use.cust_acct_site_id
               AND UPPER (hl.city) = UPPER (p_ship_to_city)
               AND UPPER (hl.state) = UPPER (p_ship_to_state)
               AND upper(hl.address1)=UPPER(p_ship_to_address)
               AND upper(hl.address2)=UPPER(p_ship_to_address2)
               AND hca.account_number = p_distributor_acct_number;

        RETURN lv_location_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END derive_location;

    PROCEDURE create_location (p_distributor_acct_number       VARCHAR2,
                               p_ship_to_address               VARCHAR2,
                               p_ship_to_address2              VARCHAR2,
                               p_ship_to_city                  VARCHAR2,
                               p_ship_to_state                 VARCHAR2,
                               p_zip_code                      VARCHAR2,
                               p_ship_to_name                  VARCHAR2,
                               p_out_location_id OUT NUMBER,
                               p_out_site_use_id out number,

                               x_status_code               OUT VARCHAR2,
                               x_error_message             OUT VARCHAR2)
    IS
        lv_application_id        NUMBER;
        lv_responsibility_id     NUMBER;
        lv_user_id               NUMBER;
        lv_org_id                NUMBER;
        lv_go_to_final           EXCEPTION;
        lv_country               VARCHAR2 (1000);
        l_status_code            VARCHAR2 (1000);
        l_error_message          VARCHAR2 (4000);
        x_cust_account_id        NUMBER;
        x_account_number         VARCHAR2 (2000);
        x_party_id               NUMBER;
        x_party_number           VARCHAR2 (2000);
        x_profile_id             NUMBER;
        x_return_status          VARCHAR2 (2000);
        x_msg_count              NUMBER;
        x_msg_data               VARCHAR2 (2000);
        x_cust_acct_site_id      NUMBER;
        p_location_rec           HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
        lv_county                VARCHAR2 (100);
        x_location_id            NUMBER;
        l_party_id               NUMBER;
        l_cust_account_id        NUMBER;
        x_party_site_number      VARCHAR2 (2000);

        p_party_site_rec         HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
        p_cust_acct_site_rec     hz_cust_account_site_v2pub.cust_acct_site_rec_type;
        p_cust_site_use_rec      HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
        x_party_site_id          NUMBER;
        p_customer_profile_rec   HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
        x_site_use_id            NUMBER;
    BEGIN
        --initialize the parameters
        l_error_message := NULL;
        l_status_code := c_return_status_success;
        mo_global.init ('AR');
        fnd_debug ('intialize environment');

        BEGIN
            SELECT application_id, responsibility_id
              INTO lv_application_id, lv_responsibility_id
              FROM fnd_responsibility
             WHERE responsibility_key = 'RECEIVABLES_MANAGER';

            SELECT USER_ID
              INTO lv_user_id
              FROM fnd_user
             WHERE user_name = 'SYSADMIN';

            SELECT organization_id
              INTO lv_org_id
              FROM hr_operating_units
             WHERE name = 'US Operating Unit';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := c_return_status_error;
                l_error_message := 'Error in deriving the user id or org id';
                RAISE lv_go_to_final;
        END;
        fnd_debug('Before Distributor acct number');
        IF p_distributor_acct_number IS NULL
        THEN
            l_status_code := c_return_status_error;
            l_error_message :=
                'Please send the distributor account number in the payload';
            RAISE lv_go_to_final;
        END IF;

        BEGIN
            SELECT party_id, cust_account_id
              INTO l_party_id, l_cust_account_id
              FROM hz_cust_accounts
             WHERE account_number = p_distributor_acct_number;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := c_return_status_error;
                l_error_message :=
                    'Error in deriving the Customer Account ID';
                RAISE lv_go_to_final;
        END;
fnd_debug('After Distributor acct number');
        --deriving country
        BEGIN
            SELECT DISTINCT COUNTRY_CODE
              INTO lv_country
              FROM HZ_GEOGRAPHIES
             WHERE     UPPER (geography_element2_code) = upper(p_ship_to_state)
                   AND UPPER (geography_element4) = upper(p_ship_to_city);
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := c_return_status_error;
                l_error_message :=
                       'Error in derving the country for state '
                    || p_ship_to_state;
                RAISE lv_go_to_final;
        END;

        fnd_debug ('lv_country' || lv_country);

        --Get county for the city

        BEGIN
            SELECT geography_element3
              INTO lv_county
              FROM hz_geographies
             WHERE     geography_element5_id = geography_id
                   AND geography_element1_code = UPPER (lv_country)
                   AND UPPER (geography_element4) = UPPER (p_ship_to_city)
                   AND UPPER (geography_element2_code) =
                       UPPER (p_ship_to_state)
                   AND UPPER (geography_element1_code) = UPPER (lv_country)
                   AND UPPER (geography_element5) = UPPER (p_zip_code)
                   AND ROWNUM = 1;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_Status_code := c_return_status_error;
                l_error_message :=
                    'Could not derive the County for the state,postal code,city,country combination';
                RAISE lv_go_to_final;
        END;

        fnd_debug ('lv_county' || lv_county);
        -- Create Location for the party

        p_location_rec.country  := UPPER(lv_country);
        p_location_rec.address1 := UPPER(p_ship_to_address);
		p_location_rec.address2 := UPPER(p_ship_to_address2) ;
        p_location_rec.address3 := UPPER(p_ship_to_name);
        p_location_rec.city := UPPER(p_ship_to_city);
        p_location_rec.postal_code := UPPER(p_zip_code);
        p_location_rec.county := UPPER(lv_county);
        p_location_rec.state := UPPER(p_ship_to_state);
        p_location_rec.created_by_module := 'HZ_IMPORT';

        fnd_debug ('Calling the API hz_location_v2pub.create_location');

        HZ_LOCATION_V2PUB.CREATE_LOCATION (
            p_init_msg_list   => FND_API.G_TRUE,
            p_location_rec    => p_location_rec,
            x_location_id     => x_location_id,
            x_return_status   => x_return_status,
            x_msg_count       => x_msg_count,
            x_msg_data        => x_msg_data);

        IF x_return_status = fnd_api.g_ret_sts_success
        THEN
            COMMIT;
            fnd_debug ('Creation of Location is Successful ');
            fnd_debug ('Output information ....');
            fnd_debug ('x_location_id: ' || x_location_id);
            fnd_debug ('x_return_status: ' || x_return_status);
            fnd_debug ('x_msg_count: ' || x_msg_count);
            fnd_debug ('x_msg_data: ' || x_msg_data);
        ELSE
            fnd_debug ('Creation of Location failed:' || x_msg_data);

            FOR i IN 1 .. x_msg_count
            LOOP
                l_status_code := c_return_status_error;
                l_error_message :=
                       l_error_message
                    || oe_msg_pub.get (p_msg_index => i, p_encoded => 'F');
            END LOOP;

            RAISE lv_go_to_final;
        END IF;
        p_out_location_id:=x_location_id;

        fnd_debug ('Completion of hz_location_v2pub.create_location');


        -- Initializing the Mandatory API parameters
        p_party_site_rec.party_id := l_party_id;
        p_party_site_rec.location_id := x_location_id;
        --p_party_site_rec.identifying_address_flag := 'Y';
        p_party_site_rec.created_by_module := 'HZ_IMPORT';

        FND_DEBUG ('Calling the API hz_party_site_v2pub.create_party_site');

        HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE (
            p_init_msg_list       => FND_API.G_TRUE,
            p_party_site_rec      => p_party_site_rec,
            x_party_site_id       => x_party_site_id,
            x_party_site_number   => x_party_site_number,
            x_return_status       => x_return_status,
            x_msg_count           => x_msg_count,
            x_msg_data            => x_msg_data);

        IF x_return_status = fnd_api.g_ret_sts_success
        THEN
            COMMIT;
            fnd_debug ('Creation of Party Site is Successful ');
            fnd_debug ('Output information ....');
            fnd_debug ('Party Site Id     = ' || x_party_site_id);
            fnd_debug ('Party Site Number = ' || x_party_site_number);
        ELSE
            fnd_debug ('Creation of Party Site failed:' || x_msg_data);


            FOR i IN 1 .. x_msg_count
            LOOP
                l_status_code := c_return_status_error;
                l_error_message :=
                       l_error_message
                    || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F');
            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        fnd_debug ('Completion of API CREATE_PARTY_SITE');

        ----Create Customer account site
        fnd_global.set_nls_context ('AMERICAN');

        -- Initializing the Mandatory API parameters
        p_cust_acct_site_rec.cust_account_id := l_cust_account_id;
        p_cust_acct_site_rec.party_site_id := x_party_site_id;
        p_cust_acct_site_rec.org_id := lv_org_id;
        p_cust_acct_site_rec.created_by_module := 'HZ_IMPORT';
        p_cust_acct_site_rec.customer_category_code := 'AUS AGENTS';
		p_cust_acct_site_rec.attribute_category:='US Operating Unit';
        fnd_debug (
            'Calling the API hz_cust_account_site_v2pub.create_cust_acct_site');

        HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE (
            p_init_msg_list        => FND_API.G_TRUE,
            p_cust_acct_site_rec   => p_cust_acct_site_rec,
            x_cust_acct_site_id    => x_cust_acct_site_id,
            x_return_status        => x_return_status,
            x_msg_count            => x_msg_count,
            x_msg_data             => x_msg_data);

        IF x_return_status = fnd_api.g_ret_sts_success
        THEN
            COMMIT;
            fnd_debug ('Creation of Customer Account Site is Successful ');
            fnd_debug ('Output information ....');
            fnd_debug (
                'Customer Account Site Id is = ' || x_cust_acct_site_id);
        ELSE
            fnd_debug (
                'Creation of Customer Account Site got failed:' || x_msg_data);

            --ROLLBACK;

            FOR i IN 1 .. x_msg_count
            LOOP
                l_status_CODE := c_return_status_error;
                l_error_message :=
                       l_error_message
                    || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F');
            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        fnd_debug (
            'Completion of API HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE ');

        --Creating Site Use

        -- Initializing the Mandatory API parameters
        p_cust_site_use_rec.cust_acct_site_id := x_cust_acct_site_id;
        p_cust_site_use_rec.site_use_code := 'DELIVER_TO';
        --p_cust_site_use_rec.location := p_ship_to_city;
        p_cust_site_use_rec.created_by_module := 'HZ_IMPORT';

        fnd_debug (
            'Calling the API hz_cust_account_site_v2pub.create_cust_site_use');

        HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE (
            p_init_msg_list          => FND_API.G_TRUE,
            p_cust_site_use_rec      => p_cust_site_use_rec,
            p_customer_profile_rec   => p_customer_profile_rec,
            p_create_profile         => FND_API.G_TRUE,
            p_create_profile_amt     => FND_API.G_TRUE,
            x_site_use_id            => x_site_use_id,
            x_return_status          => x_return_status,
            x_msg_count              => x_msg_count,
            x_msg_data               => x_msg_data);
        p_out_site_use_id :=x_site_use_id;
        IF x_return_status = fnd_api.g_ret_sts_success
        THEN
            COMMIT;
            fnd_debug ('Creation of Customer Accnt Site use is Successful ');
            fnd_debug ('Output information ....');
            fnd_debug ('Site Use Id = ' || x_site_use_id);
            fnd_debug ('Site Use    = ' || p_cust_site_use_rec.site_use_code);
        ELSE
            fnd_debug (
                   'Creation of Customer Accnt Site use got failed:'
                || x_msg_data);


            FOR i IN 1 .. x_msg_count
            LOOP
                l_status_code := c_return_status_error;
                l_error_message :=
                       l_error_message
                    || fnd_msg_pub.get (p_msg_index => i, p_encoded => 'F');
            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        DBMS_OUTPUT.PUT_LINE ('Completion of API');

        x_status_code := l_status_code;
    EXCEPTION
        WHEN lv_go_to_final
        THEN
            x_status_code := l_status_code;
            x_error_message := l_error_message;
    END create_location;

    PROCEDURE ins_djo_consign_dtl_rec (
        p_batch_id                       IN     djo_auto_repl_consign_stgn_dtl.batch_id%TYPE,
        p_original_inventory_item_id     IN     djo_auto_repl_consign_stgn_dtl.original_inventory_item_id%TYPE,
        p_substitute_inventory_item_id   IN     djo_auto_repl_consign_stgn_dtl.substitute_inventory_item_id%TYPE,
        p_ordered_quantity               IN     djo_auto_repl_consign_stgn_dtl.ordered_quantity%TYPE,
        p_max_level_override             IN     djo_auto_repl_consign_stgn_dtl.max_level_override%TYPE,
        p_source_organization_id         IN     djo_auto_repl_consign_stgn_dtl.source_organization_id%TYPE,
        p_need_by_date                   IN     djo_auto_repl_consign_stgn_dtl.need_by_date%TYPE,
        p_ship_method                    IN     djo_auto_repl_consign_stgn_dtl.ship_method%TYPE,
        p_detail_status_code             IN     djo_auto_repl_consign_stgn_dtl.detail_status_code%TYPE,
        p_detail_error_msg               IN     djo_auto_repl_consign_stgn_dtl.detail_error_msg%TYPE,
        p_shipment_priority_code         IN     djo_auto_repl_consign_stgn_dtl.shipment_priority_code%TYPE --v1.05 Charles Harding, 02-FEB-2010
                                                                                                          ,
        p_last_updated_by                IN     djo_auto_repl_consign_stgn_dtl.last_updated_by%TYPE --v1.06 begin Charles Harding, 01-APR-2010
                                                                                                   ,
        p_last_update_date               IN     djo_auto_repl_consign_stgn_dtl.last_update_date%TYPE,
        p_last_update_login              IN     djo_auto_repl_consign_stgn_dtl.last_update_login%TYPE,
        p_creation_date                  IN     djo_auto_repl_consign_stgn_dtl.creation_date%TYPE,
        p_created_by                     IN     djo_auto_repl_consign_stgn_dtl.created_by%TYPE,
        P_INTERFACE_SOURCE_HEADER_ID     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.INTERFACE_SOURCE_HEADER_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                           ,
        P_INTERFACE_SOURCE_LINE_ID       IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.INTERFACE_SOURCE_LINE_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                         ,
        P_INTERFACE_SOURCE_LINE_NUM      IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.INTERFACE_SOURCE_LINE_NUM%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                          ,
        P_CONSOLIDATION_BATCH_ID         IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.CONSOLIDATION_BATCH_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                       ,
        P_CONSOLIDATION_LINE_ID          IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.CONSOLIDATION_LINE_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                      ,
        P_CONSOLIDATION_LINE_NUM         IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.CONSOLIDATION_LINE_NUM%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                       ,
        P_CONSOLIDATION_STATUS           IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.CONSOLIDATION_STATUS%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                     ,
        P_ISO_HEADER_ID                  IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ISO_HEADER_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                              ,
        P_ISO_LINE_ID                    IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ISO_LINE_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                            ,
        P_ISO_LINE_NUMBER                IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ISO_LINE_NUMBER%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                ,
        P_ATTRIBUTE1                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE1%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        P_ATTRIBUTE2                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE2%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        P_ATTRIBUTE3                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE3%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        P_ATTRIBUTE4                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE4%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        P_ATTRIBUTE5                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE5%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        P_ATTRIBUTE6                     IN     DJO_AUTO_REPL_CONSIGN_STGN_DTL.ATTRIBUTE6%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                           ,
        x_return_status                     OUT VARCHAR2,
        x_return_message                    OUT VARCHAR2)
    IS
        l_inventory_item_id   djo_auto_repl_consign_stgn_dtl.original_inventory_item_id%TYPE;
        l_item_type           mtl_system_items_b.item_type%TYPE;
    BEGIN
        x_return_status := c_return_status_success;

        l_inventory_item_id := p_original_inventory_item_id;

        IF (p_substitute_inventory_item_id IS NOT NULL)
        THEN
            l_inventory_item_id := p_substitute_inventory_item_id;
        END IF;

        BEGIN
            SELECT item_type
              INTO l_item_type
              FROM mtl_system_items
             WHERE     inventory_item_id = l_inventory_item_id
                   AND organization_id = p_source_organization_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_item_type := ' ';
            WHEN OTHERS
            THEN
                l_item_type := ' ';
        END;

        IF (l_item_type <> 'SPG')
        THEN
            INSERT INTO djo_auto_repl_consign_stgn_dtl (
                            batch_id,
                            line_id,
                            original_inventory_item_id,
                            substitute_inventory_item_id,
                            ordered_quantity,
                            need_by_date,
                            max_level_override,
                            ship_method,
                            source_organization_id,
                            detail_status_code,
                            detail_error_msg,
                            object_version_number,
                            shipment_priority_code --v1.05 Charles Harding, 02-FEB-2010
                                                  ,
                            last_updated_by,
                            last_update_date,
                            last_update_login,
                            creation_date,
                            created_by,
                            cancel_flag   --v1.06 Charles Harding, 01-APR-2010
                                       --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 START.NEW
                                       ,
                            INTERFACE_SOURCE_LINE_ID,
                            INTERFACE_SOURCE_HEADER_ID,
                            INTERFACE_SOURCE_LINE_NUM,
                            CONSOLIDATION_BATCH_ID,
                            CONSOLIDATION_LINE_ID,
                            CONSOLIDATION_LINE_NUM,
                            CONSOLIDATION_STATUS,
                            ISO_HEADER_ID,
                            ISO_LINE_ID,
                            ISO_LINE_NUMBER,
                            ATTRIBUTE1,
                            ATTRIBUTE2,
                            ATTRIBUTE3,
                            ATTRIBUTE4,
                            ATTRIBUTE5,
                            ATTRIBUTE6 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 END.NEW
                                      )
                 VALUES (p_batch_id,
                         djo_auto_repl_cnsgn_stgn_dtl_s.NEXTVAL,
                         p_original_inventory_item_id,
                         p_substitute_inventory_item_id,
                         p_ordered_quantity,
                         p_need_by_date,
                         p_max_level_override,
                         p_ship_method,
                         p_source_organization_id,
                         p_detail_status_code,
                         p_detail_error_msg,
                         1,
                         p_shipment_priority_code --v1.05 Charles Harding, 02-FEB-2010
                                                 ,
                         p_last_updated_by --v1.06 begin Charles Harding, 01-APR-2010
                                          ,
                         p_last_update_date,
                         p_last_update_login,
                         p_creation_date,
                         p_created_by,
                         'N'          --v1.06 end Charles Harding, 01-APR-2010
                            ,
                         P_INTERFACE_SOURCE_LINE_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                   ,
                         P_INTERFACE_SOURCE_HEADER_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                     ,
                         P_INTERFACE_SOURCE_LINE_NUM --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                    ,
                         P_CONSOLIDATION_BATCH_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                 ,
                         P_CONSOLIDATION_LINE_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                ,
                         P_CONSOLIDATION_LINE_NUM --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                                 ,
                         P_CONSOLIDATION_STATUS --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                               ,
                         P_ISO_HEADER_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                        ,
                         P_ISO_LINE_ID --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                      ,
                         P_ISO_LINE_NUMBER --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                          ,
                         P_ATTRIBUTE1 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     ,
                         P_ATTRIBUTE2 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     ,
                         P_ATTRIBUTE3 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     ,
                         P_ATTRIBUTE4 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     ,
                         P_ATTRIBUTE5 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     ,
                         P_ATTRIBUTE6 --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 01-APR-2011 .NEW
                                     );
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := c_return_status_error;
            x_return_message :=
                '>> ins_djo_consign_dtl_rec Error: ' || SQLERRM || CHR (10);
            fnd_file.put_line (
                fnd_file.LOG,
                'When Others ins_djo_consign_dtl_rec: ' || x_return_message);
    --      ROLLBACK;  --v1.08 Charles Harding, 28-Jan-2011
    END ins_djo_consign_dtl_rec;

    PROCEDURE ins_djo_consign_hdr_rec (
        p_batch_id                      IN     djo_auto_repl_consign_stgn_hdr.batch_id%TYPE,
        p_consignment_unit              IN     djo_auto_repl_consign_stgn_hdr.consignment_unit%TYPE,
        p_destination_organization_id   IN     djo_auto_repl_consign_stgn_hdr.destination_organization_id%TYPE,
        p_destination_subinventory      IN     djo_auto_repl_consign_stgn_hdr.destination_subinventory%TYPE,
        p_deliver_to_location_id        IN     djo_auto_repl_consign_stgn_hdr.deliver_to_location_id%TYPE,
        p_header_status_code            IN     djo_auto_repl_consign_stgn_hdr.header_status_code%TYPE,
        p_interface_source_code         IN     djo_auto_repl_consign_stgn_hdr.interface_source_code%TYPE,
        p_preparer_emp_id               IN     djo_auto_repl_consign_stgn_hdr.preparer_emp_id%TYPE,
        p_alt_deliver_to_loc_id         IN     djo_auto_repl_consign_stgn_hdr.alternate_deliver_to_loc_id%TYPE,
        p_header_id                     IN     djo_auto_repl_consign_stgn_hdr.interface_source_hdr_id%TYPE,
        p_packing_instruction           IN     djo_auto_repl_consign_stgn_hdr.packing_instruction%TYPE -- v1.04 Charles Harding, 02-Feb-2010
                                                                                                      ,
        p_last_updated_by               IN     djo_auto_repl_consign_stgn_hdr.last_updated_by%TYPE --v1.06 begin Charles Harding, 01-APR-2010
                                                                                                  ,
        p_last_update_date              IN     djo_auto_repl_consign_stgn_hdr.last_update_date%TYPE,
        p_last_update_login             IN     djo_auto_repl_consign_stgn_hdr.last_update_login%TYPE,
        p_creation_date                 IN     djo_auto_repl_consign_stgn_hdr.creation_date%TYPE,
        p_created_by                    IN     djo_auto_repl_consign_stgn_hdr.created_by%TYPE,
        p_deliver_to_cust_account_id    IN     djo_auto_repl_consign_stgn_hdr.deliver_to_cust_account_id%TYPE,
        p_source_order                  IN     djo_auto_repl_consign_stgn_hdr.source_order%TYPE --v1.06 end Charles Harding, 01-APR-2010
                                                                                               ,
        P_CONSOLIDATION_BATCH_ID        IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.CONSOLIDATION_BATCH_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                      ,
        P_CONSOLIDATION_STATUS          IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.CONSOLIDATION_STATUS%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                                    ,
        P_ISO_NUMBER                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ISO_NUMBER%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ISO_HEADER_ID                 IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ISO_HEADER_ID%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                             ,
        P_ATTRIBUTE1                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE1%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ATTRIBUTE2                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE2%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ATTRIBUTE3                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE3%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ATTRIBUTE4                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE4%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ATTRIBUTE5                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE5%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        P_ATTRIBUTE6                    IN     DJO_AUTO_REPL_CONSIGN_STGN_HDR.ATTRIBUTE6%TYPE DEFAULT NULL --V1.09 PRAVEEN KUMAR THIRUKOVALLURU 31-MAR-2011 .NEW
                                                                                                          ,
        p_po_number                     IN     VARCHAR2 DEFAULT NULL,
        x_return_status                    OUT VARCHAR2,
        x_return_message                   OUT VARCHAR2)
    IS
    BEGIN
        x_return_status := c_return_status_success;
        DBMS_OUTPUT.put_line (
            'p_interface_source_code: ' || p_interface_source_code);

        INSERT INTO djo_auto_repl_consign_stgn_hdr (
                        batch_id,
                        consignment_unit,
                        destination_organization_id,
                        destination_subinventory,
                        deliver_to_location_id,
                        header_status_code,
                        interface_source_code,
                        preparer_emp_id,
                        interface_source_hdr_id,
                        object_version_number,
                        last_updated_by,
                        last_update_date,
                        last_update_login,
                        creation_date,
                        created_by,
                        alternate_deliver_to_loc_id,
                        deliver_to_cust_account_id,
                        packing_instruction --v1.04 charles harding, 02-feb-2010
                                           ,
                        source_order      --v1.06 charles harding, 01-apr-2010
                                    --v1.09 praveen kumar thirukovalluru 01-apr-2011 start.new
                                    ,
                        consolidation_batch_id,
                        consolidation_status,
                        iso_number,
                        iso_header_id,
                        attribute1,
                        attribute2,
                        attribute3,
                        attribute4,
                        attribute5,
                        attribute6 --v1.09 praveen kumar thirukovalluru 01-apr-2011 end.new
                                  ,
                        po_number)
                 VALUES (
                     p_batch_id,
                     p_consignment_unit,
                     p_destination_organization_id,
                     p_destination_subinventory,
                     p_deliver_to_location_id,
                     p_header_status_code,
                     p_interface_source_code,
                     p_preparer_emp_id,
                     p_header_id,
                     1,
                     p_last_updated_by --v1.06 begin Charles Harding, 01-APR-2010
                                      ,
                     p_last_update_date,
                     p_last_update_login,
                     p_creation_date,
                     p_created_by,
                     p_alt_deliver_to_loc_id --v1.06 end  Charles Harding, 01-APR-2010
                                            ,
                     p_deliver_to_cust_account_id,
                     p_packing_instruction --v1.04 Charles Harding, 02-Feb-2010
                                          --Below line commented and new line inserted by Saranya on 8/21/2014 for Motiuon MD
                                          --Start
                                          --,p_source_order           --v1.06 Charles Harding, 01-APR-2010
                                          ,
                     DECODE (p_interface_source_code,
                             '9', NULL,
                             '8', NULL,
                             p_source_order)                             --End
                                            --v1.09 praveen kumar thirukovalluru 01-apr-2011 start.new
                                            ,
                     p_consolidation_batch_id,
                     p_consolidation_status,
                     p_iso_number,
                     p_iso_header_id,
                     p_attribute1,
                     p_attribute2,
                     p_attribute3,
                     p_attribute4,
                     p_attribute5,
                     p_attribute6 --v1.09 praveen kumar thirukovalluru 01-apr-2011 end.new
                                 --Below line commented and new line inserted by Saranya on 8/21/2014 for Motiuon MD
                                                                --,p_po_number
                                                                       --Start
                     ,
                     DECODE (p_interface_source_code,
                             '9', p_source_order,
                             '8', p_source_order,
                             p_po_number)                                --End
                                         );
    --    DBMS_OUTPUT.put_line('header batch id: '||p_batch_id);
    --    fnd_file.put_line(fnd_file.log,'header batch id: '||p_batch_id);

    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := c_return_status_error;
            x_return_message :=
                '>> ins_djo_consign_hdr_rec Error: ' || SQLERRM || CHR (10);
            fnd_file.put_line (
                fnd_file.LOG,
                'When Others ins_djo_consign_hdr_rec: ' || x_return_message);
    --      ROLLBACK;  --v1.08 Charles Harding, 28-Jan-2011
    END ins_djo_consign_hdr_rec;

    /**************************************************************************
    * *   PROCEDURE
    *    calc_deliver_to_location
    *
    *   DESCRIPTION
    *   The procedure will return the location id for the destination organization and destination subinventory.
    *
    *   PARAMETERS
    *   ==========
    *   NAME                           TYPE         DESCRIPTION
    *   -----------------              --------     -------------------------------------------------
    *   p_destination_organization_id  IN           The Oracle internal ID of the destination organization.
    *   p_destination_subinventory     IN           The destination subinventory code.
    *   x_deliver_to_location_id       OUT          The Oracle internal ID of the delivery location.
    *   x_return_status                OUT          Returns a status of "E" if routine returns an Oracle error.
    *                                                Returns 'S' if the routine completes normally.
    *   x_return_message               OUT          Returns a message with the Oracle error.
    *
    *   RETURN VALUE
    *     Return the location id for the destination organization and destination subinventory.
    *
    *     Returns a status of "E" if routine returns an Oracle error.  Returns 'S' if the routine
    *      completes normally.
    *
    *   PREREQUISITES
    *   Need to pass the destination organization id and destination subinventory.
    *
    *   CALLED BY
    *     This procedure is called by the exec_auto_repl_ordered_item val_batch_id, and exec_process_header procedures.
    *
    *************************************************************************/

    PROCEDURE calc_deliver_to_location (
        p_destination_organization_id   IN     djo_auto_repl_consign_stgn_hdr.destination_organization_id%TYPE,
        p_destination_subinventory      IN     djo_auto_repl_consign_stgn_hdr.destination_subinventory%TYPE,
        x_deliver_to_location_id           OUT djo_auto_repl_consign_stgn_hdr.deliver_to_location_id%TYPE,
        x_return_status                    OUT VARCHAR2,
        x_return_message                   OUT VARCHAR2)
    IS
    BEGIN
        x_return_status := c_return_status_success;

        SELECT MSI.location_id
          INTO x_deliver_to_location_id
          FROM mtl_secondary_inventories MSI, hr_locations_all HL
         WHERE     MSI.secondary_inventory_name = p_destination_subinventory
               AND MSI.organization_id = p_destination_organization_id
               AND MSI.location_id = HL.location_id
               AND NVL (inactive_date, SYSDATE + 1) > SYSDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            x_return_status := c_return_status_error;
            x_deliver_to_location_id := 0;
        WHEN OTHERS
        THEN
            x_return_status := c_return_status_unexpected;
            x_deliver_to_location_id := 0;
            x_return_message :=
                '>> calc_deliver_to_location: ' || SQLERRM || CHR (10);
    END calc_deliver_to_location;

    PROCEDURE process_restock_orders (
        p_request_id VARCHAR2,
        p_associated_ctm_id                 NUMBER,
        p_date_created                      DATE,
        p_distributor_acct_number           VARCHAR2,
        p_need_by_date                      DATE,
        p_ship_to_name                      VARCHAR2,
        p_ship_to_attn                      VARCHAR2,
        p_ship_to_address                   VARCHAR2,
		p_ship_to_address2                  VARCHAR2,
        p_ship_to_city                      VARCHAR2,
        p_ship_to_state                     VARCHAR2,
        p_ship_to_zip_code                  VARCHAR2,
        p_shipping_method                   VARCHAR2,
        p_destination_org                   VARCHAR2,
        p_destination_subinv                VARCHAR2,
        p_alternate_deliver_to_loc_id       NUMBER,
        p_items                             t_tab_items,
        p_out_request_id                OUT NUMBER,
        p_status_flag                   OUT VARCHAR2,
        p_error_message                 OUT VARCHAR2)
    IS
        l_request_id                    NUMBER;
        --l_excpetion                     EXCEPTION;
        l_status_code                   VARCHAR2 (10);
        l_error_message                 VARCHAR2 (3500);
        l_consignment_unit              VARCHAR2 (300);
        l_destination_organization_id   NUMBER;
        l_destination_subinv            VARCHAR2 (300);
        l_deliver_to_loc_id             NUMBER;
        l_interface_source_code         djo_auto_repl_consign_stgn_hdr.interface_source_code%TYPE;
        l_preparer_emp_id               NUMBER;
        l_alt_deliver_to_org_id         NUMBER;
        l_header_id                     NUMBER;
        l_packing_instruction           VARCHAR2 (4000);
        l_header_status_code            VARCHAR2 (1000);
        l_deliver_to_cust_acct_id       NUMBER;
        items_list                      t_tab_items;
        l_exception                     EXCEPTION;
        l_source_order                  VARCHAR2 (1000);
        l_cust_po_number                VARCHAR2 (1000);
        lv_organization_id              NUMBER;
        lv_inventory_item_id            NUMBER;
        l_site_use_id NUMBER;
        lv_ship_method_meaning VARCHAR2(1000);
        lv_request_count NUMBER;
    BEGIN
        ---Get batch id
        l_status_code := c_return_status_success;

        ---Validating the request id

        BEGIN
        SELECT count(1) into lv_request_count 
        FROM djo_auto_repl_consign_stgn_hdr WHERE PACKING_INSTRUCTION =p_request_id and header_status_code<>1;
        EXCEPTION
        WHEN OTHERS THEN
         l_status_code := 'E';
                l_error_message :=
                    'Exception in checking the request id duplicates ' ||'p_request_id'||p_request_id|| SQLERRM;
                RAISE l_exception;
        END;

        if lv_request_count>0 then
         l_status_code := 'E';
                l_error_message :=
                    'This request id is already processed in the system. Please enter the new request id  ' ||'p_request_id'||p_request_id|| SQLERRM;
                RAISE l_exception;
        end if;


        BEGIN
            SELECT djo_auto_repl_cnsgn_stgn_hdr_s.NEXTVAL
              INTO l_request_id
              FROM DUAL;
        END;
        p_out_request_id:=l_request_id;
        fnd_debug ('deriving Org id p_destination_org'||p_destination_org);
        --Get consignment Unit and destination org id
        BEGIN
            SELECT organization_id, attribute7
              INTO l_destination_organization_id, l_consignment_unit
              FROM mtl_parameters
             WHERE organization_code = p_destination_org;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := 'E';
                l_error_message :=
                    'Exception in Deriving the consignment Unit for ' ||'p_destination_org'||p_destination_org|| SQLERRM;
                RAISE l_exception;
        END;

        -- getting destination subinv
        fnd_debug (
            'l_destination_organization_id' || l_destination_organization_id);

        --Validating the shipmethod code
         BEGIN
           select ship_method_meaning 
           into lv_ship_method_meaning
           from wsh_carrier_services where ship_method_code= p_shipping_method
               and enabled_flag='Y';
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := 'E';
                l_error_message :=
                    'Shipping Method Code '||p_shipping_method||' does not exists in oracle '|| SQLERRM;
                RAISE l_exception;
        END;


        l_destination_subinv := p_destination_subinv;

        fnd_debug ('l_destination_subinv' || l_destination_subinv);
        --getting delivery to location id
        calc_deliver_to_location (
            p_destination_organization_id   => l_destination_organization_id,
            p_destination_subinventory      => l_destination_subinv,
            x_deliver_to_location_id        => l_deliver_to_loc_id,
            x_return_status                 => l_status_code,
            x_return_message                => l_error_message);

        IF l_status_code IN ('E', 'U')
        THEN
            RAISE l_exception;
        END IF;


        fnd_debug (
            'calc_deliver_to_location' || l_status_code || l_error_message);

        --Getting interface header code
        l_header_status_code := c_header_new;
        fnd_debug ('l_header_status_code' || l_header_status_code);
        --Getting interface source code

        l_interface_source_code :=c_source_replenishment_order; --'REPLENISHMENT ORDER';

        fnd_debug ('l_interface_source_code' || l_interface_source_code);

        --gettin the replenishment order preparer
        BEGIN
            l_preparer_emp_id :=
                fnd_profile.VALUE ('DJO_CONSIGNMENT_AUTO_REPLENISH_PREPARER');
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := c_return_status_error;
                l_error_message :=
                    'Exception in Deriving the l_preparer_emp_id' || SQLERRM;
                RAISE l_exception;
        END;

        fnd_debug ('l_preparer_emp_id' || l_preparer_emp_id);
        l_alt_deliver_to_org_id := p_alternate_deliver_to_loc_id;
        fnd_debug ('l_alt_deliver_to_org_id' || l_alt_deliver_to_org_id);
        l_source_order := p_associated_ctm_id;
        l_packing_instruction := p_request_id;
        fnd_debug ('before cust_account_id');

        BEGIN
            SELECT cust_account_id
              INTO l_deliver_to_cust_acct_id
              FROM hz_cust_accounts
             WHERE account_number = p_distributor_acct_number;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_status_code := c_return_status_error;
                l_error_message :=
                    'Exception in Deriving the customer account' || SQLERRM;
                RAISE l_exception;
        END;


        fnd_debug ('l_deliver_to_cust_acct_id' || l_deliver_to_cust_acct_id);


    l_site_use_id:=derive_location (p_distributor_acct_number=>p_distributor_acct_number,
                              p_ship_to_address =>p_ship_to_address,
                              p_ship_to_address2=>p_ship_to_address2,
                              p_ship_to_city   =>p_ship_to_city,
                              p_ship_to_state  =>p_ship_to_state,
                              p_zip_code      =>p_ship_to_zip_code);

fnd_debug ('AFTER DERIVE LOCATION' || l_site_use_id);
    IF l_site_use_id is null then
    fnd_debug (' INTO CREATE LOCATION' || l_deliver_to_cust_acct_id);
    create_location (p_distributor_acct_number =>p_distributor_acct_number,
                               p_ship_to_address=>p_ship_to_address,
                               p_ship_to_address2=>p_ship_to_address2,
                               p_ship_to_city =>p_ship_to_city,
                               p_ship_to_state=>p_ship_to_state,
                               p_zip_code    =>p_ship_to_zip_code,
                               p_ship_to_name=> p_ship_to_name,
                               p_out_location_id =>l_alt_deliver_to_org_id,
                               p_out_site_use_id=>l_site_use_id,
                               x_status_code =>L_status_code,
                               x_error_message =>l_error_message);
    IF l_status_code =c_return_status_error THEN
     l_status_code := c_return_status_error;
    RAISE l_exception;
    end if;
    END IF;



        BEGIN
            SELECT organization_id
              INTO lv_organization_id
              FROM mtl_parameters
             WHERE organization_code = 'AUS';
        END;

        fnd_debug ('lv_organization_id' || lv_organization_id);



        l_cust_po_number := p_ship_to_attn;
        ins_djo_consign_hdr_rec (
            p_batch_id                      => l_request_id,
            p_consignment_unit              => l_consignment_unit,
            p_destination_organization_id   => l_destination_organization_id,
            p_destination_subinventory      => l_destination_subinv,
            p_deliver_to_location_id        => l_deliver_to_loc_id,
            p_header_status_code            => l_header_status_code --        ,p_interface_source_code       => c_source_replenishment_order       --V1.09 Praveen Kumar THirukovalluru 31-MAR-2011 .old
                                                                   ,
            p_interface_source_code         => l_interface_source_code,
            p_preparer_emp_id               =>
                fnd_profile.VALUE ('DJO_CONSIGNMENT_AUTO_REPLENISH_PREPARER'),
            p_alt_deliver_to_loc_id         => l_site_use_id,
            p_header_id                     => NULL,
            p_packing_instruction           => l_packing_instruction,
            p_last_updated_by               => g_last_updated_by,
            p_last_update_date              => g_last_update_date,
            p_last_update_login             => g_last_update_login,
            p_creation_date                 => g_creation_date,
            p_created_by                    => g_created_by,
            p_deliver_to_cust_account_id    => l_deliver_to_cust_acct_id,
            p_source_order                  => l_source_order,
            p_po_number                     => l_cust_po_number,
            x_return_status                 => l_status_code,
            x_return_message                => l_error_message);

        IF l_status_code = c_return_status_error
        THEN
            RAISE l_exception;
        END IF;

        fnd_debug ('after inserting into headers ' || l_status_code);

        IF (l_status_code = c_return_status_success)
        THEN
            items_list := p_items;

            FOR i IN items_list.FIRST .. items_list.LAST
            LOOP
                BEGIN
                    SELECT inventory_item_id
                      INTO lv_inventory_item_id
                      FROM mtl_system_items_b
                     WHERE     organization_id = lv_organization_id
                           AND segment1 = items_list (i).part_number;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        l_status_code := c_return_status_error;
                        l_error_message :=
                               'Error in deriving the Inventory Item ID for Part Number '
                            || items_list (i).part_number;
                        RAISE l_exception;
                END;

                fnd_debug ('alv_inventory_item_id ' || lv_inventory_item_id);
                ins_djo_consign_dtl_rec (
                    p_batch_id                       => l_request_id,
                    p_original_inventory_item_id     => lv_inventory_item_id,
                    p_substitute_inventory_item_id   => NULL,
                    p_ordered_quantity               =>
                        items_list (i).ordered_quantity,
                    p_max_level_override             => 'N',
                    p_source_organization_id         => lv_organization_id,
                    p_need_by_date                   =>
                        TRUNC (NVL (p_need_by_date, SYSDATE)),
                    p_ship_method                    => p_shipping_method -- l_shipping_method_code
                                                                         ,
                    p_detail_status_code             => NULL,
                    p_detail_error_msg               => NULL,
                    p_shipment_priority_code         => NULL,
                    p_last_updated_by                => g_last_updated_by,
                    p_last_update_date               => g_last_update_date,
                    p_last_update_login              => g_last_update_login,
                    p_creation_date                  => g_creation_date,
                    p_created_by                     => g_created_by,
                    p_interface_source_header_id     => NULL,
                    p_interface_source_line_id       => NULL,
                    p_interface_source_line_num      =>
                        items_list (i).line_number,
                    x_return_status                  => l_status_code,
                    x_return_message                 => l_error_message);

                IF l_status_code = c_return_status_error
                THEN
                    RAISE l_exception;
                ELSE
                    l_status_code := c_return_status_success;
                END IF;

                fnd_debug ('after inserting into details');
            END LOOP;
        END IF;
        -- calling the interface 


DJO_AUTO_REPL_CONSIGN_STGN_PKG.exec_manual_batches(p_batch_id =>l_request_id
                               ,p_interface_source_code =>2
                               ,x_return_status         =>l_status_code
                               ,x_return_message        =>l_error_message) ;
DBMS_OUTPUT.PUT_LINE('l_status_code -'||l_status_code);
DBMS_OUTPUT.PUT_LINE('l_error_message -'||l_error_message);

IF l_status_code = c_return_status_error
                THEN
                    RAISE l_exception;
                ELSE
                    l_status_code := c_return_status_success;
                END IF;

        --
        p_status_flag := l_status_code;
    EXCEPTION
        WHEN L_EXCEPTION
        THEN
            p_status_flag := l_status_code;
            p_error_message := l_error_message;
            fnd_debug ('l_status_code' || l_status_code);
            fnd_debug ('l_error_message' || l_error_message);
    END process_restock_orders;
END DJOOIC_RESTOCK_ORDERS_INBOUND_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" TO "XXOIC";
  GRANT DEBUG ON "APPS"."DJOOIC_RESTOCK_ORDERS_INBOUND_PKG" TO "XXOIC";

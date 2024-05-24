--------------------------------------------------------
--  DDL for Package Body DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" --djooic_om_impbs_process_order_pkg
 AS
/* $Header: asopqtes.pls 120.12.12010000.9 2010/07/01 04:59:45 vidsrini ship $ */
/*# These public APIs allow users to create new quotes, modify existing quotes and convert quotes into orders.
 * @rep:scope public
 * @rep:product ASO
 * @rep:displayname Order Capture
 * @rep:lifecycle active
 * @rep:compatibility S
 * @rep:category BUSINESS_ENTITY SALES ORDER
*/

   -- Start of Comments
-- Package name     : djooic_om_impbs_process_order_pkg
-- Purpose          :
--   This package contains specification for pl/sql records and tables and the
--   Public API of Order Capture
  -- g_debug                      BOOLEAN                  := true;
  -- g_trace                      BOOLEAN                  := true;
    PROCEDURE apps_initilzation (
        ip_username         VARCHAR2,
        ip_responsibility   VARCHAR2,
        ip_application_name VARCHAR2,
        op_status           OUT VARCHAR2,
        op_message          OUT VARCHAR2
    ) IS

        l_test_init    NUMBER;
        l_error_msg    VARCHAR2(1000);
        l_user_id      fnd_user.user_id%TYPE;
        l_resp_id      fnd_responsibility_tl.responsibility_id%TYPE;
        l_resp_appl_id fnd_responsibility_tl.application_id%TYPE;
    BEGIN
        BEGIN
            SELECT
                user_id
            INTO l_user_id
            FROM
                fnd_user
            WHERE
                upper(user_name) = upper(ip_username);

        EXCEPTION
            WHEN OTHERS THEN
                op_status := 'E';
                op_message := 'FND User '
                              || ip_username
                              || ' not found.';
        END;

        BEGIN
            SELECT
                responsibility_id
            INTO l_resp_id
            FROM
                fnd_responsibility_tl
            WHERE
                    upper(responsibility_name) = upper(ip_responsibility)
                AND language = userenv('LANG');

        EXCEPTION
            WHEN OTHERS THEN
                op_status := 'E';
                op_message := 'Responsibility '
                              || ip_responsibility
                              || ' not found.';
        END;

        BEGIN
            SELECT
                application_id
            INTO l_resp_appl_id
            FROM
                fnd_application_tl
            WHERE
                    application_name = ip_application_name                                                                                 --661
                AND language = userenv('LANG');

        EXCEPTION
            WHEN no_data_found THEN
                op_status := 'E';
                op_message := 'Application: '
                              || ip_application_name
                              || ' not found.';
        END;

        SELECT
            fnd_global.user_id
        INTO l_test_init
        FROM
            dual;

        IF l_test_init = -1 THEN
            fnd_global.apps_initialize(l_user_id, l_resp_id, l_resp_appl_id);
            op_status := 'S';
            op_message := 'Initialize sucess';
        ELSE
            fnd_global.apps_initialize(0, 0, 0);
            fnd_global.apps_initialize(l_user_id, l_resp_id, l_resp_appl_id);
            op_status := 'S';
            op_message := 'Initialize sucess';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            l_error_msg := 'Error: ' || sqlerrm;
            op_status := 'E';
            op_message := 'exception when apps initilization: ' || l_error_msg;
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
    PROCEDURE print_debug (
        p_msg   IN VARCHAR2,
        p_debug IN BOOLEAN DEFAULT g_debug
    ) AS
    BEGIN
        IF p_debug = true THEN
            INSERT INTO price_debug VALUES ( p_msg );

            COMMIT;
            dbms_output.put_line(p_msg);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
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
    PROCEDURE populate_staging (
        p_process_order_rec IN djooic_om_impbs_process_order_stg%rowtype
    ) AS
        PRAGMA autonomous_transaction;
        l_process_order_rec djooic_om_impbs_process_order_stg%rowtype := p_process_order_rec;
    BEGIN
        INSERT INTO djooic_om_impbs_process_order_stg VALUES (
            l_process_order_rec.transaction_id,
            l_process_order_rec.item,
            l_process_order_rec.customer,
            l_process_order_rec.pricing_date,
            l_process_order_rec.ib_order_number,
            l_process_order_rec.price_list_name,
            l_process_order_rec.list_price,
            l_process_order_rec.selling_price,
            l_process_order_rec.error_code,
            l_process_order_rec.error_message,
            l_process_order_rec.oic_status,
            l_process_order_rec.oic_error_message,
            l_process_order_rec.interface_identifier,
            l_process_order_rec.created_by,
            l_process_order_rec.creation_date,
            l_process_order_rec.last_updated_by,
            l_process_order_rec.last_update_date,
            l_process_order_rec.last_update_login
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
    END populate_staging;

    PROCEDURE create_person (
        p_cust_account_number  IN VARCHAR2,
        p_contact_first_name   IN VARCHAR2,
        p_contact_last_name    IN VARCHAR2,
        p_contact_phone        IN VARCHAR2,
        p_phone_extension      IN VARCHAR2,
        p_contact_email        IN VARCHAR2,
        p_cust_account_site_id IN NUMBER,
        x_contact_point_id     OUT NUMBER
    ) IS

        l_person_rec            hz_party_v2pub.person_rec_type;
        l_org_contact_rec       hz_party_contact_v2pub.org_contact_rec_type;
        l_cr_cust_acc_role_rec  hz_cust_account_role_v2pub.cust_account_role_rec_type;
        l_contact_point_rec     hz_contact_point_v2pub.contact_point_rec_type;
        l_phone_rec             hz_contact_point_v2pub.phone_rec_type;
        l_email_rec             hz_contact_point_v2pub.email_rec_type;
        lx_party_id             NUMBER;
        l_party_id              NUMBER;
        lx_cust_account_role_id NUMBER;
        lx_party_number         VARCHAR2(2000);
        lx_profile_id           NUMBER;
        l_cust_account_id       NUMBER;
        lx_return_status        VARCHAR2(1);
        lx_msg_count            NUMBER;
        lx_msg_data             VARCHAR2(2000);
        lv_go_to_final EXCEPTION;
        l_validation_err EXCEPTION;
        l_error EXCEPTION;
        lv_application_id       NUMBER;
        lv_responsibility_id    NUMBER;
        lv_user_id              NUMBER;
        l_org_id                NUMBER;
        l_error_message         VARCHAR2(3000);
        l_person_count          NUMBER;
        l_status                VARCHAR2(20);
        lx_org_contact_id       NUMBER;
        lx_party_rel_id         NUMBER;
        lx_contact_point_id     NUMBER;
        l_transaction_id        NUMBER;
    BEGIN
        print_debug('l_transaction_id ');
      --initialize the parameters
        l_error_message := NULL;
        l_status := 'SUCCESS';
        mo_global.init('AR');
        BEGIN
            SELECT
                application_id,
                responsibility_id
            INTO
                lv_application_id,
                lv_responsibility_id
            FROM
                fnd_responsibility
            WHERE
                responsibility_key = 'RECEIVABLES_MANAGER';

            SELECT
                user_id
            INTO lv_user_id
            FROM
                fnd_user
            WHERE
                user_name = 'SYSADMIN';

         --l_org_id := p_org_id;
            SELECT
                lpad(replace(to_char(dbms_random.value(1, 9999999999)),
                             '.',
                             ''),
                     10,
                     '0')
            INTO l_transaction_id
            FROM
                dual;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE lv_go_to_final;
        END;

        BEGIN
            print_debug('l_transaction_id ' || l_transaction_id);
            fnd_global.apps_initialize(user_id => lv_user_id, resp_id => lv_responsibility_id, resp_appl_id => lv_application_id);
         --mo_global.set_policy_context('S', 81);
            fnd_global.set_nls_context('AMERICAN');
            SELECT
                party_id,
                cust_account_id
            INTO
                l_party_id,
                l_cust_account_id
            FROM
                hz_cust_accounts
            WHERE
                account_number = p_cust_account_number;

        EXCEPTION
            WHEN OTHERS THEN
                print_debug('Error in fetching custom account id' || sqlerrm);
                RAISE l_validation_err;
        END;

        l_person_rec.person_first_name := p_contact_first_name;
        l_person_rec.person_last_name := p_contact_last_name;
        l_person_rec.party_rec.orig_system := 'USER_ENTERED';
        l_person_rec.party_rec.orig_system_reference := l_transaction_id;
        l_person_rec.party_rec.status := 'A';
        l_person_rec.created_by_module := 'TCA_V1_API';
        hz_party_v2pub.create_person(p_init_msg_list => apps.fnd_api.g_false, p_person_rec => l_person_rec, x_party_id => lx_party_id
        , x_party_number => lx_party_number, x_profile_id => lx_profile_id,
                                    x_return_status => lx_return_status, x_msg_count => lx_msg_count, x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            print_debug('Creation of person is Successful ');
            print_debug('Output information ....');
            print_debug('lx_party_id: ' || lx_party_id);
            print_debug('lx_party_number: ' || lx_party_number);
            print_debug('x_return_status: ' || lx_return_status);
            print_debug('x_msg_count: ' || lx_msg_count);
            print_debug('x_msg_data: ' || lx_msg_data);
        ELSE
            lx_msg_data := ( 'error creating person'
                             || sqlerrm );
            print_debug('Creation of person failed:'
                        || lx_msg_data
                        || '-'
                        || l_transaction_id);
            FOR i IN 1..lx_msg_count LOOP
                l_status := 'ERROR';
                l_error_message := l_error_message
                                   || oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE l_error;
        END IF;

        l_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
        l_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
        l_org_contact_rec.party_rel_rec.subject_id := lx_party_id;
        l_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
        l_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
        l_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
        l_org_contact_rec.party_rel_rec.object_id := l_party_id;
        l_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
        l_org_contact_rec.party_rel_rec.start_date := sysdate;
        l_org_contact_rec.created_by_module := 'TCA_V2_API';
        hz_party_contact_v2pub.create_org_contact(p_init_msg_list => fnd_api.g_true, p_org_contact_rec => l_org_contact_rec, x_org_contact_id => lx_org_contact_id
        , x_party_rel_id => lx_party_rel_id, x_party_id => lx_party_id,
                                                 x_party_number => lx_party_number, x_return_status => lx_return_status, x_msg_count => lx_msg_count
                                                 , x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            dbms_output.put_line('***************************');
            dbms_output.put_line('Output information ....');
            dbms_output.put_line('Success');
            dbms_output.put_line('lv_org_contact_id: ' || lx_org_contact_id);
            dbms_output.put_line('lv_party_id: ' || lx_party_id);
            dbms_output.put_line('lv_party_rel_id: ' || lx_party_rel_id);
            dbms_output.put_line('***************************');
        ELSE
            lx_msg_data := ( 'error creating org contact'
                             || sqlerrm );
            print_debug('Creation of org contact failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                l_status := 'ERROR';
                l_error_message := l_error_message
                                   || oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE l_error;
        END IF;

        l_cr_cust_acc_role_rec.party_id := lx_party_id;            --<<this is the value of lv_party_id which gets generated from the Step 2>>
        l_cr_cust_acc_role_rec.cust_account_id := l_cust_account_id;
      --<<value for hz_cust_accounts_all.cust_account_id of the Organization party>>
        l_cr_cust_acc_role_rec.cust_acct_site_id := p_cust_account_site_id;
                              --<<To create contact at site level, if not to create contact at customer levl, we need to comment this line>>
-- p_cr_cust_acc_role_rec.primary_flag := 'Y';
        l_cr_cust_acc_role_rec.role_type := 'CONTACT';
        l_cr_cust_acc_role_rec.created_by_module := 'HZ_CPUI';
        mo_global.init('AR');
--
        hz_cust_account_role_v2pub.create_cust_account_role('T', l_cr_cust_acc_role_rec, lx_cust_account_role_id, lx_return_status, lx_msg_count
        ,
                                                           lx_msg_data);
        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            dbms_output.put_line('Success');
            dbms_output.put_line('lx_cust_account_role_id: ' || lx_cust_account_role_id);
            dbms_output.put_line('***************************');
            x_contact_point_id := lx_cust_account_role_id;
        ELSE
            lx_msg_data := ( 'error creating org contact'
                             || sqlerrm );
            print_debug('Creation of org contact failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                l_status := 'ERROR';
                l_error_message := l_error_message
                                   || oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE l_error;
        END IF;

        l_contact_point_rec.contact_point_type := 'PHONE';
        l_contact_point_rec.contact_point_purpose := 'BUSINESS';
        l_contact_point_rec.created_by_module := 'TCA_V2_API';
        l_contact_point_rec.status := 'A';
        l_email_rec.email_format := 'MAILHTML';
        l_email_rec.email_address := p_contact_email;
        l_phone_rec.phone_area_code := substr(p_contact_phone, 1, 3);
        l_phone_rec.phone_number := substr(p_contact_phone, 4, 7);
        l_phone_rec.phone_extension := p_phone_extension;
        l_contact_point_rec.owner_table_name := 'HZ_PARTIES';
        l_contact_point_rec.owner_table_id := lx_party_id;
      --<< This is the lv_party_id value generated from the Step 2>>
        l_phone_rec.phone_line_type := 'MOBILE';
        mo_global.init('AR');
        hz_contact_point_v2pub.create_contact_point(p_init_msg_list => fnd_api.g_true, p_contact_point_rec => l_contact_point_rec, p_email_rec => l_email_rec
        , p_phone_rec => l_phone_rec, x_contact_point_id => lx_contact_point_id,
                                                   x_return_status => lx_return_status, x_msg_count => lx_msg_count, x_msg_data => lx_msg_data
                                                   );

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            dbms_output.put_line('***************************');
            dbms_output.put_line('Output information ....');
            dbms_output.put_line('Success');
            dbms_output.put_line('lv_contact_point_id: ' || lx_contact_point_id);
            dbms_output.put_line('***************************');
      --x_contact_point_id := lx_contact_point_id;
        ELSE
            lx_msg_data := ( 'error creating org contact'
                             || sqlerrm );
            print_debug('Creation of org contact failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                l_status := 'ERROR';
                l_error_message := l_error_message
                                   || oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE l_error;
        END IF;

    EXCEPTION
        WHEN lv_go_to_final THEN
            print_debug('lv_error_message' || l_error_message);
            print_debug('Error in getting the Username, Responsibility Details');
        WHEN l_validation_err THEN
            print_debug('lv_error_message' || l_error_message);
            print_debug('Error in validating paramters');
        WHEN l_error THEN
            print_debug('lv_error_message' || l_error_message);
            print_debug('Error in executing seeded package');
        WHEN OTHERS THEN
            print_debug('Error in in the create_contact' || sqlerrm);
    END create_person;

    PROCEDURE create_cust_site (
        p_cust_account_number IN VARCHAR2,
        p_site_use_code       IN VARCHAR2,
        p_address1            IN VARCHAR2,
        p_address2            IN VARCHAR2,
        p_address3            IN VARCHAR2,
        p_address4            IN VARCHAR2,
        p_country             IN VARCHAR2,
        p_state               IN VARCHAR2,
        p_city                IN VARCHAR2,
        p_postal_code         IN VARCHAR2,
        p_org_id              IN NUMBER,
        x_party_site_id       OUT NOCOPY NUMBER                                                                                     --new
        ,
        x_return_status       OUT NOCOPY VARCHAR2,
        x_return_message      OUT NOCOPY VARCHAR2
    ) IS

        p_cust_account_rec     hz_cust_account_v2pub.cust_account_rec_type;
        p_person_rec           hz_party_v2pub.person_rec_type;
        p_customer_profile_rec hz_customer_profile_v2pub.customer_profile_rec_type;
        p_cust_acct_site_rec   hz_cust_account_site_v2pub.cust_acct_site_rec_type;
        p_cust_site_use_rec    hz_cust_account_site_v2pub.cust_site_use_rec_type;
        l_cust_account_id      NUMBER;
        lx_account_number      VARCHAR2(2000);
        l_party_id             NUMBER;
        l_county               VARCHAR2(200);
        lx_party_number        VARCHAR2(2000);
        lx_profile_id          NUMBER;
        lx_return_status       VARCHAR2(1);
        lx_init_message        VARCHAR2(2000);
        lx_msg_count           NUMBER;
        lx_msg_data            VARCHAR2(2000);
        lx_cust_acct_site_id   NUMBER;
        p_party_site_rec       hz_party_site_v2pub.party_site_rec_type;
        lx_party_site_id       NUMBER;
        lx_party_site_number   VARCHAR2(2000);
        l_location_rec         hz_location_v2pub.location_rec_type;
        lx_location_id         NUMBER;
        lx_site_use_id         NUMBER;
        lv_application_id      NUMBER;
        lv_responsibility_id   NUMBER;
        lv_user_id             NUMBER;
        lv_go_to_final EXCEPTION;
        lv_org_id              NUMBER;
        lv_error_message       VARCHAR2(3000);
        lv_person_count        NUMBER;
        lv_status              VARCHAR2(20);
    BEGIN
      --initialize the parameters
        lv_error_message := NULL;
        lv_status := 'SUCCESS';
        mo_global.init('AR');
        BEGIN
            SELECT
                application_id,
                responsibility_id
            INTO
                lv_application_id,
                lv_responsibility_id
            FROM
                fnd_responsibility
            WHERE
                responsibility_key = 'RECEIVABLES_MANAGER';

            SELECT
                user_id
            INTO lv_user_id
            FROM
                fnd_user
            WHERE
                user_name = 'SYSADMIN';

            lv_org_id := p_org_id;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE lv_go_to_final;
        END;

      /*---Validation for the existing person
      SELECT COUNT (*)
        INTO lv_person_count
        FROM hz_parties
       WHERE     party_type = 'PERSON'
             AND person_first_name = p_person_first_name
             AND person_last_name = p_person_last_name;

      IF lv_person_count > 0
      THEN
          lv_status :='ERROR';
          lv_error_message :=
              ' The person already defined in Oracle System';
          RAISE lv_go_to_final;
      END IF;

      fnd_global.apps_initialize (user_id        => lv_user_id,
                                  resp_id        => lv_responsibility_id,
                                  resp_appl_id   => lv_application_id);
      mo_global.set_policy_context ('S', lv_org_id);
      fnd_global.set_nls_context ('AMERICAN');
      p_cust_account_rec.account_name := p_account_name;
      p_cust_account_rec.created_by_module := 'HZ_IMPORT';
      p_person_rec.person_first_name := p_person_first_name;
      p_person_rec.person_last_name := p_person_last_name;
      p_person_rec.person_iden_type := 'NPI_NUMBER';
      p_person_rec.person_identifier := p_npi_number;
      print_debug('Calling the API hz_cust_account_v2pub.create_cust_account');
      hz_cust_account_v2pub.create_cust_account ('T',
                                                 p_cust_account_rec,
                                                 p_person_rec,
                                                 p_customer_profile_rec,
                                                 'F',
                                                 x_cust_account_id,
                                                 x_account_number,
                                                 x_party_id,
                                                 x_party_number,
                                                 x_profile_id,
                                                 x_return_status,
                                                 x_msg_count,
                                                 x_msg_data);
      print_debug (
          'x_return_status = ' || SUBSTR (x_return_status, 1, 255));
      print_debug ('x_msg_count = ' || TO_CHAR (x_msg_count));
      print_debug ('Party Id = ' || TO_CHAR (x_party_id));
      print_debug ('Party Number = ' || x_party_number);
      print_debug ('Profile Id = ' || TO_CHAR (x_profile_id));
      print_debug ('x_msg_data = ' || SUBSTR (x_msg_data, 1, 255));

      IF x_msg_count > 1
      THEN
          FOR I IN 1 .. x_msg_count
          LOOP
              lv_status :='ERROR';
              lv_error_message :=
                     lv_error_message
                  || (   I
                      || '. '
                      || SUBSTR (
                             FND_MSG_PUB.Get (p_encoded => FND_API.G_FALSE),
                             1,
                             255));
          END LOOP;

          RAISE lv_go_to_final;
      END IF;*/

      ---Validation for the existing person
        BEGIN
            fnd_global.apps_initialize(user_id => lv_user_id, resp_id => lv_responsibility_id, resp_appl_id => lv_application_id);

            mo_global.set_policy_context('S', lv_org_id);
            fnd_global.set_nls_context('AMERICAN');
            SELECT
                party_id,
                cust_account_id
            INTO
                l_party_id,
                l_cust_account_id
            FROM
                hz_cust_accounts
            WHERE
                account_number = p_cust_account_number;

        EXCEPTION
            WHEN OTHERS THEN
                print_debug('Error in fetching custom account id' || sqlerrm);
                RAISE lv_go_to_final;
        END;

        BEGIN
            SELECT
                geography_element3
            INTO l_county
            FROM
                hz_geographies
            WHERE
                    geography_element5_id = geography_id
                AND geography_element1_code = upper(p_country)
                AND upper(geography_element4) = upper(p_city)
                AND upper(geography_element2_code) = upper(p_state)
                AND upper(geography_element1_code) = upper(p_country)
                AND upper(geography_element5) = upper(p_postal_code)
                AND ROWNUM = 1;

        EXCEPTION
            WHEN OTHERS THEN
                lv_status := 'ERROR';
                lv_error_message := 'Could not derive the County for the state,postal code,city,country combination';
                RAISE lv_go_to_final;
        END;

      -- Create Location for the party
        l_location_rec.country := p_country;
        l_location_rec.address1 := p_address1;
        l_location_rec.address2 := p_address2;
        l_location_rec.address3 := p_address3;
        l_location_rec.address4 := p_address4;
        l_location_rec.city := p_city;
        l_location_rec.county := l_county;
        l_location_rec.postal_code := p_postal_code;
        l_location_rec.state := p_state;
        l_location_rec.created_by_module := 'HZ_IMPORT';
        print_debug('Calling the API hz_location_v2pub.create_location');
        print_debug('Before calling hz_location.create_location');
        print_debug('fnd_global.user_id - ' || fnd_global.user_id);
        print_debug('fnd_global.resp_id - ' || fnd_global.resp_id);
        print_debug('fnd_global.resp_appl_id - ' || fnd_global.resp_appl_id);
        print_debug('fnd_global.user_name - ' || fnd_global.user_name);
        print_debug('fnd_global.resp_name - ' || fnd_global.resp_name);
        print_debug('fnd_global.application_name - ' || fnd_global.application_name);
        print_debug('fnd_global.org_name - ' || fnd_global.org_name);
        print_debug('p_country - ' || p_country);
        print_debug('p_county - ' || l_county);
        print_debug('p_address1 - ' || p_address1);
        print_debug('p_city - ' || p_city);
        print_debug('p_postal_code - ' || p_postal_code);
        print_debug('p_state - ' || p_state);
        hz_location_v2pub.create_location(p_init_msg_list => fnd_api.g_true, p_location_rec => l_location_rec, x_location_id => lx_location_id
        , x_return_status => lx_return_status, x_msg_count => lx_msg_count,
                                         x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            print_debug('Creation of Location is Successful ');
            print_debug('Output information ....');
            print_debug('x_location_id: ' || lx_location_id);
            print_debug('x_return_status: ' || lx_return_status);
            print_debug('x_msg_count: ' || lx_msg_count);
            print_debug('x_msg_data: ' || lx_msg_data);
        ELSE
            lx_msg_data := ( 'error creating location'
                             || sqlerrm );
            print_debug('Creation of Location failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                lv_status := 'ERROR';
                lv_error_message := lv_error_message
                                    || oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        print_debug('Completion of hz_location_v2pub.create_location');
      -- Initializing the Mandatory API parameters
        p_party_site_rec.party_id := l_party_id;
        p_party_site_rec.location_id := lx_location_id;
        p_party_site_rec.identifying_address_flag := 'Y';
        p_party_site_rec.created_by_module := 'HZ_IMPORT';
        print_debug('Calling the API hz_party_site_v2pub.create_party_site');
        hz_party_site_v2pub.create_party_site(p_init_msg_list => fnd_api.g_true, p_party_site_rec => p_party_site_rec, x_party_site_id => lx_party_site_id
        , x_party_site_number => lx_party_site_number, x_return_status => lx_return_status,
                                             x_msg_count => lx_msg_count, x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            print_debug('Creation of Party Site is Successful ');
            print_debug('Output information ....');
            print_debug('Party Site Id     = ' || lx_party_site_id);
            print_debug('Party Site Number = ' || lx_party_site_number);
        ELSE
            print_debug('Creation of Party Site failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                lv_status := 'ERROR';
                lv_error_message := lv_error_message
                                    || fnd_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        print_debug('Completion of API CREATE_PARTY_SITE');
      ----Create Customer account site

      -- Initializing the Mandatory API parameters
        p_cust_acct_site_rec.cust_account_id := l_cust_account_id;
        p_cust_acct_site_rec.party_site_id := lx_party_site_id;
        p_cust_acct_site_rec.created_by_module := 'HZ_IMPORT';
        p_cust_acct_site_rec.customer_category_code := 'ORTHOPAEDIC SURGEON';
        print_debug('Calling the API hz_cust_account_site_v2pub.create_cust_acct_site');
        hz_cust_account_site_v2pub.create_cust_acct_site(p_init_msg_list => fnd_api.g_true, p_cust_acct_site_rec => p_cust_acct_site_rec
        , x_cust_acct_site_id => lx_cust_acct_site_id, x_return_status => lx_return_status, x_msg_count => lx_msg_count,
                                                        x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            print_debug('Creation of Customer Account Site is Successful ');
            print_debug('Output information ....');
            print_debug('Customer Account Site Id is = ' || lx_cust_acct_site_id);
        ELSE
            print_debug('Creation of Customer Account Site got failed:' || lx_msg_data);

         --ROLLBACK;
            FOR i IN 1..lx_msg_count LOOP
                lv_status := 'ERROR';
                lv_error_message := lv_error_message
                                    || fnd_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        print_debug('Completion of API HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE ');
      --Creating Site Use

      -- Initializing the Mandatory API parameters
        p_cust_site_use_rec.cust_acct_site_id := lx_cust_acct_site_id;
        p_cust_site_use_rec.site_use_code := p_site_use_code;
      --p_cust_site_use_rec.LOCATION := 'NEWYORK';
        p_cust_site_use_rec.created_by_module := 'HZ_IMPORT';
        print_debug('Calling the API hz_cust_account_site_v2pub.create_cust_site_use');
        hz_cust_account_site_v2pub.create_cust_site_use(p_init_msg_list => fnd_api.g_true, p_cust_site_use_rec => p_cust_site_use_rec
        , p_customer_profile_rec => p_customer_profile_rec, p_create_profile => fnd_api.g_true, p_create_profile_amt => fnd_api.g_true
        ,
                                                       x_site_use_id => lx_site_use_id, x_return_status => lx_return_status, x_msg_count => lx_msg_count
                                                       , x_msg_data => lx_msg_data);

        IF lx_return_status = fnd_api.g_ret_sts_success THEN
            COMMIT;
            print_debug('Creation of Customer Accnt Site use is Successful ');
            print_debug('Output information ....');
            print_debug('Site Use Id = ' || lx_site_use_id);
            print_debug('Site Use    = ' || p_cust_site_use_rec.site_use_code);
            x_party_site_id := lx_party_site_id;                                                                                         --new
        ELSE
            print_debug('Creation of Customer Accnt Site use got failed:' || lx_msg_data);
            FOR i IN 1..lx_msg_count LOOP
                lv_status := 'ERROR';
                lv_error_message := lv_error_message
                                    || fnd_msg_pub.get(p_msg_index => i, p_encoded => 'F');

            END LOOP;

            RAISE lv_go_to_final;
        END IF;

        dbms_output.put_line('Completion of API');
    EXCEPTION
        WHEN lv_go_to_final THEN
            print_debug('lv_error_message' || lv_error_message);
            print_debug('Error in getting the Username, Responsibility Details');
        WHEN OTHERS THEN
            print_debug('Error in in the create_surgeons' || sqlerrm);
    END create_cust_site;

--++++++++++++++++++++++++++++
    PROCEDURE update_reservation (
        p_header_id      IN NUMBER,
        p_lines_tbl      IN oe_order_pub.line_tbl_type,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) IS

        l_api_version              NUMBER := 1.0;
        l_init_msg_list            VARCHAR2(2) := fnd_api.g_true;
        l_data_valid_excep EXCEPTION;
        lx_return_status           VARCHAR2(2);
        lx_msg_count               NUMBER := 0;
        lx_msg_data                VARCHAR2(2000);
        l_data_valid_error_message VARCHAR2(2000);
        l_data_valid_error_sts     VARCHAR2(1);
        l_upd_res_ret_status       VARCHAR2(1) := 'S';
        l_upd_res_ret_msg          VARCHAR2(1) := 'S';
        lx_msg_index_out           NUMBER(10);
      -- WHO columns
        l_user_id                  NUMBER := -1;
        l_resp_id                  NUMBER := -1;
        l_application_id           NUMBER := -1;
        l_row_cnt                  NUMBER := 1;
        l_user_name                VARCHAR2(30) := 'MFG';
        l_resp_name                VARCHAR2(50) := 'Manufacturing and Distribution Manager';
      -- API specific declarations
        l_rsv_rec                  inv_reservation_global.mtl_reservation_rec_type;
        l_new_rsv_rec              inv_reservation_global.mtl_reservation_rec_type;
        l_serial_number            inv_reservation_global.serial_number_tbl_type;
        l_new_serial_number        inv_reservation_global.serial_number_tbl_type;
        l_validation_flag          VARCHAR2(2) := fnd_api.g_true;
        l_sales_order_id           NUMBER;
        l_line_tbl                 oe_order_pub.line_tbl_type;
        l_msg_data                 VARCHAR2(3000);
        l_inventory_location_id    NUMBER := NULL;

      -- Load required serial numbers that are reserved
        CURSOR c_serials IS
        SELECT
            msn.inventory_item_id,
            msn.serial_number
        FROM
            mtl_system_items_b msi,
            mtl_serial_numbers msn,
            mtl_parameters     mp
        WHERE
                msi.organization_id = mp.organization_id
            AND msi.organization_id = msn.current_organization_id
            AND msi.inventory_item_id = msn.inventory_item_id
            AND msn.group_mark_id IS NOT NULL
            AND msi.serial_number_control_code NOT IN ( 1, 6 )             -- item is not serial controlled / controlled at sales order issue
            AND msi.segment1 = 'SU_TEST_STS3'
            AND mp.organization_code = 'M1'
            AND msn.serial_number BETWEEN '' AND ''
        ORDER BY
            msn.serial_number DESC;

      -- Load reservation for this item
        CURSOR cur_item_reservations (
            cp_demand_source_header_id NUMBER,
            cp_demand_source_line_id   NUMBER
        ) IS
        SELECT
            msi.organization_id,
            msi.inventory_item_id,
            res.reservation_id,
            res.reservation_quantity,
            res.demand_source_name,
            res.lot_number,
            res.subinventory_code
        FROM
            mtl_system_items_b msi,
            mtl_parameters     mp,
            mtl_reservations   res
        WHERE
                1 = 1
            --and msi.segment1 = 'AS68112'
            --  AND mp.organization_code = 'M1'
            AND msi.organization_id = mp.organization_id
            AND res.organization_id = msi.organization_id
            AND res.inventory_item_id = msi.inventory_item_id
            AND res.demand_source_header_id = cp_demand_source_header_id
            AND res.demand_source_line_id = cp_demand_source_line_id
                                                                    --  and res.reservation_id =6789898
            ;

    BEGIN
        BEGIN
            SELECT
                sales_order_id
            INTO l_sales_order_id
            FROM
                mtl_sales_orders
            WHERE
                    segment1 = (
                        SELECT
                            order_number
                        FROM
                            oe_order_headers_all
                        WHERE
                            header_id = p_header_id
                    )
                AND segment2 = (
                    SELECT
                        ottl.name
                    FROM
                        oe_transaction_types_all ott,
                        oe_transaction_types_tl  ottl,
                        oe_order_headers_all     oeh
                    WHERE
                            1 = 1
                        AND ott.transaction_type_id = ottl.transaction_type_id
                        AND ott.transaction_type_id = oeh.order_type_id
                        AND ottl.language = userenv('LANG')
                        AND oeh.header_id = p_header_id
                )
                AND segment3 = 'ORDER ENTRY';

        EXCEPTION
            WHEN OTHERS THEN
                l_sales_order_id := NULL;
                l_data_valid_error_sts := 'E';
                l_data_valid_error_message := l_data_valid_error_message || 'Sales Order ID did not exist.';
                RAISE l_data_valid_excep;
        END;

        l_line_tbl := p_lines_tbl;
        IF l_line_tbl.count > 0 THEN
            print_debug('number of lines to update reservation --> ' || l_line_tbl.count);
            FOR l_line_tbl_idx IN l_line_tbl.first..l_line_tbl.last LOOP
                print_debug('update reservation Line# --> ' || l_line_tbl_idx);
            -- Get the first row
                print_debug('update reservation l_sales_order_id and order line id --> '
                            || l_sales_order_id
                            || '-'
                            || l_line_tbl(l_line_tbl_idx).line_id);

                FOR rec_item_reservations IN cur_item_reservations(cp_demand_source_header_id => l_sales_order_id, cp_demand_source_line_id => l_line_tbl
                (l_line_tbl_idx).line_id) LOOP
                    print_debug('update reservation in reservation cursor reservation_id # --> ' || rec_item_reservations.reservation_id
                    );
                    l_rsv_rec.reservation_id := rec_item_reservations.reservation_id;
                    l_rsv_rec.demand_source_name := rec_item_reservations.demand_source_name;
                    l_rsv_rec.reservation_quantity := rec_item_reservations.reservation_quantity;
               -- Update Demand Source Name, reservation qty for reservations that exist for this item
                    l_new_rsv_rec.reservation_id := rec_item_reservations.reservation_id;
--      l_new_rsv_rec.demand_source_name := ir.demand_source_name;                                                               --||'_0723';
                    l_new_rsv_rec.subinventory_code := l_line_tbl(l_line_tbl_idx).attribute17;
                    l_new_rsv_rec.lot_number := l_line_tbl(l_line_tbl_idx).attribute19;
                    l_new_rsv_rec.reservation_quantity := l_line_tbl(l_line_tbl_idx).ordered_quantity;
                    IF l_line_tbl(l_line_tbl_idx).attribute18 IS NOT NULL THEN
--
                        BEGIN
                            l_inventory_location_id := NULL;
                            SELECT
                                inventory_location_id
                            INTO l_inventory_location_id
                            FROM
                                mtl_item_locations mil
                            WHERE
                                    1 = 1
                                AND mil.disable_date IS NULL
                                AND mil.enabled_flag = 'Y'
                        --AND  MIL.SUBINVENTORY_CODE =:$FLEX$.DJOINV_RESERV_SUBINV
                                AND mil.status_id IN (
                                    SELECT
                                        status_id
                                    FROM
                                        mtl_material_statuses_vl
                                    WHERE
                                        reservable_type = 1
                                )
                        --AND mp.organization_id = mp.master_organization_id
                                AND mil.organization_id = l_line_tbl(l_line_tbl_idx).ship_from_org_id
                        -- AND mil.inventory_item_id = l_inventory_item_id
                                AND mil.subinventory_code = l_line_tbl(l_line_tbl_idx).attribute17
                                AND mil.segment1
                                    || '.'
                                    || mil.segment2
                                    || '.'
                                    || mil.segment3 = l_line_tbl(l_line_tbl_idx).attribute18;

                     /*SELECT inventory_location_id
                       INTO l_inventory_location_id
                       FROM mtl_item_locations mil
                      WHERE 1 = 1
                        --AND mp.organization_id = mp.master_organization_id
                        AND mil.organization_id = l_line_tbl(l_line_tbl_idx).ship_from_org_id
                        AND mil.inventory_item_id = l_line_tbl(l_line_tbl_idx).inventory_item_id
                        AND mil.subinventory_code = l_line_tbl(l_line_tbl_idx).attribute17
                        AND mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3  = l_line_tbl(l_line_tbl_idx).attribute18;*/
                            l_new_rsv_rec.locator_id := l_inventory_location_id;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_new_rsv_rec.locator_id := NULL;
                        END;
                    END IF;

            --l_new_rsv_rec.locator_id := 3261;
--      BEGIN
--         -- Initialize Serials to be updated / reserved
--         FOR ser IN c_serials LOOP
--            l_serial_number(l_row_cnt).inventory_item_id := ser.inventory_item_id;
--            l_serial_number(l_row_cnt).serial_number := ser.serial_number;
--            l_new_serial_number(l_row_cnt).inventory_item_id := ser.inventory_item_id;
--            l_new_serial_number(l_row_cnt).serial_number := ser.serial_number + 10;
--            l_row_cnt := l_row_cnt + 1;
--         END LOOP;
--      EXCEPTION
--         WHEN NO_DATA_FOUND THEN
--            DBMS_OUTPUT.put_line('Item not serial controlled / serials not provided');
--      END;

               -- call API to update all the reservations for this item
                    print_debug('=======================================================');
                    print_debug('Calling INV_RESERVATION_PUB.Update_Reservation');
                    inv_reservation_pub.update_reservation(p_api_version_number => l_api_version, p_init_msg_lst => l_init_msg_list, x_return_status => lx_return_status
                    , x_msg_count => lx_msg_count, x_msg_data => lx_msg_data,
                                                          p_original_rsv_rec => l_rsv_rec, p_to_rsv_rec => l_new_rsv_rec, p_original_serial_number => l_serial_number
                                                          , p_to_serial_number => l_new_serial_number, p_validation_flag => l_validation_flag
                                                          ,
                                                          p_check_availability => fnd_api.g_false);

                    print_debug('l_return_status inv_reservation_pub.update_reservation for line number#'
                                || l_line_tbl(l_line_tbl_idx).line_number
                                || ' IS -->'
                                || lx_return_status);

                    x_return_status := lx_return_status;
                    x_return_message := lx_msg_data;
                    print_debug('Before inv_reservation_pub.update_reservation  loop - ');
                -- Retrieve messages
               /* FOR i IN 1 .. lx_msg_count LOOP
                   fnd_msg_pub.get(p_msg_index          => i
                                  ,p_encoded            => fnd_api.g_false
                                  ,p_data               => lx_msg_data
                                  ,p_msg_index_out      => lx_msg_index_out);
                   print_debug('message is: ' || lx_msg_data);
                   print_debug('message index is: ' || lx_msg_index_out);
                END LOOP;*/
                    print_debug('After inv_reservation_pub.update_reservation end loop - ' || lx_msg_data);
                    IF ( lx_return_status <> fnd_api.g_ret_sts_success ) THEN
                        l_upd_res_ret_status := 'E';
                        print_debug('Error Message :' || lx_msg_data);
                        l_msg_data := l_msg_data
                                      || lx_msg_data
                                      || ' Failed to update reservation for line number#'
                                      || l_line_tbl(l_line_tbl_idx).line_number;

                        ROLLBACK;
                    ELSE
                        COMMIT;
                        print_debug('Reservation ID           :' || l_new_rsv_rec.reservation_id);
                        print_debug('Demand Source Name (old) :' || l_rsv_rec.demand_source_name);
                        print_debug('Demand Source Name (new) :' || l_new_rsv_rec.demand_source_name);
                        print_debug('Reservation Qty  (old)   :' || l_rsv_rec.reservation_quantity);
                        print_debug('Reservation Qty  (new)   :' || l_new_rsv_rec.reservation_quantity);
                    END IF;

                END LOOP;

            END LOOP;

            x_return_status := l_upd_res_ret_status;
            x_return_message := l_msg_data;
        ELSE
            x_return_status := 'S';
            x_return_message := 'No records to update';
        END IF;

    EXCEPTION
        WHEN l_data_valid_excep THEN
            print_debug('Data validation failed.:');
            x_return_status := 'E';
            x_return_message := l_data_valid_error_message
                                || '...'
                                || dbms_utility.format_error_backtrace();
        WHEN OTHERS THEN
            print_debug('WHE OTHERS Exception Occured :'
                        || sqlerrm
                        || '...'
                        || dbms_utility.format_error_backtrace());
            x_return_status := 'E';
            x_return_message := l_msg_data
                                || 'WHE OTHERS Exception Occured :'
                                || sqlerrm
                                || '...'
                                || dbms_utility.format_error_backtrace();

    END update_reservation;

--++++++++++++++++++++++++++++

   -- realeses holds on  sales Order
--++++++++++++++++++++++++++++
    PROCEDURE release_hold (
        p_header_id      IN NUMBER,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) AS

        l_order_tbl      oe_holds_pvt.order_tbl_type;
        l_return_status  VARCHAR2(30) := 'S';
        l_msg_data       VARCHAR2(4000) DEFAULT NULL;
        l_msg_count      NUMBER DEFAULT 0;
        l_ra_po_num      oe_order_headers_all.cust_po_number%TYPE;
        l_return_message VARCHAR2(4000) DEFAULT NULL;

      --Cursor to get the order details for which the PO Verification hold is not released
        CURSOR cur_ord_hdr (
            cp_header_id NUMBER
        ) IS
        SELECT
            ooh.header_id,
            ooh.order_number,
            nvl(ooh.cust_po_number, 'N') cust_po_num_exists,
            ohd.hold_id,
            oohold.line_id,
            ooh.cust_po_number                                                                            --added on nov 12 2009 by Siva
        FROM
            oe_order_holds_all   oohold,
            oe_hold_sources_all  ohs,
            oe_hold_definitions  ohd,
            oe_order_headers_all ooh
        WHERE
                oohold.hold_source_id = ohs.hold_source_id
            AND ohs.hold_id = ohd.hold_id
            AND ooh.header_id = oohold.header_id
            AND ohd.name = 'Pricing Hold'
            AND oohold.released_flag = 'N'
            AND ooh.header_id = cp_header_id;

        l_cnt            NUMBER;
        l_start_col_num  NUMBER;
        l_column_name    VARCHAR2(50);
        l_upd_stmt       VARCHAR2(300);
    BEGIN
        FOR rec_cur_ord_hdr IN cur_ord_hdr(cp_header_id => p_header_id) LOOP
         --Assigning the order header id
            l_order_tbl(1).header_id := rec_cur_ord_hdr.header_id;
            l_order_tbl(1).line_id := rec_cur_ord_hdr.line_id;
            BEGIN
                print_debug('Calling OE_Holds_PUB.Release_Holds');
                oe_holds_pub.release_holds(p_api_version => 1.0, p_commit => fnd_api.g_false, p_validation_level => fnd_api.g_valid_level_full
                , p_order_tbl => l_order_tbl, p_hold_id => rec_cur_ord_hdr.hold_id,
                                          p_release_reason_code => 'MANUAL_RELEASE_MARGIN_HOLD', p_release_comment => 'Pricing Hold Released'
                                          , p_check_authorization_flag => 'N', x_return_status => l_return_status, x_msg_count => l_msg_count
                                          ,
                                          x_msg_data => l_msg_data);

                IF ( l_return_status = 'S' ) THEN
                    l_return_message := l_return_message
                                        || 'Hold Released for Order number line id'
                                        || rec_cur_ord_hdr.line_id;
                    print_debug(l_return_message);
                    COMMIT;
                ELSE
                    l_return_message := l_return_message
                                        || 'Hold NOT Released for Order number line id '
                                        || rec_cur_ord_hdr.line_id
                                        || '.The reason is '
                                        || l_msg_data;

                    print_debug(l_return_message);
                    ROLLBACK;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    l_return_message := l_return_message
                                        || 'Others error for line id '
                                        || rec_cur_ord_hdr.line_id
                                        || sqlerrm;
                    print_debug(l_return_message);
            END;

        END LOOP;

        x_return_status := l_return_status;
        x_return_message := l_return_message;
    EXCEPTION
        WHEN OTHERS THEN
            x_return_status := 'E';
            x_return_message := l_msg_data
                                || 'WHE OTHERS Exception Occured :'
                                || sqlerrm
                                || '...'
                                || dbms_utility.format_error_backtrace();

    END release_hold;

--++++++++++++++++++++++++++++

   -- updating PO, case start date, Surgeon on  sales Order header
--++++++++++++++++++++++++++++
    PROCEDURE update_so (
        p_so_header_rec  IN djooic_om_impbs_header_rec,
        p_so_header_id   IN NUMBER,
        p_so_lines_tbl   IN djooic_om_impbs_line_tbl,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) AS

        l_header_rec                 oe_order_pub.header_rec_type;
        v_header_rec                 oe_order_pub.header_rec_type;
        l_line_tbl                   oe_order_pub.line_tbl_type;
        lx_line_tbl                  oe_order_pub.line_tbl_type;
        l_action_request_tbl         oe_order_pub.request_tbl_type;
        lx_action_request_tbl        oe_order_pub.request_tbl_type;
        l_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
        l_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
        l_header_scr_tbl             oe_order_pub.header_scredit_tbl_type;
        l_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
        l_request_rec                oe_order_pub.request_rec_type;
        l_return_status              VARCHAR2(1000);
        l_msg_count                  NUMBER;
        l_msg_data                   VARCHAR2(1000);
        p_api_version_number         NUMBER := 1.0;
        p_init_msg_list              VARCHAR2(10) := fnd_api.g_false;
        p_return_values              VARCHAR2(10) := fnd_api.g_false;
        p_action_commit              VARCHAR2(10) := fnd_api.g_false;
      --x_return_status                VARCHAR2(1);
        l_error_msg                  VARCHAR2(2000);
        x_msg_count                  NUMBER;
        x_msg_data                   VARCHAR2(100);
        p_header_rec                 oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
        p_old_header_rec             oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
        p_header_val_rec             oe_order_pub.header_val_rec_type := oe_order_pub.g_miss_header_val_rec;
        p_old_header_val_rec         oe_order_pub.header_val_rec_type := oe_order_pub.g_miss_header_val_rec;
        p_header_adj_tbl             oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
        p_old_header_adj_tbl         oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
        p_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type := oe_order_pub.g_miss_header_adj_val_tbl;
        p_old_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type := oe_order_pub.g_miss_header_adj_val_tbl;
        p_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
        p_old_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
        p_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
        p_old_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
        p_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
        p_old_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
        p_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
        p_old_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
        p_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type := oe_order_pub.g_miss_header_scredit_val_tbl;
        p_old_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type := oe_order_pub.g_miss_header_scredit_val_tbl;
        p_line_tbl                   oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
        p_old_line_tbl               oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
        p_line_val_tbl               oe_order_pub.line_val_tbl_type := oe_order_pub.g_miss_line_val_tbl;
        p_old_line_val_tbl           oe_order_pub.line_val_tbl_type := oe_order_pub.g_miss_line_val_tbl;
        p_line_adj_tbl               oe_order_pub.line_adj_tbl_type := oe_order_pub.g_miss_line_adj_tbl;
        p_old_line_adj_tbl           oe_order_pub.line_adj_tbl_type := oe_order_pub.g_miss_line_adj_tbl;
        p_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type := oe_order_pub.g_miss_line_adj_val_tbl;
        p_old_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type := oe_order_pub.g_miss_line_adj_val_tbl;
        p_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
        p_old_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
        p_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
        p_old_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
        p_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
        p_old_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
        p_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
        p_old_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
        p_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type := oe_order_pub.g_miss_line_scredit_val_tbl;
        p_old_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type := oe_order_pub.g_miss_line_scredit_val_tbl;
        p_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
        p_old_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
        p_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type := oe_order_pub.g_miss_lot_serial_val_tbl;
        p_old_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type := oe_order_pub.g_miss_lot_serial_val_tbl;
        p_action_request_tbl         oe_order_pub.request_tbl_type := oe_order_pub.g_miss_request_tbl;
        x_header_val_rec             oe_order_pub.header_val_rec_type;
        x_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
        x_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type;
        x_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type;
        x_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type;
        x_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type;
        x_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
        x_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type;
        x_line_val_tbl               oe_order_pub.line_val_tbl_type;
        x_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
        x_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type;
        x_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type;
        x_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type;
        x_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type;
        x_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
        x_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type;
        x_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type;
        x_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type;
        x_action_request_tbl         oe_order_pub.request_tbl_type;
        x_debug_file                 VARCHAR2(100);
        l_line_tbl_index             NUMBER;
        l_line_tbl_idx               NUMBER := 1;
        l_msg_index_out              NUMBER(10);
        l_data_valid_excep EXCEPTION;
        l_surgeon_account_id         NUMBER;
        l_validation_status          VARCHAR2(10);
        l_val_error_msg              VARCHAR2(2000);
        l_so_line_id                 NUMBER;
        l_so_lines_tbl               djooic_om_impbs_line_tbl;
        l_success_msg                VARCHAR2(2000);
        l_rel_hold_return_status     VARCHAR2(1);
        l_rel_hold_return_message    VARCHAR2(2000);
        l_po_upd_yn                  VARCHAR2(1);
        l_line_flow_status_code      VARCHAR2(100);
        l_line_number                NUMBER;
        l_release_hold_yn            VARCHAR2(1);
        l_hold_release_excep EXCEPTION;
    BEGIN
    
    
--Initialize header record to missing
        l_header_rec := oe_order_pub.g_miss_header_rec;
        l_header_rec.operation := oe_globals.g_opr_update;
        l_header_rec.header_id := p_so_header_id;
        
        
        IF p_so_header_rec.surgeon_account_number IS NOT NULL THEN
            BEGIN
                l_surgeon_account_id := NULL;
                print_debug('START OF Surgeon account number' || p_so_header_rec.surgeon_account_number);
                SELECT
                    cust_account_id
                INTO l_surgeon_account_id
                FROM
                    hz_cust_accounts  hca,
                    qp_list_headers_b qlb
                WHERE
                        hca.price_list_id = qlb.list_header_id (+)
                    AND account_number = p_so_header_rec.surgeon_account_number;

                print_debug('l_cust_account_id --> ' || l_surgeon_account_id);
                l_success_msg := l_success_msg || ' Surgeon Account has been updated, ';
            EXCEPTION
                WHEN OTHERS THEN
                    l_validation_status := 'E';
                    l_val_error_msg := l_val_error_msg
                                       || '...Error in fetching Surgeon account number -->'
                                       || sqlerrm;
                    RAISE l_data_valid_excep;
            END;
        END IF;

      -- l_header_rec.context :='GLOBAL';
        l_header_rec.attribute19 := l_surgeon_account_id;
        

        
         IF p_so_header_rec.case_start_date IS NOT NULL THEN
            SELECT
                fnd_date.date_to_canonical(p_so_header_rec.case_start_date)
            INTO l_header_rec.attribute18
            FROM
                dual;

            l_success_msg := l_success_msg || ' Case Start Date has been updated, ';
            print_debug('date to canonical update --> ' || l_header_rec.attribute18);
        END IF;
        
        IF p_so_header_rec.po_number IS NOT NULL THEN
            BEGIN
                print_debug('START OF Purchase Order validation-->' || p_so_header_rec.po_number);
                l_po_upd_yn := NULL;
                SELECT
                    decode(COUNT(1),
                           0,
                           'Y',
                           'N')
                INTO l_po_upd_yn
                FROM
                    oe_order_lines_all
                WHERE
                        1 = 1
                    AND header_id = p_so_header_id
                    AND flow_status_code NOT IN ( 'CANCELLED' )
                    AND flow_status_code <> 'FULFILLED';

                IF l_po_upd_yn = 'Y' THEN
                    print_debug('PO_UPD_YN-->' || l_po_upd_yn);
                    l_header_rec.cust_po_number := p_so_header_rec.po_number;
--               l_header_rec.cust_po_number := p_so_header_rec.po_number;
                    l_success_msg := l_success_msg || ' Purchase Order, ';
                    BEGIN
                        UPDATE oe_order_lines_all
                        SET
                            cust_po_number = p_so_header_rec.po_number
                        WHERE
                            header_id = p_so_header_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_validation_status := 'E';
                            l_val_error_msg := l_val_error_msg
                                               || '...Error in updating PO number at line level ->'
                                               || sqlerrm;
                            RAISE l_data_valid_excep;
                    END;

                ELSE
               --l_header_rec.cust_po_number := p_so_header_rec.po_number;
                    l_success_msg := l_success_msg || ' Purchase Order can not be updated as all the lines are not in FULFILLED status.'
                    ;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    l_validation_status := 'E';
                    l_val_error_msg := l_val_error_msg
                                       || '...Error in validating the Purchase Order -->'
                                       || sqlerrm;
                    RAISE l_data_valid_excep;
            END;
        END IF;

--This is to UPDATE order line.
-- As of 8/9/23. only unit selling was the requirement
        IF p_so_lines_tbl.count > 0 THEN
            FOR l_line_tbl_index IN p_so_lines_tbl.first..p_so_lines_tbl.last LOOP
                BEGIN
                    l_line_flow_status_code := NULL;
                    l_line_number := NULL;
                    SELECT
                        oola.flow_status_code,
                        oola.line_id
                    INTO
                        l_line_flow_status_code,
                        l_so_line_id
                    FROM
                        oe_order_lines_all   oola,
                        oe_order_headers_all ooha
                    WHERE
                            1 = 1
                        AND ooha.header_id = oola.header_id
                        AND oola.header_id = p_so_header_id
                        AND oola.line_number = p_so_lines_tbl(l_line_tbl_index).line_number
                        AND ooha.flow_status_code NOT IN ( 'CLOSED', 'CANCELLED' );

                EXCEPTION
                    WHEN OTHERS THEN
                        l_validation_status := 'E';
                        l_val_error_msg := l_val_error_msg
                                           || '...Error in fetching flow status code for the provided line number -->'
                                           || p_so_lines_tbl(l_line_tbl_index).line_number
                                           || '..'
                                           || sqlerrm;

                END;

                IF
                    l_po_upd_yn = 'Y'
                    AND l_line_flow_status_code = 'FULFILLED'
                THEN
                    l_line_tbl(l_line_tbl_idx) := oe_order_pub.g_miss_line_rec;
                    l_line_tbl(l_line_tbl_idx).operation := oe_globals.g_opr_update;
                    l_line_tbl(l_line_tbl_idx).line_id := l_so_line_id;
                    l_line_tbl(l_line_tbl_idx).change_reason := 'Not provided';
--               l_action_request_tbl(1).request_type := oe_globals.g_price_order;
--               l_action_request_tbl(1).entity_code := oe_globals.g_entity_header;
--               l_action_request_tbl(1).entity_id := p_so_header_id;
               --l_line_tbl(l_line_tbl_idx).cust_po_number := p_so_header_rec.po_number;
                    l_line_tbl_idx := l_line_tbl_idx + 1;
                ELSE
                    l_success_msg := l_success_msg
                                     || ' Line#  '
                                     || p_so_lines_tbl(l_line_tbl_index).line_number
                                     || '  Status -->'
                                     || l_line_flow_status_code;
                END IF;
                  /*
                  BEGIN
                     l_so_line_id := NULL;

         --               l_line_flow_status_code := NULL;
         --               l_line_number := NULL;
                     SELECT oola.line_id
         --                     ,oola.flow_status_code
         --                     ,oola.line_number
                     INTO   l_so_line_id
         --                     ,l_line_flow_status_code
         --                     ,l_line_number
                     FROM   oe_order_lines_all oola
                           ,oe_order_headers_all ooha
                      WHERE 1 = 1
                        AND ooha.header_id = oola.header_id
                        AND oola.header_id = p_so_header_id
                        AND oola.line_number = p_so_lines_tbl(l_line_tbl_index).line_number
                        AND ooha.flow_status_code NOT IN('CLOSED', 'CANCELLED')
                        AND oola.flow_status_code IN('FULFILLED')
                        AND (   (EXISTS(
                                    SELECT 1
                                      --           holds.header_id
                                      --      ,holds.line_id
                                      --      ,holds.org_id
                                      --      ,holds.hold_source_id
                                      --      ,holds.creation_date hold_creation_id
                                      --      ,ohsa.hold_id
                                      --      ,ohsa.hold_entity_id
                                      --      ,ohsa.hold_until_date
                                      --      ,ohsa.released_flag
                                      --      ,ohsa.hold_comment
                                      --      ,ohd.NAME hold_name
                                      --      ,ohd.type_code hold_type_code
                                      --      ,ohd.description hold_description
                                      --      ,ohd.start_date_active hold_start_date
                                    FROM   oe_order_holds_all holds
                                          ,oe_hold_sources_all ohsa
                                          ,oe_hold_definitions ohd
                                     --,oe_order_lines_all oola
                                    WHERE  holds.header_id = oola.header_id
                                       AND holds.line_id = oola.line_id
                                       AND holds.org_id = oola.org_id
                                       AND holds.released_flag = 'N'
                                       AND holds.hold_source_id = ohsa.hold_source_id
                                       AND ohsa.hold_id = ohd.hold_id
                                       AND ohd.NAME = 'Pricing Hold'))
                             OR (NOT EXISTS(
                                    SELECT 1
                                      FROM oe_order_holds_all holds
                                          ,oe_hold_sources_all ohsa
                                          ,oe_hold_definitions ohd
                                     WHERE holds.header_id = oola.header_id
                                       AND holds.line_id = oola.line_id
                                       AND holds.org_id = oola.org_id
                                       AND holds.hold_source_id = ohsa.hold_source_id
                                       AND ohsa.hold_id = ohd.hold_id
                                       AND ohd.NAME = 'Pricing Error Hold')))
                                                                             --ORDER BY OOLA.LINE_ID DESC
                     ;

                     print_debug('l_so_line_id --> ' || l_so_line_id);
                     -- l_line_tbl(l_line_tbl_idx).CUST_PO_NUMBER := p_so_header_rec.po_number;
                     l_success_msg := l_success_msg || ' line number#  ' || p_so_lines_tbl(l_line_tbl_index).line_number;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_validation_status := 'E';
                        l_val_error_msg :=
                              l_val_error_msg
                           || '...Error in fetching line id for the provided line number -->'
                           || p_so_lines_tbl(l_line_tbl_index).line_number
                           || '..'
                           || SQLERRM;
                  --  RAISE l_data_valid_excep; commented to proceed even if
                  END;

                  IF l_so_line_id IS NOT NULL
                  THEN
                     l_line_tbl(l_line_tbl_idx) := oe_order_pub.g_miss_line_rec;
                     -- Primary key of the entity i.e. the order line
                     l_line_tbl(l_line_tbl_idx).line_id := l_so_line_id;
                     l_line_tbl(l_line_tbl_idx).change_reason := 'Not provided';
                     -- Indicates to process order that this is an update operation
                     l_line_tbl(l_line_tbl_idx).operation := oe_globals.g_opr_update;

         --               IF l_po_upd_yn = 'Y'
         --               THEN
         --                  l_line_tbl(l_line_tbl_idx).cust_po_number := p_so_header_rec.po_number;
         --               ELSE
         --                  l_success_msg := l_success_msg || ' Line#  ' || l_line_number || '  Status -->' || l_line_flow_status_code;
         --               END IF;

                     --l_action_request_tbl(l_line_tbl_idx).request_type := oe_globals.G_PRICE_LINE;
         --      l_action_request_tbl(l_line_tbl_idx).entity_code := oe_globals.G_ENTITY_LINE;
         --     l_action_request_tbl(l_line_tbl_idx).entity_id := l_so_line_id;
                     IF p_so_lines_tbl(l_line_tbl_index).calculate_price_flag = 'Y'
                     THEN
                --Populate the Actions Table for Header
         --      l_action_request_tbl(l_line_tbl_idx).request_type := oe_globals.G_PRICE_LINE;
         --      l_action_request_tbl(l_line_tbl_idx).entity_code := oe_globals.G_ENTITY_LINE;
         --     l_action_request_tbl(l_line_tbl_idx).entity_id := l_so_line_id;
                        DBMS_OUTPUT.put_line('po header id  ' || p_so_header_id);
                        l_action_request_tbl(1).request_type := oe_globals.g_price_order;
                        l_action_request_tbl(1).entity_code := oe_globals.g_entity_header;
                        l_action_request_tbl(1).entity_id := p_so_header_id;
                        l_line_tbl(l_line_tbl_idx).calculate_price_flag := 'Y';
                        l_success_msg := l_success_msg || ' Re Price Line Y,  ';
                        DBMS_OUTPUT.put_line('price flag  ' || p_so_lines_tbl(l_line_tbl_index).calculate_price_flag);
                     ELSE
                        --l_line_tbl(l_line_tbl_idx).calculate_price_flag := 'N';
                        DBMS_OUTPUT.put_line('price flag N ' || p_so_lines_tbl(l_line_tbl_index).calculate_price_flag);

                        IF p_so_lines_tbl(l_line_tbl_index).case_price IS NOT NULL
                        THEN
                           l_line_tbl(l_line_tbl_idx).calculate_price_flag := 'N';
                           l_line_tbl(l_line_tbl_idx).unit_selling_price := p_so_lines_tbl(l_line_tbl_index).case_price;
                           l_success_msg := l_success_msg || ' Case Price ' || p_so_lines_tbl(l_line_tbl_index).case_price;
                        END IF;
                     END IF;

                     l_line_tbl_idx := l_line_tbl_idx + 1;
                  END IF;
                  */
            END LOOP;
        END IF;

        IF p_so_header_rec.po_number IS NOT NULL                                                                     --l_release_hold_yn = 'Y'

         THEN
            djooic_om_impbs_process_order_pkg.release_hold(p_header_id => l_header_rec.header_id, x_return_status => l_rel_hold_return_status
            , x_return_message => l_rel_hold_return_message);

            print_debug('release_hold status:' || l_rel_hold_return_status);
            print_debug('release_hold message:' || l_rel_hold_return_message);
            IF l_rel_hold_return_status != 'S' THEN
                RAISE l_hold_release_excep;
            END IF;
        END IF;
--        l_header_rec.attribute19 := l_surgeon_account_id;
       
-- CALL TO PROCESS ORDER Check the return status and then commit.
        dbms_output.put_line('Before seeded package process order in update sales order');
         print_debug('Before seeded package process order in update sales order' || l_header_rec.attribute18 || l_header_rec.attribute19);
        oe_order_pub.process_order(p_api_version_number          => 1.0
                                ,p_init_msg_list               => fnd_api.g_false
                                ,p_return_values               => fnd_api.g_false
                                ,p_action_commit               => fnd_api.g_false
                                ,x_return_status               => l_return_status
                                ,x_msg_count                   => l_msg_count
                                ,x_msg_data                    => l_msg_data
                                ,p_header_rec                  => l_header_rec
                                ,p_line_tbl                    => l_line_tbl
                                ,p_action_request_tbl          => l_action_request_tbl
                                -- OUT PARAMETERS
      ,                          x_header_rec                  => v_header_rec
                                ,x_header_val_rec              => x_header_val_rec
                                ,x_header_adj_tbl              => x_header_adj_tbl
                                ,x_header_adj_val_tbl          => x_header_adj_val_tbl
                                ,x_header_price_att_tbl        => x_header_price_att_tbl
                                ,x_header_adj_att_tbl          => x_header_adj_att_tbl
                                ,x_header_adj_assoc_tbl        => x_header_adj_assoc_tbl
                                ,x_header_scredit_tbl          => x_header_scredit_tbl
                                ,x_header_scredit_val_tbl      => x_header_scredit_val_tbl
                                ,x_line_tbl                    => lx_line_tbl
                                ,x_line_val_tbl                => x_line_val_tbl
                                ,x_line_adj_tbl                => x_line_adj_tbl
                                ,x_line_adj_val_tbl            => x_line_adj_val_tbl
                                ,x_line_price_att_tbl          => x_line_price_att_tbl
                                ,x_line_adj_att_tbl            => x_line_adj_att_tbl
                                ,x_line_adj_assoc_tbl          => x_line_adj_assoc_tbl
                                ,x_line_scredit_tbl            => x_line_scredit_tbl
                                ,x_line_scredit_val_tbl        => x_line_scredit_val_tbl
                                ,x_lot_serial_tbl              => x_lot_serial_tbl
                                ,x_lot_serial_val_tbl          => x_lot_serial_val_tbl
                                ,x_action_request_tbl          => lx_action_request_tbl);

-- Retrieve messages
        FOR i IN 1..l_msg_count LOOP
            oe_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => l_msg_data, p_msg_index_out => l_msg_index_out);

            print_debug('message is: ' || l_msg_data);
            print_debug('message index is: ' || l_msg_index_out);
        END LOOP;

-- Check the return status
        IF l_return_status = fnd_api.g_ret_sts_success THEN
            print_debug('Process Order Sucess');

         -- status should return E WHEN Purchase order number update is failed but others fields are updated.
            IF l_po_upd_yn <> 'Y' THEN
                x_return_status := 'E';
            ELSE
                x_return_status := l_return_status;
            END IF;

            IF l_validation_status = 'E' THEN
                x_return_message := l_success_msg || l_val_error_msg;
            ELSE
                x_return_message := l_success_msg || ' have been updated successfully';
            END IF;

            COMMIT;
            print_debug('COMMIT');
       -- Release hold only when Purchase Order Number is updated on Header and lines
      /* BEGIN
          l_release_hold_yn := NULL;

          SELECT DECODE(COUNT(1)
                       ,0, 'Y'
                       ,'N')
            INTO l_release_hold_yn
            FROM oe_order_lines_all
           WHERE 1 = 1
             AND header_id = p_so_header_id
             AND flow_status_code NOT IN('CANCELLED', 'CLOSED')
             AND cust_po_number IS NULL;
       EXCEPTION
          WHEN OTHERS
          THEN
             l_validation_status := 'E';
             l_val_error_msg :=
                   l_val_error_msg
                || '...Error in fetching flow status code for the provided line number -->'
                || p_so_lines_tbl(l_line_tbl_index).line_number
                || '..'
                || SQLERRM;
       END;

       IF l_release_hold_yn = 'Y'
       THEN
          djooic_om_impbs_process_order_pkg.release_hold(p_header_id           => l_header_rec.header_id
                                                        ,x_return_status       => l_rel_hold_return_status
                                                        ,x_return_message      => l_rel_hold_return_message);
          print_debug('release_hold status:' || l_rel_hold_return_status);
          print_debug('release_hold message:' || l_rel_hold_return_message);
          x_return_message :=
                x_return_message
             || 'Release hold Status --> '
             || l_rel_hold_return_status
             || 'Release hold message --> '
             || l_rel_hold_return_message;
       END IF;*/
        ELSE
            print_debug('Update Failed');
            x_return_status := 'E';

         --x_return_message := l_msg_data;
            IF l_validation_status = 'E' THEN
                x_return_message := l_msg_data
                                    || '+++++update failed++++++++-->'
                                    || l_val_error_msg;
            ELSE
                x_return_message := l_msg_data;
            END IF;

            ROLLBACK;
        END IF;

    EXCEPTION
        WHEN l_hold_release_excep THEN
            print_debug('Hold Relase Failed :');
            x_return_status := l_rel_hold_return_status;
            x_return_message := l_rel_hold_return_message;
        WHEN l_data_valid_excep THEN
            print_debug('Data validation failed.:');
            x_return_status := 'E';
            x_return_message := l_val_error_msg
                                || '...'
                                || dbms_utility.format_error_backtrace();
        WHEN OTHERS THEN
            l_error_msg := 'when others error: '
                           || sqlerrm
                           || '...'
                           || dbms_utility.format_error_backtrace();
            print_debug(l_error_msg);
            x_return_status := 'E';
            x_return_message := l_error_msg;
    END update_so;

    PROCEDURE create_ref_rma (
        p_so_header_rec  IN oe_order_pub.header_rec_type,
        p_so_lines_tbl   IN oe_order_pub.line_tbl_type,
        p_x_header_rec   OUT oe_order_pub.header_rec_type,
        p_x_line_tbl     OUT oe_order_pub.line_tbl_type,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) AS

        l_session_id             NUMBER;
        l_user_id                NUMBER := 127055;
        l_responsibility_id      NUMBER := 21623;
        l_resp_appl_id           NUMBER := 660;
        l_count                  NUMBER;
        l_msg_count              NUMBER := 0;
        x_cnt                    NUMBER := 3;
        l_return_status          VARCHAR2(1);
        l_msg_data               VARCHAR2(2000);
        x_msg_data               VARCHAR2(2000);
        x_msg_details            VARCHAR2(2000);
        x_msg_count              VARCHAR2(2000);
        msg_text                 VARCHAR2(2000) DEFAULT NULL;
        l_org_id                 NUMBER;
        l_cust_account_id        NUMBER;
        l_party_id               NUMBER;
        l_price_list_id          NUMBER;
        l_currency_code          VARCHAR2(10);
        l_transaction_type_id    NUMBER;
        l_order_category_code    VARCHAR2(20);
        party_id                 NUMBER;
        price_list_id            NUMBER;
        currency_code            VARCHAR2(20);
        l_header_rec             oe_order_pub.header_rec_type;
        l_header_val_rec         oe_order_pub.header_val_rec_type;
        l_header_adj_tbl         oe_order_pub.header_adj_tbl_type;
        l_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type;
        l_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type;
        l_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type;
        l_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type;
        l_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type;
        l_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type;
        l_line_tbl               oe_order_pub.line_tbl_type;
        l_line_val_tbl           oe_order_pub.line_val_tbl_type;
        l_line_adj_tbl           oe_order_pub.line_adj_tbl_type;
        l_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type;
        l_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type;
        l_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type;
        l_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type;
        l_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type;
        l_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type;
        l_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type;
        l_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type;
        l_action_request_tbl     oe_order_pub.request_tbl_type;
        o_header_val_rec         oe_order_pub.header_val_rec_type;
        o_header_adj_tbl         oe_order_pub.header_adj_tbl_type;
        o_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type;
        o_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type;
        o_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type;
        o_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type;
        o_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type;
        o_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type;
        o_header_payment_tbl     oe_order_pub.header_payment_tbl_type;
        o_line_val_tbl           oe_order_pub.line_val_tbl_type;
        o_line_adj_tbl           oe_order_pub.line_adj_tbl_type;
        o_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type;
        o_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type;
        o_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type;
        o_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type;
        o_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type;
        o_line_payment_tbl       oe_order_pub.line_payment_tbl_type;
        o_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type;
        o_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type;
        o_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type;
        o_action_request_tbl     oe_order_pub.request_tbl_type;
        l_payment_term_id        NUMBER;
        l_line_type_id           NUMBER;
        dbg_file                 VARCHAR2(1024);
        l_line_tbl_index         NUMBER;
        l_error_msg              VARCHAR2(2000);
    BEGIN
/*
   oe_debug_pub.initialize;
   oe_debug_pub.debug_on;
   oe_debug_pub.setdebuglevel(5);
   dbg_file := oe_debug_pub.set_debug_mode('FILE');
   DBMS_OUTPUT.put_line('The debug file is : ' || oe_debug_pub.g_dir || '/' || oe_debug_pub.g_file);
   fnd_global.apps_initialize(user_id           => l_user_id
                             ,resp_id           => l_responsibility_id
                             ,resp_appl_id      => l_resp_appl_id);
   mo_global.init('ONT');                                                                                                -- Required for R12
   mo_global.set_policy_context('S', 81);
   oe_msg_pub.initialize;
   */

      --    BEGIN
--         SELECT a.operating_unit
--                /*a.organization_id, a.organization_code, a.organization_name,
--           a.operating_unit, b.name OU, a.set_of_books_id,d.name LEDGER,
--           a.legal_entity,c.name LE_NAME*/
--         INTO   l_org_id
--           FROM apps.org_organization_definitions a
--               ,apps.hr_operating_units b
--               ,apps.xle_entity_profiles c
--               ,apps.gl_ledgers d
--          WHERE a.operating_unit = b.organization_id
--            AND c.legal_entity_id = a.legal_entity
--            AND d.ledger_id = a.set_of_books_id
--            AND a.organization_code = p_so_header_rec.inv_org_code;
--
--         print_debug('l_org_id --> ' || l_org_id);
--      EXCEPTION
--         WHEN OTHERS THEN
--            l_org_id := NULL;
--            l_return_status := 'E';
--            l_msg_data := '...' || l_msg_data || '...' || 'Error in fetching Org id from inventory org code -->' || SQLERRM;
--      END;
--
--       SELECT cust_account_id
--               ,party_id
--               ,hca.price_list_id
--               ,qlb.currency_code
--           INTO l_cust_account_id
--               ,l_party_id
--               ,l_price_list_id
--               ,l_currency_code
--           FROM hz_cust_accounts hca
--               ,qp_list_headers_b qlb
--          WHERE hca.price_list_id = qlb.list_header_id(+)
--            AND account_number = p_so_header_rec.hospital_account_number;
--
--            SELECT ott.transaction_type_id
--               ,ott.order_category_code
--           INTO l_transaction_type_id
--               ,l_order_category_code
--           FROM oe_transaction_types_all ott
--               ,oe_transaction_types_tl ottl
--          WHERE 1 = 1
--            AND ott.transaction_type_id = ottl.transaction_type_id
--            AND ottl.LANGUAGE = USERENV('LANG')
--            AND ott.org_id = l_org_id                      --AND ottl.NAME IN ('AUS RETURN ORDER','AUS STANDARD ORDER', 'DJO BILL ONLY LINE'
--            AND ottl.NAME = p_so_header_rec.order_type
--            AND ott.transaction_type_code = 'ORDER';
--
--                   SELECT cust_account_id
--               ,party_id
--               ,hca.price_list_id
--               ,qlb.currency_code
--           INTO l_cust_account_id
--               ,l_party_id
--               ,l_price_list_id
--               ,l_currency_code
--           FROM hz_cust_accounts hca
--               ,qp_list_headers_b qlb
--          WHERE hca.price_list_id = qlb.list_header_id(+)
--            AND account_number = p_so_header_rec.hospital_account_number;
--==================================================================================================
-- Order Header Information
--==================================================================================================
        l_header_rec := oe_order_pub.g_miss_header_rec;
        l_header_rec.operation := oe_globals.g_opr_create;                                                                 --Create operation
--      l_header_rec.org_id := l_org_id;--p_so_header_rec.org_id;
--      l_header_rec.sold_to_org_id := l_cust_account_id;--p_so_header_rec.sold_to_org_id;                                                                 --1006
--      l_header_rec.payment_term_id := 1000;--p_so_header_rec.payment_term_id;                                                               --1000
--      l_header_rec.order_type_id := l_transaction_type_id;--p_so_header_rec.order_type_id;                                                                   --1436
--      l_header_rec.price_list_id := l_price_list_id;--p_so_header_rec.price_list_id;                                                                   --1000
--      l_header_rec.transactional_curr_code := l_currency_code;--p_so_header_rec.transactional_curr_code;                                                --USD
        l_header_rec.org_id := p_so_header_rec.org_id;
        l_header_rec.sold_to_org_id := p_so_header_rec.sold_to_org_id;                                                                 --1006
        l_header_rec.payment_term_id := p_so_header_rec.payment_term_id;                                                               --1000
        l_header_rec.order_type_id := p_so_header_rec.order_type_id;                                                                   --1436
        l_header_rec.price_list_id := p_so_header_rec.price_list_id;                                                                   --1000
        l_header_rec.transactional_curr_code := p_so_header_rec.transactional_curr_code;
        print_debug('l_header_rec.org_id --> ' || l_header_rec.org_id);
        print_debug('l_header_rec.sold_to_org_id --> ' || l_header_rec.sold_to_org_id);
        print_debug('l_header_rec.payment_term_id --> ' || l_header_rec.payment_term_id);
        print_debug('l_header_rec.order_type_id --> ' || l_header_rec.order_type_id);
        print_debug('l_header_rec.price_list_id --> ' || l_header_rec.price_list_id);
        print_debug('l_header_rec.transactional_curr_code --> ' || l_header_rec.transactional_curr_code);

--==================================================================================================
-- Order Line Create Information
--==================================================================================================
        IF p_so_lines_tbl.count > 0 THEN
            FOR l_line_tbl_index IN p_so_lines_tbl.first..p_so_lines_tbl.last LOOP
                print_debug('LINES TABLE COUNTER --> ' || l_line_tbl_index);
                l_line_tbl(l_line_tbl_index) := oe_order_pub.g_miss_line_rec;
                l_line_tbl(l_line_tbl_index).operation := oe_globals.g_opr_create;                                           --Create operation
                l_line_tbl(l_line_tbl_index).ordered_quantity := p_so_lines_tbl(l_line_tbl_index).ordered_quantity;
                l_line_tbl(l_line_tbl_index).return_context := p_so_lines_tbl(l_line_tbl_index).return_context;                      --'ORDER';
                l_line_tbl(l_line_tbl_index).return_attribute1 := p_so_lines_tbl(l_line_tbl_index).return_attribute1;
            -- Original Order Header ID against which RMA is being created
                l_line_tbl(l_line_tbl_index).return_attribute2 := p_so_lines_tbl(l_line_tbl_index).return_attribute2;
            -- Original Order Line ID against which RMA is being created
                l_line_tbl(l_line_tbl_index).return_reason_code := p_so_lines_tbl(l_line_tbl_index).return_reason_code;
                l_line_tbl(l_line_tbl_index).line_type_id := p_so_lines_tbl(l_line_tbl_index).line_type_id;
                print_debug('l_line_tbl(l_line_tbl_index).ordered_quantity --> ' || l_line_tbl(l_line_tbl_index).ordered_quantity);
                print_debug('l_line_tbl(l_line_tbl_index).return_context --> ' || l_line_tbl(l_line_tbl_index).return_context);
                print_debug('l_line_tbl(l_line_tbl_index).return_attribute1 --> ' || l_line_tbl(l_line_tbl_index).return_attribute1);
                print_debug('l_line_tbl(l_line_tbl_index).return_attribute2 --> ' || l_line_tbl(l_line_tbl_index).return_attribute2);
                print_debug('l_line_tbl(l_line_tbl_index).return_reason_code --> ' || l_line_tbl(l_line_tbl_index).return_reason_code
                );
                print_debug('l_line_tbl(l_line_tbl_index).line_type_id --> ' || l_line_tbl(l_line_tbl_index).line_type_id);
            END LOOP;
        END IF;

--==================================================================================================
-- Calling Process Order API
--==================================================================================================
        dbms_output.put_line('Calling Process Order.....');
        oe_order_pvt.process_order(p_api_version_number => 1.0, x_return_status => l_return_status, x_msg_count => l_msg_count, x_msg_data => l_msg_data
        , p_x_header_rec => l_header_rec,
                                  p_x_header_adj_tbl => o_header_adj_tbl, p_x_header_price_att_tbl => o_header_price_att_tbl, p_x_header_adj_att_tbl => o_header_adj_att_tbl
                                  , p_x_header_adj_assoc_tbl => o_header_adj_assoc_tbl, p_x_header_scredit_tbl => o_header_scredit_tbl
                                  ,
                                  p_x_line_tbl => l_line_tbl, p_x_line_adj_tbl => o_line_adj_tbl, p_x_line_price_att_tbl => o_line_price_att_tbl
                                  , p_x_line_adj_att_tbl => o_line_adj_att_tbl, p_x_line_adj_assoc_tbl => o_line_adj_assoc_tbl,
                                  p_x_line_scredit_tbl => o_line_scredit_tbl, p_x_lot_serial_tbl => o_lot_serial_tbl, p_lot_serial_val_tbl => o_lot_serial_val_tbl
                                  , p_x_action_request_tbl => l_action_request_tbl);

        dbms_output.put_line('l_msg_count :' || nvl(l_msg_count, 0));
        IF l_msg_count > 0 THEN
            FOR i IN 1..l_msg_count LOOP
                l_msg_data := oe_msg_pub.get(p_msg_index => i, p_encoded => 'F');
                dbms_output.put_line('MESSAGE : '
                                     || substrb(l_msg_data, 1, 200));
            END LOOP;
        END IF;

        IF l_return_status = fnd_api.g_ret_sts_success THEN
            print_debug('SUCCESS');
            COMMIT;
            print_debug('ORDER_NUMBER : ' || l_header_rec.order_number);
            print_debug('HEADER_ID : ' || l_header_rec.header_id);
            print_debug('ORG_ID : ' || l_header_rec.org_id);
            l_count := l_line_tbl.last;
            IF l_count > 0 THEN
                FOR l_index IN 1..l_count LOOP
                    print_debug('LINE_ID('
                                || l_index
                                || ') : '
                                || l_line_tbl(l_index).line_id);

                    print_debug('ORDERED_QUANTITY('
                                || l_index
                                || ') : '
                                || l_line_tbl(l_index).ordered_quantity);

                    print_debug('ORDER_QUANTITY_UOM('
                                || l_index
                                || ') : '
                                || l_line_tbl(l_index).order_quantity_uom);

                    print_debug('PRICING_QUANTITY('
                                || l_index
                                || ') : '
                                || l_line_tbl(l_index).pricing_quantity);

                    print_debug('PRICING_QUANTITY_UOM('
                                || l_index
                                || ') : '
                                || l_line_tbl(l_index).pricing_quantity_uom);

                END LOOP;
            END IF;

            x_return_status := l_return_status;
            x_return_message := 'Create referenced RMA SUCCESS..' || l_msg_data;
            p_x_header_rec := l_header_rec;
            p_x_line_tbl := l_line_tbl;
        ELSE
            print_debug('FAILURE');
            print_debug('RETURN STATUS = ' || l_return_status);
            print_debug('ORDER_NUMBER : ' || l_header_rec.order_number);
            x_return_status := l_return_status;
            x_return_message := 'Create referenced RMA Failed..' || l_msg_data;
            p_x_header_rec := l_header_rec;
            p_x_line_tbl := l_line_tbl;
            ROLLBACK;
        END IF;

        oe_debug_pub.debug_off;
    EXCEPTION
        WHEN OTHERS THEN
            l_error_msg := 'create_ref_rma when others error: '
                           || sqlerrm
                           || '...'
                           || dbms_utility.format_error_backtrace();
            print_debug(l_error_msg);
            x_return_status := 'E';
            x_return_message := l_error_msg;
            p_x_header_rec := l_header_rec;
            p_x_line_tbl := l_line_tbl;
    END create_ref_rma;

   --++++++++++++++++++++++++++++
-- updating price on sales order lines from given case prices. it will be invoked from create_order
--++++++++++++++++++++++++++++
    PROCEDURE update_so_line_price (
        p_so_header_id   IN NUMBER,
        p_so_lines_tbl   IN djooic_om_impbs_line_tbl,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) AS

        l_header_rec                 oe_order_pub.header_rec_type;
        lx_header_rec                oe_order_pub.header_rec_type;
        l_line_tbl                   oe_order_pub.line_tbl_type;
        lx_line_tbl                  oe_order_pub.line_tbl_type;
        l_action_request_tbl         oe_order_pub.request_tbl_type;
        lx_action_request_tbl        oe_order_pub.request_tbl_type;
        l_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
        l_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
        l_header_scr_tbl             oe_order_pub.header_scredit_tbl_type;
        l_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
        l_request_rec                oe_order_pub.request_rec_type;
        l_return_status              VARCHAR2(1000);
        l_msg_count                  NUMBER;
        l_msg_data                   VARCHAR2(1000);
        p_api_version_number         NUMBER := 1.0;
        p_init_msg_list              VARCHAR2(10) := fnd_api.g_false;
        p_return_values              VARCHAR2(10) := fnd_api.g_false;
        p_action_commit              VARCHAR2(10) := fnd_api.g_false;
      --x_return_status                VARCHAR2(1);
        l_error_msg                  VARCHAR2(2000);
        x_msg_count                  NUMBER;
        x_msg_data                   VARCHAR2(100);
        p_header_rec                 oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
        p_old_header_rec             oe_order_pub.header_rec_type := oe_order_pub.g_miss_header_rec;
        p_header_val_rec             oe_order_pub.header_val_rec_type := oe_order_pub.g_miss_header_val_rec;
        p_old_header_val_rec         oe_order_pub.header_val_rec_type := oe_order_pub.g_miss_header_val_rec;
        p_header_adj_tbl             oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
        p_old_header_adj_tbl         oe_order_pub.header_adj_tbl_type := oe_order_pub.g_miss_header_adj_tbl;
        p_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type := oe_order_pub.g_miss_header_adj_val_tbl;
        p_old_header_adj_val_tbl     oe_order_pub.header_adj_val_tbl_type := oe_order_pub.g_miss_header_adj_val_tbl;
        p_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
        p_old_header_price_att_tbl   oe_order_pub.header_price_att_tbl_type := oe_order_pub.g_miss_header_price_att_tbl;
        p_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
        p_old_header_adj_att_tbl     oe_order_pub.header_adj_att_tbl_type := oe_order_pub.g_miss_header_adj_att_tbl;
        p_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
        p_old_header_adj_assoc_tbl   oe_order_pub.header_adj_assoc_tbl_type := oe_order_pub.g_miss_header_adj_assoc_tbl;
        p_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
        p_old_header_scredit_tbl     oe_order_pub.header_scredit_tbl_type := oe_order_pub.g_miss_header_scredit_tbl;
        p_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type := oe_order_pub.g_miss_header_scredit_val_tbl;
        p_old_header_scredit_val_tbl oe_order_pub.header_scredit_val_tbl_type := oe_order_pub.g_miss_header_scredit_val_tbl;
        p_line_tbl                   oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
        p_old_line_tbl               oe_order_pub.line_tbl_type := oe_order_pub.g_miss_line_tbl;
        p_line_val_tbl               oe_order_pub.line_val_tbl_type := oe_order_pub.g_miss_line_val_tbl;
        p_old_line_val_tbl           oe_order_pub.line_val_tbl_type := oe_order_pub.g_miss_line_val_tbl;
        p_line_adj_tbl               oe_order_pub.line_adj_tbl_type := oe_order_pub.g_miss_line_adj_tbl;
        p_old_line_adj_tbl           oe_order_pub.line_adj_tbl_type := oe_order_pub.g_miss_line_adj_tbl;
        p_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type := oe_order_pub.g_miss_line_adj_val_tbl;
        p_old_line_adj_val_tbl       oe_order_pub.line_adj_val_tbl_type := oe_order_pub.g_miss_line_adj_val_tbl;
        p_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
        p_old_line_price_att_tbl     oe_order_pub.line_price_att_tbl_type := oe_order_pub.g_miss_line_price_att_tbl;
        p_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
        p_old_line_adj_att_tbl       oe_order_pub.line_adj_att_tbl_type := oe_order_pub.g_miss_line_adj_att_tbl;
        p_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
        p_old_line_adj_assoc_tbl     oe_order_pub.line_adj_assoc_tbl_type := oe_order_pub.g_miss_line_adj_assoc_tbl;
        p_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
        p_old_line_scredit_tbl       oe_order_pub.line_scredit_tbl_type := oe_order_pub.g_miss_line_scredit_tbl;
        p_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type := oe_order_pub.g_miss_line_scredit_val_tbl;
        p_old_line_scredit_val_tbl   oe_order_pub.line_scredit_val_tbl_type := oe_order_pub.g_miss_line_scredit_val_tbl;
        p_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
        p_old_lot_serial_tbl         oe_order_pub.lot_serial_tbl_type := oe_order_pub.g_miss_lot_serial_tbl;
        p_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type := oe_order_pub.g_miss_lot_serial_val_tbl;
        p_old_lot_serial_val_tbl     oe_order_pub.lot_serial_val_tbl_type := oe_order_pub.g_miss_lot_serial_val_tbl;
        p_action_request_tbl         oe_order_pub.request_tbl_type := oe_order_pub.g_miss_request_tbl;
        x_header_val_rec             oe_order_pub.header_val_rec_type;
        x_header_adj_tbl             oe_order_pub.header_adj_tbl_type;
        x_header_adj_val_tbl         oe_order_pub.header_adj_val_tbl_type;
        x_header_price_att_tbl       oe_order_pub.header_price_att_tbl_type;
        x_header_adj_att_tbl         oe_order_pub.header_adj_att_tbl_type;
        x_header_adj_assoc_tbl       oe_order_pub.header_adj_assoc_tbl_type;
        x_header_scredit_tbl         oe_order_pub.header_scredit_tbl_type;
        x_header_scredit_val_tbl     oe_order_pub.header_scredit_val_tbl_type;
        x_line_val_tbl               oe_order_pub.line_val_tbl_type;
        x_line_adj_tbl               oe_order_pub.line_adj_tbl_type;
        x_line_adj_val_tbl           oe_order_pub.line_adj_val_tbl_type;
        x_line_price_att_tbl         oe_order_pub.line_price_att_tbl_type;
        x_line_adj_att_tbl           oe_order_pub.line_adj_att_tbl_type;
        x_line_adj_assoc_tbl         oe_order_pub.line_adj_assoc_tbl_type;
        x_line_scredit_tbl           oe_order_pub.line_scredit_tbl_type;
        x_line_scredit_val_tbl       oe_order_pub.line_scredit_val_tbl_type;
        x_lot_serial_tbl             oe_order_pub.lot_serial_tbl_type;
        x_lot_serial_val_tbl         oe_order_pub.lot_serial_val_tbl_type;
        x_action_request_tbl         oe_order_pub.request_tbl_type;
        x_debug_file                 VARCHAR2(100);
        l_line_tbl_index             NUMBER;
        l_line_tbl_idx               NUMBER := 1;
        l_msg_index_out              NUMBER(10);
        l_data_valid_excep EXCEPTION;
        l_surgeon_account_id         NUMBER;
        l_validation_status          VARCHAR2(10);
        l_val_error_msg              VARCHAR2(2000);
        l_so_line_id                 NUMBER;
        l_so_lines_tbl               djooic_om_impbs_line_tbl;
        l_success_msg                VARCHAR2(2000);
        l_list_header_id             NUMBER;
        l_list_line_id               NUMBER;
        l_pricing_phase_id           NUMBER;
        l_price_adjustment_id        NUMBER;
        l_unit_sell_price            NUMBER;
    BEGIN
--Initialize header record to missing
        l_header_rec := oe_order_pub.g_miss_header_rec;
        l_header_rec.operation := oe_globals.g_opr_update;
        l_header_rec.header_id := p_so_header_id;

--This is to UPDATE order line.
-- only unit selling was the requirement
        IF p_so_lines_tbl.count > 0 THEN
            FOR l_line_tbl_index IN p_so_lines_tbl.first..p_so_lines_tbl.last LOOP
                IF
                    p_so_lines_tbl(l_line_tbl_index).calculate_price_flag = 'N'
                    AND p_so_lines_tbl(l_line_tbl_index).case_price IS NOT NULL
                THEN
                    print_debug('Number of lines --> ' || p_so_lines_tbl.count);
                    BEGIN
                        l_so_line_id := NULL;
                        SELECT
                            line_id,
                            unit_selling_price
                        INTO
                            l_so_line_id,
                            l_unit_sell_price
                        FROM
                            oe_order_lines_all   oola,
                            oe_order_headers_all ooha
                        WHERE
                                1 = 1
                            AND ooha.header_id = oola.header_id
                            AND oola.header_id = p_so_header_id
                            AND oola.line_number = p_so_lines_tbl(l_line_tbl_index).line_number;

                        print_debug('l_so_line_id --> ' || l_so_line_id);
                        l_success_msg := l_success_msg
                                         || ' line number#  '
                                         || p_so_lines_tbl(l_line_tbl_index).line_number;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_validation_status := 'E';
                            l_val_error_msg := l_val_error_msg
                                               || '...Error in fetching line id for the provided line number -->'
                                               || p_so_lines_tbl(l_line_tbl_index).line_number
                                               || '..'
                                               || sqlerrm;

                    END;

                    IF l_so_line_id IS NOT NULL THEN
                        l_line_tbl(l_line_tbl_idx) := oe_order_pub.g_miss_line_rec;
                        l_line_tbl(l_line_tbl_idx).operation := oe_globals.g_opr_update;
                        l_line_tbl(l_line_tbl_idx).line_id := l_so_line_id;
                  --  l_line_tbl(l_line_tbl_idx).change_reason := 'Not provided';
                  --  l_line_tbl(l_line_tbl_idx).unit_selling_price := p_so_lines_tbl(l_line_tbl_index).case_price;
                    -- l_action_request_tbl(1).request_type := oe_globals.g_price_order;
                     --l_action_request_tbl(1).entity_code := oe_globals.g_entity_header;
                     --l_action_request_tbl(1).entity_id := p_so_header_id;
                        l_line_tbl_idx := l_line_tbl_idx + 1;
                    END IF;

--++++++++++++++++++++++++++++++++
--
--++++++++++++++++++++++++++++++++
                    BEGIN
                        l_list_header_id := 158270;
                        l_list_line_id := 397792;
                        l_pricing_phase_id := 2;
                        l_price_adjustment_id := NULL;
                  /* SELECT list_header_id
                         ,list_line_id
                         ,pricing_phase_id
                         ,price_adjustment_id
                     INTO l_list_header_id
                         ,l_list_line_id
                         ,l_pricing_phase_id
                         ,l_price_adjustment_id
                     FROM oe_price_adjustments
                    WHERE header_id = p_so_header_id
                      AND line_id = l_so_line_id
                      AND change_reason_code = 'MANUAL'
                      AND price_adjustment_id =
                                              (SELECT MAX(price_adjustment_id)
                                                 FROM oe_price_adjustments
                                                WHERE header_id = p_so_header_id
                                                  AND line_id = l_so_line_id
                                                  AND change_reason_code = 'MANUAL');*/

                  --                  print_debug('l_PRICE_ADJUSTMENT_ID --> ' || l_price_adjustment_id);
                        l_success_msg := l_success_msg
                                         || ' line number#  '
                                         || p_so_lines_tbl(l_line_tbl_index).line_number;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_validation_status := 'E';
                            l_val_error_msg := l_val_error_msg
                                               || '...Error in fetching list line id for line number-->'
                                               || p_so_lines_tbl(l_line_tbl_index).line_number
                                               || '..'
                                               || sqlerrm;

                    END;

                    l_line_adj_tbl(l_line_tbl_idx) := oe_order_pub.g_miss_line_adj_rec;
                    l_line_adj_tbl(l_line_tbl_idx).operation := oe_globals.g_opr_create;
                    l_line_adj_tbl(l_line_tbl_idx).header_id := p_so_header_id;                                    --header_id of the sales order
                    l_line_adj_tbl(l_line_tbl_idx).line_id := l_so_line_id;
                    l_line_adj_tbl(l_line_tbl_idx).list_header_id := l_list_header_id;
                    l_line_adj_tbl(l_line_tbl_idx).list_line_id := l_list_line_id;
                    l_line_adj_tbl(l_line_tbl_idx).line_index := 1;
                    l_line_adj_tbl(l_line_tbl_idx).change_reason_code := 'MANUAL';
                    l_line_adj_tbl(l_line_tbl_idx).change_reason_text := 'Manually applied adjustments';
                    l_line_adj_tbl(l_line_tbl_idx).operand := ( l_unit_sell_price - p_so_lines_tbl(l_line_tbl_index).case_price );
               --l_line_adj_tbl_line_tbl_idx(1).operand := 10;
                    l_line_adj_tbl(l_line_tbl_idx).list_line_type_code := 'DIS';
                    l_line_adj_tbl(l_line_tbl_idx).arithmetic_operator := 'AMT';
                    l_line_adj_tbl(l_line_tbl_idx).pricing_phase_id := l_pricing_phase_id;
                    l_line_adj_tbl(l_line_tbl_idx).updated_flag := 'Y';
                    l_line_adj_tbl(l_line_tbl_idx).applied_flag := 'Y';
--*********************************
                END IF;
            END LOOP;
        END IF;

        IF l_validation_status = 'E' THEN
            RAISE l_data_valid_excep;
        END IF;

-- CALL TO PROCESS ORDER Check the return status and then commit.
        IF l_line_tbl.count > 0 THEN
            dbms_output.put_line('Before seeded package process order in update sales order');
            oe_order_pub.process_order(p_api_version_number => 1.0, p_init_msg_list => fnd_api.g_false, p_return_values => fnd_api.g_false
            , p_action_commit => fnd_api.g_false, x_return_status => l_return_status,
                                      x_msg_count => l_msg_count, x_msg_data => l_msg_data, p_header_rec => l_header_rec, p_line_tbl => l_line_tbl
                                      , p_line_adj_tbl => l_line_adj_tbl,
                                      p_action_request_tbl => l_action_request_tbl
                                   -- OUT PARAMETERS
                                      , x_header_rec => lx_header_rec, x_header_val_rec => x_header_val_rec, x_header_adj_tbl => x_header_adj_tbl
                                      , x_header_adj_val_tbl => x_header_adj_val_tbl,
                                      x_header_price_att_tbl => x_header_price_att_tbl, x_header_adj_att_tbl => x_header_adj_att_tbl,
                                      x_header_adj_assoc_tbl => x_header_adj_assoc_tbl, x_header_scredit_tbl => x_header_scredit_tbl,
                                      x_header_scredit_val_tbl => x_header_scredit_val_tbl,
                                      x_line_tbl => lx_line_tbl, x_line_val_tbl => x_line_val_tbl, x_line_adj_tbl => x_line_adj_tbl, x_line_adj_val_tbl => x_line_adj_val_tbl
                                      , x_line_price_att_tbl => x_line_price_att_tbl,
                                      x_line_adj_att_tbl => x_line_adj_att_tbl, x_line_adj_assoc_tbl => x_line_adj_assoc_tbl, x_line_scredit_tbl => x_line_scredit_tbl
                                      , x_line_scredit_val_tbl => x_line_scredit_val_tbl, x_lot_serial_tbl => x_lot_serial_tbl,
                                      x_lot_serial_val_tbl => x_lot_serial_val_tbl, x_action_request_tbl => lx_action_request_tbl);

-- Retrieve messages
            FOR i IN 1..l_msg_count LOOP
                oe_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => l_msg_data, p_msg_index_out => l_msg_index_out
                );

                print_debug('message is: ' || l_msg_data);
                print_debug('message index is: ' || l_msg_index_out);
            END LOOP;

-- Check the return status
            IF l_return_status = fnd_api.g_ret_sts_success THEN
                print_debug('Process Order Sucess');
                x_return_status := l_return_status;
                COMMIT;
            ELSE
                print_debug('Update Failed');
                x_return_status := nvl(l_return_status, 'E');
                x_return_message := 'Update Failed';
                ROLLBACK;
            END IF;

        ELSE
            print_debug('No eligle lines to update price ');
            x_return_status := 'S';
        END IF;

    EXCEPTION
        WHEN l_data_valid_excep THEN
            print_debug('Data validation failed in update_so_line_price.:');
            x_return_status := 'E';
            x_return_message := l_val_error_msg
                                || '...'
                                || dbms_utility.format_error_backtrace();
        WHEN OTHERS THEN
            l_error_msg := 'when others error: '
                           || sqlerrm
                           || '...'
                           || dbms_utility.format_error_backtrace();
            print_debug(l_error_msg);
            x_return_status := 'E';
            x_return_message := l_error_msg;
    END update_so_line_price;

--++++++++++++++++++++++++++++

   -- Create sales Order
--++++++++++++++++++++++++++++
    PROCEDURE create_order (
        p_header_rec     IN djooic_om_impbs_header_rec,
        p_lines_tbl      IN djooic_om_impbs_line_tbl,
        x_order_rec      OUT order_rec_type,
        x_transaction_id OUT NUMBER,
        x_return_status  OUT NOCOPY VARCHAR2,
        x_return_message OUT NOCOPY VARCHAR2
    ) AS

        l_username                  VARCHAR2(40);
        l_responsibility            VARCHAR2(240);
        l_application_name          VARCHAR2(240);
        l_data_valid_excep EXCEPTION;
        l_apps_init_execp EXCEPTION;
        lx_init_status              VARCHAR2(10);
        lx_init_message             VARCHAR2(2000);
        l_error_msg                 VARCHAR2(2400);
        l_transaction_id            NUMBER;
        l_org_id                    NUMBER;
        l_userenv_lang              VARCHAR2(100);
        l_master_org_code           VARCHAR2(10) := 'AUS';
        l_commit                    VARCHAR2(1);
        l_instance_name             v$instance.instance_name%TYPE;
        l_process_order_rec         djooic_om_impbs_process_order_stg%rowtype;
      --
        l_validation_status         VARCHAR2(1) := 'S';
        l_val_error_msg             VARCHAR2(2400);
        --
      --  l_ib_header_rec              header_rec_type;
       -- l_ib_lines_tbl               line_tbl_type;
       -- lx_ib_lines_tbl              line_tbl_type;
        --
        l_cust_account_id           NUMBER;
        l_party_id                  NUMBER;
        l_price_list_id             NUMBER;
        l_invoice_to_party_site_id  NUMBER;
        lx_party_site_id            NUMBER;
        lx_shipto_party_site_id     NUMBER;
        lx_shipto_contact_point_id  NUMBER;
        lx_return_status            VARCHAR2(1);
        lx_return_message           VARCHAR2(1000);
        lx_deliver_to_party_site_id NUMBER;
        lxd_return_status           VARCHAR2(1);
        lxd_return_message          VARCHAR2(1000);
        l_shipto_cust_account_id    NUMBER;
        l_shipto_party_site_id      NUMBER;
        l_ship_cust_acct_site_id    NUMBER;
        l_surgeon_account_id        NUMBER;
        l_payment_terms_id          NUMBER;
        l_transaction_type_id       NUMBER;
        l_order_category_code       oe_transaction_types_all.order_category_code%TYPE;
        l_price_list                qp_list_headers.name%TYPE;
        l_currency_code             VARCHAR2(4);
        l_inventory_item_id         NUMBER;
        l_inventory_org_id          NUMBER;
        l_order_total_amount        NUMBER;
        l_so_basic_tot              NUMBER;
        l_so_discount               NUMBER;
        l_so_charges                NUMBER;
        l_so_tax                    NUMBER;
        l_line_type_id              NUMBER;
        l_line_type_category_code   oe_transaction_types_all.order_category_code%TYPE;
        l_order_source_id           NUMBER;
        lx_order_rec                djooic_om_impbs_process_order_pkg.order_rec_type := djooic_om_impbs_process_order_pkg.g_miss_order_rec
        ;
     --++++++++++++++++++++++++'
-- OE ORDER PUB variables
--+++++++++++++++++++
        l_header_rec                oe_order_pub.header_rec_type;
        l_x_header_rec              oe_order_pub.header_rec_type;
        l_line_tbl                  oe_order_pub.line_tbl_type;
        l_x_line_tbl                oe_order_pub.line_tbl_type;
        l_lot_serial_tbl            oe_order_pub.lot_serial_tbl_type;
        x_debug_file                VARCHAR2(2000);
        l_line_tbl_index            NUMBER;
        l_return_status             VARCHAR2(1) := 'S';
        l_action_tbl_index          NUMBER;
        l_action_request_tbl        oe_order_pub.request_tbl_type;
        l_header_adj_tbl            oe_order_pub.header_adj_tbl_type;
        l_line_adj_tbl              oe_order_pub.line_adj_tbl_type;
        l_header_scr_tbl            oe_order_pub.header_scredit_tbl_type;
        l_line_scredit_tbl          oe_order_pub.line_scredit_tbl_type;
        l_request_rec               oe_order_pub.request_rec_type;
        l_msg_count                 NUMBER;
        l_msg_data                  VARCHAR2(2000);
        l_msg_index_out             NUMBER(10);
--      p_api_version_number           NUMBER                                   := 1.0;
--      p_init_msg_list                VARCHAR2(10)                             := fnd_api.g_false;
--      p_return_values                VARCHAR2(10)                             := fnd_api.g_false;
--      p_action_commit                VARCHAR2(10)                             := fnd_api.g_false;
--      x_return_status                VARCHAR2(1);
--      x_msg_count                    NUMBER;
--      x_msg_data                     VARCHAR2(100);
        x_header_val_rec            oe_order_pub.header_val_rec_type;
        x_header_adj_tbl            oe_order_pub.header_adj_tbl_type;
        x_header_adj_val_tbl        oe_order_pub.header_adj_val_tbl_type;
        x_header_price_att_tbl      oe_order_pub.header_price_att_tbl_type;
        x_header_adj_att_tbl        oe_order_pub.header_adj_att_tbl_type;
        x_header_adj_assoc_tbl      oe_order_pub.header_adj_assoc_tbl_type;
        x_header_scredit_tbl        oe_order_pub.header_scredit_tbl_type;
        x_header_scredit_val_tbl    oe_order_pub.header_scredit_val_tbl_type;
        x_line_val_tbl              oe_order_pub.line_val_tbl_type;
        x_line_adj_tbl              oe_order_pub.line_adj_tbl_type;
        x_line_adj_val_tbl          oe_order_pub.line_adj_val_tbl_type;
        x_line_price_att_tbl        oe_order_pub.line_price_att_tbl_type;
        x_line_adj_att_tbl          oe_order_pub.line_adj_att_tbl_type;
        x_line_adj_assoc_tbl        oe_order_pub.line_adj_assoc_tbl_type;
        x_line_scredit_tbl          oe_order_pub.line_scredit_tbl_type;
        x_line_scredit_val_tbl      oe_order_pub.line_scredit_val_tbl_type;
        x_lot_serial_tbl            oe_order_pub.lot_serial_tbl_type;
        x_lot_serial_val_tbl        oe_order_pub.lot_serial_val_tbl_type;
        x_action_request_tbl        oe_order_pub.request_tbl_type;
        l_x_action_request_tbl      oe_order_pub.request_tbl_type;
        lx_upd_res_ret_status       VARCHAR2(1);
        lx_upd_res_ret_message      VARCHAR2(3000);
        l_row_count                 NUMBER;
      --variables for updating sales order header
        l_order_number              oe_order_headers_all.order_number%TYPE;
        l_header_id                 oe_order_headers_all.header_id%TYPE;
        l_flow_status_code          oe_order_headers_all.flow_status_code%TYPE;
        l_upd_so_compl EXCEPTION;
        l_x_upd_hdr_ret_status      VARCHAR2(10);
        l_x_upd_hdr_ret_msg         VARCHAR2(2000);
        l_so_lines_tbl              djooic_om_impbs_line_tbl;
        l_return_reason_code        fnd_lookup_values.lookup_code%TYPE;
        l_ref_rma_yn                VARCHAR2(1) := 'N';
        l_ref_rma_data_sts          VARCHAR2(100) := 'N';
        l_rma_src_hdr_id            NUMBER;
        l_rma_src_line_id           NUMBER;
        l_rma_src_sold_to_org_id    NUMBER;
        l_rma_res_sub               VARCHAR2(240);
        l_rma_res_locator           VARCHAR2(240);
        l_rma_locator               VARCHAR2(240);
      --variables for updating sales order header
        l_orig_ib_so_number         oe_order_headers_all.order_number%TYPE;
        l_orig_ib_header_id         oe_order_headers_all.header_id%TYPE;
        l_orig_ib_flow_status_code  oe_order_headers_all.flow_status_code%TYPE;
        l_orig_ib_sold_to_org_id    oe_order_headers_all.sold_to_org_id%TYPE;
        l_lines_cnt                 NUMBER;
        lx_upd_price_ret_status     VARCHAR2(1);
        lx_upd_price_ret_message    VARCHAR2(3000);
      -- variables to handle payment terms logic
        l_invoice_to_site_use_id    NUMBER;
        l_account_payment_term_id   NUMBER;
        l_account_payment_term_name ra_terms_tl.name%TYPE;
        l_site_payment_term_id      NUMBER;
        l_site_payment_term_name    ra_terms_tl.name%TYPE;
        l_account_credit_check_flag hz_customer_profiles.credit_checking%TYPE;
        l_unreleased_credit_hold_yn VARCHAR2(1) := 'N';
        l_return_item_total_qty     NUMBER;
        l_return_orders_cnt         NUMBER;
    BEGIN
        l_username := 'SYSADMIN';
        l_responsibility := 'Order Management Super User';
      --l_responsibility := 'Order Management Super User, Vision Operations (USA)';
        l_application_name := 'Order Management';
        BEGIN
         --SELECT xxdjo.DJOOIC_QP_PRICE_REQUEST_SEQ.NEXTVAL
            SELECT
                dbms_random.normal
            INTO l_transaction_id
            FROM
                dual;

            x_transaction_id := l_transaction_id;
            print_debug('l_transaction_id --> ' || l_transaction_id);
        EXCEPTION
            WHEN OTHERS THEN
                l_transaction_id := 0;
        END;

        BEGIN
            SELECT
                substr(instance_name, 1, 4)
            INTO l_instance_name
            FROM
                v$instance;

            print_debug('l_instance_name --> ' || l_instance_name);
        EXCEPTION
            WHEN OTHERS THEN
                l_instance_name := 'DJOP';
        END;

        BEGIN
            l_order_source_id := NULL;
            SELECT
                order_source_id
            INTO l_order_source_id
            FROM
                oe_order_sources
            WHERE
                    name = p_header_rec.order_source
                AND enabled_flag = 'Y';

            print_debug('l_order_source_id --> ' || l_order_source_id);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg
                                   || '...Error in fetching Order source -->'
                                   || sqlerrm;
        END;

        BEGIN
            SELECT
                a.operating_unit
                /*a.organization_id, a.organization_code, a.organization_name,
           a.operating_unit, b.name OU, a.set_of_books_id,d.name LEDGER,
           a.legal_entity,c.name LE_NAME*/
            INTO l_org_id
            FROM
                apps.org_organization_definitions a,
                apps.hr_operating_units           b,
                apps.xle_entity_profiles          c,
                apps.gl_ledgers                   d
            WHERE
                    a.operating_unit = b.organization_id
                AND c.legal_entity_id = a.legal_entity
                AND d.ledger_id = a.set_of_books_id
                AND a.organization_code = p_header_rec.inv_org_code;

            print_debug('l_org_id --> ' || l_org_id);
        EXCEPTION
            WHEN OTHERS THEN
                l_org_id := NULL;
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Error in fetching Org id from inventory org code -->'
                                   || sqlerrm;
        END;

--+++++++++++++++++++++++++++++++++++++ Invoking sales order update api WHERE THERE IS SALES ORDER WITH GIVEN ib order number
---+++++++++++++++++++++++++++++++++++
        BEGIN
            SELECT
                header_id,
                order_number,
                flow_status_code
            INTO
                l_header_id,
                l_order_number,
                l_flow_status_code
            FROM
                oe_order_headers_all oeh,
                oe_order_sources     oes
            WHERE
                    oeh.order_source_id = oes.order_source_id
                AND orig_sys_document_ref = p_header_rec.order_number
                AND oes.name = p_header_rec.order_source;

        EXCEPTION
            WHEN no_data_found THEN
                l_header_id := NULL;
            WHEN too_many_rows THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg
                                   || '..multiple sales orders exist for given IB ORDER Number -->'
                                   || sqlerrm;
            WHEN OTHERS THEN
                l_header_id := NULL;
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg
                                   || '...when others error in fetching sales order for given IB ORDER Number -->'
                                   || sqlerrm;
        END;

---+++++++++++++++++++++++++++++++++++ Fetching Sales Order details for orginal IB Order NUmber
--+++++++++++++++++++
        IF p_header_rec.original_order_number IS NOT NULL THEN
            BEGIN
                SELECT
                    header_id,
                    order_number,
                    flow_status_code,
                    sold_to_org_id
                INTO
                    l_orig_ib_header_id,
                    l_orig_ib_so_number,
                    l_orig_ib_flow_status_code,
                    l_orig_ib_sold_to_org_id
                FROM
                    oe_order_headers_all oeh,
                    oe_order_sources     oes
                WHERE
                        oeh.order_source_id = oes.order_source_id
                    AND orig_sys_document_ref = p_header_rec.original_order_number
                    AND oes.name = p_header_rec.order_source;

            EXCEPTION
                WHEN no_data_found THEN
                    l_orig_ib_header_id := NULL;
                WHEN too_many_rows THEN
                    l_validation_status := 'E';
                    l_val_error_msg := l_val_error_msg
                                       || '..multiple sales orders exist for given original_order_number -->'
                                       || sqlerrm;
                WHEN OTHERS THEN
                    l_orig_ib_header_id := NULL;
                    l_validation_status := 'E';
                    l_val_error_msg := l_val_error_msg
                                       || '...when others error in fetching sales order for given original_order_number -->'
                                       || sqlerrm;
            END;
        END IF;

        IF l_flow_status_code = 'CLOSED' THEN
            l_val_error_msg := 'Order is closed, cannot update the Sales Order';
            x_return_status := 'E';
            x_return_message := l_val_error_msg;
            RAISE l_apps_init_execp;
        END IF;

        IF
            l_header_id IS NOT NULL
            AND p_header_rec.original_order_number IS NULL                                                                        --Added 10/17
            AND ( p_header_rec.surgeon_account_number IS NOT NULL OR p_header_rec.po_number IS NOT NULL OR p_header_rec.case_start_date
            IS NOT NULL )
        THEN
            apps_initilzation(ip_username => l_username, ip_responsibility => l_responsibility, ip_application_name => l_application_name
            , op_status => lx_init_status, op_message => lx_init_message);

            IF lx_init_status = 'E' THEN
                x_return_status := lx_init_status;
                x_return_message := lx_init_message;
                RAISE l_apps_init_execp;
            ELSE
                print_debug('Apps Initialization ..Success');
            END IF;

            IF
                l_instance_name != 'DJOP'
                AND g_trace
            THEN
                oe_msg_pub.initialize;
                oe_debug_pub.initialize;
                oe_debug_pub.debug_on;
                oe_debug_pub.setdebuglevel(5);                             -- Use 5 for the most debugging output, I warn you its a lot of data
                x_debug_file := oe_debug_pub.set_debug_mode('FILE');
                print_debug('x_debug_file -->' || x_debug_file);
                mo_global.init('ONT');
                mo_global.set_policy_context('S', l_org_id);
            END IF;

            l_so_lines_tbl := p_lines_tbl;
            djooic_om_impbs_process_order_pkg.update_so(p_so_header_rec => p_header_rec, p_so_header_id => l_header_id, p_so_lines_tbl => l_so_lines_tbl
            , x_return_status => l_x_upd_hdr_ret_status, x_return_message => l_x_upd_hdr_ret_msg);

            x_return_status := l_x_upd_hdr_ret_status;
            IF l_x_upd_hdr_ret_status = 'S' THEN
            --x_return_message := 'Purchase Order#, Case Start Date, Surgeon Account Number have been updated on the sales order#' || l_order_number;
                x_return_message := l_x_upd_hdr_ret_msg;
                lx_order_rec.order_header_id := l_header_id;
                lx_order_rec.order_number := l_order_number;
                lx_order_rec.order_status := l_flow_status_code;
                x_order_rec := lx_order_rec;
            ELSE
                x_return_message := l_x_upd_hdr_ret_msg;
            END IF;

            RAISE l_upd_so_compl;                                                      -- raising exception to skip processing rest of the code
        END IF;

--++++++++++++++++++++++++++++++++++++++++++++++++++

      -- set the context
-- set deubg

      ---CUstomer API call for ship to address creation
        IF
            p_header_rec.order_source != 'ImplantBase'
            AND p_header_rec.shipto_address1 IS NOT NULL
        THEN                                                                                                                             --new
            print_debug('If condtion when source is not implantbase');
            create_cust_site(p_cust_account_number => p_header_rec.hospital_account_number, p_site_use_code => 'SHIP_TO', p_address1 => p_header_rec.shipto_address1
            , p_address2 => p_header_rec.shipto_address2, p_address3 => p_header_rec.shipto_address3,
                            p_address4 => p_header_rec.shipto_address4, p_country => p_header_rec.shipto_country, p_state => p_header_rec.shipto_state_province
                            , p_city => p_header_rec.shipto_city, p_postal_code => p_header_rec.shipto_postal_code,
                            p_org_id => l_org_id, x_party_site_id => lx_party_site_id, x_return_status => lx_return_status, x_return_message => lx_return_message
                            );

            print_debug('Party site ID - ' || lx_party_site_id);
            IF lx_party_site_id IS NOT NULL THEN
                SELECT
                    cust_acct_site_id
                INTO l_ship_cust_acct_site_id
                FROM
                    hz_cust_acct_sites_all
                WHERE
                    party_site_id = lx_party_site_id;

                IF
                    p_header_rec.order_source != 'ImplantBase'
                    AND p_header_rec.shipto_contact_first_name IS NOT NULL
                THEN
                    create_person(p_cust_account_number => p_header_rec.hospital_account_number, p_contact_first_name => p_header_rec.shipto_contact_first_name
                    , p_contact_last_name => p_header_rec.shipto_contact_last_name, p_contact_phone => p_header_rec.shipto_contact_phone
                    , p_phone_extension => p_header_rec.shipto_contact_ext,
                                 p_contact_email => p_header_rec.shipto_contact_email, p_cust_account_site_id => l_ship_cust_acct_site_id
                                 , x_contact_point_id => lx_shipto_contact_point_id);

                    print_debug('Contact Point ID - ' || lx_shipto_contact_point_id);
                END IF;

            END IF;

        END IF;

      --CUstomer API call for deliver to address creation
        IF
            p_header_rec.order_source != 'ImplantBase'
            AND p_header_rec.deliver_to_address1 IS NOT NULL
        THEN
            create_cust_site(p_cust_account_number => p_header_rec.hospital_account_number, p_site_use_code => 'DELIVER_TO', p_address1 => p_header_rec.deliver_to_address1
            , p_address2 => p_header_rec.deliver_to_address2, p_address3 => p_header_rec.deliver_to_address3,
                            p_address4 => p_header_rec.deliver_to_address4, p_country => p_header_rec.deliver_to_country, p_state => p_header_rec.deliver_to_state_province
                            , p_city => p_header_rec.deliver_to_city, p_postal_code => p_header_rec.deliver_to_postal_code,
                            p_org_id => l_org_id, x_party_site_id => lx_deliver_to_party_site_id, x_return_status => lxd_return_status
                            , x_return_message => lxd_return_message);

            print_debug('Deliver to site ID - ' || lx_deliver_to_party_site_id);
        END IF;

        apps_initilzation(ip_username => l_username, ip_responsibility => l_responsibility, ip_application_name => l_application_name
        , op_status => lx_init_status, op_message => lx_init_message);

        IF lx_init_status = 'E' THEN
            x_return_status := lx_init_status;
            x_return_message := lx_init_message;
            RAISE l_apps_init_execp;
        ELSE
            print_debug('Apps Initialization ..Success');
        END IF;

        IF
            l_instance_name != 'DJOP'
            AND g_trace
        THEN
            oe_msg_pub.initialize;
            oe_debug_pub.initialize;
            oe_debug_pub.debug_on;
            oe_debug_pub.setdebuglevel(5);
            x_debug_file := oe_debug_pub.set_debug_mode('FILE');
            print_debug('x_debug_file -->' || x_debug_file);
            mo_global.init('ONT');
            mo_global.set_policy_context('S', l_org_id);
        END IF;

      -- hospital account number validation
      --
        BEGIN
            l_cust_account_id := NULL;
            l_party_id := NULL;
            l_price_list_id := NULL;
            l_currency_code := NULL;
            print_debug('START OF hospital account number' || p_header_rec.hospital_account_number);
            SELECT
                cust_account_id,
                party_id,
                hca.price_list_id,
                qlb.currency_code
            INTO
                l_cust_account_id,
                l_party_id,
                l_price_list_id,
                l_currency_code
            FROM
                hz_cust_accounts  hca,
                qp_list_headers_b qlb
            WHERE
                    hca.price_list_id = qlb.list_header_id (+)
                AND account_number = p_header_rec.hospital_account_number;

            print_debug('l_cust_account_id --> ' || l_cust_account_id);
            print_debug('l_party_id --> ' || l_party_id);
            print_debug('l_price_list_id --> ' || l_price_list_id);
            print_debug('l_currency_code --> ' || l_currency_code);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg
                                   || '...Error in fetching Hospital Account number -->'
                                   || sqlerrm;
        END;

        IF p_header_rec.order_source = 'ImplantBase' THEN
            BEGIN
                l_surgeon_account_id := NULL;
                print_debug('START OF Surgeon account number' || p_header_rec.surgeon_account_number);
                SELECT
                    cust_account_id
                INTO l_surgeon_account_id
                FROM
                    hz_cust_accounts  hca,
                    qp_list_headers_b qlb
                WHERE
                        hca.price_list_id = qlb.list_header_id (+)
                    AND account_number = p_header_rec.surgeon_account_number;

                print_debug('l_cust_account_id --> ' || l_surgeon_account_id);
            EXCEPTION
                WHEN OTHERS THEN
                    l_validation_status := 'E';
                    l_val_error_msg := l_val_error_msg
                                       || '...Error in fetching Surgeon account number -->'
                                       || sqlerrm;
            END;

            print_debug('START OF revision_surgery' || p_header_rec.revision_surgery);
            IF nvl(p_header_rec.revision_surgery, 'X') NOT IN ( 'Y', 'N' ) THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg || '..Invalid revision_surgery value. valid values are Y, N ';
            END IF;

            print_debug('START OF revised_djo_oti_product' || p_header_rec.revised_djo_oti_product);
            IF nvl(p_header_rec.revised_djo_oti_product, 'X') NOT IN ( 'Y', 'N' ) THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg || '..Invalid revised_djo_oti_product value. valid values are Y, N ';
            END IF;

        END IF;

      --Deriving Price List
        BEGIN
            l_price_list := NULL;
            SELECT
                to_char(name)
            INTO l_price_list
            FROM
                qp_list_headers
            WHERE
                list_header_id = l_price_list_id;

            print_debug('l_price_list --> ' || l_price_list);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := l_val_error_msg
                                   || '...INVALID PRICE LIST -->'
                                   || sqlerrm;
        END;

      -- Derive Payment terms, credit check from customer account profile.
        BEGIN
            l_account_payment_term_id := NULL;
            l_account_payment_term_name := NULL;
            SELECT
                hcp.standard_terms,
                rtt.name,
                nvl(hcp.credit_checking, 'N')
            INTO
                l_account_payment_term_id,
                l_account_payment_term_name,
                l_account_credit_check_flag
            FROM
                hz_cust_accounts     hca,
                hz_customer_profiles hcp,
                ra_terms_tl          rtt
            WHERE
                    hcp.cust_account_id = hca.cust_account_id
                AND nvl(hcp.status, 'A') = 'A'
                AND hcp.site_use_id IS NULL
                AND hca.cust_account_id = l_cust_account_id
                AND hcp.standard_terms = rtt.term_id
                AND rtt.language = userenv('LANG');

            print_debug('l_account_payment_term_id --> ' || l_account_payment_term_id);
            print_debug('l_account_payment_term_name --> ' || l_account_payment_term_name);
            print_debug('l_account_credit_check_flag --> ' || l_account_credit_check_flag);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Error in fetching payment terms -->'
                                   || sqlerrm;
        END;

      -- Derive Bill to customer site.
        BEGIN
            l_invoice_to_party_site_id := NULL;
            l_invoice_to_site_use_id := NULL;
            SELECT DISTINCT
                hps.party_site_id,
                hcsu.site_use_id
                    /*
                    hca.account_number
                      ,hca.CUST_ACCOUNT_ID
                      ,hcas.CUST_ACCT_SITE_ID
                      ,hps.party_site_id
                      ,hps.party_site_number
                      ,hps.party_site_name
                      ,hcas.BILL_TO_FLAG
                      ,hcas.SHIP_TO_FLAG
                      ,hcsu.SITE_USE_ID
                      ,hcsu.PRIMARY_FLAG
                      ,hcsu.site_use_code
                      ,hcsu.BILL_TO_SITE_USE_ID
                    */
            INTO
                l_invoice_to_party_site_id,
                l_invoice_to_site_use_id
            FROM
                apps.hz_cust_site_uses_all  hcsu,
                apps.hz_cust_acct_sites_all hcas,
                apps.hz_cust_accounts       hca,
                apps.hz_party_sites         hps
            WHERE
                    1 = 1
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                AND hca.cust_account_id = l_cust_account_id
                     --and hca.account_number = l_header_rec.Hospital_Account_Number;
                      --and hps.party_site_id='1212'
                AND hcsu.site_use_code = 'BILL_TO'
                AND nvl(hcsu.status, 'A') = 'A'
                AND nvl(hca.status, 'A') = 'A'
                AND nvl(hcas.status, 'A') = 'A'
                AND nvl(hps.status, 'A') = 'A'
                AND hcsu.primary_flag = 'Y'
                AND hcas.org_id = l_org_id
                                               --     AND hcsu.SHIP_TO_FLAG ='P'
                ;

            print_debug('l_invoice_to_party_site_id --> ' || l_invoice_to_party_site_id);
            print_debug('l_invoice_to_site_use_id --> ' || l_invoice_to_site_use_id);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Error in fetching Invoice TO to party site id -->'
                                   || sqlerrm;
        END;

      --Derive Transaction type, Trasaction order category
        BEGIN
            l_transaction_type_id := NULL;
            l_order_category_code := NULL;
            SELECT
                ott.transaction_type_id,
                ott.order_category_code
            INTO
                l_transaction_type_id,
                l_order_category_code
            FROM
                oe_transaction_types_all ott,
                oe_transaction_types_tl  ottl
            WHERE
                    1 = 1
                AND ott.transaction_type_id = ottl.transaction_type_id
                AND ottl.language = userenv('LANG')
                AND ott.org_id = l_org_id                      --AND ottl.NAME IN ('AUS RETURN ORDER','AUS STANDARD ORDER', 'DJO BILL ONLY LINE'
                AND ottl.name = p_header_rec.order_type;

         -- AND ott.transaction_type_code = 'ORDER';
            print_debug('l_transaction_type_id --> ' || l_transaction_type_id);
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Error in fetching Order Type-->'
                                   || sqlerrm;
        END;

--Derive Payment Term, from customer bill to site
        BEGIN
            l_site_payment_term_id := NULL;
            l_site_payment_term_name := NULL;
            SELECT
                hcp.standard_terms,
                rtt.name
            INTO
                l_site_payment_term_id,
                l_site_payment_term_name
            FROM
                hz_customer_profiles hcp,
                ra_terms_tl          rtt
            WHERE
                    1 = 1
                AND nvl(hcp.status, 'A') = 'A'
                AND hcp.standard_terms = rtt.term_id
                AND rtt.language = userenv('LANG')
                AND hcp.site_use_id = l_invoice_to_site_use_id
                AND hcp.cust_account_id = l_cust_account_id;

            print_debug('l_site_payment_term_id --> ' || l_site_payment_term_id);
            print_debug('l_site_payment_term_name --> ' || l_site_payment_term_name);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
      --l_validation_status := 'E';
      --l_val_error_msg := '...' || l_val_error_msg || '...' || 'Error in fetching payment terms at site level -->' || SQLERRM;
        END;

        IF l_order_category_code IN ( 'ORDER' ) THEN
            IF ( (
                l_site_payment_term_name IN ( 'CCO', 'CCI', 'CCG' )
                AND l_account_payment_term_name NOT IN ( 'CCO', 'CCI', 'CCG' )
            ) OR (
                l_account_payment_term_name IN ( 'CCO', 'CCI', 'CCG' )
                AND l_site_payment_term_name IS NULL
            ) OR (
                l_site_payment_term_name IN ( 'CCO', 'CCI', 'CCG' )
                AND l_account_payment_term_name IN ( 'CCO', 'CCI', 'CCG' )
            ) ) THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Credit Card information is required. please complete the credit card information on the header. -->'
                                   || sqlerrm;
            END IF;
        END IF;

      --Derive Ship to site
        BEGIN
            l_shipto_cust_account_id := NULL;
            l_shipto_party_site_id := NULL;
            SELECT DISTINCT
                hca.cust_account_id,
                hps.party_site_id
                    /*
                    hca.account_number
                      ,hca.CUST_ACCOUNT_ID
                      ,hcas.CUST_ACCT_SITE_ID
                      ,hps.party_site_id
                      ,hps.party_site_number
                      ,hps.party_site_name
                      ,hcas.BILL_TO_FLAG
                      ,hcas.SHIP_TO_FLAG
                      ,hcsu.SITE_USE_ID
                      ,hcsu.PRIMARY_FLAG
                      ,hcsu.site_use_code
                      ,hcsu.BILL_TO_SITE_USE_ID
                    */
            INTO
                l_shipto_cust_account_id,
                l_shipto_party_site_id
            FROM
                apps.hz_cust_site_uses_all  hcsu,
                apps.hz_cust_acct_sites_all hcas,
                apps.hz_cust_accounts       hca,
                apps.hz_party_sites         hps
            WHERE
                    1 = 1
                AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                AND hcas.cust_account_id = hca.cust_account_id
                AND hcas.party_site_id = hps.party_site_id
                     --and hca.cust_account_id =1005
                AND hca.account_number = p_header_rec.hospital_account_number
                     --and hps.party_site_id='1212'
                AND hcsu.site_use_code = 'SHIP_TO'
                AND nvl(hcsu.status, 'A') = 'A'
                AND nvl(hca.status, 'A') = 'A'
                AND nvl(hcas.status, 'A') = 'A'
                AND nvl(hps.status, 'A') = 'A'
                AND hcsu.primary_flag = 'Y'
                AND hcas.org_id = l_org_id;

            print_debug('l_shipto_cust_account_id --> ' || l_shipto_cust_account_id);
            print_debug('l_shipto_party_site_id --> ' || l_shipto_party_site_id);
--     AND hcsu.SHIP_TO_FLAG ='P'
        EXCEPTION
            WHEN OTHERS THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Error in fetching Ship to account number -->'
                                   || sqlerrm;
        END;

      --This is to CREATE an order header and an order line

      --Create Header record--Initialize header record to missing
        l_header_rec := oe_order_pub.g_miss_header_rec;
        l_header_rec.operation := oe_globals.g_opr_create;
        l_header_rec.transactional_curr_code := l_currency_code;
        l_header_rec.pricing_date := sysdate;
        l_header_rec.cust_po_number := p_header_rec.po_number;
        l_header_rec.sold_to_org_id := l_cust_account_id;
        l_header_rec.org_id := l_org_id;
        l_header_rec.invoice_to_party_site_id := l_invoice_to_party_site_id;
        IF
            p_header_rec.order_source != 'ImplantBase'
            AND p_header_rec.shipto_address1 IS NOT NULL
        THEN
            l_header_rec.ship_to_party_site_id := lx_party_site_id;
        ELSE
            l_header_rec.ship_to_party_site_id := l_shipto_party_site_id;
        END IF;

        IF
            p_header_rec.order_source != 'ImplantBase'
            AND p_header_rec.deliver_to_address1 IS NOT NULL
        THEN
            l_header_rec.deliver_to_party_site_id := lx_deliver_to_party_site_id;
        END IF;

        l_header_rec.price_list_id := l_price_list_id;
        l_header_rec.ordered_date := sysdate;
      -- l_header_rec.booked_flag := 'Y';
       --l_header_rec.shipping_method_code := 'DHL';
        l_header_rec.sold_from_org_id := l_org_id;
        l_header_rec.salesrep_id := -3;
        l_header_rec.order_type_id := l_transaction_type_id;                                                                           --mixed
        l_header_rec.order_source_id := l_order_source_id;                                                                             --mixed

--      l_header_rec.payment_term_id := l_payment_terms_id;

      --l_header_rec.transaction_phase_code := 'N';
      --Added MIXED category code
        IF l_order_category_code IN ( 'RETURN', 'MIXED' ) OR p_header_rec.original_order_number IS NOT NULL THEN                                                                                                                 --= 'RETURN' THEN
            l_header_rec.orig_sys_document_ref := p_header_rec.order_number
                                                  || '-'
                                                  || p_header_rec.original_order_number;
            print_debug('orig_sys_document_ref --> ' || p_header_rec.original_order_number);
        ELSE
            l_header_rec.orig_sys_document_ref := p_header_rec.order_number;
            print_debug('orig_sys_document_ref --> ' || p_header_rec.order_number);
        END IF;

        l_header_rec.context := 'DIRECT';
        l_header_rec.attribute14 := p_header_rec.patient_name;
        l_header_rec.attribute15 := p_header_rec.order_number;
        l_header_rec.attribute16 := p_header_rec.revised_djo_oti_product;
        l_header_rec.attribute17 := p_header_rec.revision_surgery;
        IF p_header_rec.case_start_date IS NOT NULL THEN
            SELECT
                fnd_date.date_to_canonical(p_header_rec.case_start_date)
            INTO l_header_rec.attribute18
            FROM
                dual;

            print_debug('date to canonical --> ' || l_header_rec.attribute18);
        END IF;

        l_header_rec.attribute19 := l_surgeon_account_id;
      --Action Table
        l_action_tbl_index := 1;
        l_action_request_tbl(1) := oe_order_pub.g_miss_request_rec;
        l_action_request_tbl(1).request_type := oe_globals.g_book_order;
        l_action_request_tbl(1).entity_code := oe_globals.g_entity_header;
        print_debug('p_lines_tbl.COUNT --> ' || p_lines_tbl.count);

  --+++++++++++
-- Logic to get the line details from existing sales order lines
-- for RMA reference when line records are not provided.
        IF
            l_orig_ib_header_id IS NOT NULL
            AND l_order_category_code IN ( 'RETURN', 'MIXED' )
            AND p_header_rec.order_source = 'ImplantBase'
        THEN
         --+++++++
         --Check if any line is pre-shipping phase. if yes ,throw a validation error message as RMA can not be created against such an order.
         --++++++
            BEGIN
                l_return_orders_cnt := 0;
                SELECT
                    COUNT(1)
                INTO l_return_orders_cnt
                FROM
                    oe_order_lines_all   oola,
                    oe_order_headers_all ooha
                WHERE
                        oola.header_id = ooha.header_id
                    AND ooha.flow_status_code <> 'CANCELLED'
                    AND ooha.order_source_id = l_order_source_id
                    AND ooha.orig_sys_document_ref = p_header_rec.original_order_number
                     AND oola.flow_status_code NOT IN ('FULFILLED', 'INVOICED', 'CLOSED');-- ( 'CANCELLED', 'SHIPPED', 'AWAITING_FULFILLMENT', 'AWAITING_SHIPPING', 'CUSTOMER_ACCEPTED');

                IF l_return_orders_cnt > 0 THEN
                    l_validation_status := 'E';
                    l_val_error_msg := '...'
                                       || l_val_error_msg
                                       || '...'
                                       || ' some lines are yet to be fulfilled. Return order can not be created';
                END IF;

            END;

          --+++++++
          --Check if line quantity has already been returned
          --++++++
--         IF l_orig_ib_flow_status_code = 'CLOSED'
--         THEN
--            l_validation_status := 'E';
--            l_val_error_msg :=
--                          '...' || l_val_error_msg || '...' || 'Original Sales Order is on closed status. Return order can not be created.';
         --ELSE
            l_return_orders_cnt := 0;
            SELECT
                COUNT(1)
            INTO l_return_orders_cnt
            FROM
                oe_order_headers_all
            WHERE
                    order_source_id = l_order_source_id
                AND substr(orig_sys_document_ref,
                           instr(orig_sys_document_ref, '-', 1) + 1) = p_header_rec.original_order_number;

            IF l_return_orders_cnt > 1 THEN
                l_validation_status := 'E';
                l_val_error_msg := '...'
                                   || l_val_error_msg
                                   || '...'
                                   || 'Return Order has already been created for provided Original Sales Order.';
            END IF;

            FOR l_so_lines IN (
                SELECT
                    msib.segment1 item_number,
                    oola.*
                FROM
                    oe_order_lines_all   oola,
                    oe_order_headers_all ooha,
                    mtl_system_items_b   msib
                WHERE
                        oola.header_id = ooha.header_id
                    AND ooha.flow_status_code <> 'CANCELLED'
                    AND ooha.order_source_id = l_order_source_id
                    AND ooha.orig_sys_document_ref = p_header_rec.original_order_number
                    AND oola.flow_status_code <> 'CANCELLED'
                    AND oola.inventory_item_id = msib.inventory_item_id
                    AND oola.ship_from_org_id = msib.organization_id
            ) LOOP
                SELECT
                    SUM(abs(oola.ordered_quantity))
                INTO l_return_item_total_qty
                FROM
                    oe_order_lines_all   oola,
                    oe_order_headers_all ooha
                WHERE
                        oola.header_id = ooha.header_id
                    AND ooha.flow_status_code <> 'CANCELLED'
                    AND ooha.order_source_id = l_order_source_id
                    AND substr(ooha.orig_sys_document_ref,
                               instr(ooha.orig_sys_document_ref, '-', 1) + 1) = p_header_rec.original_order_number
                    AND oola.flow_status_code <> 'CANCELLED'
                    AND oola.inventory_item_id = l_so_lines.inventory_item_id
                    AND oola.line_id = l_so_lines.line_id;

                IF l_return_item_total_qty > l_so_lines.ordered_quantity THEN
                    l_validation_status := 'E';
                    l_val_error_msg := '...'
                                       || l_val_error_msg
                                       || '...'
                                       || 'Full quantity has been returned for the item ' --|| l_lines_tbl..part_number 
                                       || '('
                                       || l_so_lines.ordered_quantity
                                       || ')';

                END IF;

            END LOOP;

         --END IF;
            print_debug('Entering ImplantBase RMA without line information --> ' || p_lines_tbl.count);
            BEGIN
                l_line_type_id := NULL;
                SELECT
                    ott.transaction_type_id,
                    ott.order_category_code
                INTO
                    l_line_type_id,
                    l_line_type_category_code
                FROM
                    oe_transaction_types_all ott,
                    oe_transaction_types_tl  ottl
                WHERE
                        1 = 1
                    AND ott.transaction_type_id = ottl.transaction_type_id
                    AND ottl.language = userenv('LANG')
                    AND ott.org_id = l_org_id                   --AND ottl.NAME IN ('AUS RETURN ORDER','AUS STANDARD ORDER', 'DJO BILL ONLY LINE'
                    AND ottl.name = p_lines_tbl(1).line_type
                    AND ott.transaction_type_code = 'LINE';

                print_debug('l_line_type_id --> ' || l_line_type_id);
                print_debug('l_line_type_category_code --> ' || l_line_type_category_code);
            EXCEPTION
                WHEN OTHERS THEN
                    l_validation_status := 'E';
                    l_val_error_msg := '...'
                                       || l_val_error_msg
                                       || '...'
                                       || 'Error in fetching Line Order Type2-->'
                                       || sqlerrm;
            END;

         --Validating return reason before assigning to lines table
            BEGIN
                l_return_reason_code := NULL;
                SELECT
                    lookup_code
                INTO l_return_reason_code
                FROM
                    fnd_lookup_values
                WHERE
                        1 = 1
                    AND lookup_type = 'CREDIT_MEMO_REASON'
                    AND language = userenv('LANG')
                    AND enabled_flag = 'Y'
                    AND trunc(sysdate) BETWEEN trunc(start_date_active) AND trunc(nvl(end_date_active, sysdate))
                    AND meaning = p_lines_tbl(1).reason_code;

            --l_line_tbl(l_line_tbl_index).return_reason_code := l_return_reason_code;
                print_debug('l_return_reason_code --> ' || l_return_reason_code);
            EXCEPTION
                WHEN no_data_found THEN
                    l_validation_status := 'E';
                    l_val_error_msg := '...'
                                       || l_val_error_msg
                                       || '...'
                                       || 'Return reason does not exist in the lookup. pls provide valid return reason.-->';
                WHEN OTHERS THEN
                    l_validation_status := 'E';
                    l_val_error_msg := '...'
                                       || l_val_error_msg
                                       || '...'
                                       || 'Error in fetching Return reason-->'
                                       || sqlerrm
                                       || '...'
                                       || dbms_utility.format_error_backtrace();

            END;

            l_lines_cnt := 1;
            FOR l_so_lines IN (
                SELECT
                    *
                FROM
                    oe_order_lines_all
                WHERE
                    header_id = l_orig_ib_header_id
            ) LOOP
                print_debug('l_so_lines --> ' || l_so_lines.line_id);
                l_header_rec.sold_to_org_id := l_orig_ib_sold_to_org_id;
                l_line_tbl(l_lines_cnt) := oe_order_pub.g_miss_line_rec;
                l_line_tbl(l_lines_cnt).operation := oe_globals.g_opr_create;
                BEGIN
                    SELECT
                        oe_order_lines_s.NEXTVAL
                    INTO l_line_tbl(l_lines_cnt).line_id
                    FROM
                        dual;

                END;
                l_line_tbl(l_lines_cnt).line_type_id := l_line_type_id;
                l_line_tbl(l_lines_cnt).line_number := l_so_lines.line_number;
                l_line_tbl(l_lines_cnt).ordered_quantity := l_so_lines.ordered_quantity;
                l_line_tbl(l_lines_cnt).calculate_price_flag := l_so_lines.calculate_price_flag;
                l_line_tbl(l_lines_cnt).return_context := 'ORDER';
--             l_line_tbl(l_line_tbl_index).return_context := 'ORDER';
--            l_line_tbl(l_lines_cnt).return_attribute1 := TO_CHAR(l_so_lines.header_id);
                l_line_tbl(l_lines_cnt).return_attribute1 := to_char(l_so_lines.header_id);
                l_line_tbl(l_lines_cnt).return_attribute2 := to_char(l_so_lines.line_id);
                l_line_tbl(l_lines_cnt).return_reason_code := l_return_reason_code;                     --'CREDIT and REBILL';--'WRONG PRODUCT';
                l_line_tbl(l_lines_cnt).context := 'DIRECT';
                l_line_tbl(l_lines_cnt).attribute17 := l_so_lines.attribute17;
                l_line_tbl(l_lines_cnt).attribute18 := l_so_lines.attribute18;
                l_line_tbl(l_lines_cnt).attribute19 := l_so_lines.attribute19;
                l_line_tbl(l_lines_cnt).cust_po_number := p_header_rec.po_number;
                l_line_tbl(l_lines_cnt).fulfillment_set := substr(p_header_rec.order_number, 1, 30);

                IF p_lines_tbl(l_lines_cnt).include_in_construct_flag = 'Y' THEN
                    l_line_tbl(l_lines_cnt).ship_set := substr(p_header_rec.order_number, 1, 30);
                ELSE
                    l_line_tbl(l_lines_cnt).ship_set := NULL;
                END IF;

                print_debug('fulfillment_set --> ' || l_line_tbl(l_lines_cnt).fulfillment_set);
                print_debug('ship_set --> ' || l_line_tbl(l_lines_cnt).ship_set);
                l_lines_cnt := l_lines_cnt + 1;
            END LOOP;

        ELSE
            IF p_lines_tbl.count > 0 THEN
                FOR l_line_tbl_index IN p_lines_tbl.first..p_lines_tbl.last LOOP
                    print_debug('LINES TABLE COUNTER --> ' || l_line_tbl_index);

               --+++++++++ Inv item details ++++++++++++
                    BEGIN
                        l_inventory_item_id := NULL;
                        l_inventory_org_id := NULL;
                        SELECT
                            msib.inventory_item_id,
                            msib.organization_id
                        INTO
                            l_inventory_item_id,
                            l_inventory_org_id
                        FROM
                            mtl_system_items_b msib,
                            mtl_parameters     mp
                        WHERE
                                1 = 1
                     --AND mp.organization_id = mp.master_organization_id
                            AND mp.organization_code = p_header_rec.inv_org_code
                            AND msib.organization_id = mp.organization_id
                            AND msib.segment1 = p_lines_tbl(l_line_tbl_index).part_number
                                                                                  -- AND organization_id = l_header_rec.manufacturer_id
                            ;

                        print_debug('l_inventory_item_id --> ' || l_inventory_item_id);
                        print_debug('l_inventory_org_id --> ' || l_inventory_org_id);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_validation_status := 'E';
                            l_val_error_msg := '...'
                                               || l_val_error_msg
                                               || '...'
                                               || 'Error in Inventory Item-->'
                                               || sqlerrm;
                    END;

               --+++++++++ Sub Inventory details ++++++++++++
                    l_line_tbl(l_line_tbl_index) := oe_order_pub.g_miss_line_rec;
                    l_line_tbl(l_line_tbl_index).operation := oe_globals.g_opr_create;
                    BEGIN
                        l_line_type_id := NULL;
                        SELECT
                            ott.transaction_type_id,
                            ott.order_category_code
                        INTO
                            l_line_type_id,
                            l_line_type_category_code
                        FROM
                            oe_transaction_types_all ott,
                            oe_transaction_types_tl  ottl
                        WHERE
                                1 = 1
                            AND ott.transaction_type_id = ottl.transaction_type_id
                            AND ottl.language = userenv('LANG')
                            AND ott.org_id = l_org_id             --AND ottl.NAME IN ('AUS RETURN ORDER','AUS STANDARD ORDER', 'DJO BILL ONLY LINE'
                            AND ottl.name = p_lines_tbl(l_line_tbl_index).line_type
                            AND ott.transaction_type_code = 'LINE';

                        print_debug('l_line_type_id --> ' || l_line_type_id);
                        print_debug('l_line_type_category_code --> ' || l_line_type_category_code);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_validation_status := 'E';
                            l_val_error_msg := '...'
                                               || l_val_error_msg
                                               || '...'
                                               || 'Error in fetching Line Order Type-->'
                                               || sqlerrm;
                    END;

                    l_line_tbl(l_line_tbl_index).line_type_id := l_line_type_id;
                    l_line_tbl(l_line_tbl_index).context := 'DIRECT';

--            l_line_tbl(l_line_tbl_index).attribute17 := p_lines_tbl(l_line_tbl_index).reservation_subinventory;
--            l_line_tbl(l_line_tbl_index).attribute18 := p_lines_tbl(l_line_tbl_index).reservation_locator;
--            l_line_tbl(l_line_tbl_index).attribute19 := p_lines_tbl(l_line_tbl_index).lot_number;
--            ELSE
--
--                         select   oola.attribute17, oola.attribute18, oola.attribute19
--             into l_rma_res_sub, l_rma_res_locator, l_rma_locator
--             from oe_order_headers_all ooha, oe_order_lines_all oola
--             where ooha.header_id = oola.header_id
--             and ooha.order_number = p_lines_tbl(l_line_tbl_index).return_reference_number
--                         and ooha.ORDER_SOURCE_ID = l_order_source_id
--                         and ooha.org_id = l_org_id;
--                l_line_tbl(l_line_tbl_index).CONTEXT := 'DIRECT';
--          l_line_tbl(l_line_tbl_index).attribute17 := l_rma_res_sub;--p_lines_tbl(l_line_tbl_index).reservation_subinventory;
--            l_line_tbl(l_line_tbl_index).attribute18 := l_rma_res_locator;--p_lines_tbl(l_line_tbl_index).reservation_locator;
--            l_line_tbl(l_line_tbl_index).attribute19 := l_rma_locator;--p_lines_tbl(l_line_tbl_index).lot_number;
--
--            END IF;
            --l_line_tbl(l_line_tbl_index).reserved_quantity := l_line_tbl(l_line_tbl_index).ordered_quantity;
                    BEGIN
                        SELECT
                            oe_order_lines_s.NEXTVAL
                        INTO l_line_tbl(l_line_tbl_index).line_id
                        FROM
                            dual;

                    END;
                    IF
                        p_lines_tbl(l_line_tbl_index).reservation_subinventory IS NOT NULL
                        AND NOT (
                            l_line_type_category_code = 'RETURN'
                            AND ( p_lines_tbl(l_line_tbl_index).return_reference_type IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_number
                            IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_line IS NOT NULL )
                        )
                    THEN
                        l_row_count := 0;
                        SELECT
                            COUNT(1)
                        INTO l_row_count
                        FROM
                            mtl_item_sub_inventories misi
                        WHERE
                                1 = 1
                     --AND mp.organization_id = mp.master_organization_id
                            AND misi.organization_id = l_inventory_org_id
                     --  AND misi.inventory_item_id = l_inventory_item_id
                            AND misi.secondary_inventory = p_lines_tbl(l_line_tbl_index).reservation_subinventory;

                        IF l_row_count > 0 THEN
                            l_line_tbl(l_line_tbl_index).attribute17 := p_lines_tbl(l_line_tbl_index).reservation_subinventory;
                            print_debug('SubInventory exists --> Yes ' || l_inventory_item_id);
                        ELSE
                            l_validation_status := 'E';
                            l_val_error_msg := '...'
                                               || l_val_error_msg
                                               || '...'
                                               || 'Reservation SubInventory does NOT exist';
                        END IF;

                    END IF;

               --+++++++++ Locator validation ++++++++++++
                    IF
                        p_lines_tbl(l_line_tbl_index).reservation_locator IS NOT NULL
                        AND NOT (
                            l_line_type_category_code = 'RETURN'
                            AND ( p_lines_tbl(l_line_tbl_index).return_reference_type IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_number
                            IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_line IS NOT NULL )
                        )
                    THEN
                        IF p_lines_tbl(l_line_tbl_index).reservation_subinventory IS NULL THEN
                            l_validation_status := 'E';
                            l_val_error_msg := '...'
                                               || l_val_error_msg
                                               || '...'
                                               || 'Locator provided without Sub Inventory';
                        ELSE
                            l_row_count := 0;
                            SELECT
                                COUNT(1)
                            INTO l_row_count
                            FROM
                                mtl_item_locations mil
                            WHERE
                                    1 = 1
                                AND mil.disable_date IS NULL
                                AND mil.enabled_flag = 'Y'
                        --AND  MIL.SUBINVENTORY_CODE =:$FLEX$.DJOINV_RESERV_SUBINV
                                AND mil.status_id IN (
                                    SELECT
                                        status_id
                                    FROM
                                        mtl_material_statuses_vl
                                    WHERE
                                        reservable_type = 1
                                )
                        --AND mp.organization_id = mp.master_organization_id
                                AND mil.organization_id = l_inventory_org_id
                        -- AND mil.inventory_item_id = l_inventory_item_id
                                AND mil.subinventory_code = p_lines_tbl(l_line_tbl_index).reservation_subinventory
                                AND mil.segment1
                                    || '.'
                                    || mil.segment2
                                    || '.'
                                    || mil.segment3 = p_lines_tbl(l_line_tbl_index).reservation_locator;

                            IF l_row_count > 0 THEN
                                l_line_tbl(l_line_tbl_index).attribute18 := p_lines_tbl(l_line_tbl_index).reservation_locator;
                                print_debug('Reservation Locator exists --> Yes ' || l_inventory_item_id);
                            ELSE
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || 'Reservation Locator does NOT exist';
                            END IF;

                        END IF;
                    END IF;

               --+++++++++ Lot Number validation ++++++++++++
                    IF
                        p_lines_tbl(l_line_tbl_index).lot_number IS NOT NULL
                        AND NOT (
                            l_line_type_category_code = 'RETURN'
                            AND ( p_lines_tbl(l_line_tbl_index).return_reference_type IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_number
                            IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_line IS NOT NULL )
                        )
                    THEN
                        l_row_count := 0;
                        SELECT
                            COUNT(1)
                        INTO l_row_count
                        FROM
                            djoinv_reservable_qty_v drqv
                        WHERE
                                drqv.inventory_item_id = l_inventory_item_id
                            AND ( ( drqv.locator_id IN (
                                SELECT
                                    inventory_location_id
                                FROM
                                    mtl_item_locations
                                WHERE
                                    segment1
                                    || '.'
                                    || segment2
                                    || '.'
                                    || segment3 = p_lines_tbl(l_line_tbl_index).reservation_locator
                                                                                                                                            --AND drqv.lot = ( p_lines_tbl(l_line_tbl_index).lot_number )
                            ) )
                                  AND drqv.lot = ( p_lines_tbl(l_line_tbl_index).lot_number )
                                  AND organization_id = l_inventory_org_id
                                                                      /*OR ( drqv.subinventory = 'Do Not Use'
                                                                          AND drqv.lot = ( p_lines_tbl(l_line_tbl_index).lot_number )
                                                                          AND NOT EXISTS (
                                                                      SELECT
                                                                          *
                                                                      FROM
                                                                          djoinv_reservable_qty_v a
                                                                      WHERE
                                                                          ( a.lot = ( p_lines_tbl(l_line_tbl_index).lot_number )
                                                                          AND a.inventory_item_id = l_inventory_item_id
                                                                          AND a.locator_id IN (
                                                                              SELECT
                                                                                  inventory_location_id
                                                                              FROM
                                                                                  mtl_item_locations
                                                                              WHERE
                                                                                  segment1
                                                                                  || '.'
                                                                                  || segment2
                                                                                  || '.'
                                                                                  || segment3 = p_lines_tbl(l_line_tbl_index).reservation_locator
                                                                          ) )
                                                                  ) ) )*/ );

                   /*FROM mtl_lot_numbers mln
                  WHERE 1 = 1
                    --AND mp.organization_id = mp.master_organization_id
                    AND mln.organization_id = l_inventory_org_id
                    AND mln.inventory_item_id = l_inventory_item_id
                    AND mln.lot_number = p_lines_tbl(l_line_tbl_index).lot_number;*/
                        IF l_row_count > 0 THEN
                            l_line_tbl(l_line_tbl_index).attribute19 := p_lines_tbl(l_line_tbl_index).lot_number;
                            print_debug('Lot Number exists --> Yes ');
                        ELSE
                            l_validation_status := 'E';
                            l_val_error_msg := l_val_error_msg
                                               || p_lines_tbl(l_line_tbl_index).lot_number
                                               || ' - Reservation Lot Number is not available';
                        END IF;

                    END IF;

               -- Line attributes
                    l_line_tbl(l_line_tbl_index).inventory_item_id := l_inventory_item_id;
                    l_line_tbl(l_line_tbl_index).ordered_quantity := nvl(p_lines_tbl(l_line_tbl_index).quantity, 1);
               --l_line_tbl(l_line_tbl_index).ship_from_org_id := 207;
                    l_line_tbl(l_line_tbl_index).ship_from_org_id := l_inventory_org_id;
                    IF p_lines_tbl(l_line_tbl_index).include_in_construct_flag = 'Y' THEN
                        l_line_tbl(l_line_tbl_index).ship_set := substr(p_header_rec.order_number, 1, 30);
                    ELSE
                        l_line_tbl(l_line_tbl_index).ship_set := NULL;
                    END IF;

                    l_line_tbl(l_line_tbl_index).fulfillment_set := substr(p_header_rec.order_number, 1, 30);

--      l_line_tbl(l_line_tbl_index).subinventory := 'FGI';
                    IF p_lines_tbl(l_line_tbl_index).case_price IS NOT NULL THEN
                        l_line_tbl(l_line_tbl_index).unit_selling_price := p_lines_tbl(l_line_tbl_index).case_price;
                    END IF;

                    IF p_lines_tbl(l_line_tbl_index).line_number IS NOT NULL THEN
                        l_line_tbl(l_line_tbl_index).line_number := p_lines_tbl(l_line_tbl_index).line_number;
                    END IF;

                    IF p_lines_tbl(l_line_tbl_index).calculate_price_flag IS NOT NULL THEN
                  -- l_line_tbl(l_line_tbl_index).calculate_price_flag := p_lines_tbl(l_line_tbl_index).calculate_price_flag;
                        l_line_tbl(l_line_tbl_index).calculate_price_flag := 'Y';
                    END IF;

                    IF
                        p_header_rec.order_source != 'ImplantBase'
                        AND p_header_rec.deliver_to_address1 IS NOT NULL
                    THEN
                        l_line_tbl(l_line_tbl_index).deliver_to_party_site_id := lx_deliver_to_party_site_id;
                    END IF;

                    IF
                        p_header_rec.order_source != 'ImplantBase'
                        AND p_header_rec.shipto_contact_first_name IS NOT NULL
                    THEN
                        l_line_tbl(l_line_tbl_index).ship_to_contact_id := lx_shipto_contact_point_id;
                    END IF;

                    IF l_line_type_category_code = 'RETURN' THEN
                        l_line_tbl(l_line_tbl_index).fulfillment_set := NULL;
                  --l_line_tbl(l_line_tbl_index).return_reason_code := 'WRONG PRODUCT';
                        l_line_tbl(l_line_tbl_index).shipping_instructions := 'TEST';
                        l_line_tbl(l_line_tbl_index).ordered_quantity := nvl(p_lines_tbl(l_line_tbl_index).quantity, 1);
                  -- l_line_tbl(l_line_tbl_index).ship_set := NULL;
                        l_line_tbl(l_line_tbl_index).fulfillment_set := substr(p_header_rec.order_number, 1, 30);

                        IF p_lines_tbl(l_line_tbl_index).include_in_construct_flag = 'Y' THEN
                            l_line_tbl(l_line_tbl_index).ship_set := substr(p_header_rec.order_number, 1, 30);
                        ELSE
                            l_line_tbl(l_line_tbl_index).ship_set := NULL;
                        END IF;

                        print_debug('Fulfillment sets --> ' || l_line_tbl(l_line_tbl_index).fulfillment_set);

                  -- SET calculate price flag on each line to 'Y' if source is Implant base and order type RMA
                        IF p_header_rec.order_source = 'ImplantBase' THEN
                            l_line_tbl(l_line_tbl_index).calculate_price_flag := 'Y';
                        END IF;

                  --Validating return reason before assigning to lines table
                        BEGIN
                            l_return_reason_code := NULL;
                            SELECT
                                lookup_code
                            INTO l_return_reason_code
                            FROM
                                fnd_lookup_values
                            WHERE
                                    1 = 1
                                AND lookup_type = 'CREDIT_MEMO_REASON'
                                AND language = userenv('LANG')
                                AND enabled_flag = 'Y'
                                AND trunc(sysdate) BETWEEN trunc(start_date_active) AND trunc(nvl(end_date_active, sysdate))
                                AND meaning = p_lines_tbl(l_line_tbl_index).reason_code;

                            l_line_tbl(l_line_tbl_index).return_reason_code := l_return_reason_code;
                            print_debug('l_return_reason_code --> ' || l_return_reason_code);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || 'Return reason does not exist in the lookup. pls provide valid return reason.-->'
                                                   ;
                            WHEN OTHERS THEN
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || 'Error in fetching Return reason-->'
                                                   || sqlerrm
                                                   || '...'
                                                   || dbms_utility.format_error_backtrace();

                        END;

                  -- RMA reference data Validation
                        IF p_lines_tbl(l_line_tbl_index).return_reference_type IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_number
                        IS NOT NULL OR p_lines_tbl(l_line_tbl_index).return_reference_line IS NOT NULL THEN
                            l_ref_rma_data_sts := 'Y';
                            l_line_tbl(l_line_tbl_index).return_context := p_lines_tbl(l_line_tbl_index).return_reference_type;
                            BEGIN
                                l_rma_src_hdr_id := NULL;
                                SELECT
                                    header_id,
                                    sold_to_org_id
                                INTO
                                    l_rma_src_hdr_id,
                                    l_rma_src_sold_to_org_id
                                FROM
                                    oe_order_headers_all ooha
                                WHERE
                                        1 = 1
                                    AND ooha.order_number = p_lines_tbl(l_line_tbl_index).return_reference_number
                                    AND ooha.order_source_id = l_order_source_id;

                                l_line_tbl(l_line_tbl_index).return_attribute1 := to_char(l_rma_src_hdr_id);
                                l_header_rec.sold_to_org_id := l_rma_src_sold_to_org_id;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    l_validation_status := 'E';
                                    l_val_error_msg := '...'
                                                       || l_val_error_msg
                                                       || '...'
                                                       || 'Error in fetching header id for return reference number->'
                                                       || sqlerrm
                                                       || '...'
                                                       || dbms_utility.format_error_backtrace();

                            END;

                            IF l_rma_src_hdr_id IS NOT NULL THEN
                                BEGIN
                                    l_rma_src_line_id := NULL;
                                    SELECT
                                        oola.line_id,
                                        oola.attribute17,
                                        oola.attribute18,
                                        oola.attribute19
                                    INTO
                                        l_rma_src_line_id,
                                        l_rma_res_sub,
                                        l_rma_res_locator,
                                        l_rma_locator
                                    FROM
                                        oe_order_lines_all oola
                                    WHERE
                                            1 = 1
                                        AND to_char(oola.line_number) = p_lines_tbl(l_line_tbl_index).return_reference_line
                                        AND oola.header_id = l_rma_src_hdr_id;

                                    print_debug('Line attributes --> '
                                                || l_rma_res_sub
                                                || l_rma_res_locator
                                                || l_rma_locator);
                                    l_line_tbl(l_line_tbl_index).return_attribute2 := to_char(l_rma_src_line_id);
                                    l_line_tbl(l_line_tbl_index).context := 'DIRECT';
                                    l_line_tbl(l_line_tbl_index).attribute17 := l_rma_res_sub;
                           --p_lines_tbl(l_line_tbl_index).reservation_subinventory;
                                    l_line_tbl(l_line_tbl_index).attribute18 := l_rma_res_locator;
                           --p_lines_tbl(l_line_tbl_index).reservation_locator;
                                    l_line_tbl(l_line_tbl_index).attribute19 := l_rma_locator;            --p_lines_tbl(l_line_tbl_index).lot_number;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        l_validation_status := 'E';
                                        l_val_error_msg := '...'
                                                           || l_val_error_msg
                                                           || '...'
                                                           || 'Error in fetching header id for return reference line->'
                                                           || sqlerrm
                                                           || '...'
                                                           || dbms_utility.format_error_backtrace();

                                END;
                            END IF;

                        END IF;

                  --+++++++
                  --Check if any line is pre-shipping phase. if yes ,throw an validation error message as RMA can not be created against such an order.
                  --++++++
                        BEGIN
                            l_return_item_total_qty := 0;
                            SELECT
                                COUNT(1)
                            INTO l_return_item_total_qty
                            FROM
                                oe_order_lines_all   oola,
                                oe_order_headers_all ooha
                            WHERE
                                    oola.header_id = ooha.header_id
                                AND ooha.flow_status_code <> 'CANCELLED'
                                AND ooha.order_source_id = l_order_source_id
                                AND ooha.header_id = l_rma_src_hdr_id
                                AND oola.flow_status_code NOT IN ('FULFILLED', 'INVOICED', 'CLOSED');--( 'CANCELLED', 'SHIPPED', 'AWAITING_FULFILLMENT', 'AWAITING_SHIPPING', 'CUSTOMER_ACCEPTED' );

                            IF l_return_item_total_qty > 0 THEN
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || ' some lines are yet to be fulfilled. Return order can not be created.';
                            END IF;

                        END;

                  --+++++++
                  --Check if line quantity has already been returned
                  --++++++
                        FOR l_so_lines IN (
                            SELECT
                                msib.segment1 item_number,
                                ooha.orig_sys_document_ref,
                                oola.inventory_item_id,
                                oola.ordered_quantity
                            FROM
                                oe_order_lines_all   oola,
                                oe_order_headers_all ooha,
                                mtl_system_items_b   msib
                            WHERE
                                    oola.header_id = ooha.header_id
                                AND ooha.flow_status_code <> 'CANCELLED'
                                AND ooha.order_source_id = l_order_source_id
                                AND oola.flow_status_code <> 'CANCELLED'
                                AND oola.inventory_item_id = msib.inventory_item_id
                                AND oola.ship_from_org_id = msib.organization_id
                                AND oola.line_id = l_rma_src_line_id
                                AND oola.header_id = l_rma_src_hdr_id
                        ) LOOP
                            l_return_item_total_qty := 0;
                            SELECT
                                SUM(abs(oola.ordered_quantity))
                            INTO l_return_item_total_qty
                            FROM
                                oe_order_lines_all   oola,
                                oe_order_headers_all ooha
                            WHERE
                                    oola.header_id = ooha.header_id
                                AND ooha.flow_status_code <> 'CANCELLED'
                                AND ooha.order_source_id = l_order_source_id
                                AND substr(ooha.orig_sys_document_ref,
                                           instr(ooha.orig_sys_document_ref, '-', 1) + 1) = l_so_lines.orig_sys_document_ref
                                AND oola.flow_status_code <> 'CANCELLED'
                                AND oola.inventory_item_id = l_so_lines.inventory_item_id
                                AND oola.line_id = l_rma_src_line_id;

                            IF l_return_item_total_qty > l_so_lines.ordered_quantity THEN
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || 'Full quantity has been returned for the item '
                                                   || l_so_lines.item_number;

                            END IF;

                        END LOOP;

--++++++++++
                        IF l_ref_rma_data_sts = 'Y' THEN
                            IF ( p_lines_tbl(l_line_tbl_index).return_reference_type IS NULL OR p_lines_tbl(l_line_tbl_index).return_reference_number
                            IS NULL OR p_lines_tbl(l_line_tbl_index).return_reference_line IS NULL ) THEN
                                l_validation_status := 'E';
                                l_val_error_msg := '...'
                                                   || l_val_error_msg
                                                   || '...'
                                                   || 'Reference data is not provided completely. Type, Number, Line should be provided for every row in the same order.'
                                                   ;
                            ELSE
                                l_ref_rma_yn := 'Y';
                            END IF;
                        END IF;

                    END IF;

                END LOOP;

            END IF;                                                                                             -- end if for p_lines_tbl.COUNT
        END IF;                                                                                                  -- fi Original ib order logic

      --l_line_tbl(2) := l_line_tbl(1);

      --for handling Lot number or serial number
            /*
               FOR l_lots_tbl_index IN l_line_tbl.FIRST .. l_line_tbl.LAST LOOP
                  print_debug('LOTS TABLE COUNTER --> ' || l_lots_tbl_index);

      --            l_lot_serial_tbl(l_lots_tbl_index) := OE_ORDER_PUB.G_MISS_LINE_REC;
                  l_lot_serial_tbl(l_lots_tbl_index).operation := OE_GLOBALS.G_OPR_CREATE;
      --            l_lot_serial_tbl(l_lots_tbl_index).operation :=OE_GLOBALS.G_OPR_UPDATE;

                  l_lot_serial_tbl(l_lots_tbl_index).line_index := l_line_tbl(l_lots_tbl_index).line_number;
                  l_lot_serial_tbl(l_lots_tbl_index).line_id := l_line_tbl(l_lots_tbl_index).line_id;
                  l_lot_serial_tbl(l_lots_tbl_index).lot_number := p_lines_tbl(l_lots_tbl_index).lot_number;
                  l_lot_serial_tbl(l_lots_tbl_index).quantity := l_line_tbl(l_lots_tbl_index).ordered_quantity;
                  l_lot_serial_tbl(l_lots_tbl_index).from_serial_number := null; --p_lines_tbl(l_lots_tbl_index).from_serial_number;
                  l_lot_serial_tbl(l_lots_tbl_index).to_serial_number := null; --p_lines_tbl(l_lots_tbl_index).to_serial_number;
                  l_lot_serial_tbl(l_lots_tbl_index).created_by := fnd_global.user_id;
                  l_lot_serial_tbl(l_lots_tbl_index).creation_date := SYSDATE;
                  l_lot_serial_tbl(l_lots_tbl_index).last_updated_by := fnd_global.user_id;
                  l_lot_serial_tbl(l_lots_tbl_index).last_update_date := SYSDATE;
                  l_lot_serial_tbl(l_lots_tbl_index).last_update_login := fnd_global.login_id;
                  print_debug(' l_lot_serial_tbl(l_lots_tbl_index).line_id -->'|| l_lot_serial_tbl(l_lots_tbl_index).line_id);
                  print_debug(' l_lot_serial_tbl(l_lots_tbl_index).line_index -->'|| l_lot_serial_tbl(l_lots_tbl_index).line_index);
                  print_debug(' l_lot_serial_tbl(l_lots_tbl_index).lot_number -->'|| l_lot_serial_tbl(l_lots_tbl_index).lot_number);
                  print_debug(' l_lot_serial_tbl(l_lots_tbl_index).quantity -->'|| l_lot_serial_tbl(l_lots_tbl_index).quantity);
               END LOOP;
               */
        IF l_validation_status = 'E' THEN
            x_return_status := 'E';
            x_return_message := l_val_error_msg;
            RAISE l_data_valid_excep;
        ELSE
            print_debug('data validation passed.');
        END IF;

        FOR l_line_tbl_idx IN l_line_tbl.first..l_line_tbl.last LOOP
            print_debug('l_line_tbl.LINES TABLE COUNTER --> ' || l_line_tbl_idx);
        END LOOP;

      -- IF IT IS REFERENCED RMA.
--      IF l_ref_rma_yn != 'Y' THEN
--      print_debug('BEFIRE calling  djooic_om_impbs_process_order_pkg.CREATE_REF_RMA--> ');
--         djooic_om_impbs_process_order_pkg.create_ref_rma(p_so_header_rec       => l_header_rec
--                                                         ,p_so_lines_tbl        => l_line_tbl
--                                                         ,p_x_header_rec        => l_x_header_rec
--                                                         ,p_x_line_tbl          => l_x_line_tbl
--                                                         ,x_return_status       => l_return_status
--                                                         ,x_return_message      => l_msg_data);
--
--      print_debug('AFTER calling  djooic_om_impbs_process_order_pkg.CREATE_REF_RMA--> ');
--      ELSE
         -- CALL TO PROCESS ORDER Check the return status and then commit.

      --"TRANSACTION_PHASE_CODE"should be set to "N" while using Process Order API to import quote.
        print_debug('Before calling oe_order_pub.process_order');
        oe_order_pub.process_order(p_api_version_number => 1.0, p_init_msg_list => fnd_api.g_true, p_return_values => fnd_api.g_true,
        p_action_commit => fnd_api.g_false, x_return_status => l_return_status,
                                  x_msg_count => l_msg_count, x_msg_data => l_msg_data, p_header_rec => l_header_rec, p_line_tbl => l_line_tbl
                                  , p_action_request_tbl => l_action_request_tbl
                                --     ,p_lot_serial_tbl              => l_lot_serial_tbl
                                     -- OUT PARAMETERS
                                  ,
                                  x_header_rec => l_x_header_rec, x_header_val_rec => x_header_val_rec, x_header_adj_tbl => x_header_adj_tbl
                                  , x_header_adj_val_tbl => x_header_adj_val_tbl, x_header_price_att_tbl => x_header_price_att_tbl,
                                  x_header_adj_att_tbl => x_header_adj_att_tbl, x_header_adj_assoc_tbl => x_header_adj_assoc_tbl, x_header_scredit_tbl => x_header_scredit_tbl
                                  , x_header_scredit_val_tbl => x_header_scredit_val_tbl, x_line_tbl => l_x_line_tbl,
                                  x_line_val_tbl => x_line_val_tbl, x_line_adj_tbl => x_line_adj_tbl, x_line_adj_val_tbl => x_line_adj_val_tbl
                                  , x_line_price_att_tbl => x_line_price_att_tbl, x_line_adj_att_tbl => x_line_adj_att_tbl,
                                  x_line_adj_assoc_tbl => x_line_adj_assoc_tbl, x_line_scredit_tbl => x_line_scredit_tbl, x_line_scredit_val_tbl => x_line_scredit_val_tbl
                                  , x_lot_serial_tbl => x_lot_serial_tbl, x_lot_serial_val_tbl => x_lot_serial_val_tbl,
                                  x_action_request_tbl => l_x_action_request_tbl);

        print_debug('AFTER oe_order_pub.process_order call');
        print_debug('oe_order_pub.process_order call l_return_status ->' || l_return_status);

--      END IF;

      -- Retrieve messages
        FOR i IN 1..l_msg_count LOOP
            fnd_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false, p_data => l_msg_data, p_msg_index_out => l_msg_index_out)
            ;

            print_debug('message is: ' || l_msg_data);
            print_debug('message index is: ' || l_msg_index_out);
        END LOOP;

      -- Check the return status
        IF l_return_status = fnd_api.g_ret_sts_success THEN
            print_debug('Process Order Sucess. Order# ' || l_x_header_rec.order_number);
         --DBMS_OUTPUT.put_line('l_x_header_rec.header_id# ' || l_x_header_rec.header_id);
         --DBMS_OUTPUT.put_line('l_x_header_rec.flow_status_code# ' || l_x_header_rec.flow_status_code);
            lx_order_rec.order_header_id := l_x_header_rec.header_id;
            lx_order_rec.order_number := l_x_header_rec.order_number;
            lx_order_rec.order_status := l_x_header_rec.flow_status_code;
            COMMIT;

         --
            -- if customer is on credit check, return the message that order is on hold along with success status.
          --
            IF l_account_credit_check_flag = 'Y' THEN
                BEGIN
                    SELECT
                        decode(COUNT(1),
                               0,
                               'N',
                               'Y')
                    INTO l_unreleased_credit_hold_yn
                    FROM
                        oe_order_holds_all   oohold,
                        oe_hold_sources_all  ohs,
                        oe_hold_definitions  ohd,
                        oe_order_headers_all ooh
                    WHERE
                            oohold.hold_source_id = ohs.hold_source_id
                        AND ohs.hold_id = ohd.hold_id
                        AND ooh.header_id = oohold.header_id
                        AND ohd.name = 'Credit Check Failure'
                        AND ohd.type_code = 'CREDIT'
                        AND oohold.released_flag = 'N'
                        AND ooh.header_id = lx_order_rec.order_header_id;

                    IF l_unreleased_credit_hold_yn = 'Y' THEN
                        l_msg_data := l_msg_data || 'Order is on Credit Check Failure Hold';
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        print_debug('Error while verifying if order is on credit hold. ' || sqlerrm);
                END;
            END IF;

            BEGIN
                apps.oe_oe_totals_summary.order_totals(l_x_header_rec.header_id, l_so_basic_tot, l_so_discount, l_so_charges, l_so_tax
                );

                l_order_total_amount := l_so_basic_tot + l_so_charges + l_so_tax;
                print_debug('Process Order Sucess. Order# ' || l_x_header_rec.order_number);
                print_debug('Fetching order total. ' || l_order_total_amount);
                print_debug('Process Order Sucess. Order header ID ' || lx_order_rec.order_header_id);
                print_debug('Process Order Sucess. Order Status ' || l_x_header_rec.flow_status_code);
                l_order_total_amount := NULL;
                l_so_basic_tot := NULL;
                l_so_charges := NULL;
                l_so_tax := NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    print_debug('Error fetching order total. ' || sqlerrm);
            END;

           -- Updating pricing
           --We should take the cal price flag as Y even though it is N
         --Then we get the modifier ,Cal the line price vs mod price and create a line and display the price
            BEGIN
                l_so_lines_tbl := p_lines_tbl;
                djooic_om_impbs_process_order_pkg.update_so_line_price(p_so_header_id => l_x_header_rec.header_id, p_so_lines_tbl => l_so_lines_tbl
                , x_return_status => lx_upd_price_ret_status, x_return_message => lx_upd_price_ret_message);

            EXCEPTION
                WHEN OTHERS THEN
                    print_debug('Error updating case price. ' || sqlerrm);
            END;

         -- end of Updating pricing
            BEGIN
                apps.oe_oe_totals_summary.order_totals(l_x_header_rec.header_id, l_so_basic_tot, l_so_discount, l_so_charges, l_so_tax
                );

                l_order_total_amount := l_so_basic_tot + l_so_charges + l_so_tax;
          /*UPDATE oe_order_headers_all
             SET CONTEXT = 'DIRECT'
           WHERE header_id = l_x_header_rec.header_id;

          COMMIT;*/
          -- print_debug('l_order_total_amount. ' || l_order_total_amount);
          --
          -- updating reservations with lot
          --
         /* update_reservation(p_header_id           => l_x_header_rec.header_id
                            ,p_lines_tbl           => l_line_tbl
                            ,x_return_status       => lx_upd_res_ret_status
                            ,x_return_message      => lx_upd_res_ret_message);*/
            EXCEPTION
                WHEN OTHERS THEN
                    print_debug('Error fetching order total. ' || sqlerrm);
            END;

            lx_order_rec.order_total_amount := l_order_total_amount;
            x_order_rec := lx_order_rec;
         -- x_return_message := l_error_msg;
            x_return_message := l_msg_data;
            x_return_status := l_return_status;
            l_process_order_rec.transaction_id := l_transaction_id;
         --l_process_order_rec.item := l_lines_tbl(1).part_number;
            l_process_order_rec.customer := p_header_rec.hospital_account_number;
            l_process_order_rec.pricing_date := sysdate;
            l_process_order_rec.ib_order_number := p_header_rec.order_number;
         --l_process_order_rec.price_list_name := l_price_list;
         --l_process_order_rec.list_price := lx_lines_tbl(1).unit_list_price;
         --l_process_order_rec.selling_price := lx_lines_tbl(1).unit_sell_price;
            l_process_order_rec.error_code := x_return_status;
            l_process_order_rec.error_message := x_return_message;
            l_process_order_rec.oic_status := 'N';
            l_process_order_rec.oic_error_message := NULL;
            l_process_order_rec.interface_identifier := 'IMPBS';
            l_process_order_rec.created_by := fnd_global.user_id;                                                                       --'-1';
            l_process_order_rec.creation_date := sysdate;
            l_process_order_rec.last_update_date := sysdate;
            l_process_order_rec.last_updated_by := fnd_global.user_id;                                                                  --'-1';
            l_process_order_rec.last_update_login := NULL;
            populate_staging(l_process_order_rec);
            COMMIT;                                                                                       -- SAVING THE ORDER CREATION api CALL
        ELSE
            print_debug('Failed to create Order.');
            x_return_status := l_return_status;
            x_return_message := l_msg_data;
            x_order_rec := lx_order_rec;
            ROLLBACK;
        END IF;

        FOR i IN 1..oe_debug_pub.g_debug_count LOOP
            print_debug(oe_debug_pub.g_debug_tbl(i));
        END LOOP;

        print_debug('End of djooic_om_impbs_process_order_pkg.create_order');
    EXCEPTION
        WHEN l_upd_so_compl THEN
            l_process_order_rec.transaction_id := l_transaction_id;
         --l_process_order_rec.item := l_lines_tbl(1).part_number;
            l_process_order_rec.customer := p_header_rec.hospital_account_number;
            l_process_order_rec.pricing_date := sysdate;
            l_process_order_rec.ib_order_number := p_header_rec.order_number;
         --l_process_order_rec.price_list_name := l_price_list;
         --l_process_order_rec.list_price := lx_lines_tbl(1).unit_list_price;
         --l_process_order_rec.selling_price := lx_lines_tbl(1).unit_sell_price;
            l_process_order_rec.error_code := x_return_status;
            l_process_order_rec.error_message := x_return_message;
            l_process_order_rec.oic_status := 'N';
            l_process_order_rec.oic_error_message := NULL;
            l_process_order_rec.interface_identifier := 'IMPBS';
            l_process_order_rec.created_by := fnd_global.user_id;                                                                      --'-1';
            l_process_order_rec.creation_date := sysdate;
            l_process_order_rec.last_update_date := sysdate;
            l_process_order_rec.last_updated_by := fnd_global.user_id;                                                                 --'-1';
            l_process_order_rec.last_update_login := NULL;
            populate_staging(l_process_order_rec);
      --COMMIT;
        WHEN l_data_valid_excep THEN
            print_debug('Validation Status Code: ' || x_return_status);
            print_debug('Validation error message -->: ' || x_return_message);
            l_process_order_rec.transaction_id := l_transaction_id;
         --l_process_order_rec.item := l_lines_tbl(1).part_number;
            l_process_order_rec.customer := p_header_rec.hospital_account_number;
            l_process_order_rec.pricing_date := sysdate;
            l_process_order_rec.ib_order_number := p_header_rec.order_number;
            l_process_order_rec.price_list_name := l_price_list;
         -- l_process_order_rec.list_price := NULL;
         -- l_process_order_rec.selling_price := NULL;
            l_process_order_rec.error_code := x_return_status;
            l_process_order_rec.error_message := x_return_message;
            l_process_order_rec.oic_status := 'N';
            l_process_order_rec.oic_error_message := NULL;
            l_process_order_rec.interface_identifier := 'IMPBS';
            l_process_order_rec.created_by := fnd_global.user_id;                                                                      --'-1';
            l_process_order_rec.creation_date := sysdate;
            l_process_order_rec.last_update_date := sysdate;
            l_process_order_rec.last_updated_by := fnd_global.user_id;                                                                 --'-1';
            l_process_order_rec.last_update_login := NULL;
            populate_staging(l_process_order_rec);
       --x_return_status := l_return_status;
       --x_return_message := l_msg_data;
      -- x_order_rec := lx_order_rec;
        WHEN l_apps_init_execp THEN
            print_debug('Status Code: ' || x_return_status);
            print_debug('Apps Initialization error: ' || x_return_message);
            l_process_order_rec.transaction_id := l_transaction_id;
         --l_process_order_rec.item := l_lines_tbl(1).part_number;
            l_process_order_rec.customer := p_header_rec.hospital_account_number;
            l_process_order_rec.pricing_date := sysdate;
            l_process_order_rec.ib_order_number := p_header_rec.order_number;
         -- l_process_order_rec.price_list_name := NULL;
         -- l_process_order_rec.list_price := NULL;
         -- l_process_order_rec.selling_price := NULL;
            l_process_order_rec.error_code := x_return_status;
            l_process_order_rec.error_message := x_return_message;
            l_process_order_rec.oic_status := 'N';
            l_process_order_rec.oic_error_message := NULL;
            l_process_order_rec.interface_identifier := 'IMPBS';
            l_process_order_rec.created_by := fnd_global.user_id;                                                                      --'-1';
            l_process_order_rec.creation_date := sysdate;
            l_process_order_rec.last_update_date := sysdate;
            l_process_order_rec.last_updated_by := fnd_global.user_id;                                                                 --'-1';
            l_process_order_rec.last_update_login := NULL;
            populate_staging(l_process_order_rec);
         --  x_return_status := l_return_status;
         --  x_return_message := l_msg_data;
            x_order_rec := lx_order_rec;
        WHEN OTHERS THEN
            l_error_msg := 'when others error: '
                           || sqlerrm
                           || '...'
                           || dbms_utility.format_error_backtrace();
            print_debug(l_error_msg);
            x_return_status := 'E';
            x_return_message := l_error_msg;
            l_process_order_rec.transaction_id := l_transaction_id;
         -- l_process_order_rec.item := l_lines_tbl(1).part_number;
            l_process_order_rec.customer := p_header_rec.hospital_account_number;
            l_process_order_rec.pricing_date := sysdate;
            l_process_order_rec.ib_order_number := p_header_rec.order_number;
            l_process_order_rec.price_list_name := NULL;
            l_process_order_rec.list_price := NULL;
            l_process_order_rec.selling_price := NULL;
            l_process_order_rec.error_code := x_return_status;
            l_process_order_rec.error_message := x_return_message;
            l_process_order_rec.oic_status := 'N';
            l_process_order_rec.oic_error_message := NULL;
            l_process_order_rec.interface_identifier := 'IMPBS';
            l_process_order_rec.created_by := fnd_global.user_id;                                                                      --'-1';
            l_process_order_rec.creation_date := sysdate;
            l_process_order_rec.last_update_date := sysdate;
            l_process_order_rec.last_updated_by := fnd_global.user_id;                                                                 --'-1';
            l_process_order_rec.last_update_login := NULL;
            populate_staging(l_process_order_rec);
         --  x_return_status := l_return_status;
          -- x_return_message := l_msg_data;
            x_order_rec := lx_order_rec;
    END create_order;
--++++++++++++++++++++++++++++
END djooic_om_impbs_process_order_pkg;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" TO "XXOIC";
  GRANT DEBUG ON "APPS"."DJOOIC_OM_IMPBS_PROCESS_ORDER_PKG" TO "XXOIC";

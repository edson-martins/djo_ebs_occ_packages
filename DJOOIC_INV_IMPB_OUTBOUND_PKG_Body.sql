--------------------------------------------------------
--  DDL for Package Body DJOOIC_INV_IMPB_OUTBOUND_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_INV_IMPB_OUTBOUND_PKG" 
IS
    /**************************************************************************************
    *    Copyright (c) DJO
    *     All rights reserved
    ***************************************************************************************
    *
    *   HEADER
    *   Package Body
    *
    *   PROGRAM NAME
    *   DJOOIC_INV_IMPB_OUTBOUND_PKG.pkb
    *
    *   DESCRIPTION
    *   Creation Script of Package Body for ImplantBase Outbound Interface
    *
    *   USAGE
    *   To create Package Body of the package DJOOIC_INV_IMPB_OUTBOUND_PKG
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
    -- Private Global variables
    L_MAX_RECORD   NUMBER := 5000;

    /* Design Overview:
    Keep data in staging TABLE
    if staging is empty insert all extracted records
    if staging contain records
       same records exists in extract and staging
       check if any attribute changes
          yes replace staging records
       no do nothing
       new record insert into staging
     */
    ------------------------------------------------------------------------------
	/**************************************************************************************
    *
    *   PROCEDURE
    *     debug
    *
    *   DESCRIPTION
    *   Insert debug message into temp table 
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *   p_string           IN               Debug message
	*
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/

    PROCEDURE debug (p_string VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_string   VARCHAR2 (4000) := p_string;
        l_id       NUMBER;
    BEGIN
        l_id := TO_NUMBER (TO_CHAR (SYSDATE, 'YYMMDDHH24MISS'));

        INSERT INTO DJOOIC_BE_DEBUG_LOG_TMP (id, text)
             VALUES (l_id, l_string);

        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END debug;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     fnd_debug
    *
    *   DESCRIPTION
    *   Insert debug message into fnd_log_messages table 
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *   p_string           IN               Debug message
	*
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE fnd_debug (p_string VARCHAR2)
    IS
        l_string   VARCHAR2 (4000) := p_string;
        l_id       VARCHAR2 (50);
    BEGIN
        l_id := TO_CHAR (SYSDATE, 'YYMMDDHH24MISS');
        fnd_log.string (fnd_log.level_statement,
                        'DJOOIC_INV_IMPB_OUTBOUND_PKG.master_items_pr',
                        l_id || ': ' || l_string);
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_log.string (fnd_log.level_statement,
                            'DJOOIC_INV_IMPB_OUTBOUND_PKG.master_items_pr',
                            l_id || ': ' || SQLERRM);
    END fnd_debug;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     change_stag_record
    *
    *   DESCRIPTION
    *   Insert/update data in djooic_hz_distributors_stg table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *   p_distributor_rec  IN               Distributor staging record
	*   p_type             IN               Insert/Update
	*   x_error_code       OUT              Error Code
	*   x_error_msg        OUT              Error Message
	*
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE change_stag_record (
				p_distributor_rec   IN     djooic_hz_distributors_stg%ROWTYPE,
				p_type              IN     VARCHAR2,
				x_error_code        OUT    VARCHAR2,
				x_error_msg         OUT    VARCHAR2
				)
    IS
        l_distributor_rec   djooic_hz_distributors_stg%ROWTYPE
                                := p_distributor_rec;
        l_type              VARCHAR2 (5) := p_type;
        l_error_code        VARCHAR2 (10) := 'SUCCESS';
    BEGIN
        IF l_type = 'R'
        THEN
            UPDATE djooic_hz_distributors_stg
               SET party_id = l_distributor_rec.party_id,
                   account_number = l_distributor_rec.account_number,
                   party_name = l_distributor_rec.party_name,
                   address1 = l_distributor_rec.address1,
                   city = l_distributor_rec.city,
                   state = l_distributor_rec.state,
                   postal_code = l_distributor_rec.postal_code,
                   person_first_name = l_distributor_rec.person_first_name,
                   person_last_name = l_distributor_rec.person_last_name,
                   email_address = l_distributor_rec.email_address,
                   agent_number = l_distributor_rec.agent_number,
                   error_code = 'SUCCESS',
                   error_message = NULL,
                   oic_status = 'N',
                   oic_error_message = NULL,
                   Interface_Identifier = 'IMPB',
                   --created_by = 1516,
                   --creation_date = SYSDATE,
                   last_updated_by = 1516,
                   last_update_date = SYSDATE,
                   last_update_login = 0
             WHERE party_id = l_distributor_rec.party_id;
        ELSE
            INSERT INTO djooic_hz_distributors_stg (party_id,
                                                    account_number,
                                                    party_name,
                                                    address1,
                                                    city,
                                                    state,
                                                    postal_code,
                                                    person_first_name,
                                                    person_last_name,
                                                    email_address,
                                                    agent_number,
                                                    error_code,
                                                    error_message,
                                                    oic_status,
                                                    oic_error_message,
                                                    Interface_Identifier,
                                                    created_by,
                                                    creation_date,
                                                    last_updated_by,
                                                    last_update_date,
                                                    last_update_login)
                 VALUES (l_distributor_rec.party_id,
                         l_distributor_rec.account_number,
                         l_distributor_rec.party_name,
                         l_distributor_rec.address1,
                         l_distributor_rec.city,
                         l_distributor_rec.state,
                         l_distributor_rec.postal_code,
                         l_distributor_rec.person_first_name,
                         l_distributor_rec.person_last_name,
                         l_distributor_rec.email_address,
                         l_distributor_rec.agent_number,
                         l_distributor_rec.error_code,
                         l_distributor_rec.error_message,
                         l_distributor_rec.oic_status,
                         l_distributor_rec.oic_error_message,
                         l_distributor_rec.Interface_Identifier,
                         l_distributor_rec.created_by,
                         l_distributor_rec.creation_date,
                         l_distributor_rec.last_updated_by,
                         l_distributor_rec.last_update_date,
                         l_distributor_rec.last_update_login);
        END IF;
        COMMIT;
        x_error_code := l_error_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_code := 'ERROR';
            x_error_msg := SQLERRM;
            debug (DBMS_UTILITY.format_error_backtrace || ':' || x_error_msg);
    END change_stag_record;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     change_item_stag_record
    *
    *   DESCRIPTION
    *   Insert/update staging table data
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *   p_item_rec         IN               Master item staging record
	*   p_type             IN               Insert/Update
	*   x_error_code       OUT              Error Code
	*   x_error_msg        OUT              Error Message
	*
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE change_item_stag_record (
        p_item_rec   IN     djooic_inv_items_stg%ROWTYPE,
        p_type              IN     VARCHAR2,
        x_error_code           OUT VARCHAR2,
        x_error_msg            OUT VARCHAR2)
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
		l_item_rec   djooic_inv_items_stg%ROWTYPE
                                := p_item_rec;
	    l_item_exist        VARCHAR2 (1)  := 'N';
        l_type              VARCHAR2 (5)  := p_type;
        l_error_code        VARCHAR2 (10) := 'SUCCESS';
    BEGIN
        IF l_type = 'R'
        THEN
            UPDATE djooic_inv_items_stg
               SET item_id = l_item_rec.item_id,
                   part_number = l_item_rec.part_number,
                   type = l_item_rec.type,
                   item_type = l_item_rec.item_type,
                   description = l_item_rec.description,
                   gtin = l_item_rec.gtin,
                   uom_code = l_item_rec.uom_code,
                   lot_controlled = l_item_rec.lot_controlled,
                   track_lot_number = l_item_rec.track_lot_number,
                   serial_controlled = l_item_rec.serial_controlled,
                   construct = l_item_rec.construct,
				   status = l_item_rec.status,
				   organization_code = l_item_rec.organization_code,
                   error_code = 'SUCCESS',
                   error_message = NULL,
                   oic_status = 'N',
                   oic_error_message = NULL,
                   Interface_Identifier = 'IMPB',
                   created_by = l_item_rec.created_by,
                   creation_date = l_item_rec.creation_date,
                   last_updated_by = 1516,
                   last_update_date = SYSDATE,
                   last_update_login = 0
             WHERE item_id = l_item_rec.item_id;
        ELSE
		    BEGIN
               SELECT 'Y'
			     INTO l_item_exist
			     FROM djooic_inv_items_stg
				WHERE item_id = l_item_rec.item_id;
			EXCEPTION
			   WHEN OTHERS THEN
			      l_item_exist := 'N';
			END;
			IF l_item_exist = 'N'
			THEN
			   INSERT INTO djooic_inv_items_stg (item_id,
				  								 part_number,
												 type,
												 item_type,
												 description,
												 gtin,
												 uom_code,
												 lot_controlled,
												 track_lot_number,
												 serial_controlled,
												 construct,
												 status,
												 organization_code,
												 error_code,
												 error_message,
												 oic_status,
												 oic_error_message,
												 Interface_Identifier,
												 created_by,
												 creation_date,
												 last_updated_by,
												 last_update_date,
												 last_update_login)
			   VALUES ( l_item_rec.item_id,
					    l_item_rec.part_number,
						l_item_rec.type,
						l_item_rec.item_type,    
						l_item_rec.description,
						l_item_rec.gtin,
						l_item_rec.uom_code,
						l_item_rec.lot_controlled,
						l_item_rec.track_lot_number,
						l_item_rec.serial_controlled,
						l_item_rec.construct,
						l_item_rec.status,
						l_item_rec.organization_code,
						l_item_rec.error_code,
						l_item_rec.error_message,
						l_item_rec.oic_status,
						l_item_rec.oic_error_message,
						l_item_rec.Interface_Identifier,
						l_item_rec.created_by,
						l_item_rec.creation_date,
						l_item_rec.last_updated_by,
						l_item_rec.last_update_date,
						l_item_rec.last_update_login);
			  COMMIT;
			  dbms_lock.sleep(10);
		   END IF;	
        END IF;
        COMMIT;
        x_error_code := l_error_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_code := 'ERROR';
            x_error_msg := SQLERRM;
            debug (DBMS_UTILITY.format_error_backtrace || ':' || x_error_msg);
    END change_item_stag_record;
		/**************************************************************************************
    *
    *   PROCEDURE
    *     change_item_stag_record
    *
    *   DESCRIPTION
    *   Insert/update staging table data
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *   p_item_rec         IN               Master item staging record
	*   p_type             IN               Insert/Update
	*   x_error_code       OUT              Error Code
	*   x_error_msg        OUT              Error Message
	*
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE change_txn_stag_record (
        p_txn_rec   IN     djooic_inv_transactions_stg%ROWTYPE,
        x_error_code           OUT VARCHAR2,
        x_error_msg            OUT VARCHAR2)
    IS
	    PRAGMA AUTONOMOUS_TRANSACTION;
        l_txn_rec   djooic_inv_transactions_stg%ROWTYPE
                                := p_txn_rec;
        l_error_code        VARCHAR2 (10) := 'SUCCESS';
    BEGIN
       INSERT INTO djooic_inv_transactions_stg
				   (transaction_id,
					transfer_transaction_id,
					transaction_date,
					transaction_type,
					transaction_reference,
					item,
					transaction_quantity,
					lot_quantity,
					lot_number,
					expiration_date,
					serial_number,
					organization_code,
					subinventory_code,
					locator,
					trnsfer_org_code,
					transfer_subinventory,
					transfer_locator,
					error_code,
					error_message,
					oic_status,
					oic_error_message,
					Interface_Identifier,
					created_by,
					creation_date,
					last_updated_by,
					last_update_date,
					last_update_login)
       VALUES (l_txn_rec.transaction_id,
			   l_txn_rec.transfer_transaction_id,
			   l_txn_rec.transaction_date,
			   l_txn_rec.transaction_type,
			   l_txn_rec.transaction_reference,
			   l_txn_rec.item,
			   l_txn_rec.transaction_quantity,
			   l_txn_rec.lot_quantity,
			   l_txn_rec.lot_number,
			   l_txn_rec.expiration_date,
               l_txn_rec.serial_number,
               l_txn_rec.organization_code,
               l_txn_rec.subinventory_code,
               l_txn_rec.locator,
               l_txn_rec.trnsfer_org_code,
               l_txn_rec.transfer_subinventory,
               l_txn_rec.transfer_locator,
               l_txn_rec.error_code,
               l_txn_rec.error_message,
               l_txn_rec.oic_status,
               l_txn_rec.oic_error_message,
               l_txn_rec.Interface_Identifier,
               l_txn_rec.created_by,
               l_txn_rec.creation_date,
               l_txn_rec.last_updated_by,
               l_txn_rec.last_update_date,
               l_txn_rec.last_update_login
			   );
        COMMIT;
        x_error_code := l_error_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_error_code := 'ERROR';
            x_error_msg := SQLERRM;
            debug (DBMS_UTILITY.format_error_backtrace || ':' || x_error_msg);
    END change_txn_stag_record;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     extract_inv_transactions
    *
    *   DESCRIPTION
    *   Load data into DJOOIC_INV_TRANSACTIONS_STG table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE extract_inv_transactions (p_txn_id IN NUMBER)
    IS
        ----------------------------------------------------------------------------------
        -- Cursor to get inventory adjustment transactions information
        ----------------------------------------------------------------------------------
        CURSOR cur_transactions (p_txn_id IN NUMBER)
        IS
        SELECT mmt.transaction_id,
			   mmt.transfer_transaction_id,
			   mmt.transaction_date,  
            DECODE(mtt.transaction_type_name, 
                   'Account alias receipt', 'Write-On',
                   'Account alias issue', 'Write-off',
                   'Subinventory Transfer', 'Transfer',
                   'Direct Org Transfer', 'Transfer',
				   'Cycle Count Adjust', 'Cycle-count',
                   'Cycle Count Transfer','Cycle-count', 
                   'Physical Inv Adjust', 'Physical-inv',
                   'Physical Inv Transfer''Physical-inv',
                   'Others')transaction_type,
			   mmt.transaction_reference,
			   msi.segment1 Item, 
			   ABS(mmt.transaction_quantity) transaction_quantity,
			   mtln.transaction_quantity lot_quantity,
			   mtln.lot_number,
			   mln.expiration_date,
			   (SELECT LISTAGG(serial_number,',') WITHIN GROUP(ORDER BY serial_number) serial 
				  FROM MTL_UNIT_TRANSACTIONS 
				 WHERE transaction_id=mmt.transaction_id AND msi.serial_number_control_code!=1)serial_number,
			   mp.organization_code, 
			   mmt.subinventory_code, 
			   milk.concatenated_segments Locator, 
			   (select organization_code from mtl_parameters where organization_id=transfer_organization_id) Trnsfer_Org_Code, 
			   mmt.transfer_subinventory,
			   (select concatenated_segments from apps.mtl_item_locations_kfv where inventory_location_id=mmt.transfer_locator_id) Transfer_Locator
		  FROM apps.mtl_transaction_types mtt,
			   apps.mtl_transaction_lot_numbers mtln,
			   apps.mtl_material_transactions mmt,
			   apps.mtl_system_items_b msi,
			   apps.mtl_parameters mp,
			   apps.mtl_lot_numbers mln,
			   apps.mtl_item_locations_kfv milk
		 WHERE msi.inventory_item_id = mmt.inventory_item_id
		   AND mtln.transaction_id(+)=mmt.transaction_id
		   AND mtln.inventory_item_id(+)=mmt.inventory_item_id
		   AND mtln.organization_id(+)=mmt.organization_id
		   AND mtln.lot_number=mln.lot_number(+)
		   AND mtln.organization_id=mln.organization_id(+)
		   AND mtln.inventory_item_id=mln.inventory_item_id(+)
		   AND mmt.organization_id=msi.organization_id
		   AND msi.organization_id = mp.organization_id
		   AND mmt.organization_id=milk.organization_id
		   AND mmt.locator_id=milk.inventory_location_id
		   AND mmt.transaction_type_id=mtt.transaction_type_id
		   --Added below to restrict transaction created by ImplantBase Inbound
		   AND NVL(mmt.source_code, 'NORMAL')  NOT IN ( 'ImplantBase Write-on', 'ImplantBase Write-off', 'ImplantBase Bank Transfer',
		                                                'ImplantBase Direct Transfer', 'ImplantBase Transfer Parts'
		                                              )
		   AND ((p_txn_id = 18012014 AND mmt.transaction_date >= SYSDATE-5/(24*60))
		   OR (p_txn_id = 1 AND mmt.transaction_date >= SYSDATE-10/(24*60))
		   )
		   AND mtt.transaction_type_name IN ('Account alias receipt', 'Account alias issue', 'Subinventory Transfer', 'Direct Org Transfer',
											 'Cycle Count Adjust', 'Cycle Count Transfer', 'Physical Inv Adjust', 'Physical Inv Transfer')
		   AND ( (transfer_organization_id IS NOT NULL AND mmt.transaction_quantity < 0) OR (transfer_organization_id IS NULL AND 1=1))
		   AND (
			   (transfer_organization_id IS NOT NULL AND (((mp.organization_code ='AUS' AND mmt.subinventory_code='BANK')
				OR(transfer_organization_id=83 AND transfer_subinventory='BANK' )) 
				OR (mp.organization_code ='400' OR transfer_organization_id=102))
				)
			  OR (transfer_organization_id IS NULL AND ((mp.organization_code ='AUS' AND mmt.subinventory_code='BANK') 
				  OR (mp.organization_code ='400' AND 1=1 ))
				  )
		   )
		ORDER BY mmt.transaction_id;
        ----------------------------------------------------------------------------------
        -- Cursor to get transactions information from staging
        ----------------------------------------------------------------------------------
        CURSOR cur_stag_txn (p_txn_id IN NUMBER)
        IS
            SELECT transaction_id,
				   transfer_transaction_id,
				   transaction_date,
				   transaction_type,  
				   transaction_reference,
				   item,
				   transaction_quantity,
				   lot_quantity,
				   lot_number,
				   expiration_date,
				   serial_number,
				   organization_code,
				   subinventory_code,
				   locator,
				   trnsfer_org_code,
				   transfer_subinventory,
				   transfer_locator,
                   error_code,
                   error_message,
                   oic_status,
                   oic_error_message,
                   interface_identifier,
                   created_by,
                   creation_date,
                   last_updated_by,
                   last_update_date,
                   last_update_login  
              FROM DJOOIC_INV_TRANSACTIONS_STG
             WHERE transaction_id = p_txn_id;
        --------------------------------------------------------------------------
        -- Private Variables
        --------------------------------------------------------------------------
        l_record_count        NUMBER := 0;
        l_stag_txns           cur_stag_txn%ROWTYPE;
        l_error_code          VARCHAR2 (10);
        l_error_msg           VARCHAR2 (2000);
        l_stag_count          NUMBER := 0;
        l_txn_id              NUMBER := p_txn_id;
        TYPE djooic_txn_tbl_type IS TABLE OF cur_transactions%ROWTYPE
            INDEX BY BINARY_INTEGER;
        djooic_txn_tbl   djooic_txn_tbl_type;
    BEGIN
        debug ('Fetching Records FOR txn: '||l_txn_id);
		dbms_lock.sleep(45);
        BEGIN
            OPEN cur_transactions (l_txn_id);
            FETCH cur_transactions BULK COLLECT INTO djooic_txn_tbl;
            IF djooic_txn_tbl.COUNT = 0
            THEN
                debug ('No Records');
            ELSE
			   l_record_count := djooic_txn_tbl.COUNT;
			   debug ('Records: ' || l_record_count);
            END IF;
            CLOSE cur_transactions;
        EXCEPTION
            WHEN OTHERS THEN
                debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;
        debug ('Check count: ' || djooic_txn_tbl.COUNT);
        IF djooic_txn_tbl.COUNT > 0
		THEN
		   FOR i IN djooic_txn_tbl.FIRST .. djooic_txn_tbl.LAST
		   LOOP
			  OPEN cur_stag_txn (djooic_txn_tbl(i).transaction_id);
			  --debug('Processing record with party Id: '||djooic_txn_tbl(i).transaction_id);
			  FETCH cur_stag_txn INTO l_stag_txns;
			  l_stag_count := cur_stag_txn%ROWCOUNT;
			  CLOSE cur_stag_txn;
			  IF l_stag_count = 0
			  THEN
				 BEGIN
					debug ('Inserting record with transaction Id: '|| djooic_txn_tbl(i).transaction_id);
					l_stag_txns.transaction_id          := djooic_txn_tbl(i).transaction_id;
					l_stag_txns.transfer_transaction_id := djooic_txn_tbl(i).transfer_transaction_id;
					l_stag_txns.transaction_date        := djooic_txn_tbl(i).transaction_date;
					l_stag_txns.transaction_type        := djooic_txn_tbl(i).transaction_type;
					l_stag_txns.transaction_reference   := djooic_txn_tbl(i).transaction_reference;
					l_stag_txns.item                    := djooic_txn_tbl(i).item;
					l_stag_txns.transaction_quantity    := djooic_txn_tbl(i).transaction_quantity;
					l_stag_txns.lot_quantity            := djooic_txn_tbl(i).lot_quantity;
					l_stag_txns.lot_number              := djooic_txn_tbl(i).lot_number;
					l_stag_txns.expiration_date         := djooic_txn_tbl(i).expiration_date;
					l_stag_txns.serial_number           := djooic_txn_tbl(i).serial_number;
					l_stag_txns.organization_code       := djooic_txn_tbl(i).organization_code;
					l_stag_txns.subinventory_code       := djooic_txn_tbl(i).subinventory_code;
					l_stag_txns.locator                 := djooic_txn_tbl(i).locator;
					l_stag_txns.trnsfer_org_code        := djooic_txn_tbl(i).trnsfer_org_code;
					l_stag_txns.transfer_subinventory   := djooic_txn_tbl(i).transfer_subinventory;
					l_stag_txns.transfer_locator        := djooic_txn_tbl(i).transfer_locator;
					l_stag_txns.error_code              := 'SUCCESS';
					l_stag_txns.error_message           := NULL;
					l_stag_txns.oic_status              := 'N';
					l_stag_txns.oic_error_message       := NULL;
					l_stag_txns.Interface_Identifier    := 'IMPB';
					l_stag_txns.created_by              := 1516;
					l_stag_txns.creation_date           := SYSDATE;
					l_stag_txns.last_updated_by         := 1516;
					l_stag_txns.last_update_date        := SYSDATE;
					l_stag_txns.last_update_login       := 0;
					change_txn_stag_record (
						p_txn_rec    => l_stag_txns,
						x_error_code => l_error_code,
						x_error_msg  => l_error_msg);
					EXCEPTION
						WHEN OTHERS
						THEN
							debug (
								   DBMS_UTILITY.format_error_backtrace
								|| ':'
								|| SQLERRM);
							debug ('IF l_stag_count = 0');
					END;
				END IF;
			END LOOP;
        END IF;
        debug (l_record_count || ' record(s) processed.');
    EXCEPTION
        WHEN OTHERS
        THEN
            debug (
                'Error occurred while populating Table DJOOIC_INV_ITEMS_STG');
            debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
    END extract_inv_transactions;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     extract_items
    *
    *   DESCRIPTION
    *   Load data into DJOOIC_INV_ITEMS_STG table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE extract_items (p_item_id IN NUMBER)
    IS
        ----------------------------------------------------------------------------------
        -- Cursor to get distributors information
        ----------------------------------------------------------------------------------
        CURSOR cur_items (p_item_id IN NUMBER)
        IS
        SELECT msib.inventory_item_id item_id,
				msib.segment1 part_number,
				(
				 SELECT initcap(substr(micv.segment1, instr(micv.segment1, ' ')+1))
				   FROM apps.mtl_item_categories_v micv,
				 	    apps.mtl_parameters mp
				  WHERE micv.inventory_item_id = msib.inventory_item_id
				    AND micv.organization_id = mp.organization_id
				    AND micv.category_set_name = 'Products'
				    AND mp.organization_id=mp.master_organization_id
				) type,
				flv.meaning item_type,
				regexp_replace(msib.description, '[^0-9A-Za-z]', ' ')   description,
				mcr.cross_reference                                     gtin,
				msib.primary_uom_code                                   uom_code,
				decode(msib.lot_control_code, 1, 'No', 2, 'Yes')        lot_controlled,
				decode(msib.lot_control_code, 1, 'No', 2, 'Yes')        track_lot_number,
				decode(msib.serial_number_control_code, 1, 'No', 'Yes') serial_controlled,
				decode(msib.item_type, 'SPG', 'Yes', 'No')              construct,
				decode(msib.inventory_item_status_code, 'Active', 'Active', 'Phase-Out', 'Active', 'Inactive') status,
				mtp.organization_code
			FROM apps.mtl_system_items_b     msib,
				apps.mtl_parameters       mtp,
				apps.mtl_cross_references mcr,
				apps.fnd_lookup_values_vl flv
			WHERE 1 = 1
			  AND msib.inventory_item_id = mcr.inventory_item_id (+)
			  AND mcr.cross_reference_type (+) = 'BARCODE'
			  --AND msib.inventory_item_status_code  in ('Active','Phase-Out')
			  AND mtp.organization_id = msib.organization_id
			  AND mtp.organization_code = 'AUS'
			  AND flv.lookup_type = 'ITEM_TYPE'
			  AND msib.item_type = flv.lookup_code
			  AND EXISTS  (
					SELECT 1
					  FROM qp_list_headers       qlh,
						   qp_list_lines         qll,
						   qp_pricing_attributes qpa
					 WHERE 1=1
					   AND qlh.name IN ( 'SURGICAL USLIST', 'SURGICAL USLISTINST' )
					   AND qlh.list_header_id = qll.list_header_id
					   AND qpa.list_line_id = qll.list_line_id
					   AND  (qll.end_date_active is  null or sysdate between qll.start_date_active and qll.end_date_active)
					   AND to_char(msib.inventory_item_id) = qpa.product_attr_value
					   ) 
                AND ((p_item_id IS NULL
						AND ((    msib.last_update_date >= SYSDATE - 1 / 144
						     AND msib.creation_date < TRUNC (SYSDATE))
						      OR msib.creation_date >= SYSDATE - 1 / 144))
						 OR (p_item_id = 1 --AND msib.last_update_date >= SYSDATE - 1 / 144 
						 )
						 OR msib.inventory_item_id = p_item_id)					   
				UNION
				SELECT msib.inventory_item_id item_id,
				msib.segment1 part_number,
				(
				 SELECT initcap(substr(micv.segment1, instr(micv.segment1, ' ')+1))
				   FROM apps.mtl_item_categories_v micv,
				 	   apps.mtl_parameters mp
				  WHERE micv.inventory_item_id = msib.inventory_item_id
				    AND micv.organization_id = mp.organization_id
				    AND micv.category_set_name = 'Products'
				    AND mp.organization_id=mp.master_organization_id
				)                                                       type,
				flv.meaning item_type,
				regexp_replace(msib.description, '[^0-9A-Za-z]', ' ')   description,
				mcr.cross_reference                                     gtin,
				msib.primary_uom_code                                   uom_code,
				decode(msib.lot_control_code, 1, 'No', 2, 'Yes')        lot_controlled,
				decode(msib.lot_control_code, 1, 'No', 2, 'Yes')        track_lot_number,
				decode(msib.serial_number_control_code, 1, 'No', 'Yes') serial_controlled,
				decode(msib.item_type, 'SPG', 'Yes', 'No')              construct,
				decode(msib.inventory_item_status_code, 'Active', 'Active', 'Phase-Out', 'Active', 'Inactive')  status,
				mtp.organization_code
			FROM apps.mtl_system_items_b     msib,
				 apps.mtl_parameters       mtp,
				 apps.mtl_cross_references mcr,
				 apps.fnd_lookup_values_vl flv
			WHERE 1 = 1
				AND msib.inventory_item_id = mcr.inventory_item_id (+)
				AND mcr.cross_reference_type (+) = 'BARCODE'
				--AND msib.inventory_item_status_code  in ('Active','Phase-Out')
				AND mtp.organization_id = msib.organization_id
				AND mtp.organization_code = 'AUS'
				AND flv.lookup_type = 'ITEM_TYPE'
				AND msib.item_type = flv.lookup_code
				AND EXISTS(
						  SELECT  1
							FROM qp_secondary_price_lists_v qspl,
								 qp_list_headers            qlh,
								 qp_list_lines              qll,
								 qp_pricing_attributes      qpa
							 WHERE 1=1
							   and qspl.parent_price_list_id = to_char(qlh.list_header_id)
							   and qspl.list_header_id = qll.list_header_id
							   AND qlh.name IN ( 'SURGICAL USLIST', 'SURGICAL USLISTINST' )
							   and  (qll.end_date_active is  null or sysdate between qll.start_date_active and qll.end_date_active)
							   AND qpa.list_line_id = qll.list_line_id
							   AND to_char(msib.inventory_item_id) = qpa.product_attr_value
					  )
				AND ((p_item_id IS NULL
						AND ((    msib.last_update_date >= SYSDATE - 1 / 144
						     AND msib.creation_date < TRUNC (SYSDATE))
						      OR msib.creation_date >= SYSDATE - 1 / 144))
						 OR (p_item_id = 1 --AND msib.last_update_date >= SYSDATE - 1 / 144 
						                     )
						 OR msib.inventory_item_id = p_item_id)
            ;
        ----------------------------------------------------------------------------------
        -- Cursor to get items information from staging
        ----------------------------------------------------------------------------------
        CURSOR cur_stag_item (p_item_id IN NUMBER)
        IS
        SELECT ITEM_ID,
			   PART_NUMBER,
			   TYPE,
			   ITEM_TYPE,    
			   DESCRIPTION,
			   GTIN,
			   UOM_CODE,
			   LOT_CONTROLLED,
			   TRACK_LOT_NUMBER,
			   SERIAL_CONTROLLED,
			   CONSTRUCT,
			   STATUS,
			   ORGANIZATION_CODE,
                error_code,
                error_message,
                oic_status,
                oic_error_message,
                interface_identifier,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login
           FROM DJOOIC_INV_ITEMS_STG
          WHERE item_id = p_item_id;
        --------------------------------------------------------------------------
        -- Private Variables
        --------------------------------------------------------------------------
        l_record_count        NUMBER := 0;
        l_stag_items          cur_stag_item%ROWTYPE;
        l_error_code          VARCHAR2 (10);
        l_error_msg           VARCHAR2 (2000);
        l_stag_count          NUMBER := 0;
        l_item_id             NUMBER := p_item_id;
        TYPE djooic_item_tbl_type IS TABLE OF cur_items%ROWTYPE
            INDEX BY BINARY_INTEGER;
        djooic_item_tbl   djooic_item_tbl_type;
    BEGIN
        debug ('01. Fetching Records: ');
		dbms_lock.sleep(10);
		debug ('02. Item Id: '||l_item_id);
        BEGIN
            OPEN cur_items (l_item_id);
            FETCH cur_items BULK COLLECT INTO djooic_item_tbl;
            IF djooic_item_tbl.COUNT = 0
            THEN
                debug ('03. No Records');
            ELSE
			   l_record_count := djooic_item_tbl.COUNT;
			   debug ('03. Records: ' || l_record_count);
            END IF;
            CLOSE cur_items;
        EXCEPTION
            WHEN OTHERS THEN
                debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;

        debug ('04. Check count: ' || djooic_item_tbl.COUNT);
        IF djooic_item_tbl.COUNT > 0
		THEN
		   FOR i IN djooic_item_tbl.FIRST .. djooic_item_tbl.LAST
		   LOOP
			  OPEN cur_stag_item (djooic_item_tbl(i).item_id);
			  --debug('Processing record with party Id: '||djooic_item_tbl(i).item_id);
			  FETCH cur_stag_item INTO l_stag_items;
			  l_stag_count := cur_stag_item%ROWCOUNT;
			  CLOSE cur_stag_item;
			  IF l_stag_count = 0
			  THEN
				 BEGIN
					debug ('05. Inserting record with item Id: '|| djooic_item_tbl (i).item_id);
					l_stag_items.item_id :=
						djooic_item_tbl (i).item_id;
					l_stag_items.part_number :=
						djooic_item_tbl (i).part_number;
					l_stag_items.type :=
						djooic_item_tbl (i).type;
					l_stag_items.item_type :=
						djooic_item_tbl (i).item_type;
					l_stag_items.description := djooic_item_tbl (i).description;
					l_stag_items.gtin :=
						djooic_item_tbl (i).gtin;
					l_stag_items.uom_code :=
						djooic_item_tbl (i).uom_code;
					l_stag_items.lot_controlled :=
						djooic_item_tbl (i).lot_controlled;
					l_stag_items.track_lot_number :=
						djooic_item_tbl (i).track_lot_number;
					l_stag_items.serial_controlled :=
						djooic_item_tbl (i).serial_controlled;
					l_stag_items.construct :=
						djooic_item_tbl (i).construct;
					l_stag_items.status :=
						djooic_item_tbl (i).status;
					l_stag_items.organization_code :=
						djooic_item_tbl (i).organization_code;
					l_stag_items.ERROR_CODE := 'SUCCESS';
					l_stag_items.error_message := NULL;
					l_stag_items.oic_status := 'N';
					l_stag_items.oic_error_message := NULL;
					l_stag_items.Interface_Identifier := 'IMPB';
					l_stag_items.created_by := 1516;
					l_stag_items.creation_date := SYSDATE;
					l_stag_items.last_updated_by := 1516;
					l_stag_items.last_update_date := SYSDATE;
					l_stag_items.last_update_login := 0;
					change_item_stag_record (
						p_item_rec   => l_stag_items,
						p_type              => 'I',
						x_error_code        => l_error_code,
						x_error_msg         => l_error_msg);
					EXCEPTION
						WHEN OTHERS
						THEN
							debug (
								   DBMS_UTILITY.format_error_backtrace
								|| ':'
								|| SQLERRM);
							debug ('IF l_stag_count = 0');
					END;
				ELSE
					BEGIN
						IF (l_stag_items.type != djooic_item_tbl(i).type)
						   OR (l_stag_items.item_type != djooic_item_tbl(i).item_type)
						   OR (l_stag_items.description != djooic_item_tbl(i).description)
						   OR (l_stag_items.gtin != djooic_item_tbl(i).gtin)
						   OR (l_stag_items.lot_controlled != djooic_item_tbl(i).lot_controlled)
						   OR (l_stag_items.serial_controlled != djooic_item_tbl(i).serial_controlled)
						   OR (l_stag_items.status != djooic_item_tbl(i).status)
						THEN
							debug ( '05. Updating record with item Id: ' || djooic_item_tbl (i).item_id);
							l_stag_items.item_id :=
								djooic_item_tbl (i).item_id;
							l_stag_items.part_number :=
								djooic_item_tbl (i).part_number;
							l_stag_items.type :=
								djooic_item_tbl (i).type;
							l_stag_items.item_type :=
								djooic_item_tbl (i).item_type;
							l_stag_items.description :=
								djooic_item_tbl (i).description;
							l_stag_items.gtin :=
								djooic_item_tbl (i).gtin;
							l_stag_items.uom_code :=
								djooic_item_tbl (i).uom_code;
							l_stag_items.lot_controlled :=
								djooic_item_tbl (i).lot_controlled;
							l_stag_items.track_lot_number :=
								djooic_item_tbl (i).track_lot_number;
							l_stag_items.serial_controlled :=
								djooic_item_tbl (i).serial_controlled;
							l_stag_items.construct :=
								djooic_item_tbl (i).construct;
							l_stag_items.status :=
								djooic_item_tbl (i).status;
							l_stag_items.organization_code :=
								djooic_item_tbl (i).organization_code;
							l_stag_items.ERROR_CODE := 'SUCCESS';
							l_stag_items.error_message := NULL;
							l_stag_items.oic_status := 'N';
							l_stag_items.oic_error_message := NULL;
							--l_stag_items.Interface_Identifier:= 'IMPB';
							--l_stag_items.created_by      := 1516;
							--l_stag_items.creation_date     := SYSDATE;
							l_stag_items.last_updated_by := 1516;
							l_stag_items.last_update_date := SYSDATE;
							l_stag_items.last_update_login := 0;
							change_item_stag_record (
								p_item_rec   => l_stag_items,
								p_type       => 'R',
								x_error_code => l_error_code,
								x_error_msg  => l_error_msg);
						END IF;
					EXCEPTION
						WHEN OTHERS
						THEN
							debug (
								   DBMS_UTILITY.format_error_backtrace
								|| ':'
								|| SQLERRM);
							debug ('IF l_stag_count = 0--ELSE');
					END;
				END IF;
			END LOOP;
        END IF;
        debug ('06. '||l_record_count || ' record(s) processed.');
    EXCEPTION
        WHEN OTHERS
        THEN
            debug (
                'Error occurred while populating Table DJOOIC_INV_ITEMS_STG');
            debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
    END extract_items;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     extract_distributors
    *
    *   DESCRIPTION
    *   Load data into djoinv_cdm_items table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE extract_distributors (p_party_id IN NUMBER)
    IS
        ----------------------------------------------------------------------------------
        -- Cursor to get distributors information
        ----------------------------------------------------------------------------------
        CURSOR cur_distributors (p_party_id IN NUMBER)
        IS
              SELECT hca.account_number,
                     hp.party_id,
                     hp.party_name,
                     hp.address1,
                     hp.city,
                     hp.state,
                     hp.postal_code,
                     hp.person_first_name,
                     hp.person_last_name,
                     hp.email_address,
                     hl.location_code     agent_number,
                     hca.primary_salesrep_id
                FROM hz_parties                   hp,
                     hz_cust_accounts             hca,
                     hz_party_sites               hps,
                     qp_list_headers              qlh,
                     hz_cust_acct_sites_all       hcas,
                     hz_cust_site_uses_all        hcsu,
                     po_location_associations_all pla,
                     hr_locations                 hl
               WHERE hp.party_type = 'ORGANIZATION'
                 AND hp.status = 'A'
                 AND hca.party_id = hp.party_id
                 AND hca.status = 'A'
                 AND hca.price_list_id = qlh.list_header_id
                 AND qlh.name = 'SURGICAL AGENT'
                 AND hcas.status = 'A'
                 AND hps.party_id = hp.party_id
                 AND hcas.cust_account_id = hca.cust_account_id
                 AND hcas.party_site_id = hps.party_site_id
                 AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id
                 AND pla.site_use_id = hcsu.site_use_id
                 AND hcas.org_id = hcsu.org_id
                 AND pla.org_id = hcas.org_id
                 AND pla.customer_id = hcas.cust_account_id
                 AND hl.location_id = pla.location_id
                 AND hcsu.site_use_code = 'SHIP_TO'
                 AND hcsu.primary_flag = 'Y'
                 AND hps.status = 'A'
                 AND hcas.status = 'A'
                 AND hcsu.status = 'A'
                 AND (   (    p_party_id IS NULL
                          AND (   (    hp.last_update_date >=
                                           SYSDATE - 1 / 144
                                   AND hp.creation_date < TRUNC (SYSDATE))
                                   OR hp.creation_date >= SYSDATE - 1 / 144))
                          OR (p_party_id = 1 AND 1 = 1)
                          OR hp.party_id = p_party_id)
            ORDER BY hca.account_number;
        ----------------------------------------------------------------------------------
        -- Cursor to get distributors information from staging
        ----------------------------------------------------------------------------------
        CURSOR cur_stag_distributor (p_party_id IN NUMBER)
        IS
            SELECT party_id,
                   account_number,
                   party_name,
                   address1,
                   city,
                   state,
                   postal_code,
                   person_first_name,
                   person_last_name,
                   email_address,
                   agent_number,
                   ERROR_CODE,
                   error_message,
                   oic_status,
                   oic_error_message,
                   Interface_Identifier,
                   created_by,
                   creation_date,
                   last_updated_by,
                   last_update_date,
                   last_update_login
              FROM DJOOIC_HZ_DISTRIBUTORS_STG
             WHERE party_id = p_party_id;

        --------------------------------------------------------------------------
        -- Private Variables
        --------------------------------------------------------------------------
        l_record_count        NUMBER := 0;
        l_stag_distributors   cur_stag_distributor%ROWTYPE;
        l_error_code          VARCHAR2 (10);
        l_error_msg           VARCHAR2 (2000);
        l_stag_count          NUMBER := 0;
        l_party_id            NUMBER := p_party_id;

        TYPE djooic_distributor_tbl_type IS TABLE OF cur_distributors%ROWTYPE
            INDEX BY BINARY_INTEGER;
        --
        djooic_distributor_tbl   djooic_distributor_tbl_type;
        djooic_distributor_tmp   djooic_distributor_tbl_type;
    BEGIN
        debug ('Fetching Records: ');
        BEGIN
           OPEN cur_distributors (l_party_id);
           FETCH cur_distributors BULK COLLECT INTO djooic_distributor_tbl;
           IF djooic_distributor_tbl.COUNT = 0
           THEN
              debug ('No Records');
           ELSE                        
			  l_record_count := djooic_distributor_tbl.COUNT;
			  debug ('Records: ' || l_record_count);
           END IF; -- IF cdm_items_tbl.COUNT = 0 THEN
           CLOSE cur_distributors;
        EXCEPTION
           WHEN OTHERS THEN
              debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
        END;
        debug ('Check count: ' || djooic_distributor_tbl.COUNT);
        IF djooic_distributor_tbl.COUNT > 0
		THEN
			FOR i IN djooic_distributor_tbl.FIRST .. djooic_distributor_tbl.LAST
			LOOP
				OPEN cur_stag_distributor (djooic_distributor_tbl (i).party_id);
				--debug('Processing record with party Id: '||djooic_distributor_tbl(i).party_id);
				FETCH cur_stag_distributor INTO l_stag_distributors;

				l_stag_count := cur_stag_distributor%ROWCOUNT;

				CLOSE cur_stag_distributor;

				IF l_stag_count = 0
				THEN
					BEGIN
						debug (
							   'Inserting record with party Id: '
							|| djooic_distributor_tbl (i).party_id);
						l_stag_distributors.party_id :=
							djooic_distributor_tbl (i).party_id;
						l_stag_distributors.account_number :=
							djooic_distributor_tbl (i).account_number;
						l_stag_distributors.party_name :=
							djooic_distributor_tbl (i).party_name;
						l_stag_distributors.address1 :=
							djooic_distributor_tbl (i).address1;
						l_stag_distributors.city := djooic_distributor_tbl (i).city;
						l_stag_distributors.state :=
							djooic_distributor_tbl (i).state;
						l_stag_distributors.postal_code :=
							djooic_distributor_tbl (i).postal_code;
						l_stag_distributors.person_first_name :=
							djooic_distributor_tbl (i).person_first_name;
						l_stag_distributors.person_last_name :=
							djooic_distributor_tbl (i).person_last_name;
						l_stag_distributors.email_address :=
							djooic_distributor_tbl (i).email_address;
						l_stag_distributors.agent_number :=
							djooic_distributor_tbl (i).agent_number;
						l_stag_distributors.ERROR_CODE := 'SUCCESS';
						l_stag_distributors.error_message := NULL;
						l_stag_distributors.oic_status := 'N';
						l_stag_distributors.oic_error_message := NULL;
						l_stag_distributors.Interface_Identifier := 'IMPB';
						l_stag_distributors.created_by := 1516;
						l_stag_distributors.creation_date := SYSDATE;
						l_stag_distributors.last_updated_by := 1516;
						l_stag_distributors.last_update_date := SYSDATE;
						l_stag_distributors.last_update_login := 0;
						change_stag_record (
							p_distributor_rec   => l_stag_distributors,
							p_type              => 'I',
							x_error_code        => l_error_code,
							x_error_msg         => l_error_msg);
					EXCEPTION
						WHEN OTHERS
						THEN
							debug (
								   DBMS_UTILITY.format_error_backtrace
								|| ':'
								|| SQLERRM);
							debug ('IF l_stag_count = 0');
					END;
				ELSE
					BEGIN
						IF    (l_stag_distributors.party_name !=
							   djooic_distributor_tbl (i).party_name)
						   OR (l_stag_distributors.address1 !=
							   djooic_distributor_tbl (i).address1)
						   OR (l_stag_distributors.city !=
							   djooic_distributor_tbl (i).city)
						   OR (l_stag_distributors.state !=
							   djooic_distributor_tbl (i).state)
						   OR (l_stag_distributors.postal_code !=
							   djooic_distributor_tbl (i).postal_code)
						   OR (l_stag_distributors.agent_number !=
							djooic_distributor_tbl (i).agent_number)
						THEN
							debug (
								   'Updating record with party Id: '
								|| djooic_distributor_tbl (i).party_id);
							l_stag_distributors.party_id :=
								djooic_distributor_tbl (i).party_id;
							l_stag_distributors.account_number :=
								djooic_distributor_tbl (i).account_number;
							l_stag_distributors.party_name :=
								djooic_distributor_tbl (i).party_name;
							l_stag_distributors.address1 :=
								djooic_distributor_tbl (i).address1;
							l_stag_distributors.city :=
								djooic_distributor_tbl (i).city;
							l_stag_distributors.state :=
								djooic_distributor_tbl (i).state;
							l_stag_distributors.postal_code :=
								djooic_distributor_tbl (i).postal_code;
							l_stag_distributors.person_first_name :=
								djooic_distributor_tbl (i).person_first_name;
							l_stag_distributors.person_last_name :=
								djooic_distributor_tbl (i).person_last_name;
							l_stag_distributors.email_address :=
								djooic_distributor_tbl (i).email_address;
							l_stag_distributors.agent_number :=
								djooic_distributor_tbl (i).agent_number;
							l_stag_distributors.ERROR_CODE := 'SUCCESS';
							l_stag_distributors.error_message := NULL;
							l_stag_distributors.oic_status := 'N';
							l_stag_distributors.oic_error_message := NULL;
							--l_stag_distributors.Interface_Identifier:= 'IMPB';
							--l_stag_distributors.created_by      := djooic_distributor_tbl (i).created_by;
							--l_stag_distributors.creation_date   := djooic_distributor_tbl (i).creation_date;
							l_stag_distributors.last_updated_by := 1516;
							l_stag_distributors.last_update_date := SYSDATE;
							l_stag_distributors.last_update_login := 0;
							change_stag_record (
								p_distributor_rec   => l_stag_distributors,
								p_type              => 'R',
								x_error_code        => l_error_code,
								x_error_msg         => l_error_msg);
						END IF;
					EXCEPTION
						WHEN OTHERS
						THEN
							debug (
								   DBMS_UTILITY.format_error_backtrace
								|| ':'
								|| SQLERRM);
							debug ('IF l_stag_count = 0--ELSE');
					END;
				END IF;
			END LOOP;
			debug (l_record_count || ' record(s) processed.');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            debug (
                'Error occurred while populating Table djooic_hz_distributors_stg');
            debug (DBMS_UTILITY.format_error_backtrace || ':' || SQLERRM);
    END extract_distributors;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     exec_main_pr
    *
    *   DESCRIPTION
    *   Call the procedure to process data
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   NA
    *
    **************************************************************************************/
    PROCEDURE exec_main_pr (p_errbuf OUT VARCHAR2, p_retcode OUT VARCHAR2)
    IS
    BEGIN
	    p_retcode := 0;
        extract_distributors (1);
		extract_items (1);
		extract_inv_transactions(1);
    EXCEPTION
        WHEN OTHERS
        THEN
            p_errbuf := SQLERRM;
            p_retcode := 1;
    END exec_main_pr;
	/**************************************************************************************
    *
    *   FUNCTION
    *     exec_main_fun
    *
    *   DESCRIPTION
    *   Business Event Subscription to called this function wheneven the specific business event fires
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   ERROR/SUCCESS
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   NA
    *
    **************************************************************************************/
    FUNCTION exec_main_fun (p_subscription_guid   IN            RAW,
                            p_event               IN OUT NOCOPY wf_event_t)
        RETURN VARCHAR2
    IS
	    /*
		Business Events
		oracle.apps.ar.hz.PartySite.create
		oracle.apps.ar.hz.PartySite.update
		oracle.apps.ar.hz.PartySiteUse.create
		oracle.apps.ar.hz.PartySiteUse.update
		oracle.apps.ar.hz.Person.create
		oracle.apps.ar.hz.Person.update
		oracle.apps.inv.itemCreate
		oracle.apps.inv.itemUpdate
		oracle.apps.inv.acctAliasIssue
		oracle.apps.inv.acctIssue
		oracle.apps.inv.acctReceipt
		oracle.apps.inv.miscIssue
		oracle.apps.inv.miscReceipt
		oracle.apps.inv.subinvTransfer
        */
        l_param_list         wf_parameter_list_t;
        l_param_name         VARCHAR2 (240);
        l_param_value        VARCHAR2 (2000);
        l_event_name         VARCHAR2 (2000);
        l_event_key          VARCHAR2 (2000);
        l_event_data         VARCHAR2 (4000);
        l_party_id           NUMBER;
        l_item_id            NUMBER;
        l_party_type         VARCHAR2 (2000);                              --Suresh
        l_location_id        NUMBER;                                       --Suresh
		l_cust_account_id    NUMBER; 
		l_site_use_id        NUMBER;
    BEGIN
        l_param_list := p_event.getparameterlist;
        l_event_name := p_event.geteventname ();
        l_event_key  := p_event.geteventkey ();
        l_event_data := p_event.geteventdata ();
        debug ('EVENT NAME: ' || l_event_name);
        debug ('EVENT KEY: ' || l_event_key);
        debug ('EVENT DATA: ' || l_event_data);
        IF l_param_list IS NOT NULL
        THEN
            FOR i IN l_param_list.FIRST .. l_param_list.LAST
            LOOP
                l_param_name := l_param_list (i).getname;
                l_param_value := l_param_list (i).getvalue;
                debug (l_param_name || ': ' || l_param_value);
            END LOOP;
        END IF;

        IF l_event_name IN
               ('oracle.apps.ar.hz.Organization.create',
                'oracle.apps.ar.hz.Organization.update')
        THEN                                          -- Hospital, Distributor
            l_party_id := p_event.getvalueforparameter ('PARTY_ID');
            DEBUG ('PARTY_ID: ' || l_party_id);
            extract_distributors (l_party_id);
            --djooic_mst_impb_outbound_pkg.extract_hospitals (l_party_id); --Added by suresh for hospitals
		--Added by Samir on 18-Jul-23 Starts
	    ELSIF l_event_name IN ('oracle.apps.ar.hz.CustAcctSiteUse.update')
		THEN
		   l_site_use_id := p_event.getvalueforparameter ('SITE_USE_ID');
		   BEGIN
		      SELECT hps.party_id
                INTO l_party_id			  
			    FROM hz_cust_site_uses_all hcsu, 
				     hz_cust_acct_sites_all hcs, 
				     hz_party_sites hps
               WHERE hcsu.site_use_id=l_site_use_id
                 AND hcsu.cust_acct_site_id=hcs.cust_acct_site_id
                 AND hps.party_site_id=hcs.party_site_id;
		   EXCEPTION
		      WHEN OTHERS THEN
			     l_party_id := 1;
			END;
		   extract_distributors (l_party_id);
		--Added by Samir on 18-Jul-23 Ends
        ---Start : Added by Suresh
        ELSIF l_event_name IN ('oracle.apps.ar.hz.Location.update')
        THEN
            l_location_id := p_event.getvalueforparameter ('LOCATION_ID');

            SELECT DISTINCT hp.party_id, hp.party_type
              INTO l_party_id, l_party_type
              FROM hz_party_sites hps, hz_parties hp
             WHERE hps.party_id = hp.party_id AND location_id = l_location_id;

            IF l_party_type = 'PERSON'
            THEN
                NULL;--djooic_mst_impb_outbound_pkg.extract_surgeons (l_party_id);
            ELSE
                --djooic_mst_impb_outbound_pkg.extract_hospitals (l_party_id);
                extract_distributors (l_party_id);
            END IF;
        -- End : Added by suresh
        ELSIF l_event_name IN
                  ('oracle.apps.ar.hz.Person.create',
                   'oracle.apps.ar.hz.Person.update')
        THEN                                                        --Surgeons
            l_party_id := p_event.getvalueforparameter ('PARTY_ID'); --Added by suresh for hospitals
            --djooic_mst_impb_outbound_pkg.extract_surgeons (l_party_id); --Added by suresh for hospitals
        ELSIF l_event_name IN
                  ('oracle.apps.inv.itemCreate', 'oracle.apps.inv.itemUpdate')
        THEN                                                           --Parts
            l_item_id := p_event.getvalueforparameter ('INVENTORY_ITEM_ID');
            DEBUG ('INVENTORY_ITEM_ID: ' || l_item_id);
        ELSIF l_event_name IN
                  ('oracle.apps.inv.acctAliasReceipt',
                   'oracle.apps.inv.acctAliasIssue',
                   'oracle.apps.inv.subinvTransfer')
        THEN                                           --inventory transaction
            NULL;
		ELSIF l_event_name IN
                  ('oracle.apps.ar.hz.CustAccount.update')
        THEN                                           --inventory transaction
            l_cust_account_id := p_event.getvalueforparameter ('CUST_ACCOUNT_ID');
			BEGIN
               SELECT DISTINCT PARTY_ID 
			     INTO l_party_id 
			     FROM hz_cust_accounts 
				WHERE cust_account_id=l_cust_account_id;
			EXCEPTION
			   WHEN OTHERS THEN
			       wf_core.CONTEXT (pkg_name    => 'DJOOIC_INV_IMPB_OUTBOUND_PKG',
                             proc_name   => 'exec_main_fun',
                             arg1        => p_event.geteventname(),
                             arg2        => p_event.geteventkey(),
                             arg3        => p_subscription_guid);
			      RETURN 'ERROR';
			END;
            NULL; --djooic_mst_impb_outbound_pkg.extract_hospitals (l_party_id);
        END IF;
        RETURN 'SUCCESS';
    EXCEPTION
        WHEN OTHERS
        THEN
            wf_core.CONTEXT (pkg_name    => 'DJOOIC_INV_IMPB_OUTBOUND_PKG',
                             proc_name   => 'exec_main_fun',
                             arg1        => p_event.geteventname (),
                             arg2        => p_event.geteventkey (),
                             arg3        => p_subscription_guid);
            --
            --Retrieves error information from the error stack and sets it into the event message.
            --
            wf_event.seterrorinfo (p_event => p_event, p_type => 'ERROR');
            --
            RETURN 'ERROR';
    END exec_main_fun;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     master_items_pr
    *
    *   DESCRIPTION
    *   Procedure to be called from Oracle Alerts for processing items in the staging table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE master_items_pr (p_item_id           IN NUMBER,
                               p_organization_id   IN NUMBER)
    IS
    BEGIN
        debug ('INVENTORY_ITEM_ID: ' || p_item_id);
        debug ('ORGANIZATION_ID: ' || p_organization_id);
		extract_items (p_item_id => p_item_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            DEBUG ('ERROR: ' || SQLERRM);
    END master_items_pr;
    /**************************************************************************************
    *
    *   PROCEDURE
    *     inv_transactions_pr
    *
    *   DESCRIPTION
    *   Procedure to be called from Oracle Alerts for processing transactions in the staging table
    *
    *   PARAMETERS
    *   ==========
    *   NAME               TYPE             DESCRIPTION
    *   -----------------  --------         -----------------------------------------------
    *
    *   RETURN VALUE
    *   NA
    *
    *   PREREQUISITES
    *   NA
    *
    *   CALLED BY
    *   exec_main_pr
    *
    **************************************************************************************/
    PROCEDURE inv_transactions_pr (p_transaction_id    IN NUMBER,
                                   p_item_id           IN NUMBER,
                                   p_organization_id   IN NUMBER)
    IS
        l_user_id        NUMBER := 1516;   -- REQUEST
        l_resp_id        NUMBER := 20634;  -- Inventory
        l_resp_appl_id   NUMBER := 401;    -- Inventory
		l_txn_id         NUMBER := 1;
    BEGIN
	    SELECT NVL2(p_transaction_id, 18012014, 1) INTO l_txn_id FROM dual;
        debug ('TRANSACTION_ID: ' || p_transaction_id);
        debug ('INVENTORY_ITEM_ID: ' || p_item_id);
        debug ('ORGANIZATION_ID: ' || p_organization_id);
		extract_inv_transactions(l_txn_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            DEBUG ('ERROR: ' || SQLERRM);
    END inv_transactions_pr;
END DJOOIC_INV_IMPB_OUTBOUND_PKG;

/

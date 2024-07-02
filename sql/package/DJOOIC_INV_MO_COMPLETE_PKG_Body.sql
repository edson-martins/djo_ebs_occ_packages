--------------------------------------------------------
--  DDL for Package Body DJOOIC_INV_MO_COMPLETE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_INV_MO_COMPLETE_PKG" 
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
    *   DJOOIC_INV_MO_COMPLETE_PKG.pkb
    *
    *   DESCRIPTION
    *   Creation Script of Package Body for ImplantBase Outbound Interface
    *
    *   USAGE
    *   To create Package Body of the package DJOOIC_INV_MO_COMPLETE_PKG
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
    *   1.0      27-Jul-2023 Saantosh               Creation
    ***************************************************************************************/
    ------------------------------------------------------------------------------
    -- Private Global variables

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
    *   main
    *
    **************************************************************************************/

	PROCEDURE main (errbuf	OUT VARCHAR2,
	                errcod	OUT NUMBER)
    IS
		l_error_status VARCHAR2(1) := 'N';
		l_upd_status   VARCHAR2(1) := 'N';
		l_mo_dtl_upd_date  DATE;


		CURSOR mo_dtls_cur (c_updated_date DATE)
		IS
		SELECT DISTINCT mtrh.header_id
		  FROM mtl_txn_request_headers mtrh,
			   mtl_txn_request_lines mtrl
		 WHERE mtrl.header_id = mtrh.header_id
		   AND mtrh.attribute1 = 'IMPBS'
		   AND mtrh.ORGANIZATION_ID = 83
		   AND mtrl.attribute2 = 'U'
		   AND mtrl.line_status IN (5, 6)
		   AND mtrl.last_update_date >= c_updated_date;

	BEGIN
		fnd_file.put_line(fnd_file.LOG,'Move Order Complte Outbound Process Starts');

        BEGIN
            SELECT MAX(fcr.actual_start_date)
              INTO l_mo_dtl_upd_date
              FROM fnd_concurrent_programs_tl fcp,
                   fnd_concurrent_requests fcr
             WHERE fcp.USER_CONCURRENT_PROGRAM_NAME = 'DJO MoveOrder Complete Outbound Process'
               AND fcp.language = 'US'
               AND fcr.Concurrent_program_id = fcp.Concurrent_program_id
               AND fcr.status_code = 'C';
        EXCEPTION
            WHEN OTHERS THEN
                l_mo_dtl_upd_date := SYSDATE - 1/24;
        END;

		fnd_file.put_line(fnd_file.LOG,'Selected Move Order Transactions Closed / Updated after: '||l_mo_dtl_upd_date);

		FOR mo_dtls_rec IN mo_dtls_cur (NVL(l_mo_dtl_upd_date, SYSDATE - 1/24))
		LOOP
			insert_staging (mo_dtls_rec.header_id);
		END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.LOG,'Move OrderComplete Program Errored');
	END main;

	PROCEDURE insert_staging (p_header_id IN NUMBER)
    IS

	CURSOR mo_dtls_cur (c_header_id NUMBER)
	IS
	SELECT DISTINCT mtrh.header_id,
	                mtrl.line_id,
					msi.segment1,
					flv.meaning,
					mtrl.attribute1 line_number,
					mtrl.quantity_delivered,					
					mtrl.serial_number_start					
			   FROM mtl_txn_request_headers mtrh,
					mtl_txn_request_lines mtrl,
					mtl_system_items_b msi,
					fnd_lookup_values_vl flv,
					mtl_lot_numbers mln
			  WHERE mtrl.header_id = mtrh.header_id
				AND msi.inventory_item_id = mtrl.inventory_item_id
				AND msi.organization_id = mtrh.organization_id
				AND flv.lookup_code = mtrl.line_status
				AND flv.lookup_type = 'MTL_TXN_REQUEST_STATUS'
				AND mln.lot_number (+) = mtrl.lot_number
				AND mtrl.attribute2 = 'U'
                AND mtrl.line_status = 5
				AND mtrh.header_id = c_header_id;

	l_mo_count          NUMBER;
    l_tracnum          NUMBER;
    l_mo_line_count     NUMBER;
    l_line_closed_cnt NUMBER;
    l_mo_lot_expiry_date  DATE;
    l_lot_num VARCHAR2(80);
	BEGIN
		fnd_file.put_line(fnd_file.LOG, 'MO Data Insert process starting');
		fnd_file.put_line(fnd_file.LOG, 'Inserting data to Staging tables for MO header ID: '||p_header_id);

		BEGIN
			SELECT COUNT(1)
			  INTO l_mo_count
			  FROM DJOOIC_OE_SHIPMENTS_STG
			 WHERE shipment_id = p_header_id
			   AND interface_identifier = 'IMPB_MO';
		EXCEPTION
			WHEN OTHERS THEN
				l_mo_count := 0;
		END;
        BEGIN
			SELECT tracnum_seq.NEXTVAL
            INTO   l_tracnum
            FROM   dual;
		EXCEPTION
			WHEN OTHERS THEN
				l_tracnum := null;
		END;
        fnd_file.put_line(fnd_file.LOG, 'MO Data Insert process l_tracnum : '||l_tracnum);
        BEGIN
			SELECT COUNT(1)
			  INTO l_mo_line_count
			  FROM mtl_txn_request_headers mtrh,
                   mtl_txn_request_lines mtrl
            WHERE mtrh.header_id = mtrl.header_id
              AND mtrh.organization_id = mtrl.organization_id
              AND mtrh.header_id = p_header_id;
		EXCEPTION
			WHEN OTHERS THEN
				l_mo_line_count := 0;
		END;
        fnd_file.put_line(fnd_file.LOG, 'MO Data Insert process l_mo_line_count : '||l_mo_line_count);
        BEGIN
			SELECT COUNT(1)
			  INTO l_line_closed_cnt
			  FROM mtl_txn_request_headers mtrh,
                   mtl_txn_request_lines mtrl
            WHERE mtrh.header_id = mtrl.header_id
              AND mtrh.organization_id = mtrl.organization_id
              AND mtrl.line_status IN (5, 6)
              AND mtrh.header_id = p_header_id;
		EXCEPTION
			WHEN OTHERS THEN
				l_line_closed_cnt := 0;
		END;
        fnd_file.put_line(fnd_file.LOG, 'MO Data Insert process l_line_closed_cnt : '||l_line_closed_cnt);
		BEGIN	
			IF l_mo_count != 0 THEN           
				BEGIN
					UPDATE DJOOIC_OE_SHIPMENTS_STG
					   SET oic_status = 'X',
						   last_update_date = SYSDATE,
                           tracking_number=l_tracnum
					 WHERE shipment_id = p_header_id                       
					   AND interface_identifier = 'IMPB_MO';
				EXCEPTION
					WHEN OTHERS THEN
						fnd_file.put_line(fnd_file.LOG, 'Error when updating DJOOIC_OE_SHIPMENTS_STG');
				END;
			ELSE 
				INSERT INTO DJOOIC_OE_SHIPMENTS_STG (shipment_id,
													implantbase_req_id,
													manufacturer_number,
                                                    tracking_number,
													status,
													error_code,
													error_message,
													oic_status,
													oic_error_message,
													interface_identifier,
													created_by,
													creation_date,
													last_updated_by,
													last_update_date,
													last_update_login--,
												--	procedure_pick_flag
													)
											 SELECT DISTINCT mtrh.header_id,
													mtrh.attribute2,
													mtrh.request_number,
                                                    l_tracnum,
													mfg2.meaning,
													'SUCCESS',
													NULL,
													'X',
													NULL,
													'IMPB_MO',
													1516,
													SYSDATE,
													1516,
													SYSDATE,
													0
											  FROM mtl_txn_request_headers mtrh,
												   mfg_lookups             mfg2
											 WHERE mtrh.header_id = p_header_id
											   AND mfg2.lookup_type = 'MTL_TXN_REQUEST_STATUS'
											   AND mfg2.lookup_code = mtrh.header_status ;
			END IF;		

			FOR mo_dtls_rec IN mo_dtls_cur (p_header_id)
			LOOP
              l_lot_num := NULL;
              l_mo_lot_expiry_date := NULL;
            BEGIN
			  SELECT  mtln.lot_number,
	                   mln.expiration_date
                INTO l_lot_num,
                     l_mo_lot_expiry_date
                FROM mtl_transaction_lot_numbers mtln,
                     mtl_material_transactions   mmt,
                     mtl_lot_numbers  mln
               WHERE mmt.transaction_id = mtln.transaction_id
                     AND mtln.transaction_quantity > 0
                     AND mln.lot_number =mtln.lot_number
                     and mln.inventory_item_id= mtln.inventory_item_id
                     and mln.organization_id= mtln.organization_id
                     AND mmt.move_order_line_id = mo_dtls_rec.line_id;
            EXCEPTION
					WHEN OTHERS THEN
						l_lot_num := NULL;
                        l_mo_lot_expiry_date := NULL;
            END;

				INSERT INTO XXDJO.DJOOIC_OE_SHIPMENTS_DTL_STG (SHIPMENT_ID,
															   PART_NUMBER,
															   LINE_STATUS,
															   LINE_NUMBER,
															   SHIPPED_QUANTITY,
															   LOT_NUMBER,
															   TO_SERIAL_NUMBER,
															   LOT_EXPIRY_DATE,
															   CREATED_BY,
															   CREATION_DATE,
															   LAST_UPDATED_BY,
															   LAST_UPDATE_DATE,
															   LAST_UPDATE_LOGIN,
                                                               PROCEDURE_PICK_FLAG)
													   VALUES (mo_dtls_rec.header_id,
															   mo_dtls_rec.segment1,
															   mo_dtls_rec.meaning,
															   mo_dtls_rec.line_number,
															   mo_dtls_rec.quantity_delivered,
															   l_lot_num,
															   mo_dtls_rec.serial_number_start,
															   l_mo_lot_expiry_date,
															   1516,
															   SYSDATE,
															   1516,
															   SYSDATE,
															   0,
                                                               'N');				

              update_mo_line(mo_dtls_rec.line_id);
			END LOOP;
		EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK;
				fnd_file.put_line(fnd_file.LOG, 'Data Insertion process Errored');
		END;


        IF ((l_mo_line_count >0) and (l_line_closed_cnt>0)) THEN
            IF l_mo_line_count=l_line_closed_cnt THEN

                BEGIN
					UPDATE DJOOIC_OE_SHIPMENTS_STG
					   SET oic_status = 'N',
						   last_update_date = SYSDATE,
                           tracking_number=l_tracnum
					 WHERE shipment_id = p_header_id                       
					   AND interface_identifier = 'IMPB_MO';
				EXCEPTION
					WHEN OTHERS THEN
						fnd_file.put_line(fnd_file.LOG, 'Error when updating DJOOIC_OE_SHIPMENTS_STG');
				END;
                END IF;
                END IF;

                COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
			fnd_file.put_line(fnd_file.LOG,'Error while inserting into DJOOIC_INV_MO_COMPLETE_STG for MO Header ID: '|| p_header_id || ' ~ Error: '||SQLERRM);
	END insert_staging;	

	PROCEDURE update_mo_line(p_line_id  IN NUMBER)
    IS
    -- Move order variables
        l_trolin_tbl            inv_move_order_pub.trolin_tbl_type;
        l_trolin_old_tbl        inv_move_order_pub.trolin_tbl_type;
        x_trolin_tbl            inv_move_order_pub.trolin_tbl_type;
        l_mo_line_rec           inv_move_order_pub.trolin_rec_type;	

	    l_responsibility_id     NUMBER;
		l_application_id	    NUMBER;

		l_attribute2            VARCHAR2(1) := 'C';
		l_mo_line_id            NUMBER;

		-- Errors
        x_return_status           VARCHAR2 (10);
        x_msg_count             NUMBER;
        x_msg_data              VARCHAR2(255);
        x_message_list          error_handler.error_tbl_type;

	BEGIN
		NULL;
		l_mo_line_id := p_line_id;

		BEGIN
			SELECT DISTINCT responsibility_id, application_id
			  INTO l_responsibility_id, l_application_id
			  FROM apps.fnd_responsibility_tl
			 WHERE responsibility_name = 'DJO IT BA Inventory Global';
		EXCEPTION
			WHEN OTHERS THEN
				l_responsibility_id := NULL;
				l_application_id := NULL;
				fnd_file.put_line(fnd_file.LOG, 'Error when Initialising APPS for MO Line ID: '|| p_line_id || ' ~ Error: '||SQLERRM);
		END;

        BEGIN
            fnd_global.APPS_INITIALIZE(1516,l_responsibility_id,l_application_id);
            mo_global.init('INV');
        END;		

		l_mo_line_rec := inv_trolin_util.query_row(p_line_id => l_mo_line_id);
        l_trolin_tbl(1) := l_mo_line_rec;
        l_trolin_old_tbl(1) := l_mo_line_rec;
        l_trolin_tbl(1).operation := 'UPDATE';
        l_trolin_tbl(1).attribute2 := l_attribute2;

        inv_move_order_pub.process_move_order_line(p_api_version_number => 1.0, 
		                                           p_init_msg_list => fnd_api.g_true, 
												   p_return_values => fnd_api.g_false,
												   p_commit => fnd_api.g_false,
												   x_return_status => x_return_status,
                                                   x_msg_count => x_msg_count, 
												   x_msg_data => x_msg_data, 
												   p_trolin_tbl => l_trolin_tbl,
                                                   p_trolin_old_tbl => l_trolin_old_tbl, 
												   x_trolin_tbl => x_trolin_tbl);		


        IF ( x_return_status <> fnd_api.g_ret_sts_success ) THEN
            dbms_output.put_line('x_msg_data :' || x_msg_data);
            dbms_output.put_line('Error Messages :');
            error_handler.get_message_list(x_message_list => x_message_list);
            FOR i IN 1..x_message_list.count LOOP
                fnd_file.put_line(fnd_file.LOG, x_message_list(i).message_text);
            END LOOP;
			ROLLBACK;
        END IF;

	END update_mo_line;

END DJOOIC_INV_MO_COMPLETE_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_MO_COMPLETE_PKG" TO "XXOIC";

--------------------------------------------------------
--  DDL for Package Body DJOOIC_INV_LOANER_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."DJOOIC_INV_LOANER_PKG" AS 
/**************************************************************************************
*    Copyright (c) DJO
*     All rights reserved
***************************************************************************************
*
*   HEADER
*   Package Body
*
*   PROGRAM NAME
*   DJOOIC_INV_LOANER_PKG.pkb
*
*   DESCRIPTION
*   Creation Script of Package Body for ImplantBase Inventory Loaner API
*
*   USAGE
*   To create Package Body of the package DJOOIC_INV_LOANER_PKG
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
***************************************************************************************/
   /**************************************************************************************
    *
    *   PROCEDURE
    *     populate_staging
    *
    *   DESCRIPTION
    *   Procedure to insert data into stock locators staging table
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_stock_loc_rec    IN        Staging table record type
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   create_locator
	*
	**************************************************************************************/ 
	PROCEDURE populate_staging(p_stock_loc_rec IN DJOOIC_INV_STOCK_LOC_STG%ROWTYPE)
	AS
	   l_stock_loc_rec DJOOIC_INV_STOCK_LOC_STG%ROWTYPE := p_stock_loc_rec;
	BEGIN
	   INSERT 
		 INTO djooic_inv_stock_loc_stg
                (transaction_id       
				,organization_code          
				,subinventory_code    
				,locator_segments              
				,Description                 
				,locator_type         
				,locator_status     
                ,error_code 		  
				,error_message        
				,oic_status           
				,oic_error_message    
				,interface_identifier 
				,created_by 		  
				,creation_date 	      
				,last_updated_by 	  
				,last_update_date     
				,last_update_login  
				)  			  
	   VALUES  ( l_stock_loc_rec.transaction_id     
				,l_stock_loc_rec.organization_code              
				,l_stock_loc_rec.subinventory_code         
				,l_stock_loc_rec.locator_segments               
				,l_stock_loc_rec.Description                               
				,l_stock_loc_rec.locator_type
				,l_stock_loc_rec.locator_status
                ,l_stock_loc_rec.error_code 		   
				,l_stock_loc_rec.error_message         
				,l_stock_loc_rec.oic_status            
				,l_stock_loc_rec.oic_error_message     
				,l_stock_loc_rec.interface_identifier  
				,l_stock_loc_rec.created_by 		   
				,l_stock_loc_rec.creation_date 	      
				,l_stock_loc_rec.last_updated_by 	  
				,l_stock_loc_rec.last_update_date     
				,l_stock_loc_rec.last_update_login  
			   );
	   COMMIT;
	EXCEPTION
	   WHEN OTHERS THEN
	      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END populate_staging;
   /**************************************************************************************
    *
    *   PROCEDURE
    *     create_locator
    *
    *   DESCRIPTION
    *   Procedure to create stock locator in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_organization_code IN       Source Organization Code
	*   p_subinv_code       IN       Source Subinventory Code
	*   p_locator           IN       Locator Segments
	*   p_description       IN       Locator Description
	*   p_locator_type      IN       Locator Type
    *   x_transaction_id    OUT      Adjustment Transaction Id
	*   x_error_code        OUT      Transaction Status code
	*   x_error_msg         OUT      Transaction Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   OIC integation
	*
	**************************************************************************************/
	PROCEDURE create_locator(p_organization_code IN  VARCHAR2,
							 p_subinv_code       IN  VARCHAR2,
							 p_locator           IN  VARCHAR2,
							 p_description       IN  VARCHAR2,
                             p_locator_type      IN  VARCHAR2 DEFAULT g_location_type,
							 p_status_code       IN  VARCHAR2 DEFAULT g_status_code,
                             x_transaction_id    OUT NUMBER,
							 x_error_code        OUT VARCHAR2,
							 x_error_msg         OUT VARCHAR2
							 )
	IS
	   l_api_version	   NUMBER        := 1.0; 
       x_return_status	   VARCHAR2(10);  
       x_msg_count		   NUMBER        := 0;
       x_msg_data          VARCHAR2(255) ;
	   l_organization_id   NUMBER        := 83;
       l_organization_code VARCHAR2(10)  := p_organization_code;
	   l_subinventory_code VARCHAR2(10)  := p_subinv_code;
	   l_loc_segments      VARCHAR2(90)  := p_locator;
	   l_description       VARCHAR2(200) := p_description;
	   l_locator_type      VARCHAR2(60)  := NVL(p_locator_type, g_location_type);
	   l_status_code       VARCHAR2(90)  := NVL(p_status_code, g_status_code);
	   l_status_id         NUMBER        := NULL;
       -- WHO columns
       l_user_id			NUMBER       := -1;
       l_resp_id			NUMBER       := -1;
       l_application_id		NUMBER       := -1;
       l_row_cnt			NUMBER       := 1;
       l_user_name			VARCHAR2(30) := 'REQUEST';
       l_resp_name			VARCHAR2(50) := 'Inventory';   
       l_txn_id             NUMBER       := NULL;
	   l_error_code         VARCHAR2(10) := 'SUCCESS';
	   l_error_msg          VARCHAR2(20000);	
       -- API specific declarations
       l_locator_id         NUMBER       := NULL;
       l_locator_exists		VARCHAR2(1)  := 'N';
	   l_stock_loc_rec      djooic_inv_stock_loc_stg%ROWTYPE;
	BEGIN
	   --Populate staging record
	   BEGIN
	      l_stock_loc_rec.transaction_id       := NULL;
		  l_stock_loc_rec.organization_code    := l_organization_code;
		  l_stock_loc_rec.subinventory_code    := l_subinventory_code;
		  l_stock_loc_rec.locator_segments     := l_loc_segments;
		  l_stock_loc_rec.Description          := l_description;
		  l_stock_loc_rec.locator_type         := l_locator_type;
		  l_stock_loc_rec.locator_status       := l_status_code;
		  l_stock_loc_rec.error_code 		   := l_error_code;
		  l_stock_loc_rec.error_message        := l_error_msg;
		  l_stock_loc_rec.oic_status           := NULL;
		  l_stock_loc_rec.oic_error_message    := NULL;
		  l_stock_loc_rec.interface_identifier := 'IMPBS';
		  l_stock_loc_rec.created_by 		   := l_user_id;
		  l_stock_loc_rec.creation_date 	   := SYSDATE;
		  l_stock_loc_rec.last_updated_by 	   := l_user_id;
		  l_stock_loc_rec.last_update_date     := SYSDATE;
		  l_stock_loc_rec.last_update_login    := -1;
	   EXCEPTION
	      WHEN OTHERS THEN
	         l_stock_loc_rec.creation_date 	   := SYSDATE;
		     l_stock_loc_rec.error_code        := 'ERROR';
		     l_stock_loc_rec.error_message     := SQLERRM;
	   END;
	   -- Get the user_id
	   SELECT user_id
		 INTO l_user_id
		 FROM fnd_user
		WHERE user_name = l_user_name;
		-- Get the application_id and responsibility_id
		SELECT application_id, 
		       responsibility_id
		  INTO l_application_id, l_resp_id
		  FROM fnd_responsibility_vl
		 WHERE responsibility_name = l_resp_name;
	   --Validate organization code
	   BEGIN
		  SELECT organization_id
			INTO l_organization_id
			FROM org_organization_definitions
		   WHERE organization_code =l_organization_code;
	   EXCEPTION
		  WHEN OTHERS THEN
			 l_error_code := 'ERROR';
			 l_error_msg  := 'INVALID ORG';
	   END;
	   --Validate Subinventory
	   BEGIN
		  SELECT secondary_inventory_name
			INTO l_subinventory_code
			FROM mtl_secondary_inventories
		   WHERE organization_id=l_organization_id
			 AND secondary_inventory_name=l_subinventory_code
			 AND disable_date IS NULL; 
		  EXCEPTION
	         WHEN OTHERS THEN
			    l_error_code := 'ERROR';
			    IF l_error_msg IS NULL
			    THEN
				   l_error_msg  := 'INVALID SUBINV';
			    ELSE
				   l_error_msg  := l_error_msg||', SUBINV';
			    END IF;
		  END;
		  IF l_loc_segments IS NULL
		  THEN
		     l_error_code := 'ERROR';
			 IF l_error_msg IS NULL
			 THEN
			    l_error_msg  := 'INVALID LOCATOR';
			 ELSE
				l_error_msg  := l_error_msg||', LOCATOR';
			 END IF;
		  ELSE 
			 BEGIN
			    SELECT mil.inventory_location_id
			      INTO l_locator_id
			      FROM mtl_item_locations_kfv mil
			     WHERE mil.organization_id = l_organization_id
			 	   AND mil.subinventory_code = l_subinventory_code
			 	   AND mil.concatenated_segments=l_loc_segments
			 	   AND mil.enabled_flag='Y'
			 	   ;
			 	l_locator_exists := 'Y';
			 EXCEPTION
			  WHEN OTHERS THEN
				 l_locator_exists := 'N';
			  END;
		  END IF;
		  IF l_locator_type IS NOT NULL
		  THEN 
		     BEGIN
			    SELECT   lookup_code
				  INTO   l_locator_type
                  FROM   mfg_lookups l
                 WHERE   lookup_type = 'MTL_LOCATOR_TYPES'
                   AND   meaning = l_locator_type;
		     EXCEPTION
			    WHEN OTHERS THEN
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'INVALID LOCATOR TYPE';
				   ELSE
					  l_error_msg  := l_error_msg||', LOCATOR TYPE';
				   END IF;
			 END;
		  END IF;
          IF l_status_code IS NOT NULL
		  THEN 
		     BEGIN
			    SELECT status_id
				  INTO l_status_id
				  FROM mtl_material_statuses_vl
                 WHERE status_code=l_status_code;
		     EXCEPTION
			    WHEN OTHERS THEN
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'INVALID STATUS CODE';
				   ELSE
					  l_error_msg  := l_error_msg||', STATUS CODE';
				   END IF;
			 END;
		  END IF;
		  fnd_global.apps_initialize(l_user_id, l_resp_id, l_application_id); 
          dbms_output.put_line('Initialized applications context: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );
		  l_stock_loc_rec.error_code        := l_error_code;
		  l_stock_loc_rec.error_message     := l_error_msg;
		  l_stock_loc_rec.created_by 		:= l_user_id;
		  l_stock_loc_rec.last_updated_by 	:= l_user_id;
		  IF l_error_code != 'ERROR' AND l_locator_exists = 'N'
		  THEN
			 -- call API to update material status
			 DBMS_OUTPUT.PUT_LINE('=======================================================');
			 DBMS_OUTPUT.PUT_LINE('Calling INV_LOC_WMS_PUB.CREATE_LOCATOR');        
			 INV_LOC_WMS_PUB.CREATE_LOCATOR 
					  ( x_return_status	           => x_return_status	 
					  , x_msg_count		           => x_msg_count		 
					  , x_msg_data		           => x_msg_data		 
					  , x_inventory_location_id    => l_locator_id
					  , x_locator_exists	       => l_locator_exists	 
					  , p_organization_id          => l_organization_id
					  , p_organization_code        => l_organization_code
					  , p_concatenated_segments    => l_loc_segments
					  , p_description              => l_description
					  , p_inventory_location_type  => l_locator_type
					  , p_picking_order            => NULL
					  , p_location_maximum_units   => NULL
					  , p_subinventory_code        => l_subinventory_code
					  , p_location_weight_uom_code => NULL  
					  , p_max_weight               => NULL  
					  , p_volume_uom_code          => NULL  
					  , p_max_cubic_area           => NULL  
					  , p_x_coordinate             => NULL  
					  , p_y_coordinate             => NULL  
					  , p_z_coordinate             => NULL  
					  , p_physical_location_id     => NULL    -- required when creating logical locators
					  , p_pick_uom_code            => NULL  
					  , p_dimension_uom_code       => NULL  
					  , p_length               	   => NULL   
					  , p_width                	   => NULL     
					  , p_height               	   => NULL 
					  , p_status_id            	   => l_status_id 
					  , p_dropping_order       	   => NULL 
					  , p_attribute_category   	   => NULL 
					  , p_attribute1  			   => NULL 
					  , p_attribute2  			   => NULL 
					  , p_attribute3  			   => NULL 
					  , p_attribute4  			   => NULL 
					  , p_attribute5  			   => NULL
					  , p_attribute6  			   => NULL
					  , p_attribute7  			   => NULL
					  , p_attribute8  			   => NULL 
					  , p_attribute9  			   => NULL 
					  , p_attribute10 			   => NULL 
					  , p_attribute11 			   => NULL 
					  , p_attribute12 			   => NULL 
					  , p_attribute13 			   => NULL 
					  , p_attribute14 			   => NULL 
					  , p_attribute15 			   => NULL 
					  , p_alias  	               => NULL
					  );
			DBMS_OUTPUT.PUT_LINE('=======================================================');
			DBMS_OUTPUT.PUT_LINE('Return Status: '||x_return_status);
			DBMS_OUTPUT.PUT_LINE('x_locator_exists: '||l_locator_exists||' x_inventory_location_id:'||l_locator_id);
			IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) 
			THEN
				DBMS_OUTPUT.PUT_LINE('Msg Count:'||x_msg_count||' Error Message :'||x_msg_data);
				IF ( x_msg_count > 1 ) 
				THEN
				   FOR i IN 1 .. x_msg_count LOOP
					  x_msg_data := fnd_msg_pub.get ( p_msg_index => i , p_encoded =>FND_API.G_FALSE ) ;
					  dbms_output.put_line ( 'message :' || x_msg_data);
				   END LOOP;
				END IF;
				l_txn_id     := l_locator_id;
				l_error_code := 'ERROR';
				l_error_msg  := x_msg_data;
			ELSE
				COMMIT;
				l_txn_id     := l_locator_id;
				l_error_code := 'SUCCESS';
				l_error_msg  := NULL;
			END IF;     
			DBMS_OUTPUT.PUT_LINE('=======================================================');
       END IF;	   
	   IF l_locator_exists = 'Y'
	   THEN
	      l_txn_id     := l_locator_id;
		  l_error_code := 'SUCCESS';
		  l_error_msg  := NULL;
	   END IF;
	   l_stock_loc_rec.transaction_id    := l_txn_id;
	   l_stock_loc_rec.error_code        := l_error_code;
	   l_stock_loc_rec.error_message     := l_error_msg;
	   populate_staging(p_stock_loc_rec => l_stock_loc_rec);
	   x_transaction_id := l_txn_id;
	   x_error_code     := l_error_code;
	   x_error_msg      := l_error_msg; 
	EXCEPTION
	   WHEN OTHERS THEN 
	      x_error_code := 'ERROR';
		  x_error_msg  := dbms_utility.format_error_backtrace||':'||SQLERRM;
	END create_locator;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     populate_chkloc_staging
    *
    *   DESCRIPTION
    *   Procedure to insert data into stock locators staging table
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_stock_loc_rec    IN        Staging table record type
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   create_locator
	*
	**************************************************************************************/ 
	PROCEDURE populate_chkloc_staging(p_check_loc_rec IN DJOOIC_INV_CHECK_LOC_STG%ROWTYPE)
	AS
	   l_check_loc_rec DJOOIC_INV_CHECK_LOC_STG%ROWTYPE := p_check_loc_rec;
	BEGIN
	   INSERT 
		 INTO djooic_inv_check_loc_stg
                (transaction_id       
				,organization_code          
				,subinventory_code    
				,locator_segments                
                ,error_code 		  
				,error_message        
				,oic_status           
				,oic_error_message    
				,interface_identifier 
				,created_by 		  
				,creation_date 	      
				,last_updated_by 	  
				,last_update_date     
				,last_update_login  
				)  			  
	   VALUES  ( l_check_loc_rec.transaction_id     
				,l_check_loc_rec.organization_code              
				,l_check_loc_rec.subinventory_code         
				,l_check_loc_rec.locator_segments               
				,l_check_loc_rec.error_code 		   
				,l_check_loc_rec.error_message         
				,l_check_loc_rec.oic_status            
				,l_check_loc_rec.oic_error_message     
				,l_check_loc_rec.interface_identifier  
				,l_check_loc_rec.created_by 		   
				,l_check_loc_rec.creation_date 	      
				,l_check_loc_rec.last_updated_by 	  
				,l_check_loc_rec.last_update_date     
				,l_check_loc_rec.last_update_login  
			   );
	   COMMIT;
	EXCEPTION
	   WHEN OTHERS THEN
	      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END populate_chkloc_staging;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     check_locator
    *
    *   DESCRIPTION
    *   Procedure to create stock locator in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_organization_code IN       Source Organization Code
	*   p_subinv_code       IN       Source Subinventory Code
	*   p_locator           IN       Locator Segments
	*   x_transaction_id    OUT      Adjustment Transaction Id
	*   x_error_code        OUT      Transaction Status code
	*   x_error_msg         OUT      Transaction Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   OIC integation
	*
	**************************************************************************************/
	PROCEDURE check_locator(p_organization_code IN  VARCHAR2,
							p_subinv_code       IN  VARCHAR2,
							p_locator           IN  VARCHAR2,
							x_transaction_id    OUT NUMBER,
							x_error_code        OUT VARCHAR2,
							x_error_msg         OUT VARCHAR2
							)
	IS
	   l_api_version	   NUMBER        := 1.0; 
       x_return_status	   VARCHAR2(10);  
       x_msg_count		   NUMBER        := 0;
       x_msg_data          VARCHAR2(255) ;
	   l_organization_id   NUMBER        := 83;
       l_organization_code VARCHAR2(10)  := p_organization_code;
	   l_subinventory_code VARCHAR2(10)  := p_subinv_code;
	   l_loc_segments      VARCHAR2(90)  := p_locator;
	   l_status_id         NUMBER        := NULL;
       -- WHO columns
       l_user_id			NUMBER       := -1;
       l_resp_id			NUMBER       := -1;
       l_application_id		NUMBER       := -1;
       l_row_cnt			NUMBER       := 1;
       l_user_name			VARCHAR2(30) := 'REQUEST';
       l_resp_name			VARCHAR2(50) := 'Inventory';   
       l_txn_id             NUMBER       := NULL;
	   l_error_code         VARCHAR2(10) := 'SUCCESS';
	   l_error_msg          VARCHAR2(20000);	
	   l_enabled_flag       CHAR(1)      := 'Y';
       -- API specific declarations
       l_locator_id         NUMBER       := NULL;
       l_locator_exists		VARCHAR2(1)  := 'N';
	   l_check_loc_rec      djooic_inv_check_loc_stg%ROWTYPE;
	BEGIN
	   --Populate staging record
	   BEGIN
	      l_check_loc_rec.transaction_id       := NULL;
		  l_check_loc_rec.organization_code    := l_organization_code;
		  l_check_loc_rec.subinventory_code    := l_subinventory_code;
		  l_check_loc_rec.locator_segments     := l_loc_segments;
		  l_check_loc_rec.error_code 		   := l_error_code;
		  l_check_loc_rec.error_message        := l_error_msg;
		  l_check_loc_rec.oic_status           := NULL;
		  l_check_loc_rec.oic_error_message    := NULL;
		  l_check_loc_rec.interface_identifier := 'IMPBS';
		  l_check_loc_rec.created_by 		   := l_user_id;
		  l_check_loc_rec.creation_date 	   := SYSDATE;
		  l_check_loc_rec.last_updated_by 	   := l_user_id;
		  l_check_loc_rec.last_update_date     := SYSDATE;
		  l_check_loc_rec.last_update_login    := -1;
	   EXCEPTION
	      WHEN OTHERS THEN
	         l_check_loc_rec.creation_date 	   := SYSDATE;
		     l_check_loc_rec.error_code        := 'ERROR';
		     l_check_loc_rec.error_message     := SQLERRM;
	   END;
	   -- Get the user_id
	   SELECT user_id
		 INTO l_user_id
		 FROM fnd_user
		WHERE user_name = l_user_name;
		-- Get the application_id and responsibility_id
		SELECT application_id, 
		       responsibility_id
		  INTO l_application_id, l_resp_id
		  FROM fnd_responsibility_vl
		 WHERE responsibility_name = l_resp_name;
	   --Validate organization code
	   BEGIN
		  SELECT organization_id
			INTO l_organization_id
			FROM org_organization_definitions
		   WHERE organization_code =l_organization_code;
	   EXCEPTION
		  WHEN OTHERS THEN
			 l_error_code := 'ERROR';
			 l_error_msg  := 'INVALID ORG';
	   END;
	   --Validate Subinventory
	   BEGIN
		  SELECT secondary_inventory_name
			INTO l_subinventory_code
			FROM mtl_secondary_inventories
		   WHERE organization_id=l_organization_id
			 AND secondary_inventory_name=l_subinventory_code
			 AND disable_date IS NULL; 
	   EXCEPTION
	      WHEN OTHERS THEN
			 l_error_code := 'ERROR';
			 IF l_error_msg IS NULL
			 THEN
			    l_error_msg  := 'INVALID SUBINV';
			 ELSE
				l_error_msg  := l_error_msg||', SUBINV';
			 END IF;
	   END;
	   IF l_loc_segments IS NULL
	   THEN
		  l_error_code := 'ERROR';
		  IF l_error_msg IS NULL
		  THEN
			 l_error_msg  := 'INVALID LOCATOR';
		  ELSE
			 l_error_msg  := l_error_msg||', LOCATOR';
		  END IF;
	   ELSE 
		  BEGIN
			 SELECT mil.inventory_location_id, mil.enabled_flag
			   INTO l_locator_id, l_enabled_flag
			   FROM mtl_item_locations_kfv mil
			  WHERE mil.organization_id = l_organization_id
			 	AND mil.subinventory_code = l_subinventory_code
			 	AND mil.concatenated_segments=l_loc_segments
			 ;
			 l_locator_exists := 'Y';
		  EXCEPTION
			 WHEN OTHERS THEN
			    l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID LOCATOR';
				ELSE
				   l_error_msg  := l_error_msg||', LOCATOR';
				END IF;
		  END;
	   END IF;
	   IF l_enabled_flag = 'N'
	   THEN
	      l_txn_id     := l_locator_id;
		  l_error_code := 'ERROR';
		  l_error_msg  := 'LOCATOR DISABLED';
	   END IF;
       IF l_error_code != 'ERROR' AND l_locator_exists = 'Y'
	   THEN
		  -- call API to update material status
		  DBMS_OUTPUT.PUT_LINE('=======================================================');
		  l_txn_id     := l_locator_id;
		  l_error_code := 'SUCCESS';
		  l_error_msg  := NULL;
       END IF;	   
	   IF l_locator_exists = 'N'
	   THEN
	      l_txn_id     := NULL;
		  l_error_code := 'ERROR';
		  l_error_msg  := l_error_msg;
	   END IF;
	   l_check_loc_rec.transaction_id    := l_txn_id;
	   l_check_loc_rec.error_code        := l_error_code;
	   l_check_loc_rec.error_message     := l_error_msg;
	   populate_chkloc_staging(p_check_loc_rec => l_check_loc_rec);
	   x_transaction_id := l_txn_id;
	   x_error_code     := l_error_code;
	   x_error_msg      := l_error_msg; 
	EXCEPTION
	   WHEN OTHERS THEN 
	      x_error_code := 'ERROR';
		  x_error_msg  := dbms_utility.format_error_backtrace||':'||SQLERRM;
	END check_locator;
	/**************************************************************************************
    *
    *   PROCEDURE
    *     get_onhand
    *
    *   DESCRIPTION
    *   Procedure to check onhand quantity in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_organization_code IN       Organization Code
	*   p_subinv_code       IN       Subinventory Code
	*   p_locator           IN       Locator Segments
	*   p_item              IN       Item Number
	*   p_lot_number        IN       Item Lot Number
	*   p_serial_num_fm     IN       Serial Number From
	*   p_serial_num_to     IN       Serial Number To
	*   x_transaction_id    OUT      Adjustment Transaction Id
	*   x_error_code        OUT      Transaction Status code
	*   x_error_msg         OUT      Transaction Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   OIC integation
	*
	**************************************************************************************/
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
						 )
	IS
	   l_api_return_status  VARCHAR2(1);
	   l_qty_oh             NUMBER;
	   l_qty_res_oh         NUMBER;
	   l_qty_res            NUMBER;
	   l_qty_sug            NUMBER;
	   l_qty_att            NUMBER;
	   l_qty_atr            NUMBER;
	   l_onhand_qty         NUMBER;
	   l_msg_count          NUMBER;
	   l_msg_data           VARCHAR2(1000);
	   l_org_code           VARCHAR2(4)   := p_organization_code;--'AUS';
	   l_subinv_code        VARCHAR2(30)  := p_subinv_code;--'FG';
	   l_locator            VARCHAR2(100) := p_locator;--'M06B.01.0208'; 
	   l_item               VARCHAR2(30)  := p_item;
	   l_quantity           NUMBER        := p_quantity;
	   l_lot_num            VARCHAR2(30)  ;
	   l_serial_num         VARCHAR2(2000)  ;
	   l_lot_control        NUMBER        := 1;
	   l_serial_control     NUMBER        := 1;
	   l_is_lot             BOOLEAN       := FALSE;
	   l_is_serial          BOOLEAN       := FALSE;
	   l_item_id            NUMBER        := 0;
	   l_organization_id    NUMBER        := 83;
	   l_locator_id         NUMBER        := 0;
	   l_txn_id             NUMBER        := NULL;
	   l_error_code         VARCHAR2(10)  := 'SUCCESS';
	   l_error_msg          VARCHAR2(20000);	
	   --Cursor to get LOCATOR
	   CURSOR c_locator(p_organization_id   IN NUMBER,
	                    p_subinventory_code IN VARCHAR2,
	                    p_locator_id        IN NUMBER
						)
	   IS
	   SELECT mil.concatenated_segments
         FROM mtl_item_locations_kfv mil
        WHERE mil.organization_id = p_organization_id
          AND mil.subinventory_code = p_subinventory_code
          AND mil.inventory_location_id=p_locator_id;
	   --Curson to get lot_number
	   CURSOR c_lot_number(p_organization_id   IN NUMBER,
	                       p_subinventory_code IN VARCHAR2,
						   p_locator_id        IN NUMBER,
						   p_inventory_item_id IN NUMBER
					      )
	   IS
	   SELECT locator_id, lot_number, SUM(primary_transaction_quantity) quantity
         FROM mtl_onhand_quantities_detail moqd 
        WHERE organization_id=p_organization_id
          AND subinventory_code=p_subinventory_code
          AND locator_id=NVL(p_locator_id, locator_id)
          AND inventory_item_id=p_inventory_item_id
       GROUP BY locator_id, lot_number;
	   --Curson to get serial number
	   CURSOR c_serial_number(p_organization_id   IN NUMBER,
	                          p_subinventory_code IN VARCHAR2,
						      p_locator_id        IN NUMBER,
						      p_inventory_item_id IN NUMBER
					         )
	   IS
	   SELECT moqd.locator_id, LISTAGG(DISTINCT serial_number,',') WITHIN GROUP(ORDER BY serial_number) serial,
	          COUNT(DISTINCT serial_number) quantity
         FROM mtl_onhand_quantities_detail moqd,
              mtl_serial_numbers msn
        WHERE moqd.organization_id=p_organization_id
          AND moqd.subinventory_code=p_subinventory_code
          AND moqd.locator_id=NVL(p_locator_id, moqd.locator_id)
          AND moqd.inventory_item_id=p_inventory_item_id
	      AND msn.inventory_item_id=moqd.inventory_item_id
	      AND msn.current_organization_id=moqd.organization_id
	      AND msn.current_subinventory_code=moqd.subinventory_code
	      AND msn.current_locator_id=moqd.locator_id
		  --AND msn.last_transaction_id=create_transaction_id
          AND msn.current_status=3
		GROUP BY moqd.locator_id
		ORDER BY 3 DESC
	   ;
	   l_serial_arr  dbms_utility.lname_array;
	   l_serial_arr1 djooic_serial_number_type := djooic_serial_number_type();
       l_count       BINARY_INTEGER;
	   l_ser_qty     NUMBER;
	BEGIN
	--Validate organization code
	BEGIN
	   SELECT organization_id
         INTO l_organization_id
         FROM org_organization_definitions
        WHERE organization_code =l_org_code;
	EXCEPTION
	   WHEN OTHERS THEN
         l_error_code := 'ERROR';
		 l_error_msg  := 'INVALID ORG';
	END;
	--Validate Item
	BEGIN
	   SELECT inventory_item_id, lot_control_code, serial_number_control_code
		 INTO l_item_id, l_lot_control, l_serial_control
		 FROM mtl_system_items_b
	    WHERE segment1 = l_item
	      AND organization_id=l_organization_id;
		IF l_lot_control = 2
		THEN
		   l_is_lot := TRUE;
		ELSE
		   l_is_lot := FALSE;
		END IF;
	EXCEPTION
	   WHEN OTHERS THEN
		  l_error_code := 'ERROR';
		  IF l_error_msg IS NULL
		  THEN
			 l_error_msg  := 'INVALID ITEM';
		  ELSE
		     l_error_msg  := l_error_msg||', ITEM';
		  END IF;
          l_item_id    := NULL;
    END;
	--Validate subinventory
    IF l_subinv_code IS NOT NULL
    THEN
       BEGIN
          SELECT secondary_inventory_name
       	    INTO l_subinv_code
       	    FROM mtl_secondary_inventories
       	   WHERE organization_id=l_organization_id
       	     AND secondary_inventory_name=l_subinv_code
       	     AND disable_date IS NULL; 
       EXCEPTION
       	  WHEN OTHERS THEN
       		 l_error_code := 'ERROR';
			 IF l_error_msg IS NULL
			 THEN
				l_error_msg  := 'INVALID SUBINV';
			 ELSE
				l_error_msg  := l_error_msg||', SUBINV';
			 END IF;
       END;
    ELSE
       l_subinv_code := NULL;
    END IF;
	--Validate Locator
    IF l_locator IS NOT NULL
    THEN
       BEGIN
          SELECT mil.inventory_location_id
            INTO l_locator_id
            FROM mtl_item_locations_kfv mil
           WHERE mil.organization_id = l_organization_id
             AND mil.subinventory_code = l_subinv_code
             AND mil.concatenated_segments=l_locator;
      EXCEPTION
         WHEN OTHERS THEN
            l_error_code := 'ERROR';
			IF l_error_msg IS NULL
			THEN
			   l_error_msg  := 'INVALID LOCATOR';
			ELSE
			   l_error_msg  := l_error_msg||', LOCATOR';
			END IF;
      END;
    ELSE
       l_locator_id := NULL;
    END IF;
	IF l_lot_control = 2
	THEN
	   l_is_lot         := TRUE;
	   FOR rec_lot IN c_lot_number(l_organization_id, l_subinv_code, l_locator_id, l_item_id)
	   LOOP
	      IF rec_lot.quantity >= l_quantity
		  THEN
		     l_lot_num        := rec_lot.lot_number;
			 l_locator_id     := rec_lot.locator_id;
		  END IF;
	   END LOOP;
	   IF l_lot_num IS NULL
	   THEN
	      l_error_code := 'ERROR';
	   END IF;
	ELSIF l_serial_control IN (2, 5)
	THEN
	   l_is_serial      := TRUE;
	   OPEN c_serial_number(l_organization_id, l_subinv_code, l_locator_id, l_item_id);
	   FETCH c_serial_number INTO l_locator_id, l_serial_num, l_ser_qty;
	   CLOSE c_serial_number;
	   dbms_output.put_line('locaor '||l_locator_id);
	   dbms_output.put_line('serial_num  '||l_serial_num);
	   IF l_serial_num IS NOT NULL
	   THEN
		  dbms_utility.comma_to_table
					  ( list   => l_serial_num
					  , tablen => l_count
					  , tab    => l_serial_arr
					  );
		  FOR i IN 1..l_count
		  LOOP
			 l_serial_arr1.extend();
			 l_serial_arr1(i).serial_number := l_serial_arr(i);
		  END LOOP;
	   END IF;
	ELSE
	   l_is_serial      := FALSE;
	   l_is_lot         := FALSE;
	END IF;
	IF l_error_code != 'ERROR'
    THEN
      inv_quantity_tree_grp.clear_quantity_cache;
      --dbms_output.put_line('Transaction Mode:'||inv_quantity_tree_pub.g_transaction_mode);
      INV_QUANTITY_TREE_PUB.query_quantities(
               p_api_version_number => 1.0
             , p_init_msg_lst       => fnd_api.g_false
             , x_return_status      => l_api_return_status
             , x_msg_count          => l_msg_count 
             , x_msg_data           => l_msg_data
             , p_organization_id    => l_organization_id
             , p_inventory_item_id  => l_item_id 
             , p_tree_mode          => inv_quantity_tree_pub.g_transaction_mode
             , p_onhand_source      => 3 -- NULL- changed per note 296015.1
             , p_is_revision_control=> FALSE
             , p_is_lot_control     => l_is_lot
             , p_is_serial_control  => l_is_serial
             , p_revision           => NULL
             , p_lot_number         => l_lot_num
             , p_subinventory_code  => l_subinv_code
             , p_locator_id         => l_locator_id
             , x_qoh                => l_qty_oh
             , x_rqoh               => l_qty_res_oh
             , x_qr                 => l_qty_res
             , x_qs                 => l_qty_sug
             , x_att                => l_qty_att
             , x_atr                => l_qty_atr
             );
	  dbms_output.put_line('Quantity on hand: '||to_char(l_qty_oh));
      dbms_output.put_line('Quantity res oh: '||to_char(l_qty_res_oh));
      dbms_output.put_line('Quantity res '||to_char(l_qty_res));
      dbms_output.put_line('Quantity sug '||to_char(l_qty_sug));
      dbms_output.put_line('Quantity ATT '||to_char(l_qty_att));
      dbms_output.put_line('Quantity ATR '||to_char(l_qty_atr));
	  dbms_output.put_line('Status of on-hand api: '||l_api_return_status);
	  --x_onhand_qty := l_qty_oh;
   ELSE
      l_error_code := 'ERROR';
      --dbms_output.put_line('Error Code: '||to_char(l_error_code));
      --dbms_output.put_line('Error Msg: '||l_error_msg);
   END IF;
   IF l_qty_oh >= l_quantity
   THEN
      l_txn_id        := 1;
	  x_lot_number    := l_lot_num;
	  x_serial_number := l_serial_arr1;
	  IF l_locator IS NULL
	  THEN
	     OPEN c_locator(l_organization_id, l_subinv_code, l_locator_id);
	     FETCH c_locator INTO l_locator;
	     CLOSE c_locator;
	  END IF;
	  x_locator       := l_locator;
      l_error_code    := 'SUCCESS';
	  l_error_msg     := NULL;
   ELSE
      l_error_code := 'ERROR';
	  --x_onhand_qty := l_qty_oh;
	  l_error_msg  := 'INSUFFICIENT QTY';
   END IF;
   x_transaction_id := l_txn_id;
   x_error_code     := l_error_code;
   x_error_msg      := l_error_msg; 
   EXCEPTION
	  WHEN OTHERS THEN 
	     x_error_code := 'ERROR';
		 x_error_msg  := dbms_utility.format_error_backtrace||':'||SQLERRM;
   END get_onhand;
   /**************************************************************************************
    *
    *   PROCEDURE
    *     populate_mo_staging
    *
    *   DESCRIPTION
    *   Procedure to insert data into move order staging table
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_move_order_rec    IN        Staging table record type
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   create_locator
	*
	**************************************************************************************/ 
	PROCEDURE populate_mo_staging(p_move_order_rec IN DJOOIC_INV_MOV_ORD_STG%ROWTYPE,
	                              p_update BOOLEAN DEFAULT FALSE)
	AS
	   l_mov_ord_rec DJOOIC_INV_MOV_ORD_STG%ROWTYPE := p_move_order_rec;
	   PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
	   IF p_update
	   THEN
	      UPDATE djooic_inv_mov_ord_stg
		     SET transaction_id = l_mov_ord_rec.transaction_id,
			     error_code     = l_mov_ord_rec.error_code,
			     error_message  = DECODE(l_mov_ord_rec.error_code, 'SUCCESS', error_message, 
				                         nvl(l_mov_ord_rec.error_message, error_message)
										 )
		   WHERE source_mo_number = l_mov_ord_rec.source_mo_number
		     AND transaction_id IS NULL;		  
	   ELSE
	      INSERT 
		  INTO djooic_inv_mov_ord_stg
                (transaction_id   
                ,source_mo_number
                ,source_mo_line				
				,organization_code         
				,from_subinventory_code
				,to_subinventory_code         
				,from_locator               
				,to_locator            
				,item_number           
                ,quantity              
				,lot_number            
				,serial_number_fm      
				,serial_number_to      
				,error_code 		   
				,error_message         
				,oic_status            
				,oic_error_message     
				,Interface_Identifier  
				,created_by 		   
                ,creation_date 	       
				,last_updated_by 	   
				,last_update_date      
				,last_update_login     	
				)  			  
	        VALUES  ( l_mov_ord_rec.transaction_id        
			      	 ,l_mov_ord_rec.source_mo_number             
				     ,l_mov_ord_rec.source_mo_line   
				     ,l_mov_ord_rec.organization_code             
				     ,l_mov_ord_rec.from_subinventory_code   
				     ,l_mov_ord_rec.to_subinventory_code          
				     ,l_mov_ord_rec.from_locator                             
				     ,l_mov_ord_rec.to_locator            
				     ,l_mov_ord_rec.item_number           
                     ,l_mov_ord_rec.quantity              
				     ,l_mov_ord_rec.lot_number            
				     ,l_mov_ord_rec.serial_number_fm      
				     ,l_mov_ord_rec.serial_number_to      
				     ,l_mov_ord_rec.error_code 		   
				     ,l_mov_ord_rec.error_message         
				     ,l_mov_ord_rec.oic_status            
				     ,l_mov_ord_rec.oic_error_message     
				     ,l_mov_ord_rec.Interface_Identifier  
				     ,l_mov_ord_rec.created_by 		   
                     ,l_mov_ord_rec.creation_date 	       
				     ,l_mov_ord_rec.last_updated_by 	   
				     ,l_mov_ord_rec.last_update_date      
				     ,l_mov_ord_rec.last_update_login     	
			     );
	   END IF;
	   COMMIT;
	EXCEPTION
	   WHEN OTHERS THEN
	      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END populate_mo_staging;
   /**************************************************************************************
    *
    *   PROCEDURE
    *     ProcessMoveOrder
    *
    *   DESCRIPTION
    *   Procedure to process Move Order in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_type              IN       Adjustment Type
	*   p_organization_code IN       Organization Code
	*   p_from_subinv_code  IN       Source Subinventory Code
	*   p_to_subinv_code    IN       Destination Subinventory Code
	*   p_from_locator      IN       Source Locator Segments
	*   p_to_locator        IN       Destination Locator Segments
	*   p_item              IN       Item Number
	*   p_quantity          IN       Transaction Quantity
    *   p_lot_number        IN       Item Lot Number
	*   p_serial_num_fm     IN       Serial Number From
	*   p_serial_num_to     IN       Serial Number To
	*   x_transaction_id    OUT      Adjustment Transaction Id
	*   x_error_code        OUT      Transaction Status code
	*   x_error_msg         OUT      Transaction Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   OIC integation
	*
	**************************************************************************************/
   PROCEDURE ProcessMoveOrder(p_source_mo_number    IN  VARCHAR2,
	                          p_organization_code   IN  VARCHAR2,
						      p_move_order_line_tbl IN  djooic_move_ord_line_tbl,
							  x_transaction_id      OUT NUMBER,
						      x_error_code          OUT VARCHAR2,
						      x_error_msg           OUT VARCHAR2
						      )
   IS 
      -- Common Declarations
	  l_lot_num            VARCHAR2(60);
      l_api_version		   NUMBER := 1.0; 
      l_init_msg_list	   VARCHAR2(2) := FND_API.G_TRUE; 
      l_return_values      VARCHAR2(2) := FND_API.G_FALSE; 
      l_commit		       VARCHAR2(2) := FND_API.G_FALSE; 
      x_return_status	   VARCHAR2(2);
      x_msg_count		   NUMBER := 0;
      x_msg_data           VARCHAR2(255);
	  -- Procedure Parameters initialization
	  l_org_code           VARCHAR2(4)   := 'AUS';
	  l_from_subinv_code   VARCHAR2(30)  := 'FG';
	  l_to_subinv_code     VARCHAR2(30)  := 'FG';
	  l_from_locator       VARCHAR2(100) := 'M06B.01.0208'; 
	  l_to_locator         VARCHAR2(100) := 'M06B.01.0208'; 
	  l_item               VARCHAR2(30)  := 'YUYYY';
	  l_quantity           NUMBER        := 1;
	  l_serial_num_fm      VARCHAR2(30)  := NULL;
	  l_serial_num_to      VARCHAR2(30)  := NULL;
	  l_source_system      VARCHAR2(60)  := 'IMPBS';
	  l_source_mo_num      VARCHAR2(60)  := p_source_mo_number;
	  l_source_mo_line_num VARCHAR2(60)  := '1';
	  l_mo_tract_status    VARCHAR2(10)  := 'U';
	  l_mo_exists          VARCHAR2(2)   := 'N';
	  l_item_id            NUMBER        := 0;	
	  l_uom_code           VARCHAR2(30)  := 'Ea';
	  l_lot_control        NUMBER        := 0;
	  l_serial_control     NUMBER        := 0; 
	  l_lot_onhand         NUMBER        := NULL;
	  l_open_period        VARCHAR2(1)   := 'N';
	  l_organization_id    NUMBER        := 83;
	  l_from_locator_id    NUMBER        := 0;
	  l_to_locator_id      NUMBER        := 0;
	  l_txn_id             NUMBER        := NULL;
	  l_error_code         VARCHAR2(10)  := 'SUCCESS';
	  l_any_line_err       BOOLEAN       := FALSE;
	  l_error_msg          VARCHAR2(20000);	
      -- API specific declarations
      l_header_id          NUMBER := 0;
      l_trohdr_rec         INV_MOVE_ORDER_PUB.TROHDR_REC_TYPE;
      l_trohdr_val_rec     INV_MOVE_ORDER_PUB.TROHDR_VAL_REC_TYPE;
      l_trolin_tbl         INV_MOVE_ORDER_PUB.TROLIN_TBL_TYPE;
      l_trolin_val_tbl     INV_MOVE_ORDER_PUB.TROLIN_VAL_TBL_TYPE;
      x_trolin_tbl         INV_MOVE_ORDER_PUB.TROLIN_TBL_TYPE;
      x_trolin_val_tbl     INV_MOVE_ORDER_PUB.TROLIN_VAL_TBL_TYPE;
      x_trohdr_rec         INV_MOVE_ORDER_PUB.TROHDR_REC_TYPE;
      x_trohdr_val_rec     INV_MOVE_ORDER_PUB.TROHDR_VAL_REC_TYPE;
      -- WHO columns
      l_user_id	 	       NUMBER       := -1;
      l_resp_id		       NUMBER       := -1;
      l_application_id	   NUMBER       := -1;
      l_row_cnt	   	       NUMBER       :=  1;
	  l_user_name		   VARCHAR2(30) := 'REQUEST';
      l_resp_name		   VARCHAR2(50) := 'Inventory';  
      l_data_exp           EXCEPTION;	  
	  l_mo_header_id       NUMBER       := NULL;
	  l_mo_line_id         NUMBER       := NULL;
	  l_total_line         NUMBER       := 0;
	  l_lots_idx           NUMBER       := 1;
	  l_msg_index_OUT      NUMBER;
	  --Cursor to get configuration 
	  CURSOR cur_mo_configuration(p_org_code    IN VARCHAR2,
	                              p_from_subinv IN VARCHAR2,
								  p_to_subinv   IN VARCHAR2
								  )
	  IS
	  SELECT ffv.attribute1 org_code,
             ffv.attribute2 from_subinv_code,
             ffv.attribute3 to_subinv_code,
             flv.lookup_code mo_type,
             ffv.attribute5 auto_allocate
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values ffv,
			 fnd_lookup_values_vl flv
       WHERE ffvs.flex_value_set_name='XXDJO_MOVE_ORDER_CREATION'
         AND ffv.flex_value_set_id=ffvs.flex_value_set_id
         AND ffv.value_category='XXDJO_MOVE_ORDER_CREATION'
		 AND flv.lookup_type='MOVE_ORDER_TYPE'
		 AND flv.meaning(+)=ffv.attribute4
         AND ffv.attribute1=p_org_code
		 AND ffv.attribute2=p_from_subinv
		 AND ffv.attribute3=p_to_subinv
		 ;
	  CURSOR cur_lot_serial(p_lot IN VARCHAR2)
      IS
      SELECT REGEXP_SUBSTR(p_lot, '[^,]+', 1, level) AS lot_serial
        FROM dual 
      CONNECT BY REGEXP_SUBSTR(p_lot, '[^,]+', 1, level) IS NOT NULL;
	  l_mo_api_rec cur_mo_configuration%ROWTYPE;
	  l_mov_ord_rec        DJOOIC_INV_MOV_ORD_STG%ROWTYPE;
	  TYPE l_mov_ord_tab_type IS TABLE OF DJOOIC_INV_MOV_ORD_STG%ROWTYPE;
	  l_mov_ord_tab l_mov_ord_tab_type;
   BEGIN
      --Populate staging record
	  BEGIN
	     IF p_move_order_line_tbl.COUNT > 0 
	     THEN
	        l_total_line := p_move_order_line_tbl.COUNT;
			l_mov_ord_tab := l_mov_ord_tab_type();
            FOR i IN p_move_order_line_tbl.FIRST..p_move_order_line_tbl.LAST 
		    LOOP
			   BEGIN
			      l_mov_ord_tab.EXTEND(1); 
				  l_mov_ord_rec.transaction_id         := NULL;
				  l_mov_ord_rec.source_mo_number       := l_source_mo_num;
				  l_mov_ord_rec.organization_code      := l_org_code;
				  --line records
				  l_mov_ord_rec.source_mo_line         := p_move_order_line_tbl(i).source_mo_line_num;
				  l_mov_ord_rec.from_subinventory_code := p_move_order_line_tbl(i).from_subinv_code;
				  l_mov_ord_rec.to_subinventory_code   := p_move_order_line_tbl(i).to_subinv_code;
				  l_mov_ord_rec.from_locator           := p_move_order_line_tbl(i).from_locator;
				  l_mov_ord_rec.to_locator             := p_move_order_line_tbl(i).to_locator;
				  l_mov_ord_rec.item_number            := p_move_order_line_tbl(i).item;
				  l_mov_ord_rec.quantity               := p_move_order_line_tbl(i).quantity;
				  FOR j IN 1..p_move_order_line_tbl(i).lot_serial.COUNT
				  LOOP
					 BEGIN
					    IF j > 1 
						THEN
						   IF p_move_order_line_tbl(i).lot_serial(j).lot_number IS NOT NULL
						   THEN
							  l_mov_ord_rec.lot_number := NVL(p_move_order_line_tbl(i).lot_serial(j).lot_number, l_mov_ord_rec.lot_number);
						   END IF;
						   IF p_move_order_line_tbl(i).lot_serial(j).serial_number IS NOT NULL
						   THEN
							  l_mov_ord_rec.serial_number_to := p_move_order_line_tbl(i).lot_serial(j).serial_number;
						   END IF;						
						 ELSE
							l_mov_ord_rec.lot_number       := p_move_order_line_tbl(i).lot_serial(j).lot_number;
							l_mov_ord_rec.serial_number_fm := p_move_order_line_tbl(i).lot_serial(j).serial_number;			  
						 END IF;
					  EXCEPTION
						 WHEN OTHERS THEN
							l_mov_ord_rec.creation_date 	:= SYSDATE;
							l_mov_ord_rec.error_code        := 'ERROR';
							l_mov_ord_rec.error_message     := SQLERRM;
							l_mov_ord_tab(i)                := l_mov_ord_rec;
					  END;
				   END LOOP;
				   --derive columns
				   l_mov_ord_rec.error_code 		      := l_error_code;
				   l_mov_ord_rec.error_message            := NULL;
				   l_mov_ord_rec.oic_status               := NULL;
				   l_mov_ord_rec.oic_error_message        := NULL;
				   l_mov_ord_rec.Interface_Identifier     := l_source_system;
				   l_mov_ord_rec.created_by 		      := l_user_id;
				   l_mov_ord_rec.creation_date 	          := SYSDATE;
				   l_mov_ord_rec.last_updated_by 	      := l_user_id;
				   l_mov_ord_rec.last_update_date         := SYSDATE;
				   l_mov_ord_rec.last_update_login        := -1;
				   l_mov_ord_tab(i)                       := l_mov_ord_rec;
			EXCEPTION
	           WHEN OTHERS THEN
	              l_mov_ord_rec.creation_date 	:= SYSDATE;
		          l_mov_ord_rec.error_code        := 'ERROR';
		          l_mov_ord_rec.error_message     := SQLERRM;
			      l_mov_ord_tab(i)                := l_mov_ord_rec;
	        END;
			l_mov_ord_tab(i)                := l_mov_ord_rec;
			l_mov_ord_rec := NULL; 
	     END LOOP;
	  END IF;
	  END;
	  --Check Move Order API configuration
	  FOR i IN l_mov_ord_tab.FIRST..l_mov_ord_tab.LAST
	  LOOP
	      l_mov_ord_rec       := l_mov_ord_tab(i);
	      l_lots_idx          := 1;
	      l_source_mo_line_num:= l_mov_ord_tab(i).source_mo_line;
	      l_from_subinv_code  := l_mov_ord_tab(i).from_subinventory_code;
		  l_to_subinv_code    := l_mov_ord_tab(i).to_subinventory_code;
		  l_item              := l_mov_ord_tab(i).item_number;
		  l_quantity          := l_mov_ord_tab(i).quantity;
		  l_from_locator      := l_mov_ord_tab(i).from_locator;
		  l_to_locator        := l_mov_ord_tab(i).to_locator;
		  l_serial_num_fm     := l_mov_ord_tab(i).serial_number_fm;
		  l_serial_num_to     := l_mov_ord_tab(i).serial_number_to;
		  l_lot_num           := l_mov_ord_tab(i).lot_number;
		  BEGIN
			 OPEN cur_mo_configuration(l_org_code, l_from_subinv_code, l_to_subinv_code);
			 FETCH cur_mo_configuration INTO l_mo_api_rec;
			 IF cur_mo_configuration%NOTFOUND
			 THEN
				l_error_code := 'ERROR';
				l_error_msg  := 'Invalid API call for organization: '||l_org_code||' from subinventory: '||
								 l_from_subinv_code||'and to Subinventory: '||l_to_subinv_code||' combination.';
				--RAISE l_data_exp;
			 END IF; 
			 CLOSE cur_mo_configuration;
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				l_error_msg  := 'Invalid API call for organization '||l_org_code||' From subinventory: '||
								 l_from_subinv_code||' and To Subinventory: '||l_to_subinv_code||' combination.';
				--RAISE l_data_exp;
		  END;
		  --Validate organization code
		  BEGIN
			 SELECT organization_id
			   INTO l_organization_id
			   FROM org_organization_definitions
			  WHERE organization_code = l_org_code;
			  l_mov_ord_tab(i).organization_id  := l_organization_id;
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				l_error_msg  := 'INVALID ORG';
		  END;
		  --Check if Open Period
		  BEGIN
			 SELECT open_flag
			   INTO l_open_period
			   FROM org_acct_periods 
			  WHERE organization_id = l_organization_id
				AND open_flag='Y'
				AND TRUNC(SYSDATE) BETWEEN TRUNC(period_start_date) 
									   AND TRUNC(schedule_close_date)
			  ;
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID PERIOD STATUS';
				ELSE
				   l_error_msg  := l_error_msg||', PERIOD STATUS';
				END IF;
		  END;
		  --Validate Item
		  BEGIN
			 SELECT inventory_item_id,
					primary_uom_code,
					lot_control_code,
					serial_number_control_code
			   INTO l_item_id,
					l_uom_code,
					l_lot_control,
					l_serial_control
			   FROM mtl_system_items_b
			  WHERE segment1 = l_item
				AND organization_id = l_organization_id;
				l_mov_ord_tab(i).item_id  := l_item_id;
				l_mov_ord_tab(i).uom_code := l_uom_code;
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID ITEM';
				ELSE
				   l_error_msg  := l_error_msg||', ITEM';
				END IF;
		  END;
		  --Validate Subinventory
		  IF l_from_subinv_code IS NOT NULL 
		  THEN
			 BEGIN
				SELECT secondary_inventory_name
				  INTO l_from_subinv_code
				  FROM mtl_secondary_inventories
				 WHERE organization_id = l_organization_id
				   AND secondary_inventory_name = l_from_subinv_code
				   AND disable_date IS NULL; 
			 EXCEPTION
				WHEN OTHERS THEN
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'INVALID FROM SUBINV';
				   ELSE
					  l_error_msg  := l_error_msg||', FROM SUBINV';
				   END IF;
			 END;
		  END IF;
		  BEGIN
			 SELECT secondary_inventory_name
			   INTO l_to_subinv_code
			   FROM mtl_secondary_inventories
			  WHERE organization_id=l_organization_id
				AND secondary_inventory_name=l_to_subinv_code
				AND disable_date IS NULL; 
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID TO SUBINV';
				ELSE
				   l_error_msg  := l_error_msg||', TO SUBINV';
				END IF;
		  END;
		  --Validate Locator
		  IF l_from_locator IS NOT NULL
		  THEN
			 BEGIN
				SELECT mil.inventory_location_id
				  INTO l_from_locator_id
				  FROM mtl_item_locations_kfv mil
				 WHERE mil.organization_id = l_organization_id
				   AND mil.subinventory_code = l_from_subinv_code
				   AND mil.concatenated_segments=l_from_locator
				   AND mil.enabled_flag='Y';
				   l_mov_ord_tab(i).from_locator_id  := l_from_locator_id;
			 EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID FROM LOCATOR';
				ELSE
				   l_error_msg  := l_error_msg||', FROM LOCATOR';
				END IF;
			 END;
		  ELSE
		     l_mov_ord_tab(i).from_locator_id  := NULL;
		  END IF;
		  IF l_to_locator IS NOT NULL
		  THEN
		     BEGIN
			    SELECT mil.inventory_location_id
				  INTO l_to_locator_id
				  FROM mtl_item_locations_kfv mil
				 WHERE mil.organization_id = l_organization_id
				   AND mil.subinventory_code = l_to_subinv_code
				   AND mil.concatenated_segments=l_to_locator
				   AND mil.enabled_flag='Y';
				   l_mov_ord_tab(i).to_locator_id  := l_to_locator_id;
		     EXCEPTION
			    WHEN OTHERS THEN
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'INVALID TO LOCATOR';
				   ELSE
					  l_error_msg  := l_error_msg||', TO LOCATOR';
				   END IF;
		     END;
		  ELSE
		     l_mov_ord_tab(i).to_locator_id  := NULL;
		  END IF;
		  dbms_output.put_line('Error : '||l_error_msg);
		  --Validate onhand stock for MO transfer
		  IF l_error_code != 'ERROR'
		  THEN
			 IF l_lot_control = 2
			 THEN 
				l_serial_num_fm := NULL;
				l_serial_num_to := NULL;
				l_mov_ord_rec.lot_serial := 'LOT';
				IF l_lot_num IS NULL AND l_from_locator IS NOT NULL
				THEN
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
				      l_error_msg  := 'INVALID LOT NUM';
				   ELSE
				      l_error_msg  := l_error_msg||', LOT NUM';
				   END IF;
				END IF;
				IF l_lot_num IS NOT NULL
				THEN
				   BEGIN
					  SELECT NVL(SUM(primary_transaction_quantity),0)
					    INTO l_lot_onhand			
						FROM mtl_onhand_quantities_detail 
					   WHERE organization_id=l_organization_id
						 AND subinventory_code=l_from_subinv_code
						 AND locator_id=l_from_locator_id
						 AND inventory_item_id=l_item_id
						 AND lot_number =l_lot_num;
				   EXCEPTION
					  WHEN OTHERS THEN
						 l_lot_onhand := 0;
				   END;	
				  dbms_output.put_line('Lot Onhand: '||l_lot_onhand);
				 END IF;
			 ELSIF l_serial_control IN (2, 5)
			 THEN
				l_mov_ord_rec.lot_serial := 'SERIAL';
			    IF l_serial_num_fm IS NOT NULL AND l_serial_num_to IS NOT NULL 
				THEN
				   BEGIN
					  SELECT COUNT(msn.serial_number)
						INTO l_lot_onhand
					    FROM mtl_onhand_quantities_detail moqd,
						     mtl_serial_numbers msn
					   WHERE moqd.organization_id=l_organization_id
						 AND moqd.subinventory_code=l_from_subinv_code
						 AND moqd.locator_id=l_from_locator_id
					     AND moqd.inventory_item_id=l_item_id
						 AND msn.inventory_item_id=moqd.inventory_item_id
						 AND msn.current_organization_id=moqd.organization_id
						 AND msn.current_subinventory_code=moqd.subinventory_code
						 AND msn.current_locator_id=moqd.locator_id
						 AND msn.serial_number BETWEEN l_serial_num_fm AND NVL(l_serial_num_to, l_serial_num_fm)
						 ;								  
					   dbms_output.put_line('Serial Onhand: '||l_lot_onhand);	
					   dbms_output.put_line('Serials: '||l_serial_num_fm||'-'||l_serial_num_to);	
					EXCEPTION
					   WHEN OTHERS THEN
						  l_lot_onhand := 0;
					END;		
                END IF;				
			 ELSE
			    IF l_from_locator_id IS NOT NULL
				THEN
				   BEGIN
					  SELECT NVL(SUM(primary_transaction_quantity),0)
						INTO l_lot_onhand			
						FROM mtl_onhand_quantities_detail 
					   WHERE organization_id=l_organization_id
						 AND subinventory_code=l_from_subinv_code
						 AND locator_id=l_from_locator_id
					     AND inventory_item_id=l_item_id;
				   EXCEPTION
					  WHEN OTHERS THEN
						 l_lot_onhand := 0;
				   END;
                END IF;					
			 END IF;			 
			 --dbms_output.put_line('Onhand: '||l_lot_onhand);	
             IF l_from_locator_id IS NOT NULL
             THEN			 
				IF l_lot_onhand = 0
				THEN 
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'ZERO ONHAND QTY';
				   ELSE
					  l_error_msg  := l_error_msg||', ZERO ONHAND QTY';
				   END IF;
				ELSIF l_lot_onhand < l_quantity
				THEN 
				   l_error_code := 'ERROR';
				   IF l_error_msg IS NULL
				   THEN
					  l_error_msg  := 'INSUFFICIENT ONHAND QTY';
				   ELSE
					  l_error_msg  := l_error_msg||', INSUFFICIENT ONHAND QTY';
				   END IF;
				ELSE
				   NULL;
				END IF;
		     END IF;
		  END IF;----
	  --Get the user_id
	  BEGIN
		 SELECT user_id
		   INTO l_user_id
		   FROM fnd_user
		  WHERE user_name = l_user_name;
		  -- Get the application_id and responsibility_id
		  SELECT application_id, 
				 responsibility_id
			INTO l_application_id, 
				 l_resp_id
			FROM fnd_responsibility_vl
		   WHERE responsibility_name = l_resp_name;
	  EXCEPTION
	     WHEN OTHERS THEN
		    l_error_code := 'ERROR';
			IF l_error_msg IS NULL
			THEN
			   l_error_msg  := 'INVALID USER/RESPONSIBILITY';
			ELSE
			   l_error_msg  := l_error_msg||', USER/RESPONSIBILITY';
			END IF;
	  END;
	   l_mov_ord_rec.created_by 		    := l_user_id;
	   l_mov_ord_rec.last_updated_by 	    := l_user_id; 
	   IF l_error_code != 'ERROR'
	   THEN 
	      l_mo_exists := 'N';
		    BEGIN
		 	   SELECT 'Y', mtrh.request_number
		 	     INTO l_mo_exists, l_txn_id
		 	     FROM mtl_txn_request_headers mtrh,
		 	          mtl_txn_request_lines mtrl 
		 	    WHERE 1=1
		          AND mtrh.header_id=mtrl.header_id
		 	      AND mtrh.organization_id=l_organization_id
		 	      AND mtrh.transaction_type_id=g_mo_transaction_type_id
		 	      AND mtrh.move_order_type=g_moveorder_type
		 	      AND mtrh.header_status=mtrl.line_status
		 	      AND mtrh.header_status=g_mo_header_status
		 	      AND mtrl.from_subinventory_code=l_from_subinv_code
		 	      AND mtrl.to_subinventory_code=l_to_subinv_code
		 	      AND mtrl.inventory_item_id=l_item_id
		 	      AND mtrl.quantity=l_quantity
		 	      AND mtrh.attribute1=l_source_system
		 	      AND mtrh.attribute2=l_source_mo_num
		 	      AND mtrl.attribute1=l_source_mo_line_num
				  AND mtrl.attribute2=l_mo_tract_status
		 	   AND rownum=1;
	        EXCEPTION
		 	   WHEN OTHERS THEN
		        NULL;
		    END;
	     END IF;
	     IF l_mo_exists = 'Y' 
	     THEN
	        l_error_code := 'ERROR';
            l_error_msg  := 'DUPLICATE MO';
	     END IF;
	     l_mov_ord_rec.error_code        := l_error_code;
	     l_mov_ord_rec.error_message     := l_error_msg;
	     populate_mo_staging(p_move_order_rec => l_mov_ord_rec);
	     IF  l_error_code = 'ERROR'
	     THEN
	       l_any_line_err := TRUE;
	     END IF;
	     IF l_any_line_err AND i = l_mov_ord_tab.LAST 
	     THEN
	        l_mov_ord_rec.error_code    := 'ERROR';
		    l_mov_ord_rec.error_message := NULL;
	        populate_mo_staging(l_mov_ord_rec, TRUE);
	        RAISE l_data_exp;
	     END IF;
		 l_error_code := NULL;
         l_error_msg  := NULL;
	  END LOOP;
	  --Apps Initialize
      FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, l_application_id);
      dbms_output.put_line('Initialized applications context: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );  
	  --
	  -- Initialize the move order header
      l_trohdr_rec.date_required                    :=   sysdate + 2;
      l_trohdr_rec.organization_id                  :=   l_organization_id;	
      l_trohdr_rec.from_subinventory_code           :=   l_from_subinv_code;
      l_trohdr_rec.to_subinventory_code             :=   l_to_subinv_code;
      l_trohdr_rec.status_date                      :=   sysdate;
      l_trohdr_rec.request_number                   :=   mtl_txn_request_headers_s.nextval;
      l_trohdr_rec.header_status     	            :=   g_mo_header_status;   -- preApproved
      l_trohdr_rec.transaction_type_id              :=   g_mo_transaction_type_id;  
      l_trohdr_rec.move_order_type	                :=   NVL(l_mo_api_rec.mo_type, g_moveorder_type);
	  l_trohdr_rec.attribute1	                    :=   l_source_system;
	  l_trohdr_rec.attribute2	                    :=   l_source_mo_num;
      l_trohdr_rec.db_flag                          :=   FND_API.G_TRUE;
      l_trohdr_rec.operation                        :=   INV_GLOBALS.G_OPR_CREATE;    
	  --                                            
      -- Who columns                                
      l_trohdr_rec.created_by                       :=  l_user_id;
      l_trohdr_rec.creation_date                    :=  sysdate;
      l_trohdr_rec.last_updated_by                  :=  l_user_id;
      l_trohdr_rec.last_update_date                 :=  sysdate;
      -- create  line  for the  header created above         
      FOR i IN l_mov_ord_tab.FIRST..l_mov_ord_tab.LAST
      LOOP	  
         l_trolin_tbl(i).date_required		    :=  sysdate;                                     
         l_trolin_tbl(i).organization_id 	    :=  l_mov_ord_tab(i).organization_id;        
         l_trolin_tbl(i).inventory_item_id	    :=  l_mov_ord_tab(i).item_id;       
         l_trolin_tbl(i).from_subinventory_code :=  l_mov_ord_tab(i).from_subinventory_code;  
	     l_trolin_tbl(i).from_locator_id        :=  l_mov_ord_tab(i).from_locator_id;  
         l_trolin_tbl(i).to_subinventory_code	:=  l_mov_ord_tab(i).to_subinventory_code;    
         l_trolin_tbl(i).to_locator_id          :=  l_mov_ord_tab(i).to_locator_id;  
	     l_trolin_tbl(i).quantity		        :=  l_mov_ord_tab(i).quantity;  
         IF l_mov_ord_tab(i).lot_serial  = 'SERIAL'
         THEN
            l_trolin_tbl(i).serial_number_start    :=  l_mov_ord_tab(i).serial_number_fm;
	        l_trolin_tbl(i).serial_number_end      :=  l_mov_ord_tab(i).serial_number_to;
		 ELSE
		    l_trolin_tbl(i).lot_number             :=  l_mov_ord_tab(i).lot_number;
			dbms_output.put_line(l_mov_ord_tab(i).lot_number);
		 END IF;
         l_trolin_tbl(i).status_date		    :=  sysdate;                                      
         l_trolin_tbl(i).uom_code	          	:=  l_mov_ord_tab(i).uom_code;--'Ea';   
         l_trolin_tbl(i).line_number	        :=  i;                                   
         l_trolin_tbl(i).line_status		    :=  g_mo_header_status; 
         l_trolin_tbl(i).attribute1		        :=  l_mov_ord_tab(i).source_mo_line; 
	     l_trolin_tbl(i).attribute2		        :=  l_mo_tract_status; 
         l_trolin_tbl(i).db_flag		        :=  FND_API.G_TRUE;                               
         l_trolin_tbl(i).operation		        :=  INV_GLOBALS.G_OPR_CREATE;                     
         -- Who columns                                
         l_trolin_tbl(i).created_by		        := l_user_id;                           
         l_trolin_tbl(i).creation_date	  	    := sysdate;                                      
         l_trolin_tbl(i).last_updated_by	    := l_user_id;                           
         l_trolin_tbl(i).last_update_date	    := sysdate;                                      
         l_trolin_tbl(i).last_update_login	    := FND_GLOBAL.login_id;  
	  END LOOP;
      -- call API to create move order header
      DBMS_OUTPUT.PUT_LINE('=======================================================');
      DBMS_OUTPUT.PUT_LINE('Calling INV_MOVE_ORDER_PUB.Process_Move_Order API');        
      INV_MOVE_ORDER_PUB.Process_Move_Order( 
                p_api_version_number   => l_api_version
             ,  p_init_msg_list        => l_init_msg_list
             ,  p_return_values        => l_return_values
             ,  p_commit               => l_commit
             ,  x_return_status        => x_return_status
             ,  x_msg_count            => x_msg_count
             ,  x_msg_data             => x_msg_data
             ,  p_trohdr_rec           => l_trohdr_rec
             ,  p_trohdr_val_rec       => l_trohdr_val_rec
             ,  p_trolin_tbl           => l_trolin_tbl
             ,  p_trolin_val_tbl	   => l_trolin_val_tbl
             ,  x_trohdr_rec	       => x_trohdr_rec
             ,  x_trohdr_val_rec       => x_trohdr_val_rec
             ,  x_trolin_tbl	       => x_trolin_tbl
             ,  x_trolin_val_tbl       => x_trolin_val_tbl 
             ); 
      DBMS_OUTPUT.PUT_LINE('=======================================================');
      DBMS_OUTPUT.PUT_LINE('Return Status: '||x_return_status);
      IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) 
	  THEN
         DBMS_OUTPUT.PUT_LINE('Error Message :'||x_msg_data);
		 l_txn_id     := NULL;
		 l_error_code := 'ERROR';
		 l_error_msg  := x_msg_data;
		 IF ( FND_MSG_PUB.Count_Msg > 0) THEN
            FOR i IN 1..FND_MSG_PUB.Count_Msg
			LOOP
               FND_MSG_PUB.Get(p_msg_index     => i,
                               p_encoded       => 'F',
                               p_data          => x_msg_data,
                               p_msg_index_OUT => l_msg_index_OUT
							  );
               dbms_output.put_line('l_msg_data :' ||x_msg_data);
            END LOOP;
         END IF;
		 l_mov_ord_rec.error_code    := l_error_code;
		 l_mov_ord_rec.error_message := l_error_msg;
		 populate_mo_staging(l_mov_ord_rec, TRUE);
		 ROLLBACK;
      END IF;
      IF (x_return_status = FND_API.G_RET_STS_SUCCESS) 
	  THEN
         DBMS_OUTPUT.PUT_LINE('Move Order '||x_trohdr_rec.request_number||' created Successfully');
		 l_txn_id       := x_trohdr_rec.request_number;
		 l_mo_header_id := x_trohdr_rec.header_id;
		 l_error_code   := 'SUCCESS';
		 l_mov_ord_rec.error_code    := l_error_code;
		 l_mov_ord_rec.error_message := NULL;
		 l_mov_ord_rec.transaction_id := l_txn_id;
		 populate_mo_staging(l_mov_ord_rec, TRUE);
		 COMMIT;
		 IF l_mo_api_rec.auto_allocate = 'Yes'
		 THEN
		    FOR i IN 1..x_trolin_tbl.COUNT 
			LOOP
			   l_mo_line_id   := x_trolin_tbl(I).line_id;
		       allocateMoveOrder(p_mo_header_id      => l_mo_header_id,
							     p_mo_line_id        => l_mo_line_id,
							     x_transaction_id    => l_txn_id,
						         x_error_code        => l_error_code,
						         x_error_msg         => l_error_msg
                                 );
			   DBMS_OUTPUT.PUT_LINE('Allocate Move Order '||l_error_code);
			   DBMS_OUTPUT.PUT_LINE('Allocate Move Order '||l_error_msg);
			   /*
			   TransactMoveOrder(p_request_number => x_trohdr_rec.request_number,
                              p_request_line_num  => x_trolin_tbl(i).line_number,
			                  x_transaction_id    => l_txn_id,
						      x_error_code        => l_error_code,
						      x_error_msg         => l_error_msg
							  );
			   */
			END LOOP;
		 END IF;
      END IF; 
	  l_txn_id       := x_trohdr_rec.request_number;
      DBMS_OUTPUT.PUT_LINE('=======================================================');
	  x_transaction_id               := l_txn_id;
      x_error_code                   := l_error_code;
      x_error_msg                    := l_error_msg; 
	  l_mov_ord_rec.transaction_id   := l_txn_id;
	  l_mov_ord_rec.error_code       := l_error_code;
	  l_mov_ord_rec.error_message    := l_error_msg;
   EXCEPTION
      WHEN l_data_exp THEN
	     x_transaction_id               := l_txn_id;
	     x_error_code                   := l_error_code;
         x_error_msg                    := l_error_msg; 
		 l_mov_ord_rec.transaction_id   := l_txn_id;
	     l_mov_ord_rec.error_code       := l_error_code;
	     l_mov_ord_rec.error_message    := l_error_msg;
	  WHEN OTHERS THEN 
	     x_error_code                   := 'ERROR';
		 x_error_msg                    := dbms_utility.format_error_backtrace||':'||SQLERRM;
		 l_mov_ord_rec.transaction_id   := l_txn_id;
	     l_mov_ord_rec.error_code       := l_error_code;
	     l_mov_ord_rec.error_message    := l_error_msg;
   END ProcessMoveOrder;  
   /**************************************************************************************
    *
    *   PROCEDURE
    *     allocateMoveOrder
    *
    *   DESCRIPTION
    *   Procedure to allocate Move Order in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_request_number    IN       Move Order Number
	*   p_request_line_num  IN       Move Order Line Number
	*   x_transaction_id    OUT      Transaction Id
	*   x_error_code        OUT      Status code
	*   x_error_msg         OUT      Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
	*   OIC integation
	*
	**************************************************************************************/   
   PROCEDURE allocateMoveOrder(p_request_number    IN   VARCHAR2 DEFAULT NULL,
                               p_request_line_num  IN   VARCHAR2 DEFAULT NULL,
							   p_mo_header_id      IN   NUMBER DEFAULT NULL,
							   p_mo_line_id        IN   NUMBER DEFAULT NULL,
							   x_transaction_id    OUT  NUMBER,
						       x_error_code        OUT  VARCHAR2,
						       x_error_msg         OUT  VARCHAR2
                              )
   IS
      -- Common Declarations
      l_api_version		     NUMBER := 1.0; 
      l_init_msg_list		 VARCHAR2(2) := FND_API.G_TRUE; 
      l_commit		         VARCHAR2(2) := FND_API.G_FALSE; 
      x_return_status		 VARCHAR2(2);
      x_msg_count		     NUMBER := 0;
      x_msg_data             VARCHAR2(255);
	  -- Procedure Parameters initialization
	  l_request_number     VARCHAR2(30) := p_request_number;
	  l_request_line_num   VARCHAR2(10) := p_request_line_num;
	  l_mo_header_id       NUMBER       := p_mo_header_id;
	  l_mo_line_id         NUMBER       := p_mo_line_id;
	  l_txn_id             NUMBER        := NULL;
	  l_error_code         VARCHAR2(10)  := 'SUCCESS';
	  l_error_msg          VARCHAR2(20000);	
      -- API specific declarations          
	  l_trohdr_rec INV_MOVE_ORDER_PUB.TROHDR_REC_TYPE; 
	  l_trohdr_val_rec INV_MOVE_ORDER_PUB.TROHDR_VAL_REC_TYPE; 
	  x_trohdr_rec INV_MOVE_ORDER_PUB.TROHDR_REC_TYPE; 
	  x_trohdr_val_rec INV_MOVE_ORDER_PUB.TROHDR_VAL_REC_TYPE; 
	  l_validation_flag VARCHAR2(2) := INV_MOVE_ORDER_PUB.G_VALIDATION_YES; 

	  l_trolin_tbl INV_MOVE_ORDER_PUB.TROLIN_TBL_TYPE; 
	  l_trolin_val_tbl INV_MOVE_ORDER_PUB.TROLIN_VAL_TBL_TYPE; 
	  x_trolin_tbl INV_MOVE_ORDER_PUB.TROLIN_TBL_TYPE; 
	  x_trolin_val_tbl INV_MOVE_ORDER_PUB.TROLIN_VAL_TBL_TYPE; 
	  --l_validation_flag VARCHAR2(2) := INV_MOVE_ORDER_PUB.G_VALIDATION_YES; 
	  l_move_order_type MTL_TXN_REQUEST_HEADERS.MOVE_ORDER_TYPE%TYPE := 1; 
	  x_detailed_qty          NUMBER := 5; 
	  x_number_of_rows        NUMBER := 0; 
	  x_revision              VARCHAR2(3) ; 
	  x_locator_id            NUMBER := 0; 
	  x_transfer_to_location  NUMBER := 0; 
	  x_lot_number            VARCHAR2(30) ; 
	  x_expiration_date       DATE ; 
	  x_transaction_temp_id   NUMBER := 0; 
      -- WHO columns
      l_user_id		           NUMBER := -1;
	  l_resp_id		           NUMBER := -1;
      l_application_id	       NUMBER := -1;
      l_row_cnt		           NUMBER := 1;
      l_user_name		       VARCHAR2(30) := 'REQUEST';
      l_resp_name		       VARCHAR2(80) := 'Inventory';   
	  l_qty_delivered          NUMBER  := NULL;
   BEGIN
      -- Get the user_id
      SELECT user_id
        INTO l_user_id
        FROM fnd_user
       WHERE user_name = l_user_name;
      -- Get the application_id and responsibility_id
      SELECT application_id, responsibility_id
        INTO l_application_id, l_resp_id
        FROM fnd_responsibility_vl
       WHERE responsibility_name = l_resp_name;
	  IF l_request_number IS NOT NULL
	  THEN
		 BEGIN
		    SELECT header_id
			  INTO l_mo_header_id
		      FROM mtl_txn_request_headers 
			 WHERE request_number=l_request_number;
		  EXCEPTION
			 WHEN OTHERS THEN
				l_error_code := 'ERROR';
				IF l_error_msg IS NULL
				THEN
				   l_error_msg  := 'INVALID MO NUMBER';
				ELSE
				   l_error_msg  := l_error_msg||', MO NUMBER';
				END IF;
		 END;
	  END IF;
	  IF l_error_code != 'ERROR'
	  THEN
	     BEGIN
			SELECT line_id, nvl(mmtt.transaction_quantity, mtl.quantity_delivered)
			  INTO l_mo_line_id, l_qty_delivered
		      FROM mtl_material_transactions_temp mmtt,
                   mtl_txn_request_lines mtl,
                   mtl_txn_request_headers mth 
		     WHERE mmtt.move_order_line_id(+) = mtl.line_id
			   AND mth.header_id = mtl.header_id
			   AND mth.header_id=l_mo_header_id
               AND mtl.line_number = NVL(l_request_line_num, mtl.line_number)
			   AND mtl.line_id = NVL(l_mo_line_id, mtl.line_id)
			   ;
	     EXCEPTION
	        WHEN OTHERS THEN
		       l_error_code := 'ERROR';
			   IF l_error_msg IS NULL
			   THEN
			      l_error_msg  := 'INVALID MO LINE';
			   ELSE
			      l_error_msg  := l_error_msg||', MO LINE';
			   END IF;
	     END;
	  END IF;
	  IF l_qty_delivered IS NOT NULL
	  THEN
	     l_error_code := 'ERROR';
	     l_error_msg  := 'MO ALLOCATED';
	  END IF;
	  IF l_error_code != 'ERROR'
	  THEN 
		 FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, l_application_id);
		 --dbms_output.put_line('Initialized applications context: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );
		 inv_quantity_tree_pub.clear_quantity_cache;
		 mo_global.set_policy_context ('S', 81);
         inv_globals.set_org_id (81);
         mo_global.init ('INV');
		 -- Allocate each line of the Move Order 
		 INV_REPLENISH_DETAIL_PUB.line_details_pub( 
				  p_line_id               => l_mo_line_id 
				, x_number_of_rows        => x_number_of_rows 
				, x_detailed_qty          => x_detailed_qty 
				, x_return_status         => x_return_status 
				, x_msg_count             => x_msg_count 
				, x_msg_data              => x_msg_data 
				, x_revision              => x_revision 
				, x_locator_id            => x_locator_id 
				, x_transfer_to_location  => x_transfer_to_location 
				, x_lot_number	          => x_lot_number 
				, x_expiration_date       => x_expiration_date 
				, x_transaction_temp_id   => x_transaction_temp_id 
				, p_transaction_header_id => NULL 
				, p_transaction_mode      => NULL 
				, p_move_order_type       => l_move_order_type 
				, p_serial_flag           => FND_API.G_FALSE 
				, p_plan_tasks            => FALSE --FND_API.G_FALSE 
				, p_auto_pick_confirm     => FALSE --FND_API.G_FALSE 
				, p_commit                => FALSE --FND_API.G_FALSE 
		 ); 
		 DBMS_OUTPUT.PUT_LINE('=======================================================');
		 DBMS_OUTPUT.PUT_LINE('Return Status: '||x_return_status);
		 IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
		 	 DBMS_OUTPUT.PUT_LINE('Message count: '||x_msg_count||' Error Message :'||x_msg_data);
			 l_txn_id     := NULL;
			 l_error_code := 'ERROR';
			 l_error_msg  := x_msg_data;
			 IF ( x_msg_count > 1 ) THEN
				FOR i IN 1 .. x_msg_count LOOP
					x_msg_data := fnd_msg_pub.get ( p_msg_index => i , p_encoded =>FND_API.G_FALSE ) ;
					dbms_output.put_line ( 'message :' || x_msg_data);
				END LOOP;
			 END IF;
		 ELSE
		    DBMS_OUTPUT.PUT_LINE('Detailed Qty: '||x_detailed_qty); 
		    DBMS_OUTPUT.PUT_LINE('Number of rows: '||x_number_of_rows); 
		    DBMS_OUTPUT.PUT_LINE('Trx temp ID: '||x_transaction_temp_id);
		    DBMS_OUTPUT.PUT_LINE('locator_id:'||x_locator_id);
			DBMS_OUTPUT.PUT_LINE('lot_number:'||x_lot_number);
		    l_txn_id     := l_mo_line_id;
		    l_error_code := 'SUCCESS';
		    COMMIT;
	     END IF;
         DBMS_OUTPUT.PUT_LINE('=======================================================');
      END IF; 
	  x_transaction_id := l_mo_line_id;
      x_error_code     := l_error_code;
      x_error_msg      := l_error_msg; 
   EXCEPTION
	  WHEN OTHERS THEN 
	     x_error_code := 'ERROR';
		 x_error_msg  := dbms_utility.format_error_backtrace||':'||SQLERRM;
   END allocateMoveOrder;
   /**************************************************************************************
    *
    *   PROCEDURE
    *     TransactMoveOrder
    *
    *   DESCRIPTION
    *   Procedure to Transact Move Order in EBS based on the request received from OIC
    *
    *   PARAMETERS
	*   ==========
    *   NAME               TYPE      DESCRIPTION
    *   -----------------  --------  -----------------------------------------------
    *   p_request_number    IN       Move Order Number
	*   p_request_line_num  IN       Move Order Line Number
	*   x_transaction_id    OUT      Transaction Id 
	*   x_error_code        OUT      Status code
	*   x_error_msg         OUT      Error Message
	*
	*   RETURN VALUE
	*   NA
	*
	*   PREREQUISITES
	*   NA
	*
	*   CALLED BY
   *   OIC integation
   *
   **************************************************************************************/   
   PROCEDURE TransactMoveOrder(p_request_number    IN   VARCHAR2,
                               p_request_line_num  IN   VARCHAR2,
							   x_transaction_id    OUT  NUMBER,
						       x_error_code        OUT  VARCHAR2,
						       x_error_msg         OUT  VARCHAR2
                              )
   IS
      -- Common Declarations
      l_api_version		     NUMBER      := 1.0; 
      l_init_msg_list		 VARCHAR2(2) := FND_API.G_TRUE; 
      l_commit		         VARCHAR2(2) := FND_API.G_FALSE; 
      x_return_status		 VARCHAR2(2);
      x_msg_count		     NUMBER      := 0;
      x_msg_data             VARCHAR2(255); 
	  -- Procedure Parameters initialization
	  l_request_number     VARCHAR2(30)  := p_request_number;
	  l_request_line_num   VARCHAR2(10)  := p_request_line_num;
	  l_txn_id             NUMBER        := NULL;
	  l_error_code         VARCHAR2(10)  := 'SUCCESS';
	  l_error_msg          VARCHAR2(20000);	
      -- API specific declarations          
      l_move_order_type       NUMBER     := g_moveorder_type;
      l_transaction_mode      NUMBER     := 1;
      l_trolin_tbl            INV_MOVE_ORDER_PUB.trolin_tbl_type;
      l_mold_tbl              INV_MO_LINE_DETAIL_UTIL.g_mmtt_tbl_type;
      x_mmtt_tbl              INV_MO_LINE_DETAIL_UTIL.g_mmtt_tbl_type;
      x_trolin_tbl            INV_MOVE_ORDER_PUB.trolin_tbl_type;
      l_transaction_date      DATE := SYSDATE;   
      -- WHO columns
      l_user_id		           NUMBER := -1;
	  l_resp_id		           NUMBER := -1;
      l_application_id	       NUMBER := -1;
      l_row_cnt		           NUMBER := 1;
      l_user_name		       VARCHAR2(30) := 'REQUEST';
      l_resp_name		       VARCHAR2(80) := 'Inventory';   
	  l_mo_header_id           NUMBER  := 0;
	  l_mo_line_id	           NUMBER  := 0;
	  l_qty_delivered          NUMBER  := NULL;
   BEGIN
      -- Get the user_id
      SELECT user_id
        INTO l_user_id
        FROM fnd_user
       WHERE user_name = l_user_name;
      -- Get the application_id and responsibility_id
      SELECT application_id, responsibility_id
        INTO l_application_id, l_resp_id
        FROM fnd_responsibility_vl
       WHERE responsibility_name = l_resp_name;
	  BEGIN
	     SELECT header_id
		   INTO l_mo_header_id
           FROM MTL_TXN_REQUEST_HEADERS 
          WHERE request_number=l_request_number;
	  EXCEPTION
	     WHEN OTHERS THEN
		    l_error_code := 'ERROR';
			IF l_error_msg IS NULL
			THEN
			   l_error_msg  := 'INVALID MO NUMBER';
			ELSE
			   l_error_msg  := l_error_msg||', MO NUMBER';
			END IF;
	  END;
	  IF l_error_code != 'ERROR'
	  THEN
	     BEGIN
			SELECT line_id, quantity_delivered
			  INTO l_mo_line_id, l_qty_delivered
		      FROM mtl_txn_request_lines 
		     WHERE header_id=l_mo_header_id
               AND line_number = l_request_line_num;
	     EXCEPTION
	        WHEN OTHERS THEN
		       l_error_code := 'ERROR';
			   IF l_error_msg IS NULL
			   THEN
			      l_error_msg  := 'INVALID MO LINE';
			   ELSE
			      l_error_msg  := l_error_msg||', MO LINE';
			   END IF;
	     END;
	  END IF;
	  IF l_qty_delivered IS NOT NULL
	  THEN
	     l_error_code := 'ERROR';
	     l_error_msg  := 'ALREADY TRANSACTED';
	  END IF;
	  IF l_error_code != 'ERROR'
	  THEN 
		 FND_GLOBAL.APPS_INITIALIZE(l_user_id, l_resp_id, l_application_id);
		 dbms_output.put_line('Initialized applications context: '|| l_user_id || ' '|| l_resp_id ||' '|| l_application_id );
		 l_trolin_tbl(1).header_id           := l_mo_header_id;
		 l_trolin_tbl(1).line_id             := l_mo_line_id;
		 l_trolin_tbl(1).serial_number_start := NULL;
		 l_trolin_tbl(1).serial_number_end   := NULL;
		 l_trolin_tbl(1).lot_number          := NULL;
		 -- call API to create move order header
		 DBMS_OUTPUT.PUT_LINE('=======================================================');
		 DBMS_OUTPUT.PUT_LINE('Calling INV_Pick_Wave_Pick_Confirm_PUB.Pick_Confirm API');
		 INV_PICK_WAVE_PICK_CONFIRM_PUB.Pick_Confirm
		 	        (
						p_api_version_number => l_api_version
					,   p_init_msg_list	     => l_init_msg_list
					,   p_commit		     => l_commit
					,   x_return_status	     => x_return_status
					,   x_msg_count		     => x_msg_count
					,   x_msg_data		     => x_msg_data
					,   p_move_order_type    => l_move_order_type
					,   p_transaction_mode	 => l_transaction_mode
					,   p_trolin_tbl         => l_trolin_tbl
					,   p_mold_tbl		     => l_mold_tbl
					,   x_mmtt_tbl      	 => x_mmtt_tbl
					,   x_trolin_tbl         => x_trolin_tbl
					,   p_transaction_date   => l_transaction_date
				   );
		 DBMS_OUTPUT.PUT_LINE('=======================================================');
		 DBMS_OUTPUT.PUT_LINE('Return Status: '||x_return_status);
		 IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) 
		 THEN
		    IF ( x_msg_count > 1 ) 
			THEN
			   FOR i IN 1 .. x_msg_count 
			   LOOP
				   x_msg_data := fnd_msg_pub.get ( p_msg_index => i , p_encoded =>FND_API.G_FALSE ) ;
				   dbms_output.put_line ( 'message :' || x_msg_data);
			   END LOOP;
			 END IF;
		 	 l_txn_id     := NULL;
			 l_error_code := 'ERROR';
			 l_error_msg  := x_msg_data;
		 ELSE
		    l_txn_id     := l_mo_line_id;
		    l_error_code := 'SUCCESS';
		    COMMIT;
	     END IF;
         DBMS_OUTPUT.PUT_LINE('=======================================================');
   	  END IF; 
	  x_transaction_id := l_mo_line_id;
      x_error_code     := l_error_code;
      x_error_msg      := l_error_msg; 
   EXCEPTION
	  WHEN OTHERS THEN 
	     x_error_code := 'ERROR';
		 x_error_msg  := dbms_utility.format_error_backtrace||':'||SQLERRM;
   END TransactMoveOrder;
END DJOOIC_INV_LOANER_PKG;

/

  GRANT EXECUTE ON "APPS"."DJOOIC_INV_LOANER_PKG" TO "XXOIC";

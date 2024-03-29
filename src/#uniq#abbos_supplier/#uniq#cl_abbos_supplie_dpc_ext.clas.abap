class /UNIQ/CL_ABBOS_SUPPLIE_DPC_EXT definition
  public
  inheriting from /UNIQ/CL_ABBOS_SUPPLIE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_STREAM
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_STREAM
    redefinition .
protected section.

  methods CATEGORYSET_CREATE_ENTITY
    redefinition .
  methods CATEGORYSET_DELETE_ENTITY
    redefinition .
  methods CATEGORYSET_GET_ENTITY
    redefinition .
  methods CATEGORYSET_GET_ENTITYSET
    redefinition .
  methods CATEGORYSET_UPDATE_ENTITY
    redefinition .
  methods PRODUCTSET_CREATE_ENTITY
    redefinition .
  methods PRODUCTSET_DELETE_ENTITY
    redefinition .
  methods PRODUCTSET_GET_ENTITY
    redefinition .
  methods PRODUCTSET_GET_ENTITYSET
    redefinition .
  methods PRODUCTSET_UPDATE_ENTITY
    redefinition .
  methods SUPPLIERSET_CREATE_ENTITY
    redefinition .
  methods SUPPLIERSET_DELETE_ENTITY
    redefinition .
  methods SUPPLIERSET_GET_ENTITY
    redefinition .
  methods SUPPLIERSET_GET_ENTITYSET
    redefinition .
  methods SUPPLIERSET_UPDATE_ENTITY
    redefinition .
  methods PRODUCT_IMAGESET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS /UNIQ/CL_ABBOS_SUPPLIE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_stream.

    DATA: ls_prd_bild          TYPE /uniq/prd_bilder,
          ls_media             TYPE ty_s_media_resource,
          ls_request_context   TYPE /iwbep/if_mgw_core_srv_runtime=>ty_s_mgw_request_context,  "is_request_details
          lo_entity_descriptor TYPE REF TO /iwbep/cl_mgw_expand_node,  "lo_entity_descriptor ?= ls_request_context-technical_request-expand_root.

          ls_prd               TYPE /uniq/at_prd.
    DATA(lt_request_details) = mr_request_details->t_uri_query_parameter.


    CASE iv_entity_name.
**********************************************************************
*& Wenn Request vom Entity Product kommt, wird Create auf Product vehindert
**********************************************************************
      WHEN'Product'.

        IF is_media_resource-mime_type = 'application/json'.


          DATA(lo_entry_provider) = NEW

                    /iwbep/cl_mgw_entry_raw_prv(

                      iv_raw_data = is_media_resource-value
                      ).
          lo_entity_descriptor ?= ls_request_context-technical_request-expand_root.
          me->productset_create_entity(
            EXPORTING
              iv_entity_name          = iv_entity_name
              iv_entity_set_name      = iv_entity_set_name
              iv_source_name          = iv_source_name
              it_key_tab              = it_key_tab                  " table for name value pairs
              io_tech_request_context = io_tech_request_context
              it_navigation_path      = it_navigation_path                 " table of navigation paths
              io_data_provider        = lo_entry_provider                 " MGW Entry Data Provider
            IMPORTING
              er_entity               = DATA(ls_entity)                  " Zurückg. Daten
          ).

          copy_data_to_ref(
            EXPORTING
              is_data = ls_entity
            CHANGING
              cr_data = er_entity
          ).

        ELSE.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-011.

        ENDIF.



      WHEN'Product_Image'.

        READ TABLE lt_request_details WITH KEY name = 'Productid' INTO DATA(ls_key).
**********************************************************************
*& Wenn lt_request_details kein Product id enthählt, wird exception geworfen
**********************************************************************
        IF sy-subrc <> 0.

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-007.
        ENDIF.
*************************Bilder Id wird automatisch erstellt*********************************************
        SELECT MAX( bilderid ) FROM /uniq/prd_bilder INTO @DATA(lv_bilderid).

****Hier wird productname aus Tabelle Product gehohlt, um in Tabelle Bilder filename mit productname gespiechert zu werden*************************************************
        SELECT SINGLE productname
           FROM /uniq/at_prd
           WHERE productid = @ls_key-value
          INTO ( @DATA(lv_productname) ).

        ls_prd_bild-bilderid = lv_bilderid + 1.
        ls_prd_bild-productid = ls_key-value.
        ls_prd_bild-mimitype = is_media_resource-mime_type.
        ls_prd_bild-value = is_media_resource-value.
        ls_prd_bild-filename = |{ lv_productname }.{ substring_after( val = is_media_resource-mime_type sub = '/' ) }|.

**********************Leerzeichen wird entfert************************************************
        CONDENSE ls_prd_bild-bilderid.

**********************Bilder in Datenbank eingefügt************************************************
        INSERT /uniq/prd_bilder FROM ls_prd_bild.

        IF  sy-subrc <> 0.
          mo_context->get_message_container( )->add_message_text_only(
            EXPORTING
              iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
              iv_msg_text               = TEXT-002
              iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
              iv_entity_type            = iv_entity_name ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = mo_context->get_message_container( ).
        ENDIF.

********************Eingefügte Bilder Daten wird zurückgegeben**************************************************
        copy_data_to_ref(
             EXPORTING
               is_data = ls_prd_bild
             CHANGING
               cr_data = er_entity
           ).
    ENDCASE.



  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~delete_stream.

    DATA lt_prd TYPE TABLE OF /uniq/at_prd.
    DATA(lt_keys) = io_tech_request_context->get_keys( ).

    CASE iv_entity_name.

      WHEN'Product'.

        DATA(lv_prd_id) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_prd_id IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        SELECT SINGLE *
            FROM /uniq/at_prd
           WHERE productid = @lv_prd_id
          INTO @DATA(ls_prd).

        CLEAR: ls_prd-filename, ls_prd-mimitype, ls_prd-value.

        UPDATE /uniq/at_prd FROM ls_prd.

        IF  sy-subrc <> 0.
          mo_context->get_message_container( )->add_message_text_only(
            EXPORTING
              iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
              iv_msg_text               = TEXT-004
              iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
              iv_entity_type            = iv_entity_name ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = mo_context->get_message_container( ).
        ENDIF.

      WHEN'Product_Image'.

        DATA(lv_prd_bild_id) = lt_keys[ name = 'BILDERID' ]-value.
        DATA(lv_prod_id) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_prd_bild_id IS INITIAL OR lv_prod_id IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        DELETE FROM /uniq/prd_bilder WHERE bilderid = lv_prd_bild_id AND productid = lv_prod_id.

        IF  sy-subrc <> 0.
          mo_context->get_message_container( )->add_message_text_only(
            EXPORTING
              iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
              iv_msg_text               = TEXT-004
              iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
              iv_entity_type            = iv_entity_name ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = mo_context->get_message_container( ).
        ENDIF.
*        copy_data_to_ref(
*          EXPORTING
*            is_data = ls_prd_bild
*         CHANGING
*           cr_data = /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_STREAM ).
    ENDCASE.
  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_stream.


    DATA : ls_media  TYPE ty_s_media_resource,
           ls_header TYPE ihttpnvp.
    DATA(lt_keys) = io_tech_request_context->get_keys( ).

    CASE iv_entity_name.

      WHEN'Product'.

        DATA(lv_productid) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_productid IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        SELECT SINGLE
             FROM /uniq/at_prd
               FIELDS value, mimitype, filename
             WHERE productid = @lv_productid
            INTO ( @ls_media-value, @ls_media-mime_type, @DATA(lv_filename) ).

        ls_header = VALUE ihttpnvp( name  = 'Content-Disposition'
                                                 value = |inline; filename="{ escape( val = lv_filename format = cl_abap_format=>e_url ) }";| ).
        set_header( is_header = ls_header ).

        copy_data_to_ref(
          EXPORTING
            is_data = ls_media
          CHANGING
            cr_data = er_stream
        ).

      WHEN'Product_Image'.

        DATA(lv_bilderid) = lt_keys[ name = 'BILDERID' ]-value.
        DATA(lv_prod_id) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_bilderid IS INITIAL OR lv_prod_id IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        SELECT SINGLE
             FROM /uniq/prd_bilder
               FIELDS value, mimitype, filename
             WHERE bilderid = @lv_bilderid AND productid = @lv_prod_id
            INTO ( @ls_media-value, @ls_media-mime_type, @DATA(lv_filename_bild) ).

        ls_header = VALUE ihttpnvp( name  = 'Content-Disposition'
                                                 value = |inline; filename="{ escape( val = lv_filename_bild format = cl_abap_format=>e_url ) }";| ).
        set_header( is_header = ls_header ).

        copy_data_to_ref(
          EXPORTING
            is_data = ls_media
          CHANGING
            cr_data = er_stream
        ).
    ENDCASE.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~update_stream.

    DATA(lt_keys) = io_tech_request_context->get_keys( ).

    CASE iv_entity_name.

      WHEN'Product'.
        DATA(lv_prd_id) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_prd_id IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        SELECT SINGLE *
            FROM /uniq/at_prd
           WHERE productid = @lv_prd_id
          INTO @DATA(ls_prd).

        ls_prd-mimitype = is_media_resource-mime_type.
        ls_prd-value = is_media_resource-value.
        ls_prd-filename = |{ ls_prd-productname }.{ substring_after( val = is_media_resource-mime_type sub = '/' ) }|.

        UPDATE /uniq/at_prd FROM ls_prd.

        IF  sy-subrc <> 0.
          mo_context->get_message_container( )->add_message_text_only(
            EXPORTING
              iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
              iv_msg_text               = TEXT-004
              iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
              iv_entity_type            = iv_entity_name ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = mo_context->get_message_container( ).
        ENDIF.

      WHEN'Product_Image'.

        DATA(lv_prd_bild_id) = lt_keys[ name = 'BILDERID' ]-value.
        DATA(lv_prod_id) = lt_keys[ name = 'PRODUCTID' ]-value.

        IF lv_prd_bild_id IS INITIAL OR lv_prod_id IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid           = /iwbep/cx_mgw_busi_exception=>business_error
              http_status_code = '404'
              message          = TEXT-010.
        ENDIF.

        SELECT SINGLE *
           FROM /uniq/prd_bilder
           WHERE bilderid = @lv_prd_bild_id AND productid = @lv_prod_id
          INTO @DATA(ls_prd_bild).

****Hier wird productname aus Tabelle Product geholt, um in Tabelle Bilder filename mit productname gespiechert zu werden*************************************************
        SELECT SINGLE productname
          FROM /uniq/at_prd
          WHERE productid = @lv_prod_id
         INTO @DATA(lv_productname).

        ls_prd_bild-mimitype = is_media_resource-mime_type.
        ls_prd_bild-value = is_media_resource-value.
        ls_prd_bild-filename = |{ lv_productname }.{ substring_after( val = is_media_resource-mime_type sub = '/' ) }|.

        UPDATE /uniq/prd_bilder FROM ls_prd_bild.

        IF  sy-subrc <> 0.
          mo_context->get_message_container( )->add_message_text_only(
            EXPORTING
              iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
              iv_msg_text               = TEXT-004
              iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
              iv_entity_type            = iv_entity_name ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
            EXPORTING
              message_container = mo_context->get_message_container( ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


METHOD categoryset_create_entity.

  DATA : ls_cat_db TYPE /uniq/at_cat.
  "ls_cat    LIKE er_entity.

  io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

**********************************************************************
*& Check if the user has read permission
**********************************************************************
  AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
           ID 'ACTVT' FIELD '03'
           ID 'CATEGORYID' FIELD er_entity-categoryid.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid           = /iwbep/cx_mgw_busi_exception=>business_error
        http_status_code = '404'
        message          = TEXT-013.
  ENDIF.
**********************************************************************
*& IF yes Check if the user has delete permission
**********************************************************************
  AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
       ID 'ACTVT' FIELD '01'
       ID 'CATEGORYID' FIELD er_entity-categoryid.

  IF sy-subrc <> 0.

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid           = /iwbep/cx_mgw_busi_exception=>business_error
        http_status_code = '401'
        message          = TEXT-012.
  ENDIF.

  MOVE-CORRESPONDING er_entity TO ls_cat_db.

  INSERT /uniq/at_cat FROM ls_cat_db.

  IF sy-subrc <> 0.

    mo_context->get_message_container( )->add_message_text_only(
      EXPORTING
        iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
        iv_msg_text               = TEXT-002
        iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
        iv_entity_type            = iv_entity_name ).

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
      EXPORTING
        message_container = mo_context->get_message_container( ).
  ENDIF.

ENDMETHOD.


  METHOD categoryset_delete_entity.

    DATA: ls_prd  TYPE /uniq/supplier_gw_s_prd,
          ls_keys TYPE /uniq/supplier_gw_s_cat.


    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '03'
             ID 'CATEGORYID' FIELD ls_keys-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.


**********************************************************************
*& IF yes Check if the user has delete permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
          ID 'ACTVT' FIELD '06'
          ID 'CATEGORYID' FIELD ls_keys-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '403'
          message          = TEXT-012.
    ENDIF.

**********************************************************************
*& Check if there is a reference to the category id from the products table
**********************************************************************
    SELECT SINGLE @abap_true
      FROM /uniq/at_prd
      INTO @DATA(lv_prd_exists)
     WHERE categoryid = @ls_keys-categoryid.

**********************************************************************
*& if there is a reference to the category id from the products table, than throw business execption
**********************************************************************
    IF lv_prd_exists = abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = TEXT-009.
    ENDIF.

**********************************************************************
*& Check if there is a record exist to the category id in the category table
**********************************************************************
    SELECT SINGLE @abap_true
      FROM /uniq/at_cat
      INTO @DATA(lv_cat_exists)
     WHERE categoryid = @ls_keys-categoryid.

    IF lv_cat_exists = abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = TEXT-006.
    ENDIF.

    DELETE FROM /uniq/at_cat WHERE categoryid = ls_keys-categoryid.

    IF  sy-subrc <> 0.
      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-001
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.

  ENDMETHOD.


  METHOD categoryset_get_entity.

    DATA: ls_nav_path TYPE /iwbep/s_mgw_tech_navi,
          lt_nav_path TYPE /iwbep/t_mgw_tech_navi,
          ls_prd      TYPE /uniq/supplier_gw_s_prd,
          ls_cat      TYPE /uniq/supplier_gw_s_cat.

    lt_nav_path = io_tech_request_context->get_navigation_path( ).

    DATA(lv_source_name) = iv_source_name.

**********************************************************************
*& will get single Category from given ID and From Product Path to Category
**********************************************************************
    IF lt_nav_path IS NOT INITIAL.

      READ TABLE lt_nav_path INTO ls_nav_path WITH KEY nav_prop = 'TOCATEGORY'.

      IF sy-subrc = 0.

        io_tech_request_context->get_converted_source_keys( IMPORTING es_key_values = ls_prd ).

        /uniq/cl_show_sup_proj=>get_category(
                EXPORTING
                  iv_for_cat_and_prd_id = ls_prd-productid
                  it_nav_path           = lt_nav_path
                IMPORTING
                  er_entity      =  er_entity ).
      ENDIF.

    ELSE.
**********************************************************************
*& will get single Category from given ID
**********************************************************************
      io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_cat ).

      /uniq/cl_show_sup_proj=>get_category(
                EXPORTING
                  iv_for_cat_and_prd_id = ls_cat-categoryid
                  it_nav_path           = lt_nav_path
                IMPORTING
                  er_entity      =  er_entity ).
    ENDIF.
**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '03' " read
             ID 'CATEGORYID' FIELD er_entity-categoryid.

    IF sy-subrc <> 0.

      CLEAR er_entity.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.


  ENDMETHOD.


  METHOD categoryset_get_entityset.

**********************************************************************
*& will get all Categories
**********************************************************************
    /uniq/cl_show_sup_proj=>get_all_categories(
            EXPORTING
              iv_sql_where        = io_tech_request_context->get_osql_where_clause( )
              iv_top              = io_tech_request_context->get_top( )
              iv_skip             = io_tech_request_context->get_skip( )
              it_order            = it_order
              iv_inlinecount_set  = io_tech_request_context->has_inlinecount( )
            IMPORTING
              et_category         = et_entityset
              ev_total_count      = es_response_context-inlinecount ).


  ENDMETHOD.


  METHOD categoryset_update_entity.

    DATA: ls_keys   LIKE er_entity,
          ls_cat_db TYPE /uniq/at_cat.

    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& categoryid is primary key and may NOT be changed, so we overwrite by key from URL Segment
**********************************************************************
    er_entity-categoryid = ls_keys-categoryid.
**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '03' "Lesen
             ID 'CATEGORYID' FIELD ls_keys-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.
**********************************************************************
*& IF yes Check if the user has update permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '02' "Updaten
             ID 'CATEGORYID' FIELD ls_keys-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '403'
          message          = TEXT-012.
    ENDIF.

**********************************************************************
*& Check if there is a record exist to the category id in the category table
**********************************************************************

    SELECT SINGLE @abap_true
      FROM /uniq/at_cat
      INTO @DATA(lv_cat_exists)
     WHERE categoryid = @ls_keys-categoryid.

    IF  lv_cat_exists <> abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-006.
    ENDIF.

    MOVE-CORRESPONDING er_entity TO ls_cat_db.

    UPDATE /uniq/at_cat FROM ls_cat_db.

    IF sy-subrc <> 0.
      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-004
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.
  ENDMETHOD.


  METHOD productset_create_entity.

    DATA: ls_prd_db      TYPE /uniq/at_prd,
*          ls_cat         TYPE /uniq/at_cat,
*          ls_sup         TYPE /uniq/at_sup,
          lv_err_message TYPE bapi_msg.

    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

**********************************************************************
*& Verify that the correct Supplier ID and Category ID are provided
**********************************************************************
    IF /uniq/cl_show_sup_proj=>check_validity_product(
        EXPORTING
          is_entity      = er_entity
        IMPORTING
          ev_err_message = lv_err_message ) EQ abap_false.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = lv_err_message.
    ENDIF.
**********************************************************************
*& AUTHORITY-CHECK  READ of CategoryID
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
               ID 'ACTVT' FIELD '03' "Lesen
               ID 'CATEGORYID' FIELD er_entity-categoryid.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.
**********************************************************************
*& AUTHORITY-CHECK  CREATE of CategoryID
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '01'
             ID 'CATEGORYID' FIELD er_entity-categoryid.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '403'
          message          = TEXT-012.
    ENDIF.
*
*    DATA(o_auth) = cl_auth_objects_to_sql=>create_for_open_sql( ).
*    DATA(lv_where_cond) = o_auth->get_sql_condition( ).


    MOVE-CORRESPONDING er_entity TO ls_prd_db.

    INSERT /uniq/at_prd FROM ls_prd_db.

    IF sy-subrc <> 0.

      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-002
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.


  ENDMETHOD.


  METHOD productset_delete_entity.

    DATA: ls_produktid TYPE /uniq/supplier_gw_s_prd,
          ls_keys      TYPE /uniq/supplier_gw_s_prd.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).


**********************************************************************
*& retrieves the category ID from the products table
**********************************************************************
    SELECT SINGLE *
      FROM  /uniq/at_prd
      INTO @DATA(ls_prod)
     WHERE productid = @ls_keys-productid.
**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '03'
             ID 'CATEGORYID' FIELD ls_prod-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.
**********************************************************************
*& IF yes Check if the user has delete permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
       ID 'ACTVT' FIELD '06'
       ID 'CATEGORYID' FIELD ls_prod-categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '403'
          message          = TEXT-012.
    ENDIF.
**********************************************************************
*& Check if there is a record exist to the product id in the product table
**********************************************************************

    SELECT SINGLE @abap_true
      FROM /uniq/at_prd
      INTO @DATA(lv_prd_exists)
     WHERE productid = @ls_keys-productid.

    IF lv_prd_exists <> abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-007.
    ENDIF.

    DELETE FROM /uniq/at_prd WHERE productid = ls_keys-productid.

    IF sy-subrc <> 0.

      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-001
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.
  ENDMETHOD.


  METHOD productset_get_entity.
**********************************************************************
*& will get single product from given ID
**********************************************************************
    DATA: ls_prd TYPE /uniq/supplier_gw_s_prd.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_prd ).

    SELECT SINGLE *
      FROM /uniq/at_prd
      INTO CORRESPONDING FIELDS OF @er_entity
     WHERE productid = @ls_prd-productid.

*    hat aktueller Benutzer
*     - LESE Berechtigung auf die
*     - Categorie des angeforderten Produktes
**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
         ID 'ACTVT'      FIELD '03' " LESEN
         ID 'CATEGORYID' FIELD er_entity-categoryid.

    IF sy-subrc <> 0.
      CLEAR er_entity.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.



    /uniq/cl_show_sup_proj=>calculate_poduct_totalamount(
     EXPORTING
       iv_price        = er_entity-price
       iv_quantity     =  er_entity-quantity
     RECEIVING
       rv_total_amount = er_entity-totalamount ).
  ENDMETHOD.


  METHOD productset_get_entityset.

    DATA: ls_nav_path TYPE /iwbep/s_mgw_tech_navi,
          lt_nav_path TYPE /iwbep/t_mgw_tech_navi,
          ls_product  TYPE /uniq/supplier_gw_s_prd.

    DATA: lv_my_super_where_clause TYPE string.

    lt_nav_path = io_tech_request_context->get_navigation_path( ).

    lv_my_super_where_clause = io_tech_request_context->get_osql_where_clause( ).

**********************************************************************
*& Will get all products after chack for navigation
**********************************************************************
    IF lt_nav_path IS NOT INITIAL.

      " in case of navigation, we  modify where clause using source property
      " example:
      " SupplierSet(123)/ToProducts                        => where clause:                   supplierid = 123
      " SupplierSet(123)/ToProducts?$filter=Color eq red   => where clause: (color = red) AND supplierid = 123

      IF lv_my_super_where_clause IS NOT INITIAL.
        " we HAVE a $filter, so put original WHERE clause in () and connect to nav filter using AND
        lv_my_super_where_clause = |{ lv_my_super_where_clause } AND |.
      ENDIF.

      READ TABLE lt_nav_path INTO ls_nav_path WITH KEY nav_prop = 'TOPRODUCTS'.

      io_tech_request_context->get_converted_source_keys( IMPORTING es_key_values = ls_product ).

      IF ls_nav_path-source_entity_type EQ /uniq/cl_abbos_supplie_mpc=>gc_supplier.
        lv_my_super_where_clause = |{ lv_my_super_where_clause }( supplierid = '{ ls_product-supplierid }' )|. " in where caluse muss ein String in so Form => ( CATEGORYID = '0001' ) angegeben sein
      ELSEIF ls_nav_path-source_entity_type EQ /uniq/cl_abbos_supplie_mpc=>gc_category.
        lv_my_super_where_clause = |{ lv_my_super_where_clause }( categoryid = '{ ls_product-categoryid }' )|.
      ENDIF.

    ENDIF.

**********************************************************************
*& Will get all products if don't set navigation
**********************************************************************
*    /uniq/cl_show_sup_proj=>get_all_products_jd(
*            EXPORTING
*              iv_sql_where            = lv_my_super_where_clause
*              io_tech_req             = io_tech_request_context
*              it_order                = it_order
*              it_uri_query_parameter  = mr_request_details->t_uri_query_parameter
*            IMPORTING
*              et_product              = et_entityset
*              ev_total_count          = es_response_context-inlinecount ).

    /uniq/cl_show_sup_proj=>get_all_products(
      EXPORTING
        iv_sql_where           = lv_my_super_where_clause
        iv_top                 =  io_tech_request_context->get_top( )
        iv_skip                =  io_tech_request_context->get_skip( )
        iv_inlinecount_set     =  io_tech_request_context->has_inlinecount( )
        it_order               =  it_order
        it_uri_query_parameter =  mr_request_details->t_uri_query_parameter
      IMPORTING
        et_product             = et_entityset
        ev_total_count         = es_response_context-inlinecount ).

  ENDMETHOD.


  METHOD productset_update_entity.

* - use SINGLE in valudity check
* - (or create a method check_validity_of_product
* - remove commits/rallbacks as in product_create

    DATA: ls_keys        LIKE er_entity,
          ls_prd_db      TYPE /uniq/at_prd,
          lv_err_message TYPE bapi_msg.


    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& categoryid is primary key and may NOT be changed, so we overwrite by key from URL Segment
**********************************************************************
    er_entity-productid = ls_keys-productid.
**********************************************************************
*& Verify that the correct Supplier ID and Category ID are provided
**********************************************************************
    IF /uniq/cl_show_sup_proj=>check_validity_product(
       EXPORTING
         is_entity      = er_entity
       IMPORTING
         ev_err_message = lv_err_message ) EQ abap_false.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = lv_err_message.
    ENDIF.
**********************************************************************
* FIXME: wenn ich Update-berechtigungen auf Getränke habe, aber nur lesende auf Autos,
*        dann darf ich ein Auto nicht zu einem Getränk machen !!!
*        also kategorie von BMW nciht von "auto" auf "getränk" ändern
    SELECT SINGLE categoryid
      FROM /uniq/at_prd
      INTO @DATA(lv_categoryid)
     WHERE productid = @ls_keys-productid.
**********************************************************************
*& Check if the user has read permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '03'
             ID 'CATEGORYID' FIELD er_entity-categoryid
             ID 'CATEGORYID' FIELD lv_categoryid.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-013.
    ENDIF.
**********************************************************************
*& IF yes Check if the user has update permission
**********************************************************************
    AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
             ID 'ACTVT' FIELD '02'
             ID 'CATEGORYID' FIELD er_entity-categoryid
             ID 'CATEGORYID' FIELD lv_categoryid.

    IF sy-subrc <> 0.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '403'
          message          = TEXT-012.
    ENDIF.
**********************************************************************
*& Check if there is a record exist to the supplier id in the product table
**********************************************************************
    SELECT SINGLE @abap_true
     FROM /uniq/at_prd
     INTO @DATA(lv_prd_exists)
    WHERE productid = @ls_keys-productid.

    IF lv_prd_exists <> abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-007.
    ENDIF.

    MOVE-CORRESPONDING er_entity TO ls_prd_db.

    UPDATE /uniq/at_prd FROM ls_prd_db.

    IF sy-subrc <> 0.
      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-004
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.
  ENDMETHOD.


  METHOD product_imageset_get_entityset.

    DATA: lv_where     TYPE string,
          ls_prod_bild TYPE /uniq/supplier_gw_s_prd_bild.
*          ls_media     TYPE ty_s_media_resource,
*          ls_header    TYPE ihttpnvp.

    DATA(lt_nav_path) = io_tech_request_context->get_navigation_path( ).

    io_tech_request_context->get_converted_source_keys( IMPORTING es_key_values = ls_prod_bild ).

**********************************************************************
*& wenn aus Product URL mit TOIMAGES kommt, bekommt lv_where product id in where Bedienung
*& wenn ProductSet gefragt is, ist lv_where leer, sodass alle Image geliefert werden
**********************************************************************
    IF  lt_nav_path IS NOT INITIAL.
      READ TABLE lt_nav_path INTO DATA(ls_nav_path) WITH KEY nav_prop = 'TOIMAGES'.
      IF sy-subrc EQ 0.
        lv_where = |( productid = '{ ls_prod_bild-productid }' )|.
      ENDIF.
    ENDIF.

    SELECT *
      FROM /uniq/prd_bilder
      INTO CORRESPONDING FIELDS OF TABLE @et_entityset
     WHERE (lv_where).

    IF io_tech_request_context->has_inlinecount( ) EQ abap_true .
      es_response_context-inlinecount = lines( et_entityset ).
    ENDIF.
  ENDMETHOD.


  METHOD supplierset_create_entity.

    DATA : ls_sup_db TYPE /uniq/at_sup.
*           ls_sup    LIKE er_entity.

    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    MOVE-CORRESPONDING er_entity TO ls_sup_db.

    INSERT /uniq/at_sup FROM ls_sup_db.

    IF sy-subrc <> 0.

      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-002
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.

  ENDMETHOD.


  METHOD supplierset_delete_entity.

    DATA: ls_prd  TYPE /uniq/supplier_gw_s_prd,
          ls_keys TYPE /uniq/supplier_gw_s_sup.


    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& Check if there is a reference to the supplier id from the products table
**********************************************************************

    SELECT SINGLE @abap_true
     FROM /uniq/at_prd
     INTO @DATA(lv_prd_exists)
    WHERE supplierid = @ls_keys-supplierid.

**********************************************************************
*& if there is a reference to the supplier id from the products table, than throw business execption
**********************************************************************
    IF lv_prd_exists = abap_true.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = TEXT-009.
    ENDIF.

**********************************************************************
*& Check if there is a record exist to the supplier id in the supplier table
**********************************************************************
    SELECT SINGLE @abap_true
      FROM /uniq/at_sup
      INTO @DATA(lv_sup_exists)
     WHERE supplierid = @ls_keys-supplierid.

**********************************************************************
*& if there is a record exist to the supplier id in the supplier table
**********************************************************************
    IF lv_sup_exists <> abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = TEXT-008.
    ENDIF.

    DELETE FROM /uniq/at_sup WHERE supplierid = ls_keys-supplierid.

    IF sy-subrc <> 0.
      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-001
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.

  ENDMETHOD.


  METHOD supplierset_get_entity.
**********************************************************************
*& get single Supplier by given ID
**********************************************************************
    DATA: ls_sup TYPE /uniq/supplier_gw_s_sup.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_sup ).

    SELECT SINGLE *
      FROM /uniq/at_sup
      INTO CORRESPONDING FIELDS OF @er_entity
     WHERE supplierid = @ls_sup-supplierid.

**********************************************************************
*& returns the number of products this supplier has
**********************************************************************
    er_entity-numberofproducts = /uniq/cl_show_sup_proj=>get_all_num_of_prd_for_sup( iv_sup_id = er_entity-supplierid ).

**********************************************************************
*& returns the sum of all TotalAmounts of the products associated with this supplier.
**********************************************************************
    er_entity-totalamount = /uniq/cl_show_sup_proj=>add_prd_totalamount_for_sup( iv_sup_id = er_entity-supplierid ).

  ENDMETHOD.


  METHOD supplierset_get_entityset.

**********************************************************************
*& Will get all suppliers
**********************************************************************
    /uniq/cl_show_sup_proj=>get_all_suppliers(
            EXPORTING
              iv_sql_where        = io_tech_request_context->get_osql_where_clause( ) "iv_filter_String
              iv_top              = io_tech_request_context->get_top( )
              iv_skip             = io_tech_request_context->get_skip( )
              it_order            = it_order
              iv_inlinecount_set  = io_tech_request_context->has_inlinecount( )
            IMPORTING
              et_supplier         = et_entityset
              ev_total_count      = es_response_context-inlinecount ).

  ENDMETHOD.


  METHOD supplierset_update_entity.

    DATA: ls_keys   LIKE er_entity,
          ls_sup_db TYPE /uniq/at_sup.

    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& categoryid is primary key and may NOT be changed, so we overwrite by key from URL Segment
**********************************************************************
    er_entity-supplierid = ls_keys-supplierid.

**********************************************************************
*& Check if there is a record exist to the supplier id in the supplier table
**********************************************************************
    SELECT SINGLE @abap_true
     FROM /uniq/at_sup
     INTO @DATA(lv_sup_exists)
    WHERE supplierid = @ls_keys-supplierid.

    IF  lv_sup_exists <> abap_true.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-008.
    ENDIF.

    MOVE-CORRESPONDING er_entity TO ls_sup_db.

    UPDATE /uniq/at_sup FROM ls_sup_db.

    IF sy-subrc <> 0.

      mo_context->get_message_container( )->add_message_text_only(
        EXPORTING
          iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
          iv_msg_text               = TEXT-004
          iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
          iv_entity_type            = iv_entity_name ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          message_container = mo_context->get_message_container( ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.

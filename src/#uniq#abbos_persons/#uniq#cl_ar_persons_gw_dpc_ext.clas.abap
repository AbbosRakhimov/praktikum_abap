class /UNIQ/CL_AR_PERSONS_GW_DPC_EXT definition
  public
  inheriting from /UNIQ/CL_AR_PERSONS_GW_DPC
  create public .

public section.
protected section.

  methods PERSONSET_CREATE_ENTITY
    redefinition .
  methods PERSONSET_DELETE_ENTITY
    redefinition .
  methods PERSONSET_GET_ENTITY
    redefinition .
  methods PERSONSET_GET_ENTITYSET
    redefinition .
  methods PERSONSET_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS /UNIQ/CL_AR_PERSONS_GW_DPC_EXT IMPLEMENTATION.


  METHOD personset_create_entity.

    DATA : ls_pers_db TYPE /uniq/at_pers.




    SELECT MAX( personid ) FROM /uniq/at_pers INTO @DATA(lv_pers_id).

    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

**********************************************************************
*& gets the last person id from the database
**********************************************************************
*    SELECT MAX( personid ) FROM /uniq/at_pers INTO @DATA(lv_pers_id).

    er_entity-personid = lv_pers_id + 1.
    MOVE-CORRESPONDING er_entity TO ls_pers_db.
    MOVE-CORRESPONDING er_entity-adresse TO ls_pers_db.

    INSERT /uniq/at_pers FROM ls_pers_db.

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


  METHOD personset_delete_entity.

    DATA: ls_keys TYPE /uniq/persons_gw_s_pers.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& Check if there is a record exist to the category id in the category table
**********************************************************************
    SELECT SINGLE @abap_true
      FROM /uniq/at_pers
      INTO @DATA(lv_pers_exists)
     WHERE personid = @ls_keys-personid.

    IF lv_pers_exists = abap_true.

      DELETE FROM /uniq/at_pers WHERE personid = ls_keys-personid.

      IF  sy-subrc <> 0.
        mo_context->get_message_container( )->add_message_text_only(
          EXPORTING
            iv_msg_type               = /iwbep/if_message_container=>gcs_message_type-abort
            iv_msg_text               = TEXT-003
            iv_error_category         = /iwbep/if_message_container=>gcs_error_category-conflict
            iv_entity_type            = iv_entity_name ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            message_container = mo_context->get_message_container( ).
      ENDIF.
    ELSE.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message = TEXT-004.
    ENDIF.
  ENDMETHOD.


  METHOD personset_get_entity.


    DATA: ls_pers    TYPE /uniq/persons_gw_s_pers,
          ls_entity TYPE /uniq/at_pers.

**********************************************************************
    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_pers ).

    IF ls_pers IS NOT INITIAL.

      SELECT SINGLE *
       FROM /uniq/at_pers
       INTO CORRESPONDING FIELDS OF @ls_entity
      WHERE personid = @ls_pers-personid.


      MOVE-CORRESPONDING ls_entity TO er_entity.
      MOVE-CORRESPONDING ls_entity TO er_entity-adresse.

    ELSEIF ls_pers IS INITIAL.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = TEXT-001.
    ELSE.
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

**********************************************************************
*    SELECT SINGLE *
*      FROM /uniq/at_pers
*      INTO CORRESPONDING FIELDS OF @er_entity
*      WHERE personid = @ls_pers-personid.




*    SELECT SINGLE *
*      FROM /uniq/at_adresse
*      INTO CORRESPONDING FIELDS OF @ls_adresse
*      WHERE adressid = @er_entity-adressid.

*      er_entity-adresse = ls_adresse.

  ENDMETHOD.


  METHOD personset_get_entityset.

*
* wenn INLINECOUNT angefragt wurde, brauche ich die DATEN und den COUNT
* wenn nur COUNT angefragt wurde, brauche ich gar keine DATEN, nur den COUNT
* beim berechnen des COUNTS spielt ORDERBY keine ROLLE
* beim Berechnen des COUNTS und des INLINECOUNTS spielt Filter eine Rolle!
* das  Berechnen des COUNTS und des INLINECOUNTS muss unabhängig vom PAGEING passieren
* FILTER und ORDER müssen VOR dem PAGING passieren
* FILTER und ORDER reihenfolge egal (idealerweise gleichzeitig), beide aber VOR DEM PAGING
*
* wenn calculated fields notwendig sind, diese ERST DANN berechnen,
*      wenn die MEnge der Daten soweit wie möglich reduziert ist



    DATA: lv_order_by  TYPE string,
          ls_entityset LIKE LINE OF et_entityset,
          lt_entityset TYPE TABLE OF /uniq/at_pers.
**********************************************************************
    DATA(lv_sql_where) = io_tech_request_context->get_osql_where_clause( ).
    DATA(lv_top) = io_tech_request_context->get_top( ).
    DATA(lv_skip) = io_tech_request_context->get_skip( ).
    DATA(lv_maxrows) = lv_top + lv_skip.


********************Internal Table it_order content is converted to string **************************************************
    LOOP AT it_order INTO DATA(ls_order).
      lv_order_by = lv_order_by &&
       COND string( WHEN  ls_order-order  = `desc`
                       THEN |, { ls_order-property } DESCENDING| "it is important that you make an escape after the comma->SHIFT removes comma
                    ELSE |, { ls_order-property } ASCENDING| ).
    ENDLOOP.

    "schiebt Content 2 platz nach Links
    SHIFT lv_order_by BY 2 PLACES LEFT.

**********************************************************************
*& If the query parameter contains an adresse, the adresse is truncated
**********************************************************************
**********************************************************************
*& checks whether the query parameter contains Adresse
**********************************************************************
    /uniq/cl_help_for_persons=>truncate_sting(
      EXPORTING
        iv_sql_where           = lv_sql_where
        iv_order_by            = lv_order_by
        it_uri_query_parameter = mr_request_details->t_uri_query_parameter
      IMPORTING
        ev_sql_where           = lv_sql_where
        ev_order_by            = lv_order_by
    ).

****************************Select******************************************
    SELECT *
      FROM /uniq/at_pers
      INTO CORRESPONDING FIELDS OF TABLE @lt_entityset
                                    UP TO @lv_maxrows ROWS
     WHERE (lv_sql_where)
     ORDER BY (lv_order_by).

**********************************************************************
    """"" ACHTUNG: INLINECOUNT muss unabhängig von TOP/SKIP Anzahl aller Elemente liefern
    """"" ACHTUNG: aber filter berücksichtigen!
    IF io_tech_request_context->has_inlinecount( ) = abap_true AND lv_sql_where IS INITIAL.
      SELECT COUNT( * )
          FROM /uniq/at_pers
          INTO @DATA(lv_count).
      es_response_context-inlinecount = lv_count.
    ELSEIF io_tech_request_context->has_inlinecount( ) = abap_true AND lv_sql_where IS NOT INITIAL.
      SELECT COUNT( * )
          FROM /uniq/at_pers
          INTO lv_count
        WHERE (lv_sql_where).
      es_response_context-inlinecount = lv_count.
    ELSE.
      CLEAR es_response_context-inlinecount.
    ENDIF.
**********************************************************************
***********************************************************************
    IF NOT lv_skip IS INITIAL.
      DELETE lt_entityset TO lv_skip.
    ENDIF.

**********************************************************************

****************************Insert Data to et_entityset*******************************************

    LOOP AT lt_entityset INTO DATA(ls_entityset_db).

      MOVE-CORRESPONDING ls_entityset_db TO ls_entityset.
      MOVE-CORRESPONDING ls_entityset_db TO ls_entityset-adresse.

      APPEND ls_entityset TO et_entityset.
*      wait UP TO 1 SECONDS.
    ENDLOOP.


*    LOOP AT lt_entityset INTO ls_entityset.
*      CLEAR ls_adresse.
*
*      CONCATENATE ls_entityset-street ls_entityset-city ls_entityset-postcode
*                  ls_entityset-country ls_entityset-homenumber INTO ls_adresse RESPECTING BLANKS.
*      MOVE-CORRESPONDING ls_entityset TO ls_entityset_ad.
*      MOVE-CORRESPONDING ls_adresse TO ls_entityset_ad-adresse.
*      APPEND ls_entityset_ad TO et_entityset.
*
*    ENDLOOP.

*    SELECT pr~personid, pr~fristname, pr~lastname, pr~dateofbirt, pr~email,
*           ad~street, ad~city, ad~postcalcode, ad~country, ad~homenumber, ad~adressid
*     FROM               /uniq/at_pers AS pr
*     LEFT OUTER JOIN /uniq/at_adresse AS ad
*                                      ON pr~adressid = ad~adressid
*       INTO CORRESPONDING FIELDS OF TABLE @lt_entityset
*                                    UP TO @lv_maxrows ROWS
*     WHERE (lv_sql_where)
*     ORDER BY (lv_order_by).
**********************************************************************
*    SELECT *
*      FROM /uniq/at_pers
*      INTO TABLE @DATA(lt_pers)
*           UP TO @lv_maxrows ROWS
*     WHERE (lv_sql_where)
*     ORDER BY (lv_order_by).
*
*    SELECT *
*      FROM /uniq/at_adresse
*      INTO CORRESPONDING FIELDS OF TABLE @lt_pers_ad.
*
**
*    MOVE-CORRESPONDING lt_pers TO et_entityset.
**
*    LOOP AT et_entityset ASSIGNING FIELD-SYMBOL(<fs_pers>).
*      READ TABLE lt_pers_ad WITH  KEY adressid = <fs_pers>-adressid  INTO DATA(ls_adresse).
*      IF <fs_pers>-adressid IS INITIAL.
*        CLEAR ls_adresse.
*      ENDIF.
*      <fs_pers>-adresse = ls_adresse.
*    ENDLOOP.
***********************************************************************
*    IF NOT lv_skip IS INITIAL.
*      DELETE et_entityset TO lv_skip.
*    ENDIF.
***********************************************************************
*    IF io_tech_request_context->has_inlinecount( ) = abap_true.
*      DESCRIBE TABLE et_entityset LINES es_response_context-inlinecount.
*    ELSE.
*      CLEAR es_response_context-inlinecount.
*    ENDIF.

**********************************************************************************************************

  ENDMETHOD.


  METHOD personset_update_entity.

    DATA: ls_keys   LIKE er_entity,
          ls_pers_db TYPE /uniq/at_pers.


    io_data_provider->read_entry_data( IMPORTING es_data = er_entity ).

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_keys ).

**********************************************************************
*& categoryid is primary key and may NOT be changed, so we overwrite by key from URL Segment
**********************************************************************
    er_entity-personid = ls_keys-personid.

**********************************************************************
*& Check if there is a record exist to the category id in the category table
**********************************************************************

    SELECT SINGLE @abap_true
      FROM /uniq/at_pers
      INTO @DATA(lv_pers_exists)
     WHERE personid = @ls_keys-personid.

    IF  lv_pers_exists = abap_true.

      MOVE-CORRESPONDING er_entity TO ls_pers_db.
      MOVE-CORRESPONDING er_entity-adresse TO ls_pers_db.


      UPDATE /uniq/at_pers FROM ls_pers_db.

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

    ELSE.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid           = /iwbep/cx_mgw_busi_exception=>business_error
          http_status_code = '404'
          message          = TEXT-004.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

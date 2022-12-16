class /UNIQ/CL_AR_PERSONS_GW_DPC_EXT definition
  public
  inheriting from /UNIQ/CL_AR_PERSONS_GW_DPC
  create public .

public section.
protected section.

  methods PERSONSET_GET_ENTITYSET
    redefinition .
  methods PERSONSET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS /UNIQ/CL_AR_PERSONS_GW_DPC_EXT IMPLEMENTATION.


  METHOD personset_get_entity.


    DATA: ls_pers    TYPE /uniq/persons_gw_s_pers,
          ls_adresse TYPE /uniq/persons_gw_s_pers-adresse.

    DATA: BEGIN OF ls_entity,
            personid    TYPE /uniq/persons_gw_s_pers-personid,               "/uniq/at_pers-personid,
            firstname   TYPE /uniq/persons_gw_s_pers-firstname,
            lastname    TYPE /uniq/persons_gw_s_pers-lastname,
            dateofbirth TYPE /uniq/persons_gw_s_pers-dateofbirth,
            email       TYPE /uniq/persons_gw_s_pers-email,
            street      TYPE /uniq/persons_gw_s_pers-adresse-street,
            postcode    TYPE /uniq/persons_gw_s_pers-adresse-postcode,
            country     TYPE /uniq/persons_gw_s_pers-adresse-country,
            homenumber  TYPE /uniq/persons_gw_s_pers-adresse-homenumber,
            city        TYPE /uniq/persons_gw_s_pers-adresse-city,

          END OF ls_entity.

**********************************************************************
    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_pers ).

    IF ls_pers IS NOT INITIAL.

      SELECT SINGLE *
       FROM /uniq/at_pers
       INTO CORRESPONDING FIELDS OF  @ls_entity
      WHERE personid = @ls_pers-personid.

      CONCATENATE ls_entity-street ls_entity-city ls_entity-postcode ls_entity-country ls_entity-homenumber INTO ls_adresse RESPECTING BLANKS.

      MOVE-CORRESPONDING ls_entity TO er_entity.
      MOVE-CORRESPONDING ls_adresse TO er_entity-adresse.

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



    DATA: lv_order_by               TYPE string,
          ls_adresse                TYPE /uniq/persons_gw_s_pers-adresse,
          ls_entityset_ad           LIKE LINE OF et_entityset,
          lv_query_contains_adresse TYPE boolean VALUE abap_false,
          lv_count_query            TYPE i VALUE 0.

********************************Lokale Struktur**************************************
    DATA: BEGIN OF ls_entityset,
            personid    TYPE /uniq/persons_gw_s_pers-personid,               "/uniq/at_pers-personid,
            firstname   TYPE /uniq/persons_gw_s_pers-firstname,
            lastname    TYPE /uniq/persons_gw_s_pers-lastname,
            dateofbirth TYPE /uniq/persons_gw_s_pers-dateofbirth,
            email       TYPE /uniq/persons_gw_s_pers-email,
            street      TYPE /uniq/persons_gw_s_pers-adresse-street,
            postcode    TYPE /uniq/persons_gw_s_pers-adresse-postcode,
            country     TYPE /uniq/persons_gw_s_pers-adresse-country,
            homenumber  TYPE /uniq/persons_gw_s_pers-adresse-homenumber,
            city        TYPE /uniq/persons_gw_s_pers-adresse-city,

          END OF ls_entityset.

    DATA lt_entityset LIKE TABLE OF ls_entityset.

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
    LOOP AT mr_request_details->t_uri_query_parameter INTO DATA(ls_param) WHERE value CS 'Adresse'.
      lv_query_contains_adresse = abap_true.
      DATA(lv_query_name) = ls_param-name.
      lv_count_query = lv_count_query + 1.
      "      EXIT.
    ENDLOOP.
    IF lv_query_contains_adresse = abap_true.
      IF lv_query_name = '$filter' AND lv_count_query EQ 1.
        lv_sql_where = |( { substring_after( val = lv_sql_where sub = 'ADRESSE-' ) }|.

      ELSEIF lv_query_name = '$orderby' AND lv_count_query EQ 1 .
        LOOP AT it_order INTO ls_order.
          lv_order_by = COND string( WHEN  ls_order-order  = `desc`
                           THEN |, { substring_after( val = lv_order_by sub = 'Adresse-' ) }|
                        ELSE |, { substring_after( val = lv_order_by sub = 'Adresse-' ) }| ).
        ENDLOOP.

        SHIFT lv_order_by BY 2 PLACES LEFT.

      ELSEIF lv_count_query EQ 2.
        lv_sql_where = |( { substring_after( val = lv_sql_where sub = 'ADRESSE-' ) }|.
        LOOP AT it_order INTO ls_order.
          lv_order_by = COND string( WHEN  ls_order-order  = `desc`
                           THEN |, { substring_after( val = lv_order_by sub = 'Adresse-' ) }|
                        ELSE |, { substring_after( val = lv_order_by sub = 'Adresse-' ) }| ).
        ENDLOOP.

        SHIFT lv_order_by BY 2 PLACES LEFT.
      ENDIF.
    ENDIF.

****************************Select******************************************
    SELECT *
      FROM /uniq/at_pers
      INTO CORRESPONDING FIELDS OF TABLE @lt_entityset
                                    UP TO @lv_maxrows ROWS
     WHERE (lv_sql_where)
     ORDER BY (lv_order_by).

****************************Insert Data to et_entityset*******************************************
    LOOP AT lt_entityset INTO ls_entityset.
*      ls_entityset_ad-firstname   = ls_entityset-firstname.
*      ls_entityset_ad-lastname    = ls_entityset-lastname.
*      ls_entityset_ad-email       = ls_entityset-email.
*      ls_entityset_ad-dateofbirth = ls_entityset-dateofbirth.
      MOVE-CORRESPONDING ls_entityset TO ls_entityset_ad.

*      ls_entityset_ad-adresse-street     = ls_entityset-street.
*      ls_entityset_ad-adresse-city       = ls_entityset-city.
*      ls_entityset_ad-adresse-postcode   = ls_entityset-postcode.
*      ls_entityset_ad-adresse-country    = ls_entityset-country.
*      ls_entityset_ad-adresse-homenumber = ls_entityset-homenumber.
      MOVE-CORRESPONDING ls_entityset TO ls_entityset_ad-adresse.

      APPEND ls_entityset_ad TO et_entityset.
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







***********************************************************************
    IF NOT lv_skip IS INITIAL.
      DELETE et_entityset TO lv_skip.
    ENDIF.
**********************************************************************
    """"" ACHTUNG: INLINECOUNT muss unabhängig von TOP/SKIP Anzahl aller Elemente liefern
    """"" ACHTUNG: aber filter berücksichtigen!
    IF io_tech_request_context->has_inlinecount( ) = abap_true.
      DESCRIBE TABLE et_entityset LINES es_response_context-inlinecount.
    ELSE.
      CLEAR es_response_context-inlinecount.
    ENDIF.
**********************************************************************


**********************************************************************
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
ENDCLASS.

class /UNIQ/CL_TUTOR_2E100_DPC_EXT definition
  public
  inheriting from /UNIQ/CL_TUTOR_2E100_DPC
  create public .

public section.
protected section.

  methods SALESORDERSET_GET_ENTITY
    redefinition .
  methods SALESORDERSET_GET_ENTITYSET
    redefinition .
  methods SALESORDERITEMSE_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS /UNIQ/CL_TUTOR_2E100_DPC_EXT IMPLEMENTATION.


  METHOD salesorderitemse_get_entityset.
**TRY.
*CALL METHOD SUPER->SALESORDERITEMSE_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.

    DATA: lt_nav_path   TYPE /iwbep/t_mgw_tech_navi,
          ls_nav_path   TYPE /iwbep/s_mgw_tech_navi,
          lt_keys       TYPE /iwbep/t_mgw_tech_pairs,
          ls_key        TYPE /iwbep/s_mgw_tech_pair,
          ls_so_key     TYPE /UNIQ/CL_TUTOR_2E100_MPC=>ts_salesorder-salesorder, "ruft hier statische attribut von welchen typen?ts_salesorder ist als typen in Class hinterliegt
          ls_headerdata TYPE /UNIQ/CL_TUTOR_2E100_MPC=>ts_salesorder.


    DATA: lv_osql_where_clause TYPE string.

    lt_nav_path = io_tech_request_context->get_navigation_path( ). "Navigation Path from source entity to (target) entity set

    READ TABLE lt_nav_path INTO ls_nav_path WITH KEY nav_prop = 'SALESORDERITEMSET'. "liegt nav_prop in ls_nav_path variable und müss in gänzen zeichne immer groß geschrieben werden

    IF sy-subrc = 0.

      CALL METHOD io_tech_request_context->get_converted_source_keys
        IMPORTING
          es_key_values = ls_headerdata.

      ls_so_key = ls_headerdata-salesorder.

      SELECT * FROM sepm_i_salesorderitem_e
      INTO CORRESPONDING FIELDS OF TABLE @et_entityset
      WHERE salesorder = @ls_so_key.

    ELSE.

      lv_osql_where_clause = io_tech_request_context->get_osql_where_clause_convert( ). "Converted Open SQL WHERE clause based on $filter Query

      SELECT * FROM sepm_i_salesorderitem_e
     INTO CORRESPONDING FIELDS OF TABLE @et_entityset
     WHERE (lv_osql_where_clause).

    ENDIF.
  ENDMETHOD.


  METHOD salesorderset_get_entity.
**TRY.
*CALL METHOD SUPER->SALESORDERSET_GET_ENTITY
*  EXPORTING
*    IV_ENTITY_NAME          =
*    IV_ENTITY_SET_NAME      =
*    IV_SOURCE_NAME          =
*    IT_KEY_TAB              =
**    io_request_object       =
**    io_tech_request_context =
*    IT_NAVIGATION_PATH      =
**  IMPORTING
**    er_entity               =
**    es_response_context     =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.


    DATA: lt_keys       TYPE /iwbep/t_mgw_tech_pairs,
          ls_key        TYPE /iwbep/s_mgw_tech_pair,
          ls_bp_key     TYPE /UNIQ/CL_TUTOR_2E100_MPC=>ts_salesorder-salesorder,
          ls_headerdata TYPE /UNIQ/CL_TUTOR_2E100_MPC=>ts_salesorder.

    CALL METHOD io_tech_request_context->get_converted_keys
      IMPORTING
        es_key_values = ls_headerdata.


*    ls_bp_key = ls_headerdata-salesorder.

    SELECT SINGLE *
      INTO CORRESPONDING FIELDS OF @er_entity
      FROM sepm_i_salesorder_e
      WHERE salesorder = @ls_headerdata-salesorder.

  ENDMETHOD.


  METHOD salesorderset_get_entityset.
**TRY.
*CALL METHOD SUPER->SALESORDERSET_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
** CATCH /iwbep/cx_mgw_busi_exception .
** CATCH /iwbep/cx_mgw_tech_exception .
**ENDTRY.
*    DATA: lv_osql_where_clause TYPE string.
*    lv_osql_where_clause = io_tech_request_context->get_osql_where_clause( ).
*
*    SELECT *
**     FROM  sepm_isoe " DDIC object (same as sepm_i_salesorder_e )
*      FROM sepm_i_salesorder_e " CDS View (same view as sepm_isoe)
*      INTO CORRESPONDING FIELDS OF TABLE @et_entityset
*     WHERE (lv_osql_where_clause).

    DATA: lv_osql_where_clause TYPE string,
          lv_top               TYPE i,
          lv_skip              TYPE i,
          lv_max_index         TYPE i,
          n                    TYPE i.
*- get number of records requested
    lv_top = io_tech_request_context->get_top( ).
*- get number of lines that should be skipped
    lv_skip = io_tech_request_context->get_skip( ).
*- value for maxrows must only be calculated if the request also contains a $top
    IF lv_top IS NOT INITIAL.
      lv_max_index = lv_top + lv_skip.
    ENDIF.
    lv_osql_where_clause = io_tech_request_context->get_osql_where_clause( ).

    SELECT * FROM sepm_i_salesorder_e
      INTO CORRESPONDING FIELDS OF TABLE @et_entityset
      UP TO @lv_max_index ROWS
      WHERE (lv_osql_where_clause).
*- skipping entries specified by $skip
    IF lv_skip IS NOT INITIAL.
      DELETE et_entityset TO lv_skip.
    ENDIF.
*-  Inlinecount - get the total numbers of entries that fit to the where clause
    IF io_tech_request_context->has_inlinecount( ) = abap_true.
      SELECT COUNT(*)  FROM   sepm_i_salesorder_e WHERE (lv_osql_where_clause) .
      es_response_context-inlinecount = sy-dbcnt.
    ELSE.
      CLEAR es_response_context-inlinecount.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

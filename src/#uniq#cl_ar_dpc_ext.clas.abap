class /UNIQ/CL_AR_DPC_EXT definition
  public
  inheriting from /UNIQ/CL_AR_DPC
  create public .

public section.
protected section.

  methods KOSTENSTELLESET_GET_ENTITYSET
    redefinition .
  methods KOSTENSTELLESET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS /UNIQ/CL_AR_DPC_EXT IMPLEMENTATION.


  METHOD kostenstelleset_get_entity.
**TRY.
*CALL METHOD SUPER->KOSTENSTELLESET_GET_ENTITY
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


*    DATA: lt_keys       TYPE /iwbep/t_mgw_tech_pairs,
*          ls_key        TYPE /iwbep/s_mgw_tech_pair,
*          ls_bp_key     TYPE /uniq/cl_ar_mpc=>ts_kostenstelle-bukrs,
   DATA:   ls_headerdata TYPE /uniq/cl_ar_mpc=>ts_kostenstelle.

    CALL METHOD io_tech_request_context->get_converted_keys
      IMPORTING
        es_key_values = ls_headerdata.

    CALL METHOD /uniq/cl_show_kst=>get_single_kostenstelle
      EXPORTING
        ls_bp_key    = ls_headerdata-kostl
      IMPORTING
        iv_er_entity = er_entity.


  ENDMETHOD.


  METHOD kostenstelleset_get_entityset.
**TRY.
*CALL METHOD SUPER->KOSTENSTELLESET_GET_ENTITYSET
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

** $top und $skip auslesen
*    DATA(lv_top) = io_tech_request_context->get_top( ).
*    DATA(lv_skip) = io_tech_request_context->get_skip( ).
*    DATA(lv_maxrows) = 0.
*
** lv_maxrows setzen
*    IF lv_top IS NOT INITIAL .
*      lv_maxrows = lv_top + lv_skip.
*    ENDIF.
*    DATA(lv_osql_where_clause) = io_tech_request_context->get_osql_where_clause( ).

* Daten holen
    CALL METHOD /uniq/cl_show_kst=>get_all_kostenstellen
      EXPORTING
        iv_sql_where = io_tech_request_context->get_osql_where_clause( ) "iv namenskonvension
        iv_top       = io_tech_request_context->get_top( )
        iv_skip      = io_tech_request_context->get_skip( )
      IMPORTING
        et_kostl     = et_entityset.

***************************INLINECOUNT*******************************************
    IF io_tech_request_context->has_inlinecount( ) = abap_true.
      CALL METHOD /uniq/cl_show_kst=>get_all_kostst_w_inl_count
        EXPORTING
          iv_sql_where   = io_tech_request_context->get_osql_where_clause( )
        IMPORTING
          ev_total_count = es_response_context-inlinecount.
    ELSE.
      CLEAR es_response_context-inlinecount.

    ENDIF.

*
** überflüssige Daten löschen
*    IF NOT lv_skip IS INITIAL.
*      DELETE et_entityset TO lv_skip.
*    ENDIF.




  ENDMETHOD.
ENDCLASS.

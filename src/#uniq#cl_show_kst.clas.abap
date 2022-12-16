class /UNIQ/CL_SHOW_KST definition
  public
  inheriting from /UNIQ/CL_AR_DPC_EXT
  create public .

public section.

  class-methods GET_ALL_KOSTENSTELLEN
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
      !IV_TOP type /UNIQ/TOP
      !IV_SKIP type /UNIQ/SKIP
    exporting
      !ET_KOSTL type /UNIQ/KOSTL_T .
  class-methods GET_ALL_KOSTST_W_INL_COUNT
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
    exporting
      !EV_TOTAL_COUNT type STRING .
  class-methods GET_SINGLE_KOSTENSTELLE
    importing
      !LS_BP_KEY type /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE-KOSTL
    exporting
      !IV_ER_ENTITY type /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE .
  methods GET_KOSTL_INSTANZ_METHODE
    importing
      !IV_BUKRS type BUKRS
      !IV_KOKRS type KOKRS
      !IRT_KOSAR type /UNIQ/KOSAR_RT
      !IV_DATUM type DATS
      !IV_SPRAS type SPRAS
    exporting
      !ET_KOSTL type /UNIQ/KOSTL_T .
  class-methods GET_KOSTL_STATIC_METHODE
    importing
      !IV_BUKRS type BUKRS
      !IV_KOKRS type KOKRS
      !IRT_KOSAR type /UNIQ/KOSAR_RT
      !IV_DATUM type DATS
      !IV_SPRAS type SPRAS
    exporting
      !ET_KOSTL type /UNIQ/KOSTL_T .
protected section.
private section.
ENDCLASS.



CLASS /UNIQ/CL_SHOW_KST IMPLEMENTATION.


  METHOD get_all_kostenstellen.

     DATA(lv_maxrows) = 0.

*    iv_max_index setzen
    IF iv_top IS NOT INITIAL .
      lv_maxrows = iv_top + iv_skip.
    ENDIF.

************************* Select*********************************************

    SELECT ks~bukrs, ks~kosar, ks~verak, ks~waers, ks~kokrs, ks~kostl, ks~gsber, ks~datab, ks~datbi, kt~ktext,
         kt~ltext, kt~spras, tkt~ktext AS kosar_ktext
    FROM      csks  AS ks
    LEFT JOIN cskt  AS kt
                    ON kt~kostl = ks~kostl
                   AND kt~datbi = ks~datbi
                   AND kt~kokrs = ks~kokrs
                   AND kt~spras = @sy-langu      "@iv_spras     "@sy-langu
    LEFT JOIN tkt05 AS tkt
                    ON tkt~kosar = ks~kosar
                   AND tkt~spras = @sy-langu         "@iv_spras "@sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @et_kostl
        UP TO @lv_maxrows ROWS
        WHERE (iv_sql_where)
*              AND ks~datbi >= @sy-datum " nur am @datum gültig
*              AND ks~datab <= @sy-datum


*    WHERE ks~bukrs =  'CH01'
*     AND ks~datbi >= @iv_datum " nur am @datum gültig
*     AND ks~datab <= @iv_datum " nur an @datum gültig
*     AND ks~kokrs =  @iv_kokrs
*     AND ks~kosar IN @irt_kosar
    ORDER BY ks~kosar.

* überflüssige Daten löschen
    IF NOT iv_skip IS INITIAL.
      DELETE et_kostl TO iv_skip.
    ENDIF.

*******************Wenn man es direkt in KOSTENSTELLESET_GET_ENTITYSET Methode implimintiert würde ***************************************************
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

****************************Hier kommt select******************************************


******************* Nach Select löschen Datensätze nach Skip zahl vom Tabelle***************************************************
** überflüssige Daten löschen
*    IF NOT lv_skip IS INITIAL.
*      DELETE et_entityset TO lv_skip.
*    ENDIF.
  ENDMETHOD.


  METHOD get_all_kostst_w_inl_count.

    "    DATA: ls_results TYPE /uniq/kostl_s.


    SELECT *                         "COUNT(*) AS cnt
    FROM      csks  AS ks
    LEFT JOIN cskt  AS kt
                    ON kt~kostl = ks~kostl
                   AND kt~datbi = ks~datbi
                   AND kt~kokrs = ks~kokrs
                   AND kt~spras = @sy-langu      "@iv_spras     "@sy-langu
    LEFT JOIN tkt05 AS tkt
                    ON tkt~kosar = ks~kosar
                   AND tkt~spras = @sy-langu         "@iv_spras "@sy-langu
    INTO @DATA(ls_results)
*      INTO TABLE @et_kostl
          WHERE (iv_sql_where).
*                AND ks~datbi >= @sy-datum " nur am @datum gültig
*                AND ks~datab <= @sy-datum.
*        GROUP BY ks~bukrs.
    ENDSELECT.

    ev_total_count = sy-dbcnt.                            "ls_results-cnt.

    "sy-dbcnt
  ENDMETHOD.


  method GET_KOSTL_INSTANZ_METHODE.

SELECT ks~bukrs, ks~kosar, ks~verak, ks~waers, ks~kokrs, ks~kostl, ks~gsber, ks~datab, ks~datbi, kt~ktext,
         kt~ltext, kt~spras, tkt~ktext AS kosar_ktext
    FROM      csks  AS ks
    LEFT JOIN cskt  AS kt
                    ON kt~kostl = ks~kostl
                   AND kt~datbi = ks~datbi
                   AND kt~kokrs = ks~kokrs
                   AND kt~spras = @iv_spras     "@sy-langu
    LEFT JOIN tkt05 AS tkt
                    ON tkt~kosar = ks~kosar
                   AND tkt~spras = @iv_spras "@sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @et_kostl
   WHERE ks~bukrs =  @iv_bukrs
     AND ks~datbi >= @iv_datum " nur am @datum gültig
     AND ks~datab <= @iv_datum " nur an @datum gültig
     AND ks~kokrs =  @iv_kokrs
     AND ks~kosar IN @irt_kosar
   ORDER BY ks~kosar.

  endmethod.


  method GET_KOSTL_STATIC_METHODE.

SELECT ks~bukrs, ks~kosar, ks~verak, ks~waers, ks~kokrs, ks~kostl, ks~gsber, ks~datab, ks~datbi, kt~ktext,
         kt~ltext, kt~spras, tkt~ktext AS kosar_ktext
    FROM      csks  AS ks
    LEFT JOIN cskt  AS kt
                    ON kt~kostl = ks~kostl
                   AND kt~datbi = ks~datbi
                   AND kt~kokrs = ks~kokrs
                   AND kt~spras = @iv_spras     "@sy-langu
    LEFT JOIN tkt05 AS tkt
                    ON tkt~kosar = ks~kosar
                   AND tkt~spras = @iv_spras "@sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @et_kostl
   WHERE ks~bukrs =  @iv_bukrs
     AND ks~datbi >= @iv_datum " nur am @datum gültig
     AND ks~datab <= @iv_datum " nur an @datum gültig
     AND ks~kokrs =  @iv_kokrs
     AND ks~kosar IN @irt_kosar
   ORDER BY ks~kosar.

  endmethod.


  METHOD get_single_kostenstelle.

*    /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE


*    DATA: lt_keys       TYPE /iwbep/t_mgw_tech_pairs,
*          ls_key        TYPE /iwbep/s_mgw_tech_pair,
*          ls_bp_key     TYPE /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE-bukrs,
*          ls_headerdata TYPE /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE.

*    CALL METHOD io_tech_request_context->get_converted_keys
*      IMPORTING
*        es_key_values = ls_headerdata.

*    ls_bp_key = ls_headerdata-salesorder.
    SELECT SINGLE ks~bukrs, ks~kosar, ks~verak, ks~waers, ks~kokrs, ks~kostl, ks~gsber, ks~datab, ks~datbi, kt~ktext,
          kt~ltext, kt~spras, tkt~ktext AS kosar_ktext
     FROM      csks  AS ks
     LEFT JOIN cskt  AS kt
                     ON kt~kostl = ks~kostl
                    AND kt~datbi = ks~datbi
                    AND kt~kokrs = ks~kokrs
                    AND kt~spras = @sy-langu      "@iv_spras     "@sy-langu
     LEFT JOIN tkt05 AS tkt
                     ON tkt~kosar = ks~kosar
                    AND tkt~spras = @sy-langu         "@iv_spras "@sy-langu
     INTO CORRESPONDING FIELDS OF @iv_er_entity  "TYPE /UNIQ/CL_AR_MPC=>TS_KOSTENSTELLE
         WHERE ks~kostl = @ls_bp_key.

    "ORDER BY ks~kosar.



*    SELECT SINGLE *
*      INTO CORRESPONDING FIELDS OF @iv_er_entity
*      FROM sepm_i_salesorder_e
*      WHERE bukrs = @ls_bp_key.
  ENDMETHOD.
ENDCLASS.

class /UNIQ/CL_HELP_FOR_PERSONS definition
  public
  create public .

public section.

  class-methods TRUNCATE_STING
    importing
      !IV_SQL_WHERE type STRING
      !IV_ORDER_BY type STRING
      !IT_URI_QUERY_PARAMETER type /IWBEP/IF_MGW_CORE_SRV_RUNTIME=>PARAMETER_VALUES_T
    exporting
      !EV_SQL_WHERE type STRING
      !EV_ORDER_BY type STRING .
protected section.
private section.
ENDCLASS.



CLASS /UNIQ/CL_HELP_FOR_PERSONS IMPLEMENTATION.


  METHOD truncate_sting.

    LOOP AT it_uri_query_parameter INTO DATA(ls_param) WHERE value CS 'Adresse'.

      DATA(lv_query_name) = ls_param-name.

      IF lv_query_name = '$filter'.
        ev_sql_where = |( { substring_after( val = iv_sql_where sub = 'ADRESSE-' ) }|.
      ELSEIF lv_query_name = '$orderby'.
        ev_order_by = |{ substring_after( val = iv_order_by sub = 'Adresse-' ) }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& Report /UNIQ/TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /uniq/test.

DATA: lo_show_kst1 TYPE REF TO /uniq/cl_show_kst,
      lo_show_kst2 TYPE REF TO /uniq/cl_show_kst,
      lo_show_kst3 LIKE lo_show_kst1.

CREATE OBJECT lo_show_kst1.
CREATE OBJECT lo_show_kst2.
lo_show_kst3 = lo_show_kst1.

START-OF-SELECTION.



  IF lo_show_kst1 = lo_show_kst2.
    WRITE : / 'jes 1 == 2'.
  ELSE.
    WRITE : / 'no  1 != 2'.
  ENDIF.

  IF lo_show_kst1 = lo_show_kst3.
    WRITE : / 'jes 1 == 3'.
  ELSE.
    WRITE : / 'no  1 != 3'.
  ENDIF.


  data:
    lv_unique_id    like sys_uid.

* Start of selection.
  start-of-selection.

* Init.
  clear:
    lv_unique_id.

* Get id.
  call function 'SYSTEM_GET_UNIQUE_ID'
       importing
            unique_id = lv_unique_id
       exceptions
            others    = 1.

* Print id.
  write lv_unique_id.


*  io_tech_request_context.
*   method SALESORDERSET_GET_ENTITYSET.
*
*data: lv_osql_where_clause type string.
*lv_osql_where_clause = io_tech_request_context->get_osql_where_clause( ).
*select * from sepm_i_salesorder_e
*      into corresponding fields of table @et_entityset
*      where (lv_osql_where_clause).
*
*  endmethod.

class /UNIQ/CL_SHOW_SUP_PROJ definition
  public
  create public .

public section.

  class-methods ADD_PRD_TOTALAMOUNT_FOR_SUP
    importing
      !IV_SUP_ID type /UNIQ/SUPPLIER_GW_S_SUP-SUPPLIERID
    returning
      value(RV_TOTAL_AMOUNT_SUP) type /UNIQ/SPL_PRD_TOTALAMOUNT .
  class-methods CALCULATE_PODUCT_TOTALAMOUNT
    importing
      !IV_PRICE type /UNIQ/SUPPLIER_GW_S_PRD-PRICE
      !IV_QUANTITY type /UNIQ/SUPPLIER_GW_S_PRD-QUANTITY
    returning
      value(RV_TOTAL_AMOUNT) type DECFLOAT16 .
  class-methods CHECK_VALIDITY_PRODUCT
    importing
      !IS_ENTITY type /UNIQ/SUPPLIER_GW_S_PRD
    exporting
      !EV_ERR_MESSAGE type BAPI_MSG
    returning
      value(RV_IS_VALID) type BOOLEAN .
  class-methods GET_ALL_NUM_OF_PRD_FOR_SUP
    importing
      !IV_SUP_ID type /UNIQ/SUPPLIER_GW_S_SUP-SUPPLIERID
    returning
      value(RV_NUM_PRODUCTS) type INT4 .
  class-methods TRUNCATE_TABLE_AND_INSERT_DATA
    importing
      !IV_TABEL_NAME type STRING .
  class-methods INSERT_SUP_CAT_PRD_DATA_DB .
  class-methods GET_CATEGORY
    importing
      !IV_FOR_CAT_AND_PRD_ID type /UNIQ/SUPPLIER_GW_S_PRD-PRODUCTID
      !IT_NAV_PATH type /IWBEP/T_MGW_TECH_NAVI
    exporting
      !ER_ENTITY type /UNIQ/SUPPLIER_GW_S_CAT .
  class-methods GET_INLINECOUNT
    exporting
      !EV_TOTAL_COUNT type STRING .
  class-methods GET_ALL_PRODUCTS
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
      !IV_TOP type /UNIQ/TOP
      !IV_SKIP type /UNIQ/SKIP
      !IV_INLINECOUNT_SET type ABAP_BOOL
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IT_URI_QUERY_PARAMETER type /IWBEP/IF_MGW_CORE_SRV_RUNTIME=>PARAMETER_VALUES_T
    exporting
      !ET_PRODUCT type /UNIQ/SUPPLIER_GW_T_PRD
      !EV_TOTAL_COUNT type STRING .
  class-methods GET_ALL_PRODUCTS_JD
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IT_URI_QUERY_PARAMETER type /IWBEP/IF_MGW_CORE_SRV_RUNTIME=>PARAMETER_VALUES_T
      !IO_TECH_REQ type ref to /IWBEP/IF_MGW_REQ_ENTITYSET
    exporting
      !ET_PRODUCT type /UNIQ/SUPPLIER_GW_T_PRD
      !EV_TOTAL_COUNT type STRING .
  class-methods GET_ALL_CATEGORIES
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
      !IV_TOP type /UNIQ/TOP
      !IV_SKIP type /UNIQ/SKIP
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IV_INLINECOUNT_SET type ABAP_BOOL
    exporting
      !ET_CATEGORY type /UNIQ/SUPPLIER_GW_T_CAT
      !EV_TOTAL_COUNT type STRING .
  class-methods GET_ALL_SUPPLIERS
    importing
      !IV_SQL_WHERE type /UNIQ/SQL_WHERE
      !IV_TOP type /UNIQ/TOP
      !IV_SKIP type /UNIQ/SKIP
      !IT_ORDER type /IWBEP/T_MGW_SORTING_ORDER
      !IV_INLINECOUNT_SET type ABAP_BOOL
    exporting
      !ET_SUPPLIER type /UNIQ/SUPPLIER_GW_T_SUP
      !EV_TOTAL_COUNT type STRING .
protected section.
private section.
ENDCLASS.



CLASS /UNIQ/CL_SHOW_SUP_PROJ IMPLEMENTATION.


  METHOD add_prd_totalamount_for_sup.

    DATA: lt_prd             TYPE /uniq/supplier_gw_t_prd,
          lv_totalamount_prd TYPE /uniq/spl_prd_totalamount.
*          lv_total_amount_sup LIKE rv_total_amount.

    SELECT *
      FROM /uniq/at_prd
      INTO CORRESPONDING FIELDS OF TABLE lt_prd
      WHERE supplierid = iv_sup_id.

    LOOP AT lt_prd ASSIGNING FIELD-SYMBOL(<fs_prd>).
      lv_totalamount_prd = /uniq/cl_show_sup_proj=>calculate_poduct_totalamount( iv_price = <fs_prd>-price iv_quantity = <fs_prd>-quantity ).
      rv_total_amount_sup = rv_total_amount_sup + lv_totalamount_prd.
    ENDLOOP.

  ENDMETHOD.


  METHOD calculate_poduct_totalamount.

*    WAIT UP TO 1 SECONDS.

    rv_total_amount = iv_price * iv_quantity.

  ENDMETHOD.


  METHOD check_validity_product.

    DATA: ls_cat TYPE /uniq/supplier_gw_s_cat,
          ls_sup TYPE /uniq/supplier_gw_s_sup.

    rv_is_valid = abap_true.

    SELECT SINGLE *
      FROM /uniq/at_cat
      INTO CORRESPONDING FIELDS OF @ls_cat
     WHERE categoryid = @is_entity-categoryid.

    SELECT SINGLE *
      FROM /uniq/at_sup
      INTO CORRESPONDING FIELDS OF @ls_sup
     WHERE supplierid = @is_entity-supplierid.

**********************************************************************
*& Check if a record with the requirement ID exists in the database Table Category or Supplier
**********************************************************************
    IF ls_cat IS INITIAL AND ls_sup IS NOT INITIAL.
      rv_is_valid = abap_false.
      ev_err_message = TEXT-001.
    ELSEIF ls_sup IS  INITIAL AND ls_cat IS NOT INITIAL.
      rv_is_valid = abap_false.
      ev_err_message = TEXT-002.
    ELSEIF ls_sup IS  INITIAL AND ls_cat IS INITIAL.
      rv_is_valid = abap_false.
      ev_err_message = TEXT-003.
    ENDIF.

  ENDMETHOD.


  METHOD get_all_categories.

    DATA : lv_order_by  TYPE string,
           lt_cat_check LIKE et_category.

    DATA(lv_maxrows) = 0.

***************************´SET iv_max_index********************************************    iv_max_index setzen
    IF iv_top IS NOT INITIAL .
      lv_maxrows = iv_top + iv_skip.
    ENDIF.

********************Internal Table content is converted to string **************************************************
    LOOP AT it_order INTO DATA(ls_order).
      lv_order_by = lv_order_by &&
      COND string( WHEN  ls_order-order  = `desc`
                      THEN |, { ls_order-property } DESCENDING| "it is important that you make an escape after the comma->SHIFT removes comma
                   ELSE |, { ls_order-property } ASCENDING| ).
    ENDLOOP.

    SHIFT lv_order_by BY 2 PLACES LEFT.

************************* Select*********************************************
    SELECT *
      FROM /uniq/at_cat
      INTO CORRESPONDING FIELDS OF TABLE @et_category
*           UP TO @lv_maxrows ROWS
     WHERE (iv_sql_where)
     ORDER BY (lv_order_by).

************************* AUTHORITY CHECK*********************************************
    LOOP AT et_category ASSIGNING FIELD-SYMBOL(<fs_cat>).

      AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
               ID 'ACTVT' FIELD '03'
               ID 'CATEGORYID' FIELD <fs_cat>-categoryid.
      IF sy-subrc <> 0.
        CLEAR <fs_cat>-categoryid.
      ENDIF.

    ENDLOOP.

    DELETE et_category WHERE categoryid IS INITIAL.

********************************Inlinecount**************************************
    IF iv_inlinecount_set = abap_true.
      ev_total_count = lines( et_category ).
    ELSE.
      CLEAR ev_total_count.
    ENDIF.

***********************TOP and SKIP***********************************************

      IF iv_top IS NOT INITIAL AND iv_skip IS INITIAL.
        DELETE et_category FROM iv_top + 1.
        RETURN.
      ENDIF.
      IF iv_skip IS NOT INITIAL.
        IF lv_maxrows IS NOT INITIAL.
          DELETE et_category FROM lv_maxrows + 1.
        ENDIF.
        DELETE et_category TO iv_skip.
      ENDIF.




  ENDMETHOD.


  METHOD get_all_num_of_prd_for_sup.
    SELECT COUNT( * )
      FROM /uniq/at_prd INTO @rv_num_products
     WHERE supplierid = @iv_sup_id.
  ENDMETHOD.


  METHOD get_all_products.
*
    DATA : lv_order_by        TYPE string,
           lt_prd             LIKE et_product,
           lt_prd_inlinecount LIKE et_product,
           index              TYPE i VALUE 0,
           lv_totalmount      TYPE boolean VALUE abap_false.

    DATA: lt_r_categories TYPE RANGE OF /uniq/spl_cat_id.




*************************AUTHORITY-CHECK of CATEGORYID *********************************************
    SELECT categoryid FROM /uniq/at_cat INTO TABLE @DATA(lt_cat).

    LOOP AT lt_cat ASSIGNING FIELD-SYMBOL(<fs_cat_check>).

      AUTHORITY-CHECK OBJECT '/UNIQ/ABSC'
               ID 'ACTVT' FIELD '03'
               ID 'CATEGORYID' FIELD <fs_cat_check>-categoryid.
      IF sy-subrc = 0.
        lt_r_categories = VALUE #( BASE lt_r_categories ( sign = 'I' option = 'EQ' low = <fs_cat_check>-categoryid ) ).
      ENDIF.

    ENDLOOP.
    CLEAR lt_cat.
*
    IF lt_r_categories IS NOT INITIAL.
***************************´SET iv_max_index*******************************************
      IF iv_top IS NOT INITIAL.
        DATA(lv_maxrows) = iv_top + iv_skip.
      ENDIF.

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
*& checks whether the query parameter contains the total amount
*& Nicht ganz korrekt: nur Parameter $filter und $orderby
**********************************************************************
      LOOP AT it_uri_query_parameter INTO DATA(ls_param) WHERE value CS 'Total'.
        lv_totalmount = abap_true.
        EXIT.

      ENDLOOP.

**********************************************************************
*& if the query parameter includes Totalamount fieldname, which is calculated at runtime
**********************************************************************
      IF lv_totalmount = abap_true.

        SELECT *
          FROM /uniq/at_prd
          INTO CORRESPONDING FIELDS OF TABLE @lt_prd
          WHERE categoryid IN @lt_r_categories.

**********************Calculate Totalamount************************************************
        LOOP AT lt_prd ASSIGNING FIELD-SYMBOL(<fs_prd>).
          <fs_prd>-totalamount = calculate_poduct_totalamount( iv_price = <fs_prd>-price iv_quantity = <fs_prd>-quantity ).
        ENDLOOP.

*******************************Filter***************************************
        IF iv_sql_where IS NOT INITIAL.
          LOOP AT lt_prd INTO DATA(ls_prd) WHERE (iv_sql_where).
            APPEND  ls_prd TO et_product.
          ENDLOOP.
        ENDIF.

*      CLEAR: ls_prd, lt_prd.
**********************************************************************
        IF iv_inlinecount_set = abap_true.
          ev_total_count = lines( et_product ).
        ELSE.
          CLEAR ev_total_count.

        ENDIF.
****************************Order by******************************************
        IF it_order IS NOT INITIAL AND line_exists( it_order[ property = 'Totalamount' ] ).
          DATA(ls_orderby) = it_order[ property = 'Totalamount' ].

          CASE ls_orderby-order.
            WHEN 'asc'.
              SORT: et_product BY totalamount ASCENDING.
            WHEN 'desc'.
              SORT: et_product BY totalamount DESCENDING.
          ENDCASE.
        ENDIF.

********************TOP or SKIP***************************************************
        IF iv_top IS NOT INITIAL AND iv_skip IS INITIAL.
          DELETE et_product FROM iv_top + 1.
          RETURN.
        ENDIF.
        IF iv_skip IS NOT INITIAL.
          IF lv_maxrows IS NOT INITIAL.
            DELETE et_product FROM lv_maxrows + 1.
          ENDIF.
          DELETE et_product TO iv_skip.
        ENDIF.
**********************************************************************

      ELSE.

**********************************************************************
*& select all products from the database with query parameters
**********************************************************************
        SELECT *
          FROM /uniq/at_prd
          INTO CORRESPONDING FIELDS OF TABLE @et_product
*             UP TO @lv_maxrows ROWS
         WHERE (iv_sql_where) AND categoryid IN @lt_r_categories
         ORDER BY (lv_order_by).

********************************Inlinecount**************************************

        IF iv_inlinecount_set = abap_true.
          ev_total_count = lines( et_product ).
        ELSE.
          CLEAR ev_total_count.

        ENDIF.
**************************TOP and SKIP********************************************
        IF iv_top IS NOT INITIAL AND iv_skip IS INITIAL.
          DELETE et_product FROM iv_top + 1.
          RETURN.
        ENDIF.
        IF iv_skip IS NOT INITIAL.
          IF lv_maxrows IS NOT INITIAL.
            DELETE et_product FROM lv_maxrows + 1.
          ENDIF.
          DELETE et_product TO iv_skip.
        ENDIF.
*********************************************************************
*& Calculte Totalamount for Product
*********************************************************************

        LOOP AT et_product ASSIGNING FIELD-SYMBOL(<fs_product>).
          <fs_product>-totalamount = calculate_poduct_totalamount( iv_price = <fs_product>-price iv_quantity = <fs_product>-quantity ).
        ENDLOOP.
      ENDIF.
    ENDIF.




*          WHILE lv_maxrows > index.
*            READ TABLE et_product INDEX sy-index INTO ls_prd.
*            APPEND ls_prd TO lt_prd.
*            index = index + 1.
*          ENDWHILE.
*          CLEAR et_product.
**          MOVE-CORRESPONDING lt_prd TO et_product.
*
*    IF iv_inlinecount_set = abap_true AND iv_sql_where IS NOT INITIAL AND iv_sql_where CS 'Total'.
*      ev_total_count = lines( lt_prd_inlinecount ).
*    ELSEIF iv_inlinecount_set = abap_true AND iv_sql_where IS INITIAL.
*      SELECT COUNT( * )
*        FROM /uniq/at_prd
*       INTO @DATA(lv_count).
*      ev_total_count = lv_count.
*    ELSEIF iv_inlinecount_set = abap_true AND iv_sql_where IS NOT INITIAL.
*      SELECT COUNT( * )
*        FROM /uniq/at_prd
*       INTO lv_count
*      WHERE (iv_sql_where).
*    ELSE.
*      CLEAR ev_total_count
************************delete redundant data***********************************************
*      IF iv_skip IS NOT INITIAL.
*        DELETE et_product TO iv_skip.
*      ENDIF.
  ENDMETHOD.


  METHOD get_all_products_jd.
    ""TODO comments // check import export again
    ""TODO reduce code duplication
    ""TODO -> inlinecount

    DATA : lv_order_by TYPE string,
           ls_order    TYPE /iwbep/s_mgw_sorting_order.

    DATA(lv_skip) = io_tech_req->get_skip( ).
    DATA(lv_top) = io_tech_req->get_top( ).
    DATA(lv_max) = lv_top + lv_skip.
    DATA(lt_order) = it_order.

    IF line_exists( it_order[ property = 'Totalamount' ] ).
      DATA(lv_totalamount_order) = it_order[ property = 'Totalamount' ]-order.

      DELETE lt_order WHERE property = 'Totalamount'.

      LOOP AT lt_order INTO ls_order.
        lv_order_by = lv_order_by && COND string( WHEN  ls_order-order  = `desc`
                                                    THEN |, { ls_order-property } DESCENDING| "it is important that you make an escape after the comma->SHIFT removes comma
                                                  ELSE |, { ls_order-property } ASCENDING| ).
      ENDLOOP.

      SHIFT lv_order_by BY 2 PLACES LEFT.

      "Selektiere alles aus der DB
      SELECT *
       FROM /uniq/at_prd
       INTO CORRESPONDING FIELDS OF TABLE @et_product
      WHERE (iv_sql_where)
       ORDER BY (lv_order_by).

      LOOP AT et_product ASSIGNING FIELD-SYMBOL(<fs_product>).
        <fs_product>-totalamount = calculate_poduct_totalamount( iv_price    = <fs_product>-price iv_quantity = <fs_product>-quantity ).
      ENDLOOP.

      DELETE et_product TO lv_skip.
      DELETE et_product FROM lv_top + 1.

    ELSE.
      LOOP AT lt_order INTO ls_order.
        lv_order_by = lv_order_by && COND string( WHEN  ls_order-order  = `desc`
                                                    THEN |, { ls_order-property } DESCENDING| "it is important that you make an escape after the comma->SHIFT removes comma
                                                  ELSE |, { ls_order-property } ASCENDING| ).
      ENDLOOP.

      SHIFT lv_order_by BY 2 PLACES LEFT.

      SELECT *
       FROM /uniq/at_prd
         UP TO @lv_max ROWS
       INTO CORRESPONDING FIELDS OF TABLE @et_product
      WHERE (iv_sql_where)
      ORDER BY (lv_order_by).

      IF io_tech_req->has_inlinecount( ).
        ev_total_count = lines( et_product ).
      ENDIF.

      DELETE et_product TO lv_skip.
    ENDIF.

  ENDMETHOD.


  METHOD get_all_suppliers.

    DATA : lv_order_by TYPE string.

****************************´SET iv_max_index********************************************    iv_max_index setzen
    DATA(lv_maxrows)    = iv_top + iv_skip.

*********Internal Table content is converted to string **************************************************
    LOOP AT it_order INTO DATA(ls_order).
      lv_order_by = lv_order_by &&
      COND string( WHEN  ls_order-order  = `desc`
                      THEN |, { ls_order-property } DESCENDING| "it is important that you make an escape after the comma->SHIFT removes comma
                   ELSE |, { ls_order-property } ASCENDING| ).
    ENDLOOP.

    SHIFT lv_order_by BY 2 PLACES LEFT.

******************************Select****************************************
    SELECT *
      FROM /uniq/at_sup
      INTO CORRESPONDING FIELDS OF TABLE @et_supplier
           UP TO @lv_maxrows ROWS
     WHERE (iv_sql_where)
     ORDER BY (lv_order_by).

***********************delete redundant data***********************************************
    IF NOT iv_skip IS INITIAL.
      DELETE et_supplier TO iv_skip.
    ENDIF.

**********************************************************************
    LOOP AT et_supplier ASSIGNING FIELD-SYMBOL(<fs_supplier>).
**********************************************************************
*& returns the number of products this supplier has
**********************************************************************
      <fs_supplier>-numberofproducts = /uniq/cl_show_sup_proj=>get_all_num_of_prd_for_sup( iv_sup_id = <fs_supplier>-supplierid ).
**********************************************************************
*& returns the sum of all TotalAmounts of the products associated with this supplier.
**********************************************************************
      <fs_supplier>-totalamount = /uniq/cl_show_sup_proj=>add_prd_totalamount_for_sup( iv_sup_id = <fs_supplier>-supplierid ).
    ENDLOOP.

*********************Inlinecout**************************************************
    IF iv_inlinecount_set = abap_true AND iv_sql_where IS INITIAL.
      SELECT COUNT( * )
        FROM /uniq/at_sup
        INTO @DATA(lv_count).
      ev_total_count = lv_count.
    ELSEIF iv_inlinecount_set = abap_true AND iv_sql_where IS NOT INITIAL..
      SELECT COUNT( * )
        FROM /uniq/at_sup
        INTO lv_count
       WHERE (iv_sql_where).
      ev_total_count = lv_count.
    ELSE.
      CLEAR ev_total_count.

    ENDIF.
*
*    IF iv_inlinecount_set = abap_true.
*      DESCRIBE TABLE et_supplier LINES ev_total_count.
*    ELSE.
*      CLEAR ev_total_count.
*    ENDIF.

  ENDMETHOD.


  METHOD get_category.

    IF it_nav_path IS NOT INITIAL.
      SELECT SINGLE *
         FROM /uniq/at_prd
         INTO @DATA(ls_prd)              "@er_entity
        WHERE productid = @iv_for_cat_and_prd_id.

      SELECT SINGLE *
         FROM /uniq/at_cat
         INTO CORRESPONDING FIELDS OF @er_entity
        WHERE categoryid = @ls_prd-categoryid.
    ELSE.
      SELECT SINGLE *
        FROM /uniq/at_cat
        INTO CORRESPONDING FIELDS OF @er_entity
       WHERE categoryid = @iv_for_cat_and_prd_id.
    ENDIF.
  ENDMETHOD.


  METHOD get_inlinecount.

    DATA : lv_count TYPE i.

    SELECT COUNT( * )
      FROM /uniq/at_prd
      INTO lv_count.

    ev_total_count = lv_count.

  ENDMETHOD.


  METHOD insert_sup_cat_prd_data_db.

    DATA lt_pers TYPE TABLE OF /uniq/at_pers.

    DELETE FROM /uniq/at_pers.

    lt_pers = VALUE #(
  ( personid = '11'
    firstname = 'Abbos'
    lastname = 'Jalilov'
    dateofbirth = '19910411'
    email = 'adad@il.com'
    street = 'Schöffenstrasse'
    city = 'Frankfurt'
    postcode = '33535'
    country = 'D'
    homenumber = '22a' )

   ( personid = '12'
    firstname = 'Salima'
    lastname = 'Hamidov'
    dateofbirth = '19930213'
    email = 'zuhtd@il.com'
    street = 'Schöffenstrasse'
    city = 'Hamburg'
    postcode = '33535'
    country = 'N'
    homenumber = '22a')

   ( personid = '13'
    firstname = 'kamola'
    lastname = 'qosimov'
    dateofbirth = '20050615'
    email = 'rdf@gmil.com'
    street = 'Leipziger 34'
    city = 'Hamburg'
    postcode = '33654'
    country = 'D'
    homenumber = '267' )

   ( personid = '14'
    firstname = 'Sobir'
    lastname = 'dostov'
    dateofbirth = '20070711'
    email = 'adfber@yil.com'
    street = ''
    city = 'Afganistan'
    postcode = '45655'
    country = 'A'
    homenumber = 't5' )

   ( personid = '15'
    firstname = 'Müller'
    lastname = 'Löffelholz'
    dateofbirth = '19891203'
    email = 'ergreg@il.com'
    street = 'Navruz'
    city = 'Tashkent'
    postcode = '340034'
    country = 'U'
    homenumber = '245tz'  ) ).

    INSERT /uniq/at_pers FROM TABLE lt_pers.
*
*    DATA: ls_prd TYPE /uniq/at_prd,
*          ls_cat TYPE /uniq/at_cat,
*          ls_sup TYPE /uniq/at_sup.
*    CASE iv_prd_id.
*      WHEN '1'.
*        ls_prd-mandt = '800'.
*        ls_prd-productid = '1'.
*        ls_prd-productname = 'Bier'.
*        ls_prd-supplierid = '002'.
*        ls_prd-categoryid = '0001'.
*        ls_prd-quantity = '50'.
*        ls_prd-price = '150'.
*        ls_prd-currency = 'EUR'.
*
*        INSERT /uniq/at_prd FROM ls_prd.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '2'.
*        ls_prd-mandt = '800'.
*        ls_prd-productid = '2'.
*        ls_prd-productname = 'Tomate'.
*        ls_prd-supplierid = '003'.
*        ls_prd-categoryid = '0002'.
*        ls_prd-quantity = '100'.
*        ls_prd-price = '200'.
*        ls_prd-currency = 'EUR'.
*
*        INSERT /uniq/at_prd FROM ls_prd.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '3'.
*        ls_prd-mandt = '800'.
*        ls_prd-productid = '3'.
*        ls_prd-productname = 'Sap'.
*        ls_prd-supplierid = '001'.
*        ls_prd-categoryid = '0003'.
*        ls_prd-quantity = '1'.
*        ls_prd-price = '500'.
*        ls_prd-currency = 'EUR'.
*
*        INSERT /uniq/at_prd FROM ls_prd.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '4'.
*        ls_prd-mandt = '800'.
*        ls_prd-productid = '4'.
*        ls_prd-productname = 'Brot'.
*        ls_prd-supplierid = '002'.
*        ls_prd-categoryid = '0002'.
*        ls_prd-quantity = '70'.
*        ls_prd-price = '700'.
*        ls_prd-currency = 'EUR'.
*
*        INSERT /uniq/at_prd FROM ls_prd.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '5'.
*        ls_prd-mandt = '800'.
*        ls_prd-productid = '5'.
*        ls_prd-productname = 'Cocacola'.
*        ls_prd-supplierid = '002'.
*        ls_prd-categoryid = '0001'.
*        ls_prd-quantity = '60'.
*        ls_prd-price = '600'.
*        ls_prd-currency = 'EUR'.
*
*        INSERT /uniq/at_prd FROM ls_prd.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '0001'.
*        ls_cat-mandt = '800'.
*        ls_cat-categoryid = '0001'.
*        ls_cat-categoryname = 'Getränke'.
*        ls_cat-description = 'Zu der Category Getränke gehören sowohl Getränke wie Fanta, Wasser, aber auch Alkhogol Getränke wie Bier, Wodka'.
*
*        INSERT /uniq/at_cat FROM ls_cat.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '0002'.
*        ls_cat-mandt = '800'.
*        ls_cat-categoryid = '0002'.
*        ls_cat-categoryname = 'Lebesmittel'.
*        ls_cat-description = 'Zu der  Category Lebensmittel gehören nur Lebensmittel, die für Menscheid bestimmt sind'.
*
*        INSERT /uniq/at_cat FROM ls_cat.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '0003'.
*        ls_cat-mandt = '800'.
*        ls_cat-categoryid = '0003'.
*        ls_cat-categoryname = ' IT_Deliver'.
*        ls_cat-description = 'Zu der Category IT_Deliver gehören Unternehmen. die Software zum Ausleihen zur Verfügung stellen'.
*
*        INSERT /uniq/at_cat FROM ls_cat.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '001'.
*        ls_sup-mandt = '800'.
*        ls_sup-supplierid = '001'.
*        ls_sup-phone = '+4917676349723'.
*        ls_sup-contactname = 'Mein Lieblings Lieferant'.
*        ls_sup-contacttitle = 'Irgendwas'.
*        ls_sup-street = 'Winschester 22'.
*        ls_sup-postcalcode = '69933'.
*        ls_sup-city = 'Giessen'.
*        ls_sup-companyname = 'Uniq'.
*        ls_sup-fax = '491242142'.
*
*        INSERT /uniq/at_sup FROM ls_sup.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '002'.
*        ls_sup-mandt = '800'.
*        ls_sup-supplierid = '002'.
*        ls_sup-phone = '+4917676349725'.
*        ls_sup-contactname = 'Mein verspätete Lieferant'.
*        ls_sup-contacttitle = 'Kontaktiere mich'.
*        ls_sup-street = 'Europealle 27'.
*        ls_sup-postcalcode = '65033'.
*        ls_sup-city = 'Friedberg'.
*        ls_sup-companyname = 'Rewe'.
*        ls_sup-fax = '491252123'.
*
*        INSERT /uniq/at_sup FROM ls_sup.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '003'.
*        ls_sup-mandt = '800'.
*        ls_sup-supplierid = '003'.
*        ls_sup-phone = '+4910776349892'.
*        ls_sup-contactname = 'Mein schlächteste Lieferant'.
*        ls_sup-contacttitle = 'Kontaktiere mich nicht'.
*        ls_sup-street = 'Friedberger 32'.
*        ls_sup-postcalcode = '95033'.
*        ls_sup-city = 'Frankfurt'.
*        ls_sup-companyname = 'Aldi'.
*        ls_sup-fax = '49125213535'.
*
*        INSERT /uniq/at_sup FROM ls_sup.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*
*      WHEN '004'.
*        ls_sup-mandt = '800'.
*        ls_sup-supplierid = '004'.
*        ls_sup-phone = '234'.
*        ls_sup-contactname = 'Du hast mich schon kontaktiert'.
*        ls_sup-contacttitle = 'Ja Wohl'.
*        ls_sup-street = 'Aachener Str 11'.
*        ls_sup-postcalcode = '44444'.
*        ls_sup-city = 'Frankfurt'.
*        ls_sup-companyname = 'FF'.
*        ls_sup-fax = '491256732'.
*
*        INSERT /uniq/at_sup FROM ls_sup.
*
*        IF sy-subrc = '0'.
*          COMMIT WORK AND WAIT.
*        ELSE.
*          ROLLBACK WORK.
*        ENDIF.
*    ENDCASE.
*
  ENDMETHOD.


  METHOD truncate_table_and_insert_data.

    DATA: lt_cat TYPE TABLE OF /uniq/at_cat,
          lt_sup TYPE TABLE OF /uniq/at_sup,
          lt_prd TYPE TABLE OF /uniq/at_prd.


    IF to_upper( iv_tabel_name ) EQ 'CATEGORY'.

      DELETE FROM /uniq/at_cat.

      lt_cat = VALUE #(
    ( categoryid = '0001'
      categoryname = 'Getränke'
      description = 'Zu der Category Getränke gehören sowohl Getränke wie Fanta, Wasser, aber auch Alkhogol Getränke wie Bier, Wodka' )

     ( categoryid = '0002'
      categoryname = 'Lebesmittel'
      description = 'Zu der  Category Lebensmittel gehören nur Lebensmittel, die für Menscheid bestimmt sind' )

     ( categoryid = '0003'
      categoryname = 'IT_Deliver'
      description = 'Zu der Category IT_Deliver gehören Unternehmen. die Software zum Ausleihen zur Verfügung stellen' )

     ( categoryid = '0004'
      categoryname = 'Kraftstoff'
      description = 'Zu der Category Kraftstoff gehören Verbrennungsflüssigkeit wie Öl benzin usw' )

     ( categoryid = '0005'
      categoryname = 'Autos'
      description = 'Zu der Category Autos gehören Lkw, pkw usw' ) ).

      INSERT /uniq/at_cat FROM TABLE lt_cat.

    ELSEIF to_upper( iv_tabel_name ) EQ 'SUPPLIER'.

      DELETE FROM /uniq/at_sup.

      lt_sup = VALUE #(
     ( supplierid = '011'
      phone = '+4917676349723'
      contactname = 'Mein Lieblings Lieferant'
      contacttitle = 'Irgendwas'
      street = 'Winschester 22'
      postcalcode = '69933'
      city = 'Giessen'
      companyname = 'Uniq'
      fax = '491242142' )

     ( supplierid = '012'
      phone = '+4917676349725'
      contactname = 'Mein verspätete Lieferant'
      contacttitle = 'Kontaktiere mich'
      street = 'Europealle 27'
      postcalcode = '65033'
      city = 'Friedberg'
      companyname = 'Rewe'
      fax = '491252123' )

     ( supplierid = '013'
      phone = '+4910776349892'
      contactname = 'Mein schlächteste Lieferant'
      contacttitle = 'Kontaktiere mich nicht'
      street = 'Friedberger 32'
      postcalcode = '95033'
      city = 'Frankfurt'
      companyname = 'Aldi'
      fax = '49125213535' )

     ( supplierid = '014'
      phone = '234'
      contactname = 'Du hast mich schon kontaktiert'
      contacttitle = 'Ja Wohl'
      street = 'Aachener Str 11'
      postcalcode = '44444'
      city = 'Frankfurt'
      companyname = 'ARAL'
      fax = '491256732' )

     ( supplierid = '015'
      phone = '234455'
      contactname = 'Es existiert nicht'
      contacttitle = 'Ja Stimmt'
      street = 'Aupair Str 11'
      postcalcode = '77777'
      city = 'München'
      companyname = 'Auto Händler Abbos'
      fax = '4912567334' ) ).

      INSERT /uniq/at_sup FROM TABLE lt_sup.

    ELSEIF to_upper( iv_tabel_name ) EQ 'PRODUCT'.

        DELETE FROM /uniq/at_prd.

        lt_prd = VALUE #(
       ( productid = '1'
        productname = 'Bier'
        supplierid = '012'
        categoryid = '0001'
        quantity = '50'
        price = '150'
        currency = 'EUR' )

       ( productid = '2'
        productname = 'Wodka'
        supplierid = '012'
        categoryid = '0001'
        quantity = '100'
        price = '200'
        currency = 'EUR' )

       ( productid = '3'
        productname = 'Tomate'
        supplierid = '013'
        categoryid = '0002'
        quantity = '1'
        price = '500'
        currency = 'EUR' )

       ( productid = '4'
        productname = 'Brot'
        supplierid = '013'
        categoryid = '0002'
        quantity = '70'
        price = '700'
        currency = 'EUR' )

       ( productid = '5'
        productname = 'sap'
        supplierid = '011'
        categoryid = '0003'
        quantity = '60'
        price = '600'
        currency = 'EUR' )

        ( productid = '6'
        productname = 'Eclipse'
        supplierid = '011'
        categoryid = '0003'
        quantity = '30'
        price = '300'
        currency = 'EUR' )

        ( productid = '7'
        productname = 'Postman'
        supplierid = '011'
        categoryid = '0003'
        quantity = '1'
        price = '500'
        currency = 'EUR' )

        ( productid = '8'
        productname = 'Benzin'
        supplierid = '014'
        categoryid = '0004'
        quantity = '50'
        price = '200'
        currency = 'EUR' )

        ( productid = '9'
        productname = 'Dezil'
        supplierid = '014'
        categoryid = '0004'
        quantity = '40'
        price = '10'
        currency = 'EUR' )

        ( productid = '10'
        productname = 'Gaz'
        supplierid = '014'
        categoryid = '0004'
        quantity = '80'
        price = '20'
        currency = 'EUR' )

        ( productid = '11'
        productname = 'Bmw'
        supplierid = '015'
        categoryid = '0005'
        quantity = '12'
        price = '96'
        currency = 'EUR' )

        ( productid = '12'
        productname = 'Vw'
        supplierid = '015'
        categoryid = '0005'
        quantity = '34'
        price = '683'
        currency = 'EUR' )

        ( productid = '13'
        productname = 'Jaguar'
        supplierid = '015'
        categoryid = '0005'
        quantity = '67'
        price = '453'
        currency = 'EUR' )

        ( productid = '14'
        productname = 'Ferare'
        supplierid = '015'
        categoryid = '0005'
        quantity = '21'
        price = '78'
        currency = 'EUR' )

        ( productid = '15'
        productname = 'Schewralet'
        supplierid = '015'
        categoryid = '0005'
        quantity = '55'
        price = '120'
        currency = 'EUR' )

        ( productid = '16'
        productname = 'Mini'
        supplierid = '015'
        categoryid = '0005'
        quantity = '23'
        price = '352'
        currency = 'EUR' )

        ( productid = '17'
        productname = 'Scoda'
        supplierid = '015'
        categoryid = '0005'
        quantity = '45'
        price = '115'
        currency = 'EUR' )

        ( productid = '18'
        productname = 'Niva'
        supplierid = '015'
        categoryid = '0005'
        quantity = '43'
        price = '215'
        currency = 'EUR' )

        ( productid = '19'
        productname = 'Mercedes'
        supplierid = '015'
        categoryid = '0005'
        quantity = '23'
        price = '180'
        currency = 'EUR' )

        ( productid = '20'
        productname = 'Volwo'
        supplierid = '015'
        categoryid = '0001'
        quantity = '100'
        price = '250'
        currency = 'EUR' ) ).

       INSERT /uniq/at_prd FROM TABLE lt_prd.

    ENDIF.
  ENDMETHOD.
ENDCLASS.

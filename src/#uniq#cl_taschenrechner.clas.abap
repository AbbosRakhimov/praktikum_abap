class /UNIQ/CL_TASCHENRECHNER definition
  public
  create public .

public section.

  class-methods GET_TASCHENRECHNER_ERG
    importing
      !ER_ZAHL type /UNIQ/ER_ZAHL
      !ZW_ZAHL type /UNIQ/ZW_ZAHL
      !OPERATOR type /UNIQ/OPERATOR
    returning
      value(ERGEBNIS) type /UNIQ/ERGEBNIS
    exceptions
      FEHLER .
protected section.
private section.
ENDCLASS.



CLASS /UNIQ/CL_TASCHENRECHNER IMPLEMENTATION.


  method GET_TASCHENRECHNER_ERG.


 CASE operator.
    WHEN '+'.
      COMPUTE ergebnis = er_zahl + zw_zahl.

    WHEN '-'.
      COMPUTE ergebnis = er_zahl - zw_zahl.

    WHEN '*'.
      COMPUTE ergebnis = er_zahl * zw_zahl.

    WHEN '/'.
      IF zw_zahl = 0.
        RAISE fehler.
      ENDIF.
      COMPUTE ergebnis = er_zahl / zw_zahl.

    WHEN OTHERS.
      MESSAGE TEXT-003 TYPE 'E'.

  ENDCASE.

  endmethod.
ENDCLASS.

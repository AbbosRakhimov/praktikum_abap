FUNCTION /uniq/taschen_fub.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(ER_ZAHL) TYPE  /UNIQ/ER_ZAHL
*"     REFERENCE(ZW_ZAHL) TYPE  /UNIQ/ZW_ZAHL
*"     REFERENCE(OPERATOR) TYPE  /UNIQ/OPERATOR
*"  EXPORTING
*"     REFERENCE(ERGEBNIS) TYPE  /UNIQ/ERGEBNIS
*"  EXCEPTIONS
*"      FEHLER
*"----------------------------------------------------------------------
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

ENDFUNCTION.

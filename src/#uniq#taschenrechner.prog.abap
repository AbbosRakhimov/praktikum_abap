*&---------------------------------------------------------------------*
*& Report /UNIQ/TASCHENRECHNER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /uniq/taschenrechner.

SELECTION-SCREEN PUSHBUTTON 2(10) TEXT-003 USER-COMMAND cmd1.

PARAMETERS: er_zahl TYPE /uniq/er_zahl OBLIGATORY DEFAULT 2.
PARAMETERS: zw_zahl TYPE /uniq/zw_zahl OBLIGATORY.
PARAMETERS: oper TYPE /uniq/operator OBLIGATORY.

DATA: erg TYPE /uniq/ergebnis.

AT SELECTION-SCREEN.

*  IF ( er_zahl IS INITIAL OR zw_zahl IS INITIAL OR oper IS INITIAL ).
*    MESSAGE TEXT-001 TYPE 'E'.
*
*  ENDIF.


START-OF-SELECTION.

********************** Tachenrechner mit Aufruf von statischen Methode (=> heisst statisch, -> heisst instanz Methode) ************************************************

CALL METHOD /uniq/cl_taschenrechner=>get_taschenrechner_erg
  EXPORTING
    er_zahl  = er_zahl
    zw_zahl  = zw_zahl
    operator = oper
  RECEIVING
    ergebnis = erg
  EXCEPTIONS
    fehler   = 1
    others   = 2
        .
IF sy-subrc <> 0.
    WRITE: / 'Fehler', sy-subrc. "Implement suitable error handling here : wieso kann man hier nicht einfach fehler ausgeben, muss man speicherplatz dafür in DA reservieren?
  ELSE.
      WRITE : / 'Ergebis:', erg.
ENDIF.


********************* Tachenrechner mit Funktionbaustein *************************************************


*  SELECTION-SCREEN PUSHBUTTON 10(10) btn1 USER-COMMAND cmd1.
*  SKIP.

*  CALL FUNCTION '/UNIQ/TASCHEN_FUB'
*    EXPORTING
*      er_zahl  = er_zahl
*      zw_zahl  = zw_zahl
*      operator = oper
*    IMPORTING
*      ergebnis = erg
*    EXCEPTIONS
*      fehler   = 1 "weist 1 erte zu sy-subrc zu, sodass sy-subrc bei exception 1 werte
*      OTHERS   = 2.
*
*  IF sy-subrc <> 0.
*    WRITE: / 'Fehler', sy-subrc. "Implement suitable error handling here : wieso kann man hier nicht einfach fehler ausgeben, muss man speicherplatz dafür in DA reservieren?
*  ELSE.
* "   IF sy-ucomm = 'cmd1'.
*      WRITE : / 'Ergebis:', erg.
* "   ENDIF.
*  ENDIF.

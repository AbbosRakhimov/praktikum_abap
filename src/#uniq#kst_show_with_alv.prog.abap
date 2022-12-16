*&---------------------------------------------------------------------*
*& Report /uniq/kostl_sHOW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /uniq/kostl_show.

"variablen lv Strukturen ls, Tabellen lt,

DATA: ls_kst        TYPE  /uniq/kostl_s,
      lt_kst1       LIKE TABLE OF ls_kst,
      lt_rng_kstart TYPE TABLE OF /uniq/kosar_rs.


SELECTION-SCREEN BEGIN OF BLOCK para WITH FRAME TITLE titel.

PARAMETERS: p_bukrs LIKE ls_kst-bukrs DEFAULT '1000' OBLIGATORY.
PARAMETERS: p_datum TYPE dats DEFAULT sy-datum OBLIGATORY. " parameters werden mit immer p_ geschrieben
PARAMETERS: p_kokrs LIKE ls_kst-kokrs OBLIGATORY.
PARAMETERS: p_sprach LIKE ls_kst-spras DEFAULT sy-langu OBLIGATORY.

SELECT-OPTIONS s_art FOR ls_kst-kosar. "lower case. ls_kst-kosar auch hier s_ handelt sich um strukturen

SELECTION-SCREEN END OF BLOCK para.

INITIALIZATION.

  titel = TEXT-123.

AT SELECTION-SCREEN.

  IF p_bukrs IS INITIAL.

    MESSAGE TEXT-001 TYPE 'E'.

  ENDIF.

START-OF-SELECTION.
  "Funktionsbaustein erwartet eine Tabelle; Aus der Select-Option wird aber
  "eine Struktur gegeben! Daher appenden wir die Struktur an die Tabelle
    LOOP AT s_art.
      APPEND s_art TO lt_rng_kstart.
    ENDLOOP.

  CALL METHOD /uniq/cl_show_kst=>get_kostl_static_methode
    EXPORTING
      iv_bukrs  = p_bukrs
      iv_kokrs  = p_kokrs
      irt_kosar = lt_rng_kstart
      iv_datum  = p_datum
      iv_spras  = p_sprach
    IMPORTING
      et_kostl  = lt_kst1.

* ALV-Gitter-Objekt erzeugen
  DATA(o_alv) = NEW cl_gui_alv_grid( i_parent      = cl_gui_container=>default_screen " in default container einbetten
                                     i_appl_events = abap_true ).                      " Ereignisse als Applikationsevents registrieren

* Feldkatalog automatisch durch SALV-Objekte erstellen lassen
  DATA: o_salv TYPE REF TO cl_salv_table.

  cl_salv_table=>factory( IMPORTING
                            r_salv_table = o_salv
                          CHANGING
                            t_table      = lt_kst1 ).

  DATA(it_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog( r_columns      = o_salv->get_columns( )
                                                                     r_aggregations = o_salv->get_aggregations( ) ).

* Layout des ALV setzen
  DATA(lv_layout) = VALUE lvc_s_layo( zebra      = abap_true             " ALV-Control: Alternierende Zeilenfarbe (Zebramuster)
                                      cwidth_opt = 'A'                   " ALV-Control: Spaltenbreite optimieren
                                      grid_title = 'Kostenstellen' ).    " ALV-Control: Text der Titelzeile

* ALV anzeigen
  o_alv->set_table_for_first_display( EXPORTING
                                        i_bypassing_buffer = abap_false  " Puffer ausschalten
                                        i_save             = 'A'         " Anzeigevariante sichern
                                        is_layout          = lv_layout   " Layout
                                      CHANGING
                                        it_fieldcatalog    = it_fcat     " Feldkatalog
                                        it_outtab          = lt_kst1 ).  " Ausgabetabelle

* Focus auf ALV setzen
  cl_gui_alv_grid=>set_focus( control = o_alv ).

* leere SAP-Toolbar ausblenden
  cl_abap_list_layout=>suppress_toolbar( ).

* erzwingen von cl_gui_container=>default_screen
  WRITE: space.


* [x] Kostenstellennummer ! ~
* [x] Kostenrechnungskreis
* [x] Geschäftsbereich
* [x] Bezeichnugn. Beschreibung
* [x] gültig von/bis ausgeben
* [x] in Parameters ein Datum eingeben lassen (Default = heute)
* [x]   un dbei Selektion nur KOSTL, die an diesem tag gültig sind selektieren.
* [x] wähle die Reihenfolge der Felder bei Ausgabe aus.
* [x] Kostenstellenart mit Text ausgeben
* [x] Kostenstellenart über select-options selektierbar machen (default = nichts selektiert = alles ausgeben)

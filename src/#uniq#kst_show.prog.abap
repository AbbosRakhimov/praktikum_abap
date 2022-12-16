*&---------------------------------------------------------------------*
*& Report /uniq/kostl_sHOW
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT /uniq/kostl_show.

"variablen lv Strukturen ls, Tabellen lt,
*DELETE FROM /uniq/at_pers.
DATA: ls_kst        TYPE  /uniq/kostl_s,
      lt            TYPE cskt,
      lt_kst1       LIKE TABLE OF ls_kst,
      lt_rng_kstart TYPE TABLE OF /uniq/kosar_rs,
      lt_pers       TYPE TABLE OF /uniq/at_pers.

SELECT * FROM /uniq/at_pers INTO CORRESPONDING FIELDS OF TABLE @lt_pers.

SELECTION-SCREEN BEGIN OF BLOCK para WITH FRAME TITLE titel.

PARAMETERS: p_bukrs LIKE ls_kst-bukrs DEFAULT '1000' OBLIGATORY.
PARAMETERS: s_datum TYPE dats DEFAULT sy-datum OBLIGATORY. " parameters werden mit immer p_ geschrieben
PARAMETERS: p_kokrs LIKE ls_kst-kokrs OBLIGATORY.
PARAMETERS: p_sprach TYPE spras DEFAULT sy-langu OBLIGATORY.

SELECT-OPTIONS s_art FOR ls_kst-kosar. "lower case. ls_kst-kosar auch hier s_ handelt sich um strukturen

SELECTION-SCREEN END OF BLOCK para.

INITIALIZATION.

  titel = TEXT-123.
*  lt_rng_kstart = s_art.

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


  SELECT ks~bukrs, ks~kosar, ks~verak, ks~waers, ks~kokrs, ks~kostl, ks~gsber, ks~datab, ks~datbi, kt~ktext,
         kt~ltext, kt~spras, tkt~ktext AS kosar_ktext
    FROM      csks       AS ks
    LEFT JOIN cskt       AS kt
                         ON kt~kostl = ks~kostl
                         AND kt~datbi = ks~datbi
                         AND kt~kokrs = ks~kokrs
                         AND kt~spras = @sy-langu
  LEFT JOIN tkt05        AS tkt
                         ON tkt~kosar = ks~kosar
                         AND tkt~spras = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @lt_kst1

  WHERE ks~bukrs =  @p_bukrs
    AND ks~datbi >= @s_datum " nur am @datum gültig
    AND ks~datab <= @s_datum " nur an @datum gültig
    AND ks~kosar IN @lt_rng_kstart        "@s_art
  ORDER BY ks~kosar.

  SKIP.

  WRITE: 'Gesamte Datensätze:' COLOR 6, sy-dbcnt COLOR 1.
  ULINE.

  SKIP.

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

  LOOP AT lt_kst1 INTO ls_kst.

    WRITE: /(20) ls_kst-kokrs,
            (15) ls_kst-kostl,
            (15) ls_kst-bukrs,
            (15) ls_kst-gsber,
            (30) ls_kst-verak,
            (15) ls_kst-waers,
            (15) ls_kst-datab,
            (15) ls_kst-datbi.

    HIDE: ls_kst-kostl, ls_kst-datbi, ls_kst-kokrs.

    PERFORM ueberpruefesp.

  ENDLOOP.


FORM ueberpruefesp.

  IF ls_kst-spras IS INITIAL.
    WRITE: (66) |    >>> keine KST- Bezeichnung auf { sy-langu } vorhanden <<<|.
  ELSE.
    WRITE: (25) ls_kst-ktext,
           (40) ls_kst-ltext.
  ENDIF.

  WRITE:  ls_kst-kosar, '-', ls_kst-kosar_ktext.

ENDFORM.

*AT LINE-SELECTION.
*  CASE sy-lsind.
*    WHEN '1'.
*      SELECT ct~mctxt FROM cskt AS ct INTO CORRESPONDING FIELDS OF lt
*             WHERE kostl = ls_kst-kostl
*                   AND datbi = ls_kst-datbi
*                   AND kokrs = ls_kst-kokrs.
*        WRITE: lt-mctxt.
*
*        CLEAR: lt, ls_kst.
*        IF sy-subrc > 0.
*          WRITE: 'Kein Datensatzt vorhanden'.
*        ENDIF.
*        "       CLEAR: lt, ls_kst.
*      ENDSELECT.
**      IF sy-subrc > 0.
**        WRITE: 'Kein Datensatzt vorhanden'.
**      ENDIF.
*  ENDCASE.

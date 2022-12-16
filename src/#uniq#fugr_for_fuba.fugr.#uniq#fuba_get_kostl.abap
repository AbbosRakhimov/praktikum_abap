FUNCTION /uniq/fuba_get_kostl.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(IV_BUKRS) TYPE  BUKRS
*"     REFERENCE(IV_KOKRS) TYPE  KOKRS
*"     REFERENCE(IRT_KOSAR) TYPE  /UNIQ/KOSAR_RT
*"     REFERENCE(IV_DATUM) TYPE  DATS
*"     REFERENCE(IV_SPRAS) TYPE  SPRAS
*"  EXPORTING
*"     REFERENCE(ET_KOSTL) TYPE  /UNIQ/KOSTL_T
*"----------------------------------------------------------------------

****  SELECT a,b,c,d
****    FROM zer_tb_blah
****    INTO CORRESPONDING FIELDS OF TABLE @data(lt_my_table)
****   WHERE blah = blubber
****     AND this = that
****     AND what = ever.
****

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

  "sy-subrc = 0 Selektion mit Ergebnis
  "sy-subrc = 4 Kein Ergebnis

ENDFUNCTION.

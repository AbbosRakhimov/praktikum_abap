*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_/UNIQ/AT_SUP
*   generation date: 23.11.2022 at 10:46:28
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_/UNIQ/AT_SUP       .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.

*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_/UNIQ/AT_PERS
*   generation date: 15.12.2022 at 15:52:46
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_/UNIQ/AT_PERS      .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.

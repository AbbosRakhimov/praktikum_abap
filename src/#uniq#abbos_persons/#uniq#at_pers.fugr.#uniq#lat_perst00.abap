*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 15.12.2022 at 15:52:48
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: /UNIQ/AT_PERS...................................*
DATA:  BEGIN OF STATUS_/UNIQ/AT_PERS                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/UNIQ/AT_PERS                 .
CONTROLS: TCTRL_/UNIQ/AT_PERS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */UNIQ/AT_PERS                 .
TABLES: /UNIQ/AT_PERS                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .

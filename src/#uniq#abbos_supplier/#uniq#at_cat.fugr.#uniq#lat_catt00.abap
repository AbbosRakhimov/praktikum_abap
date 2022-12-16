*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 23.11.2022 at 10:35:44
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: /UNIQ/AT_CAT....................................*
DATA:  BEGIN OF STATUS_/UNIQ/AT_CAT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/UNIQ/AT_CAT                  .
CONTROLS: TCTRL_/UNIQ/AT_CAT
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */UNIQ/AT_CAT                  .
TABLES: /UNIQ/AT_CAT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .

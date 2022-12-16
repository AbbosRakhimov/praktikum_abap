*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 23.11.2022 at 10:46:29
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: /UNIQ/AT_SUP....................................*
DATA:  BEGIN OF STATUS_/UNIQ/AT_SUP                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/UNIQ/AT_SUP                  .
CONTROLS: TCTRL_/UNIQ/AT_SUP
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */UNIQ/AT_SUP                  .
TABLES: /UNIQ/AT_SUP                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .

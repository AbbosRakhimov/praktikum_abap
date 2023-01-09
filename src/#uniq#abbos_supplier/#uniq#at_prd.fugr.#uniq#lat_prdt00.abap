*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 22.12.2022 at 12:11:43
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: /UNIQ/AT_PRD....................................*
DATA:  BEGIN OF STATUS_/UNIQ/AT_PRD                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/UNIQ/AT_PRD                  .
CONTROLS: TCTRL_/UNIQ/AT_PRD
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */UNIQ/AT_PRD                  .
TABLES: /UNIQ/AT_PRD                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .

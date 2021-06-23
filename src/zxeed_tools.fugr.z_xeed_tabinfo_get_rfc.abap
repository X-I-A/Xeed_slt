FUNCTION Z_XEED_TABINFO_GET_RFC .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"     VALUE(I_RFCDEST) TYPE  RFCDEST
*"  TABLES
*"      ET_TABINFO STRUCTURE  ZXEED_S_TABINFO OPTIONAL
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lt_dd03p TYPE TABLE OF dd03p,
        ls_dd03p LIKE LINE OF lt_dd03p,
        ls_tabinfo LIKE LINE OF et_tabinfo.

  CALL FUNCTION 'DMC_DDIF_TABL_GET_WRAPPER'
    DESTINATION i_rfcdest
    EXPORTING
      name             = i_tabname
      i_nametab_only   = abap_true
    TABLES
      dd03p_tab        = lt_dd03p
    EXCEPTIONS
      illegal_input    = 1
      undefined_error  = 2
      no_fields        = 3
      no_authorization = 4
      OTHERS           = 5.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  LOOP AT lt_dd03p INTO ls_dd03p.
    clear ls_tabinfo.
    MOVE-CORRESPONDING ls_dd03p TO ls_tabinfo.
    append ls_tabinfo to ET_TABINFO.
  ENDLOOP.

ENDFUNCTION.

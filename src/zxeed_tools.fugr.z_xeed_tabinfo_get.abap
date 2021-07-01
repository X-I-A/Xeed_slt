FUNCTION z_xeed_tabinfo_get .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     VALUE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"  TABLES
*"      ET_TABINFO STRUCTURE  ZXEED_S_TABINFO OPTIONAL
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lv_dmc_ident    TYPE dmc_ident,
        ls_dmc_settings TYPE dmc_rfc_settings,
        ls_repl_map     TYPE iuuc_repl_map.

  CONCATENATE 'ZIUUC_' i_mt_id INTO lv_dmc_ident.

* Step 1: Try to Get the data from RFC.
  SELECT SINGLE * INTO ls_dmc_settings
    FROM dmc_rfc_settings
   WHERE orgunit = 2
     AND orgident = lv_dmc_ident
     AND rfc_type = 'SEND'.
  IF sy-subrc IS INITIAL.
    IF ls_dmc_settings-rfc_dest NE 'NONE'.
* Get Tabinfo from RFC
      CALL FUNCTION 'Z_XEED_TABINFO_GET_RFC'
        EXPORTING
          i_tabname        = i_tabname
          i_rfcdest        = ls_dmc_settings-rfc_dest
        TABLES
          et_tabinfo       = et_tabinfo
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      RETURN.
    ENDIF.
  ENDIF.

* Step 2: Try to Get the data from DB Connection
  SELECT SINGLE * INTO ls_repl_map FROM iuuc_repl_map WHERE mt_id = i_mt_id.
  CALL FUNCTION 'Z_XEED_TABINFO_GET_DBCON'
    EXPORTING
      i_tabname        = i_tabname
      i_guid           = ls_repl_map-config_guid
      i_mt_id          = i_mt_id
    TABLES
      et_tabinfo       = et_tabinfo
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFUNCTION.

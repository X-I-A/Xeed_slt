FUNCTION z_xeed_tabinfo_send .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SETTINGS) TYPE  ZXEED_SETTINGS
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lt_tabinfo    TYPE TABLE OF zxeed_s_tabinfo,
        ls_tab_header TYPE zxeed_s_header,
        lo_tab_header TYPE REF TO data,
        lo_tabinfo    TYPE REF TO data,
        lx_json_tab   TYPE xstring.

  CALL FUNCTION 'Z_XEED_TABINFO_GET'
    EXPORTING
      i_mt_id          = i_settings-mt_id
      i_tabname        = i_settings-tabname
    TABLES
      et_tabinfo       = lt_tabinfo
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ELSE.
    CONCATENATE i_settings-src_sysid i_settings-src_db i_settings-src_schema i_settings-tabname INTO ls_tab_header-table_id SEPARATED BY '.'.
    MOVE i_settings-start_seq TO ls_tab_header-start_seq.
    MOVE 1 TO ls_tab_header-current_age.
    ls_tab_header-operate_flag = 'L'.

    GET REFERENCE OF ls_tab_header INTO lo_tab_header.
    GET REFERENCE OF lt_tabinfo INTO lo_tabinfo.

    CALL FUNCTION 'Z_XEED_JSON_CONV'
      EXPORTING
        i_header  = lo_tab_header
        i_data    = lo_tabinfo
      IMPORTING
        e_content = lx_json_tab.

    CALL FUNCTION 'Z_XEED_DATA_SEND'
      EXPORTING
        i_content        = lx_json_tab
        i_age            = ls_tab_header-current_age
        i_operate        = ls_tab_header-operate_flag
        i_settings       = i_settings
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        resource_failure = 3
        OTHERS           = 4.
    IF sy-subrc IS NOT INITIAL.
    ENDIF.
  ENDIF.
ENDFUNCTION.

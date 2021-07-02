class ZCL_XEED_BADI_EXIT definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_BADI_IUUC_REPL_OLO_EXIT .
protected section.
private section.
ENDCLASS.



CLASS ZCL_XEED_BADI_EXIT IMPLEMENTATION.


METHOD if_badi_iuuc_repl_olo_exit~adjust_table_structure.
  DATA: ls_settings    TYPE zxeed_settings,
        lv_current_age TYPE numc10.

  CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
    EXPORTING
      i_mt_id       = iv_mt_id
      i_tabname     = iv_tabname_source
      i_check_guid  = abap_false
    IMPORTING
      e_settings    = ls_settings
      e_current_age = lv_current_age
    EXCEPTIONS
      not_found     = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  CALL FUNCTION 'Z_XEED_TABINFO_SEND'
    EXPORTING
      i_settings       = ls_settings
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  ev_target_tab_adjusted = abap_true.
ENDMETHOD.


METHOD if_badi_iuuc_repl_olo_exit~write_data_for_initial_load.
  DATA: ls_settings    TYPE zxeed_settings,
        lv_current_age TYPE numc10,
        ls_header      TYPE zxeed_s_header,
        lo_header      TYPE REF TO data,
        lx_json        TYPE xstring.

  FIELD-SYMBOLS: <fs_table_w_content> TYPE LINE OF if_badi_iuuc_repl_olo_exit=>gty_t_table_w_payload_il.

  LOOP AT it_table_w_content ASSIGNING <fs_table_w_content>.
    CLEAR ls_header.

    CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
      EXPORTING
        i_mt_id       = iv_mt_id
        i_tabname     = <fs_table_w_content>-tabname_source
      IMPORTING
        e_settings    = ls_settings
        e_current_age = lv_current_age
      EXCEPTIONS
        not_found     = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    IF lv_current_age = 2. " Table info should be sent
      CALL FUNCTION 'Z_XEED_TABINFO_SEND'
        EXPORTING
          i_settings       = ls_settings
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.

    CONCATENATE ls_settings-src_sysid ls_settings-src_db ls_settings-src_schema ls_settings-tabname INTO ls_header-table_id SEPARATED BY '.'.
    MOVE ls_settings-start_seq TO ls_header-start_seq.
    MOVE lv_current_age TO ls_header-current_age.
    ls_header-operate_flag = 'L'.
    GET REFERENCE OF ls_header INTO lo_header.

    CALL FUNCTION 'Z_XEED_JSON_CONV'
      EXPORTING
        i_header  = lo_header
        i_data    = <fs_table_w_content>-payload
      IMPORTING
        e_content = lx_json.

    IF xstrlen( lx_json ) > ls_settings-async_limit.
      CLEAR ls_settings-rfcdest.
    ENDIF.
    CALL FUNCTION 'Z_XEED_DATA_SEND'
      EXPORTING
        i_content        = lx_json
        i_age            = lv_current_age
        i_operate        = ls_header-operate_flag
        i_settings       = ls_settings
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        resource_failure = 3
        OTHERS           = 4.
  ENDLOOP.
ENDMETHOD.


METHOD if_badi_iuuc_repl_olo_exit~write_data_for_repl.
  DATA: ls_settings    TYPE zxeed_settings,
        lv_current_age TYPE numc10,
        ls_header      TYPE zxeed_s_header,
        lo_header      TYPE REF TO data,
        lv_table_lines TYPE i,
        lx_json        TYPE xstring.

  FIELD-SYMBOLS: <fs_table_w_content> TYPE LINE OF if_badi_iuuc_repl_olo_exit=>gty_t_table_w_payload,
                 <fs_payload_table>   TYPE ANY TABLE.

  LOOP AT it_table_w_content ASSIGNING <fs_table_w_content>.
* Step 1: Filter Operation
    CLEAR ls_header.
    IF <fs_table_w_content>-operation EQ 'A'.
      CONTINUE. " Means archive delete, no need to do the data transfer
    ELSE.
      ls_header-operate_flag = <fs_table_w_content>-operation.
    ENDIF.

    ASSIGN <fs_table_w_content>-payload->* TO <fs_payload_table>.
    DESCRIBE TABLE <fs_payload_table> LINES lv_table_lines.
    IF lv_table_lines EQ 0.
      CONTINUE.
    ENDIF.

* Step 2: Get the settings (No need to check if it is a new loading)
    CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
      EXPORTING
        i_mt_id       = iv_mt_id
        i_tabname     = <fs_table_w_content>-tabname_source
        i_check_guid  = abap_false
      IMPORTING
        e_settings    = ls_settings
        e_current_age = lv_current_age
      EXCEPTIONS
        not_found     = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

* Step 2-bis: In the case of an initial empty table
    IF lv_current_age = 2. " Table info should be sent
      CALL FUNCTION 'Z_XEED_TABINFO_SEND'
        EXPORTING
          i_settings       = ls_settings
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.

    CONCATENATE ls_settings-src_sysid ls_settings-src_db ls_settings-src_schema ls_settings-tabname INTO ls_header-table_id SEPARATED BY '.'.
    MOVE ls_settings-start_seq TO ls_header-start_seq.
    MOVE lv_current_age TO ls_header-current_age.
    GET REFERENCE OF ls_header INTO lo_header.

* Step 3: Data Conversion and Data sent
    CALL FUNCTION 'Z_XEED_JSON_CONV'
      EXPORTING
        i_header  = lo_header
        i_data    = <fs_table_w_content>-payload
      IMPORTING
        e_content = lx_json.

    IF xstrlen( lx_json ) > ls_settings-async_limit.
      CLEAR ls_settings-rfcdest.
    ENDIF.
    CALL FUNCTION 'Z_XEED_DATA_SEND'
      EXPORTING
        i_content        = lx_json
        i_age            = lv_current_age
        i_operate        = ls_header-operate_flag
        i_settings       = ls_settings
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        resource_failure = 3
        OTHERS           = 4.
  ENDLOOP.
ENDMETHOD.


METHOD if_badi_iuuc_repl_olo_exit~write_data_for_repl_cluster.
  DATA: ls_settings    TYPE zxeed_settings,
        lv_current_age TYPE numc10,
        ls_header      TYPE zxeed_s_header,
        lo_header      TYPE REF TO data,
        lo_keytab      TYPE REF TO data,
        lv_table_lines TYPE i,
        lx_json        TYPE xstring.

  FIELD-SYMBOLS: <fs_table_w_content>   TYPE LINE OF if_badi_iuuc_repl_olo_exit=>gty_t_table_w_payload_clust,
                 <fs_cluster_w_content> TYPE LINE OF if_badi_iuuc_repl_olo_exit=>gty_t_table_w_payload_clust,
                 <fs_payload_table>     TYPE ANY TABLE.

* Delete stade : Generate a fake D workload for all of the tables
  READ TABLE it_table_w_content ASSIGNING <fs_cluster_w_content> WITH KEY is_physical_cluster = abap_true.
  IF sy-subrc IS INITIAL.
* Step 1: Prepare the tab which only contains key fields
    CALL FUNCTION 'Z_XEED_KEYTAB_CREATE'
      EXPORTING
        i_fulltab = <fs_cluster_w_content>-payload
        i_keylist = it_key_field
      IMPORTING
        e_keytab  = lo_keytab
      EXCEPTIONS
        no_data   = 1
        OTHERS    = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

* Step 2: For each member table, do the delete for all keys found in cluster table
    LOOP AT it_table_w_content ASSIGNING <fs_table_w_content>.
      IF <fs_table_w_content>-is_physical_cluster = abap_true.
        CONTINUE.
      ENDIF.

      CLEAR ls_header.

      ls_header-operate_flag = 'D'.
      CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
        EXPORTING
          i_mt_id       = iv_mt_id
          i_tabname     = <fs_table_w_content>-tabname_source
          i_check_guid  = abap_false
        IMPORTING
          e_settings    = ls_settings
          e_current_age = lv_current_age
        EXCEPTIONS
          not_found     = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
*   Implement suitable error handling here
      ENDIF.

* Step 2-2: In the case of an initial empty table
      IF lv_current_age = 2. " Table info should be sent
        CALL FUNCTION 'Z_XEED_TABINFO_SEND'
          EXPORTING
            i_settings       = ls_settings
          EXCEPTIONS
            rfc_error        = 1
            connection_error = 2
            OTHERS           = 3.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.
      ENDIF.

      CONCATENATE ls_settings-src_sysid ls_settings-src_db ls_settings-src_schema ls_settings-tabname INTO ls_header-table_id SEPARATED BY '.'.
      MOVE ls_settings-start_seq TO ls_header-start_seq.
      MOVE lv_current_age TO ls_header-current_age.
      GET REFERENCE OF ls_header INTO lo_header.

* Step 2-3: Data Conversion and Data sent
      CALL FUNCTION 'Z_XEED_JSON_CONV'
        EXPORTING
          i_header  = lo_header
          i_data    = lo_keytab
        IMPORTING
          e_content = lx_json.

      IF xstrlen( lx_json ) > ls_settings-async_limit.
        CLEAR ls_settings-rfcdest.
      ENDIF.
      CALL FUNCTION 'Z_XEED_DATA_SEND'
        EXPORTING
          i_content        = lx_json
          i_age            = lv_current_age
          i_operate        = ls_header-operate_flag
          i_settings       = ls_settings
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          resource_failure = 3
          OTHERS           = 4.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDLOOP.
  ENDIF.

* Insert stade
  LOOP AT it_table_w_content ASSIGNING <fs_table_w_content>.
* Step 1:
    IF <fs_table_w_content>-is_physical_cluster = abap_true.
      CONTINUE.
    ENDIF.

    CLEAR ls_header.
    ls_header-operate_flag = 'I'.
    ASSIGN <fs_table_w_content>-payload->* TO <fs_payload_table>.
    DESCRIBE TABLE <fs_payload_table> LINES lv_table_lines.
    IF lv_table_lines EQ 0.
      CONTINUE.
    ENDIF.

* Step 2: Get the settings (No need to check if it is a new loading)
    CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
      EXPORTING
        i_mt_id       = iv_mt_id
        i_tabname     = <fs_table_w_content>-tabname_source
        i_check_guid  = abap_false
      IMPORTING
        e_settings    = ls_settings
        e_current_age = lv_current_age
      EXCEPTIONS
        not_found     = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

* Step 2-bis: In the case of an initial empty table
    IF lv_current_age = 2. " Table info should be sent
      CALL FUNCTION 'Z_XEED_TABINFO_SEND'
        EXPORTING
          i_settings       = ls_settings
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.

    CONCATENATE ls_settings-src_sysid ls_settings-src_db ls_settings-src_schema ls_settings-tabname INTO ls_header-table_id SEPARATED BY '.'.
    MOVE ls_settings-start_seq TO ls_header-start_seq.
    MOVE lv_current_age TO ls_header-current_age.
    GET REFERENCE OF ls_header INTO lo_header.

* Step 3: Data Conversion and Data sent
    CALL FUNCTION 'Z_XEED_JSON_CONV'
      EXPORTING
        i_header  = lo_header
        i_data    = <fs_table_w_content>-payload
      IMPORTING
        e_content = lx_json.

    IF xstrlen( lx_json ) > ls_settings-async_limit.
      CLEAR ls_settings-rfcdest.
    ENDIF.
    CALL FUNCTION 'Z_XEED_DATA_SEND'
      EXPORTING
        i_content        = lx_json
        i_age            = lv_current_age
        i_operate        = ls_header-operate_flag
        i_settings       = ls_settings
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        resource_failure = 3
        OTHERS           = 4.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDLOOP.
ENDMETHOD.
ENDCLASS.

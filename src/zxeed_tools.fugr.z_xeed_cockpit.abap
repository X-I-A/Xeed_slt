FUNCTION z_xeed_cockpit.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_DATA) TYPE REF TO  DATA
*"     REFERENCE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     REFERENCE(I_TABNAME) TYPE  TABNAME
*"     REFERENCE(I_PARAM) TYPE  ZXEED_PARAM
*"----------------------------------------------------------------------

* Functions:
* 1. If it is an initial load, send header descriptor
* 2. Data Message Split
* 3. If Post Failed, Save a copy for a future retry (FM SEND_DATA)

  FIELD-SYMBOLS: <fs_operate_flag> TYPE iuuc_operation,
                 <fs_data_tab>     TYPE ANY TABLE,
                 <fs_data_frag>    TYPE ANY TABLE,
                 <fs_data_line>    TYPE any.

  DATA: lv_timestamp    TYPE timestampl,
        lv_seq_no_tmp   TYPE char32,
        lv_seq_no       TYPE char20,
        ls_dashboard    TYPE zxeed_dashboard,
        lt_header       TYPE ddfields,
        lv_iniload_json TYPE string,
        lv_body_json    TYPE string.

  DATA: lo_data_frag   TYPE REF TO data.
  DATA: lv_frag_size  TYPE i,
        lv_size_limit TYPE i.

  DATA:
    BEGIN OF ls_iniload,
      sysid       TYPE zxeed_d_source_name,
      db          TYPE zxeed_d_src_db_name,
      schema      TYPE zxeed_d_src_schema_name,
      tabname     TYPE tabname,
      header_type TYPE char20 VALUE 'DDIC',
      start_seq   TYPE char20,
      age         TYPE numc10 VALUE 1,
      header      LIKE lt_header,
    END OF ls_iniload.

  DATA:
    BEGIN OF ls_output,
      sysid       TYPE zxeed_d_source_name,
      db          TYPE zxeed_d_src_db_name,
      schema      TYPE zxeed_d_src_schema_name,
      tabname     TYPE tabname,
      data_type   TYPE char20 VALUE 'SLT',
      start_seq   TYPE char20,
      age         TYPE numc10 VALUE 1,
      data        TYPE REF TO data,
    END OF ls_output.

* Get Parameters:
  IF i_param IS INITIAL.
    RETURN. " Something goes wrong and no need to continue
  ENDIF.

* Data Initialization
  ls_iniload-sysid   = i_param-src_sysid.
  ls_iniload-db      = i_param-src_db.
  ls_iniload-schema  = i_param-src_schema.
  ls_iniload-tabname = i_param-tabname.

  ls_output-sysid   = i_param-src_sysid.
  ls_output-db      = i_param-src_db.
  ls_output-schema  = i_param-src_schema.
  ls_output-tabname = i_param-tabname.
  ASSIGN i_data->* TO <fs_data_tab>.

* Function 1: Initial Load Check
  LOOP AT <fs_data_tab> ASSIGNING <fs_data_line>.
    ASSIGN COMPONENT 'IUUC_OPERAT_FLAG' OF STRUCTURE <fs_data_line> TO <fs_operate_flag>.
    EXIT. " One line is sufficient
  ENDLOOP.

  IF <fs_operate_flag> IS NOT ASSIGNED OR <fs_operate_flag> EQ space. "Initial Load
* Get Sequence Number (Timestamp)
    GET TIME STAMP FIELD lv_timestamp.
    MOVE lv_timestamp TO lv_seq_no_tmp.
    CONDENSE lv_seq_no_tmp.
    CONCATENATE lv_seq_no_tmp(14) lv_seq_no_tmp+15(6) INTO lv_seq_no.

    CALL FUNCTION 'Z_XEED_GET_INILOAD'
      EXPORTING
        i_mt_id     = i_mt_id
        i_tabname   = i_tabname
        i_seq_no    = lv_seq_no
      IMPORTING
        e_headers   = lt_header
        e_dashboard = ls_dashboard
      EXCEPTIONS
        not_found   = 1
        OTHERS      = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

* Only Post the fulfilled results
    IF lt_header IS NOT INITIAL.
      ls_iniload-start_seq = lv_seq_no.
      ls_iniload-header[]  = lt_header[].
      lv_iniload_json = /ui2/cl_json=>serialize( data = ls_iniload compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).

      CALL FUNCTION 'Z_XEED_SEND_DATA'
        EXPORTING
          i_content        = lv_iniload_json
          i_seq_no         = lv_seq_no
          i_age            = ls_iniload-age
          i_param          = i_param
        EXCEPTIONS
          rfc_error        = 1
          connection_error = 2
          OTHERS           = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.
  ENDIF.

* Get the dashbord entries / Shouldn't be enmpty
  IF ls_dashboard IS INITIAL.
    SELECT SINGLE * FROM zxeed_dashboard INTO CORRESPONDING FIELDS OF ls_dashboard
                   WHERE mt_id       = i_mt_id
                     AND tabname     = i_tabname.
  ENDIF.
  lv_seq_no = ls_dashboard-start_seq.
  ls_output-start_seq = lv_seq_no.

* Function 2 : Split and Send Body Message
* Check if frag is necessary
  MOVE i_param-frag_size TO lv_size_limit.
  CALL FUNCTION 'Z_XEED_GET_DATA_FRAG_SIZE'
    EXPORTING
      i_data       = i_data
      i_size_limit = lv_size_limit
    IMPORTING
      e_frag_size  = lv_frag_size.

  IF lv_frag_size IS INITIAL. "No need to frag
    ADD 1 TO ls_dashboard-current_age.
    ls_output-age = ls_dashboard-current_age.
    ls_output-data ?= i_data.
    lv_body_json = /ui2/cl_json=>serialize( data = ls_output compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).
* Send Data
    CALL FUNCTION 'Z_XEED_SEND_DATA'
      EXPORTING
        i_content = lv_body_json
        i_seq_no  = lv_seq_no
        i_age     = ls_output-age
        i_param   = i_param.
  ELSE. "Frag
    CREATE DATA lo_data_frag LIKE <fs_data_tab>.
    ASSIGN lo_data_frag->* TO <fs_data_frag>.

    LOOP AT <fs_data_tab> ASSIGNING <fs_data_line>.
      INSERT <fs_data_line> INTO TABLE <fs_data_frag>.
      IF sy-tabix MOD lv_frag_size EQ 0.
        ADD 1 TO ls_dashboard-current_age.
        ls_output-age = ls_dashboard-current_age.
        ls_output-data ?= lo_data_frag.
        lv_body_json = /ui2/cl_json=>serialize( data = ls_output compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).
* Send Data
        CALL FUNCTION 'Z_XEED_SEND_DATA'
          EXPORTING
            i_content = lv_body_json
            i_seq_no  = lv_seq_no
            i_age     = ls_output-age
            i_param   = i_param.
        CLEAR: <fs_data_frag>[], lv_body_json.
      ENDIF.
    ENDLOOP.
* The case for the last data
    IF <fs_data_frag> IS NOT INITIAL.
      ADD 1 TO ls_dashboard-current_age.
      ls_output-age = ls_dashboard-current_age.
      ls_output-data ?= lo_data_frag.
      lv_body_json = /ui2/cl_json=>serialize( data = ls_output compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).
* Send Data
      CALL FUNCTION 'Z_XEED_SEND_DATA'
        EXPORTING
          i_content = lv_body_json
          i_seq_no  = lv_seq_no
          i_age     = ls_output-age
          i_param   = i_param.
    ENDIF.
  ENDIF.

  MODIFY zxeed_dashboard FROM ls_dashboard.

ENDFUNCTION.

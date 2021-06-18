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
* Concentration at data sending

  FIELD-SYMBOLS: <fs_operate_flag> TYPE iuuc_operation,
                 <fs_data_tab>     TYPE ANY TABLE,
                 <fs_data_frag>    TYPE ANY TABLE,
                 <fs_data_line>    TYPE any.

  DATA: lv_timestamp    TYPE timestampl,
        lv_seq_no_tmp   TYPE char32,
        lv_seq_no       TYPE char20,
        ls_dashboard    TYPE zxeed_dashboard,
        lt_header       TYPE ddfields,
        lo_header_data  TYPE REF TO data,
        lo_iniload_data TYPE REF TO data,
        lx_iniload_json TYPE xstring,
        lx_body_json    TYPE xstring.


* Get DATA / Parameters:
  IF i_param IS INITIAL.
    RETURN. " Something goes wrong and no need to continue
  ENDIF.

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
      GET REFERENCE OF lt_header INTO lo_iniload_data.
      GET REFERENCE OF ls_dashboard INTO lo_header_data.

      CALL FUNCTION 'Z_XEED_JSON_CONV'
        EXPORTING
          i_header   = lo_header_data
          i_data     = lo_iniload_data
        IMPORTING
          e_xcontent = lx_iniload_json.

      CALL FUNCTION 'Z_XEED_SEND_DATA'
        EXPORTING
          i_content        = lx_iniload_json
          i_seq_no         = lv_seq_no
          i_age            = 1
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

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZSLT000001'
    IMPORTING
      number      = ls_dashboard-current_age.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  GET REFERENCE OF ls_dashboard INTO lo_header_data.

  CALL FUNCTION 'Z_XEED_JSON_CONV'
    EXPORTING
      i_header  = lo_header_data
      i_data    = i_data
    IMPORTING
      e_content = lx_body_json.

* Send Data
  CALL FUNCTION 'Z_XEED_SEND_DATA'
    EXPORTING
      i_content = lx_body_json
      i_seq_no  = lv_seq_no
      i_age     = ls_dashboard-current_age
      i_param   = i_param.

  MODIFY zxeed_dashboard FROM ls_dashboard.

ENDFUNCTION.

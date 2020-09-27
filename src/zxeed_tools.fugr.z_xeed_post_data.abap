FUNCTION z_xeed_post_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  STRING
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_PARAM) TYPE  ZXEED_PARAM
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  I
*"     VALUE(E_RESPONSE) TYPE  STRING
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lo_http_client TYPE REF TO if_http_client.

  DATA: lv_sysid       TYPE string,
        lv_db          TYPE string,
        lv_schema      TYPE string,
        lv_header_type TYPE string,
        lv_data_type   TYPE string,
        lv_seq_no      TYPE string,
        lv_age         TYPE string,
        lv_tabname     TYPE string.

* Step 1 - HTTP Destination Creation
  cl_http_client=>create_by_destination(
      EXPORTING
        destination              = i_param-rfcdest
      IMPORTING
        client                   = lo_http_client
        EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6
    ).
  IF sy-subrc <> 0.
    RAISE rfc_error.
  ENDIF.

* Step 2 - Request Preparation
  CALL METHOD lo_http_client->request->set_method( if_http_request=>co_request_method_post ).

* Step 2.1 - Mandatory Headers
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'text/plain'.

  MOVE i_param-src_sysid TO lv_sysid.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-SYSID'
      value = lv_sysid.

  MOVE i_param-tabname TO lv_tabname.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-TABNAME'
      value = lv_tabname.

  MOVE i_seq_no TO lv_seq_no.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-START-SEQ'
      value = lv_seq_no.

  MOVE i_age TO lv_age.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-AGE'
      value = lv_age.

* Step 2.2 - Conditional Headers
  IF i_age = 1. " Header
    MOVE 'DDIC' TO lv_header_type.
    CALL METHOD lo_http_client->request->set_header_field
      EXPORTING
        name  = 'XEED-HEADER-TYPE'
        value = lv_header_type.
  ELSE. " Data
    MOVE 'SLT' TO lv_data_type.
    CALL METHOD lo_http_client->request->set_header_field
      EXPORTING
        name  = 'XEED-DATA-TYPE'
        value = lv_data_type.
  ENDIF.

* Step 2.3 - Optional Headers
  IF i_param-src_db IS NOT INITIAL.
    MOVE i_param-src_db TO lv_db.
    CALL METHOD lo_http_client->request->set_header_field
      EXPORTING
        name  = 'XEED-DB'
        value = lv_db.
  ENDIF.

  IF i_param-src_schema IS NOT INITIAL.
    MOVE i_param-src_schema TO lv_schema.
    CALL METHOD lo_http_client->request->set_header_field
      EXPORTING
        name  = 'XEED-SCHEMA'
        value = lv_schema.
  ENDIF.

  lo_http_client->request->set_cdata( i_content ).

* Step 3 - Sent Request
  CALL METHOD lo_http_client->send
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
    RAISE connection_error.
  ENDIF.

  CALL METHOD lo_http_client->receive
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
    RAISE connection_error.
  ENDIF.

* Step 4 - Get Result
  e_response = lo_http_client->response->get_cdata( ).
  CALL METHOD lo_http_client->response->get_status( IMPORTING code = e_status ).

ENDFUNCTION.

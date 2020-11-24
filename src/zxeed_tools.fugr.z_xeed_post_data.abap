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

  DATA: lv_rfcdest     LIKE i_param-rfcdest,
        lv_table_id    TYPE string,
        lv_seq_no      TYPE string,
        lv_age_int     TYPE i,
        lv_age         TYPE string,
        lv_data_encode TYPE string VALUE 'flat',
        lv_data_format TYPE string VALUE 'record',
        lv_data_store  TYPE string VALUE 'body',
        lv_data_spec   TYPE string.

* Define to be used RFC destination
  IF i_param-rfcdest IS NOT INITIAL.
    lv_rfcdest = i_param-rfcdest.
  ELSEIF i_param-rfcdest_b IS NOT INITIAL.
    lv_rfcdest = i_param-rfcdest_b.
  ELSE.
    e_status = 0. "No RFC defined, do nothing
    RETURN.
  ENDIF.

* Step 1 - HTTP Destination Creation
  cl_http_client=>create_by_destination(
      EXPORTING
        destination              = lv_rfcdest
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

* Step 2 - Request Preparation : Post with Compression Mode
  CALL METHOD lo_http_client->request->set_method( if_http_request=>co_request_method_post ).
  CALL METHOD lo_http_client->set_compression( if_http_request=>co_compress_in_all_cases ).

* Step 2.1 - Common Header
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'text/plain'.

* Step 2.2 - Identification
  CONCATENATE i_param-src_sysid i_param-src_db i_param-src_schema i_param-tabname INTO lv_table_id SEPARATED BY '.'.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-TABLE-ID'
      value = lv_table_id.

  MOVE i_seq_no TO lv_seq_no.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-START-SEQ'
      value = lv_seq_no.

  MOVE i_age TO lv_age_int.
  MOVE lv_age_int TO lv_age.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-AGE'
      value = lv_age.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-AGED'
      value = 'True'.

* Step 2.3 - Data Description
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-DATA-ENCODE'
      value = lv_data_encode.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-DATA-FORMAT'
      value = lv_data_format.

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-DATA-STORE'
      value = lv_data_store.

* Step 2.4 - Conditional Headers
  IF i_age = 1. "Header Type
    MOVE 'ddic' TO lv_data_spec.
  ELSE. " Data
    MOVE 'slt' TO lv_data_spec.
  ENDIF.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-DATA-SPEC'
      value = lv_data_spec.

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

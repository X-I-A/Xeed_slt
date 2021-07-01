FUNCTION Z_XEED_DATA_POST.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  XSTRING
*"     VALUE(I_SETTINGS) TYPE  ZXEED_SETTINGS
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_OPERATE) TYPE  ZXEED_D_OPERATE
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  I
*"     VALUE(E_RESPONSE) TYPE  STRING
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lo_http_client TYPE REF TO if_http_client.

  DATA: lv_rfcdest  LIKE i_settings-rfcdest,
        lv_seq_no   TYPE string,
        lv_age      TYPE string,
        lv_operate  TYPE string,
        lv_table_id TYPE string.

* Define to be used RFC destination
  IF i_settings-rfcdest IS NOT INITIAL.
    lv_rfcdest = i_settings-rfcdest.
  ELSEIF i_settings-rfcdest_b IS NOT INITIAL.
    lv_rfcdest = i_settings-rfcdest_b.
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

* Step 2 - Request Preparation : Post with Normal Mode (No need to send a zipped file in gzip)
  CALL METHOD lo_http_client->request->set_method( if_http_request=>co_request_method_post ).
  CALL METHOD lo_http_client->set_compression( if_http_request=>co_compress_disabled ).

* Step 2.1 - Common Header
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'application/octet-stream'.

* Step 2.2 - Table Identification
  CONCATENATE i_settings-src_sysid i_settings-src_db i_settings-src_schema i_settings-tabname INTO lv_table_id SEPARATED BY '.'.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-TABLE-ID'
      value = lv_table_id.

  MOVE i_settings-start_seq TO lv_seq_no.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-SEQ-NO'
      value = lv_seq_no.

  MOVE i_age TO lv_age.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-AGE'
      value = lv_age.

  MOVE i_operate TO lv_operate.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-OPERATE'
      value = lv_operate.

  lo_http_client->request->set_data( data = i_content length = xstrlen( i_content ) ).

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

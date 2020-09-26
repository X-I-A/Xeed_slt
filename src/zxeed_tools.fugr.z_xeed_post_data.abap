FUNCTION Z_XEED_POST_DATA.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_DESTINATION) TYPE  RFCDEST
*"     VALUE(I_CONTENT) TYPE  STRING
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     VALUE(I_TABNAME) TYPE  TABNAME
*"     VALUE(I_AGE) TYPE  NUMC10
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  I
*"     VALUE(E_RESPONSE) TYPE  STRING
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lo_http_client TYPE REF TO if_http_client.

  DATA: lv_mt_id   TYPE string,
        lv_seq_no  TYPE string,
        lv_age     TYPE string,
        lv_tabname TYPE string.

* Step 1 - HTTP Destination Creation
  cl_http_client=>create_by_destination(
      EXPORTING
        destination              = i_destination
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

  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'Content-Type'
      value = 'text/plain'.

  MOVE i_mt_id TO lv_mt_id.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-MTID'
      value = lv_mt_id.

  MOVE i_tabname TO lv_tabname.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-TABNAME'
      value = lv_tabname.

  MOVE i_seq_no TO lv_seq_no.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-SEQNO'
      value = lv_seq_no.

  MOVE i_age TO lv_age.
  CALL METHOD lo_http_client->request->set_header_field
    EXPORTING
      name  = 'XEED-AGE'
      value = lv_age.

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

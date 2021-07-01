FUNCTION z_xeed_json_conv_ui2.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_HEADER) TYPE REF TO  DATA
*"     REFERENCE(I_DATA) TYPE REF TO  DATA
*"  EXPORTING
*"     REFERENCE(E_CONTENT) TYPE  XSTRING
*"  EXCEPTIONS
*"      CONV_FAILED
*"----------------------------------------------------------------------
  TYPES:
    BEGIN OF lty_payload,
      header TYPE REF TO data,
      data   TYPE REF TO data,
    END OF lty_payload.

  DATA: lv_json    TYPE string,
        ls_payload TYPE lty_payload.

  ls_payload-header ?= i_header.
  ls_payload-data   ?= i_data.

  lv_json = /ui2/cl_json=>serialize( data = ls_payload compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).

  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text   = lv_json
    IMPORTING
      buffer = e_content.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFUNCTION.

FUNCTION z_xeed_json_conv.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_HEADER) TYPE REF TO  DATA
*"     REFERENCE(I_DATA) TYPE REF TO  DATA
*"  EXPORTING
*"     REFERENCE(E_CONTENT) TYPE  XSTRING
*"----------------------------------------------------------------------
  CALL FUNCTION 'Z_XEED_JSON_CONV_KNL'
    EXPORTING
      i_header    = i_header
      i_data      = i_data
    IMPORTING
      e_content   = e_content
    EXCEPTIONS
      conv_failed = 1
      OTHERS      = 2.
  IF sy-subrc <> 0.
* When kernal transformation failed, we will try to use the slower one
    CALL FUNCTION 'Z_XEED_JSON_CONV_UI2'
      EXPORTING
        i_header    = i_header
        i_data      = i_data
      IMPORTING
        e_content   = e_content
      EXCEPTIONS
        conv_failed = 1
        OTHERS      = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDIF.

ENDFUNCTION.

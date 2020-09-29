FUNCTION z_xeed_send_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  STRING
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_PARAM) TYPE  ZXEED_PARAM
*"----------------------------------------------------------------------


  DATA: lv_http_status TYPE i VALUE 0.
* When Main RFC not configured, save the data to local filesystem
  IF i_param-rfcdest IS NOT INITIAL.
    CALL FUNCTION 'Z_XEED_POST_DATA'
      EXPORTING
        i_param          = i_param
        i_content        = i_content
        i_seq_no         = i_seq_no
        i_age            = i_age
      IMPORTING
        e_status         = lv_http_status
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        OTHERS           = 3.
  ENDIF.
  IF sy-subrc <> 0 OR lv_http_status NE 200.
* In the case of fail or no main RFC configured, archive data
    CALL FUNCTION 'Z_XEED_ARCHIVE_DATA'
      EXPORTING
        i_param   = i_param
        i_content = i_content
        i_seq_no  = i_seq_no
        i_age     = i_age.
  ENDIF.

ENDFUNCTION.

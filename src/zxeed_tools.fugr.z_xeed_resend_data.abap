FUNCTION z_xeed_resend_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_FILENAME) TYPE  CHAR255
*"     VALUE(I_PARAM) TYPE  ZXEED_PARAM
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_DELETE) TYPE  BOOLE DEFAULT ''
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  I
*"     VALUE(E_RESPONSE) TYPE  STRING
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lx_content TYPE xstring,
        lv_status  TYPE i.

  OPEN DATASET i_filename FOR INPUT IN BINARY MODE.
  READ DATASET i_filename INTO lx_content.
  CLOSE DATASET i_filename.

  CALL FUNCTION 'Z_XEED_POST_DATA'
    EXPORTING
      i_param          = i_param
      i_content        = lx_content
      i_seq_no         = i_seq_no
      i_age            = i_age
    IMPORTING
      e_status         = lv_status
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      resource_failure = 3
      OTHERS           = 4.

  IF i_delete EQ abap_true AND lv_status EQ 200.
    DELETE DATASET i_filename.
  ENDIF.

ENDFUNCTION.

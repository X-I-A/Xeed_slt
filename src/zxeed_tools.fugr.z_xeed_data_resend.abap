FUNCTION z_xeed_data_resend.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_FILENAME) TYPE  CHAR255
*"     VALUE(I_SETTINGS) TYPE  ZXEED_SETTINGS
*"     VALUE(I_AGE) TYPE  NUMC10
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

* TODO Check data format here by using winzip crc32
  DELETE DATASET i_filename.

  CALL FUNCTION 'Z_XEED_DATA_SEND'
    EXPORTING
      i_settings       = i_settings
      i_content        = lx_content
      i_age            = i_age
    IMPORTING
      e_status         = lv_status
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      resource_failure = 3
      OTHERS           = 4.

ENDFUNCTION.

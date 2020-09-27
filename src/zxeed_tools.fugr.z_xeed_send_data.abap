FUNCTION Z_XEED_SEND_DATA.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  STRING
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     VALUE(I_TABNAME) TYPE  TABNAME
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_RFCDES) TYPE  ZXEED_D_RFCDEST
*"     VALUE(I_PATH) TYPE  ZXEED_D_PATHINTERN
*"----------------------------------------------------------------------

* Always Post Data to HTTP
* If it KO => Save a local copy
  DATA: lv_http_status TYPE i.

  CALL FUNCTION 'Z_XEED_POST_DATA'
    EXPORTING
      i_destination    = i_rfcdes
      i_content        = i_content
      i_seq_no         = i_seq_no
      i_mt_id          = i_mt_id
      i_tabname        = i_tabname
      i_age            = i_age
    IMPORTING
      e_status         = lv_http_status
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0 OR lv_http_status NE 200.
* In the case of fail, archive data
    CALL FUNCTION 'Z_XEED_ARCHIVE_DATA'
      EXPORTING
        i_content = i_content
        i_path    = i_path
        i_seq_no  = i_seq_no
        i_mt_id   = i_mt_id
        i_tabname = i_tabname
        i_age     = i_age.
  ENDIF.

ENDFUNCTION.

FUNCTION z_xeed_data_resend.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_FILENAME) TYPE  CHAR255
*"     VALUE(I_SETTINGS) TYPE  ZXEED_SETTINGS
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_OPERATE) TYPE  ZXEED_D_OPERATE
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lv_rfcdest      TYPE rfcdest,
        lx_content      TYPE xstring,
        lv_filename_tmp TYPE char255,
        lv_filename_len TYPE i,
        lv_http_status  TYPE i.

  DATA: lo_zip      TYPE REF TO cl_abap_zip.

  OPEN DATASET i_filename FOR INPUT IN BINARY MODE.
  READ DATASET i_filename INTO lx_content.
  CLOSE DATASET i_filename.

* Should be about to load a zip file or there is something goes wrong.
  CREATE OBJECT lo_zip.
  CALL METHOD lo_zip->load
    EXPORTING
      zip             = lx_content
    EXCEPTIONS
      zip_parse_error = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
* TODO: make difference between a writting file and a corrupted file
    RETURN.
  ENDIF.

* Mark this file as running
  lv_filename_tmp = i_filename.
  lv_filename_len = strlen( lv_filename_tmp ) - 1.
  CONCATENATE lv_filename_tmp+0(lv_filename_len) 'R' INTO lv_filename_tmp.
  OPEN DATASET lv_filename_tmp FOR OUTPUT IN BINARY MODE.
  TRANSFER lx_content TO lv_filename_tmp.
  CLOSE DATASET lv_filename_tmp.
  DELETE DATASET i_filename.

  IF i_settings-rfcdest IS INITIAL AND i_settings-rfcdest_b IS NOT INITIAL.
    i_settings-rfcdest = i_settings-rfcdest_b.
  ELSEIF i_settings-rfcdest IS INITIAL AND i_settings-rfcdest_b IS INITIAL.
    RAISE rfc_error.
  ENDIF.

* Try to post file, write back to file system if failed
  CALL FUNCTION 'Z_XEED_DATA_POST'
    EXPORTING
      i_settings       = i_settings
      i_content        = lx_content
      i_age            = i_age
      i_operate        = i_operate
    IMPORTING
      e_status         = lv_http_status
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.

  IF sy-subrc <> 0 OR lv_http_status NE 200.
* In the case of fail or no main RFC configured, archive data
    CALL FUNCTION 'Z_XEED_DATA_ARCHIVE'
      EXPORTING
        i_settings = i_settings
        i_content  = lx_content
        i_age      = i_age
        i_operate  = i_operate.
  ENDIF.

  DELETE DATASET lv_filename_tmp.
ENDFUNCTION.

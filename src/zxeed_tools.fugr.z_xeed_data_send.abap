FUNCTION z_xeed_data_send.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  XSTRING
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_OPERATE) TYPE  ZXEED_D_OPERATE
*"     VALUE(I_SETTINGS) TYPE  ZXEED_SETTINGS
*"----------------------------------------------------------------------


  DATA: lv_http_status TYPE i VALUE 0,
        lv_content     TYPE xstring.

  DATA: lo_zip      TYPE REF TO cl_abap_zip.

  CREATE OBJECT lo_zip.
  lo_zip->add( name = 'content' content = i_content ).
  lv_content = lo_zip->save( ).

* When Main RFC not configured, save the data to local filesystem
  IF i_settings-rfcdest IS NOT INITIAL.
    CALL FUNCTION 'Z_XEED_DATA_POST'
      EXPORTING
        i_settings       = i_settings
        i_content        = lv_content
        i_age            = i_age
        i_operate        = i_operate
      IMPORTING
        e_status         = lv_http_status
      EXCEPTIONS
        rfc_error        = 1
        connection_error = 2
        OTHERS           = 3.
  ENDIF.

  IF sy-subrc <> 0 OR lv_http_status NE 200.
* In the case of fail or no main RFC configured, archive data
    CALL FUNCTION 'Z_XEED_DATA_ARCHIVE'
      EXPORTING
        i_settings = i_settings
        i_content  = lv_content
        i_age      = i_age
        i_operate  = i_operate.
  ENDIF.

ENDFUNCTION.

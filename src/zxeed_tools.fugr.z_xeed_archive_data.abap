FUNCTION z_xeed_archive_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  XSTRING
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_AGE) TYPE  NUMC10
*"     VALUE(I_PARAM) TYPE  ZXEED_PARAM
*"  EXCEPTIONS
*"      PATH_ERROR
*"----------------------------------------------------------------------
  DATA: lv_filename   TYPE c LENGTH 255,
        lv_fname_json TYPE c LENGTH 255.


* WRITE TO FILE - Max 32 Characters
  CONCATENATE i_seq_no '-' i_age INTO lv_filename.

  CALL FUNCTION 'FILE_GET_NAME_USING_PATH'
    EXPORTING
      logical_path               = i_param-pathintern
      file_name                  = lv_filename
    IMPORTING
      file_name_with_path        = lv_fname_json
    EXCEPTIONS
      path_not_found             = 1
      missing_parameter          = 2
      operating_system_not_found = 3
      file_system_not_found      = 4
      OTHERS                     = 5.
  IF sy-subrc <> 0.
    RAISE path_error.
  ENDIF.

  OPEN DATASET lv_fname_json FOR OUTPUT IN BINARY MODE.
  TRANSFER i_content TO lv_fname_json.
  CLOSE DATASET lv_fname_json.

ENDFUNCTION.

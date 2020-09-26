FUNCTION z_xeed_archive_data.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTENT) TYPE  STRING
*"     VALUE(I_PATH) TYPE  ZXEED_D_PATHINTERN
*"     VALUE(I_SEQ_NO) TYPE  CHAR20
*"     VALUE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     VALUE(I_TABNAME) TYPE  TABNAME
*"     VALUE(I_AGE) TYPE  NUMC10
*"  EXCEPTIONS
*"      PATH_ERROR
*"----------------------------------------------------------------------
  DATA: lv_filename   TYPE c LENGTH 255,
        lv_fname_json TYPE c LENGTH 255.

* WRITE TO FILE
  CONCATENATE i_seq_no '-' i_age '-' i_tabname '-' i_mt_id '.json' INTO lv_filename.

  CALL FUNCTION 'FILE_GET_NAME_USING_PATH'
    EXPORTING
      logical_path               = i_path
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

  OPEN DATASET lv_fname_json FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  TRANSFER i_content TO lv_fname_json.
  CLOSE DATASET lv_fname_json.

ENDFUNCTION.

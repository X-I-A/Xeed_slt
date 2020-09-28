*&---------------------------------------------------------------------*
*& Report Z_XEED_RESEND
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_XEED_RESEND.

CONSTANTS: dummy TYPE text20 VALUE 'dummy.txt'.

DATA: lt_path_log TYPE TABLE OF zxeed_param-pathintern,
      lv_path_log LIKE LINE OF lt_path_log,
      lv_path_phy TYPE salfile-longname,
      lv_path_len TYPE i.

DATA: lv_seqno TYPE char20,
      lv_age   TYPE numc10.

DATA: lt_file     TYPE TABLE OF  salfldir,
      ls_file     LIKE LINE OF lt_file,
      lv_filename TYPE c LENGTH 255,
      lv_json     TYPE string.

DATA: ls_param  TYPE zxeed_param,
      lv_status TYPE i.

DATA:
  BEGIN OF ls_iniload,
    sysid       TYPE zxeed_d_source_name,
    db          TYPE zxeed_d_src_db_name,
    schema      TYPE zxeed_d_src_schema_name,
    tabname     TYPE tabname,
    header_type TYPE char20 VALUE 'DDIC',
    start_seq   TYPE char20,
    age         TYPE numc10 VALUE 1,
    header      TYPE ddfields,
  END OF ls_iniload.

DATA:
  BEGIN OF ls_output,
    sysid     TYPE zxeed_d_source_name,
    db        TYPE zxeed_d_src_db_name,
    schema    TYPE zxeed_d_src_schema_name,
    tabname   TYPE tabname,
    data_type TYPE char20 VALUE 'SLT',
    start_seq TYPE char20,
    age       TYPE numc10 VALUE 1,
    data      TYPE REF TO data,
  END OF ls_output.


SELECT DISTINCT pathintern FROM zxeed_param
  INTO TABLE lt_path_log.
LOOP AT lt_path_log INTO lv_path_log.
* Get Physical Path
  CALL FUNCTION 'FILE_GET_NAME_USING_PATH'
    EXPORTING
      logical_path               = lv_path_log
      file_name                  = dummy
    IMPORTING
      file_name_with_path        = lv_path_phy
    EXCEPTIONS
      path_not_found             = 1
      missing_parameter          = 2
      operating_system_not_found = 3
      file_system_not_found      = 4
      OTHERS                     = 5.
  IF sy-subrc <> 0.
    CONTINUE.
  ENDIF.
  lv_path_len = strlen( lv_path_phy ) - 9.
  lv_path_phy = lv_path_phy+0(lv_path_len).
* Get Files in the physical path
  CALL FUNCTION 'RZL_READ_DIR_LOCAL'
    EXPORTING
      name           = lv_path_phy
    TABLES
      file_tbl       = lt_file
    EXCEPTIONS
      argument_error = 1
      not_found      = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    CONTINUE.
  ENDIF.
* Get File with the correct format: <seq>-<age>-<mt-id>-<tabname>.json
  LOOP AT lt_file INTO ls_file WHERE name CP '*-*'.
    IF ls_file-name+20(1) = '-' AND strlen( ls_file-name ) = 31
     AND ls_file-name+0(20) CO '0123456789'
     AND ls_file-name+21(10) CO '0123456789'.
      CONCATENATE lv_path_phy ls_file-name INTO lv_filename.
      MOVE ls_file-name+0(20) TO lv_seqno.
      MOVE ls_file-name+21(10) TO lv_age.
      OPEN DATASET lv_filename FOR INPUT IN TEXT MODE ENCODING DEFAULT.
      READ DATASET lv_filename INTO lv_json.
      CLEAR: ls_iniload, ls_output, lv_status, ls_param.
      IF lv_age = 1.
        /ui2/cl_json=>deserialize( EXPORTING json = lv_json pretty_name = /ui2/cl_json=>pretty_mode-none CHANGING data = ls_iniload ).
        SELECT SINGLE * FROM zxeed_param
          INTO CORRESPONDING FIELDS OF ls_param
         WHERE src_sysid = ls_iniload-sysid
           AND tabname = ls_iniload-tabname
           AND src_db = ls_iniload-db
           AND src_schema = ls_iniload-schema.
* Re-Post Data Try
        CALL FUNCTION 'Z_XEED_POST_DATA'
          EXPORTING
            i_param          = ls_param
            i_content        = lv_json
            i_seq_no         = ls_iniload-start_seq
            i_age            = ls_iniload-age
          IMPORTING
            e_status         = lv_status
          EXCEPTIONS
            rfc_error        = 1
            connection_error = 2
            OTHERS           = 3.
        IF sy-subrc IS NOT INITIAL.
          CLEAR lv_status.
          CONTINUE. " Donothing
        ENDIF.
      ELSE.
        /ui2/cl_json=>deserialize( EXPORTING json = lv_json pretty_name = /ui2/cl_json=>pretty_mode-none CHANGING data = ls_output ).
        SELECT SINGLE * FROM zxeed_param
          INTO CORRESPONDING FIELDS OF ls_param
         WHERE src_sysid = ls_output-sysid
           AND tabname = ls_output-tabname
           AND src_db = ls_output-db
           AND src_schema = ls_output-schema.
* Re-Post Data Try
        CALL FUNCTION 'Z_XEED_POST_DATA'
          EXPORTING
            i_param          = ls_param
            i_content        = lv_json
            i_seq_no         = ls_output-start_seq
            i_age            = ls_output-age
          IMPORTING
            e_status         = lv_status
          EXCEPTIONS
            rfc_error        = 1
            connection_error = 2
            OTHERS           = 3.
        IF sy-subrc IS NOT INITIAL.
          CLEAR lv_status.
          CONTINUE. " Donothing
        ENDIF.
      ENDIF.
      CLOSE DATASET lv_filename.
      IF lv_status = 200. " Post OK this time
        DELETE DATASET lv_filename.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDLOOP.

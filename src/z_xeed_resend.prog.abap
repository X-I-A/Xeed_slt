*&---------------------------------------------------------------------*
*& Report Z_XEED_RESEND
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_resend.

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
      lv_size     TYPE i,
      lt_data     TYPE STANDARD TABLE OF tbl1024,
      lx_content  TYPE xstring,
      lv_header   TYPE string,
      lv_body     TYPE string.

DATA: ls_param  TYPE zxeed_param,
      lv_status TYPE i.

* Get All Possible Archive Location
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
* Get File with the correct format: <seq>-<age>
  LOOP AT lt_file INTO ls_file WHERE name CP '*-*'.
    IF ls_file-name+20(1) = '-' AND strlen( ls_file-name ) = 31
     AND ls_file-name+0(20) CO '0123456789'
     AND ls_file-name+21(10) CO '0123456789'.
      CONCATENATE lv_path_phy ls_file-name INTO lv_filename.
      MOVE ls_file-name+0(20) TO lv_seqno.
      MOVE ls_file-name+21(10) TO lv_age.

      MOVE ls_file-name+0(20) TO lv_seqno.
      MOVE ls_file-name+21(10) TO lv_age.
      ls_param-rfcdest = 'SLT-GCR-RELAY-01'.
      ls_param-src_sysid = 'RT1'.
      ls_param-src_db = 'DEFAULT'.
      ls_param-src_schema = 'DEFAULT'.
      ls_param-tabname = 'GLPCA'.

*      CALL FUNCTION 'Z_XEED_RESEND_DATA'
*        STARTING NEW TASK 'SEND'
*        EXPORTING
*          i_param          = ls_param
*          i_filename       = lv_filename
*          i_seq_no         = lv_seqno
*          i_age            = lv_age
*          i_delete         = abap_true
*        EXCEPTIONS
*          rfc_error        = 1
*          connection_error = 2
*          resource_failure = 3
*          OTHERS           = 4.
*      WRITE sy-subrc.
*      DELETE DATASET lv_filename.
*      WRITE: lv_status.
      "      DELETE DATASET lv_filename.
      "      OPEN DATASET lv_filename FOR OUTPUT IN BINARY MODE.
      "      READ DATASET lv_filename INTO lx_content.
      "      WRITE lx_content.
      "      CLOSE DATASET lv_filename.
*      DELETE DATASET lv_filename.
*      EXIT.
*      READ DATASET lv_filename INTO lv_header.
*      READ DATASET lv_filename INTO lv_body.
*      MOVE ls_file-name+0(20) TO lv_seqno.
*      MOVE ls_file-name+21(10) TO lv_age.
*      OPEN DATASET lv_filename FOR INPUT IN TEXT MODE ENCODING DEFAULT.
*      READ DATASET lv_filename INTO lv_header.
*      READ DATASET lv_filename INTO lv_body.
*      CLEAR: lv_status, ls_param.
*      /ui2/cl_json=>deserialize( EXPORTING json = lv_header pretty_name = /ui2/cl_json=>pretty_mode-none CHANGING data = ls_param ).
*      CALL FUNCTION 'Z_XEED_POST_DATA'
*        EXPORTING
*          i_param          = ls_param
*          i_content        = lv_body
*          i_seq_no         = lv_seqno
*          i_age            = lv_age
*        IMPORTING
*          e_status         = lv_status
*        EXCEPTIONS
*          rfc_error        = 1
*          connection_error = 2
*          OTHERS           = 3.
*      IF sy-subrc IS NOT INITIAL.
*        CLEAR lv_status.
*        CLOSE DATASET lv_filename.
*        CONTINUE. " Donothing
*      ENDIF.
*      CLOSE DATASET lv_filename.
*      IF lv_status = 200. " Post OK this time
*        DELETE DATASET lv_filename.
*      ENDIF.
    ENDIF.
  ENDLOOP.
ENDLOOP.

FORM processing_done USING taskname.
ENDFORM.

*&---------------------------------------------------------------------*
*& Report Z_XEED_RESEND
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_asyncro_send.

CONSTANTS: dummy TYPE text20 VALUE 'dummy.txt'.

DATA: lt_path_log TYPE TABLE OF zxeed_param-pathintern,
      lv_path_log LIKE LINE OF lt_path_log,
      lv_path_phy TYPE salfile-longname,
      lv_path_len TYPE i.

DATA: lv_seqno        TYPE char20,
      lv_age          TYPE numc10,
      lv_operate_flag TYPE zxeed_d_operate.

DATA: lt_file     TYPE TABLE OF  salfldir,
      ls_file     LIKE LINE OF lt_file,
      lv_filename TYPE c LENGTH 255,
      lv_size     TYPE i,
      lt_data     TYPE STANDARD TABLE OF tbl1024,
      lx_content  TYPE xstring,
      lv_header   TYPE string,
      lv_body     TYPE string.

DATA: ls_settings TYPE zxeed_settings,
      lv_status   TYPE i.

* Get All Possible Archive Location
SELECT DISTINCT pathintern FROM zxeed_settings
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
    IF ls_file-name+20(1) = '-' AND strlen( ls_file-name ) = 32
                                AND ls_file-name+0(20) CO '0123456789'
                                AND ls_file-name+21(10) CO '0123456789'
                                AND ls_file-name+31(1) CO 'LIDU'.
      CONCATENATE lv_path_phy ls_file-name INTO lv_filename.
      MOVE ls_file-name+0(20) TO lv_seqno.
      MOVE ls_file-name+21(10) TO lv_age.
      MOVE ls_file-name+31(1) TO lv_operate_flag.

      SELECT SINGLE * INTO ls_settings
        FROM zxeed_settings
       WHERE start_seq = lv_seqno.
      IF sy-subrc IS INITIAL.
        " We could resend the data
        CALL FUNCTION 'Z_XEED_DATA_RESEND'
          STARTING NEW TASK 'SEND'
          EXPORTING
            i_filename       = lv_filename
            i_settings       = ls_settings
            i_age            = lv_age
            i_operate        = lv_operate_flag
          EXCEPTIONS
            rfc_error        = 1
            connection_error = 2
            resource_failure = 3
            OTHERS           = 4.
        IF sy-subrc <> 0.
* In the case of asynchro failed, we put a synchro send to simulate the wait action
          CALL FUNCTION 'Z_XEED_DATA_RESEND'
            EXPORTING
              i_filename = lv_filename
              i_settings = ls_settings
              i_age      = lv_age
              i_operate  = lv_operate_flag
            EXCEPTIONS
              OTHERS     = 1.
          IF sy-subrc IS INITIAL.
            WRITE:/ 'Retry; ', lv_filename.
          ENDIF.
        ELSE.
          WRITE:/ 'Asynco; ', lv_filename.
        ENDIF.
      ELSE.
        " Obsoleted data history
        DELETE DATASET lv_filename.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDLOOP.

FORM processing_done USING taskname.
ENDFORM.

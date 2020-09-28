*&---------------------------------------------------------------------*
*& Report Z_XEED_OPERATION
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_operation.

TABLES: zxeed_param.

CONSTANTS: c_rfc_def_err  TYPE i VALUE 1,
           c_rfc_conn_err TYPE i VALUE 2,
           c_path_err     TYPE i VALUE 1.
DATA: gv_rc_code TYPE i.

DATA: gt_rul_map    LIKE TABLE OF iuuc_ass_rul_map,
      gs_rul_map    LIKE LINE OF gt_rul_map,
      gt_xeed_param LIKE TABLE OF zxeed_param,
      gs_xeed_param LIKE LINE OF gt_xeed_param.

SELECT-OPTIONS: o_mtid FOR zxeed_param-mt_id NO INTERVALS NO-EXTENSION.
SELECT-OPTIONS: o_tabnam FOR zxeed_param-tabname NO INTERVALS.
SELECT-OPTIONS: o_rfc_m FOR zxeed_param-rfcdest NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_file FOR zxeed_param-pathintern NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_srctyp FOR zxeed_param-src_flag DEFAULT 'R' NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_fgsize FOR zxeed_param-frag_size DEFAULT 1000 NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_basis FOR zxeed_param-basisversion OBLIGATORY DEFAULT '750' NO INTERVALS NO-EXTENSION MODIF ID ins.

PARAMETERS p_adv AS CHECKBOX DEFAULT '' USER-COMMAND adv MODIF ID ins.
SELECTION-SCREEN BEGIN OF BLOCK grp02 WITH FRAME TITLE TEXT-b02.
SELECT-OPTIONS: o_sid FOR zxeed_param-src_sysid NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECT-OPTIONS: o_db FOR zxeed_param-src_db NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECT-OPTIONS: o_schema FOR zxeed_param-src_schema NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECT-OPTIONS: o_rfc_b FOR zxeed_param-rfcdest_b NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECTION-SCREEN END OF BLOCK grp02.

SELECTION-SCREEN BEGIN OF BLOCK grp01 WITH FRAME TITLE TEXT-b01.
PARAMETERS: add RADIOBUTTON GROUP oper DEFAULT 'X' USER-COMMAND opr,
            upd RADIOBUTTON GROUP oper,
            del RADIOBUTTON GROUP oper.
SELECTION-SCREEN END OF BLOCK grp01.

AT SELECTION-SCREEN OUTPUT.
  IF del = 'X'.
    p_adv = ''.
  ENDIF.
  IF p_adv = ''.
    LOOP AT SCREEN.
      IF screen-group1 = 'ADV'.
        screen-active = 0.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = 'ADV'.
        screen-active = 1.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF del = 'X'.
    LOOP AT SCREEN.
      IF screen-group1 = 'INS'.
        screen-active = 0.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = 'INS'.
        screen-active = 1.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

START-OF-SELECTION.
* Step 1: Parameter Check of add / update mode
  IF add = 'X' OR upd = 'X'.
    IF o_mtid-low IS INITIAL or o_tabnam-low IS INITIAL.
      WRITE 'MT ID or Table Name shouldn''t be empty, do nothing'(e01).
    ENDIF.

    PERFORM check_rfc_connection USING o_rfc_m-low CHANGING gv_rc_code.
    IF gv_rc_code EQ c_rfc_def_err.
      WRITE 'Main RFC Definition Error, do nothing'(e02).
      RETURN.
    ELSEIF gv_rc_code EQ c_rfc_conn_err.
      WRITE 'Main RFC Connection Error, do nothing'(e03).
      RETURN.
    ENDIF.

    PERFORM check_path USING o_file-low CHANGING gv_rc_code.
    IF gv_rc_code EQ c_path_err.
      WRITE 'Archive Path Error, do nothing'(e06).
      RETURN.
    ENDIF.
  ENDIF.

  IF add = 'X' AND o_mtid-low IS NOT INITIAL. " Add Data
    LOOP AT o_tabnam WHERE low IS NOT INITIAL.
      SELECT SINGLE mt_id FROM zxeed_param
        INTO gs_xeed_param-mt_id
        WHERE mt_id = o_mtid-low
          AND tabname = o_tabnam-low.
      IF sy-subrc IS INITIAL.
        WRITE 'Entry Exists - Do Nothing'(w01).
        CONTINUE. "Entries Exist, No need to do anything
      ENDIF.
      PERFORM update_param.
      APPEND gs_xeed_param TO gt_xeed_param.
      gs_rul_map-mt_id   = o_mtid-low.
      gs_rul_map-tabname = o_tabnam-low.
      gs_rul_map-basisversion = o_basis-low.
      gs_rul_map-event = 'EOT'.
      gs_rul_map-include = 'Z_XEED_LOAD'.
      gs_rul_map-status = '02'.
      CONCATENATE '''' o_mtid-low '''' INTO gs_rul_map-imp_param_1.
      CONCATENATE '''' o_tabnam-low '''' INTO gs_rul_map-imp_param_2.
      APPEND gs_rul_map TO gt_rul_map.
    ENDLOOP.
    IF gt_xeed_param[] IS NOT INITIAL AND gt_rul_map[] IS NOT INITIAL.
      MODIFY zxeed_param FROM TABLE gt_xeed_param.
      MODIFY iuuc_ass_rul_map FROM TABLE gt_rul_map.
      WRITE 'Add Successfully'(s01).
    ENDIF.

  ELSEIF upd = 'X'. " Update Data
    LOOP AT o_tabnam WHERE low IS NOT INITIAL.
      SELECT SINGLE mt_id FROM zxeed_param
        INTO gs_xeed_param-mt_id
        WHERE mt_id = o_mtid-low
          AND tabname = o_tabnam-low.
      IF sy-subrc IS NOT INITIAL.
        WRITE 'Entry Not Exists'(w02).
        CONTINUE. "Entries Exist, No need to do anything
      ENDIF.
      PERFORM update_param.
      APPEND gs_xeed_param TO gt_xeed_param.

    ENDLOOP.
    IF gt_xeed_param[] IS NOT INITIAL.
      MODIFY zxeed_param FROM TABLE gt_xeed_param.
      WRITE 'Update Successfully'(s02).
    ENDIF.

  ELSEIF del = 'X'. " Delete Data
    LOOP AT o_tabnam.
      DELETE FROM zxeed_param
      WHERE mt_id   = o_mtid-low
        AND tabname = o_tabnam-low.

      DELETE FROM iuuc_ass_rul_map
      WHERE mt_id   = o_mtid-low
        AND tabname = o_tabnam-low
        AND include = 'Z_XEED_LOAD'.

    ENDLOOP.
    WRITE 'Entry Deleted Successfully'(s03).
  ENDIF.

* Move Screen data to param data
FORM update_param.
  gs_xeed_param-mt_id = o_mtid-low.
  gs_xeed_param-tabname = o_tabnam-low.
  gs_xeed_param-rfcdest = o_rfc_m-low.
  gs_xeed_param-pathintern = o_file-low.
  gs_xeed_param-rfcdest_b = o_rfc_b-low.
  gs_xeed_param-src_flag = o_srctyp-low.
  gs_xeed_param-frag_size = o_fgsize-low.
  gs_xeed_param-basisversion = o_basis-low.
  IF p_adv = abap_true.
    gs_xeed_param-src_sysid = o_sid-low.
    gs_xeed_param-src_db = o_db-low.
    gs_xeed_param-src_schema = o_schema-low.
  ENDIF.
  IF gs_xeed_param-src_sysid IS INITIAL.
    gs_xeed_param-src_sysid = gs_xeed_param-mt_id.
  ENDIF.
ENDFORM.

* Internet Connection Check
FORM check_rfc_connection USING rfc_name TYPE zl2h_param-rfcdest
                       CHANGING r_code TYPE i .
  DATA: lo_http_client TYPE REF TO if_http_client,
        lv_status      TYPE i.

  cl_http_client=>create_by_destination(
      EXPORTING
        destination              = rfc_name
      IMPORTING
        client                   = lo_http_client
        EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6
    ).
  IF sy-subrc <> 0.
    r_code = 1.
    RETURN.
  ENDIF.

  CALL METHOD lo_http_client->request->set_method( if_http_request=>co_request_method_get ).

  CALL METHOD lo_http_client->send
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
    r_code = 2.
    RETURN.
  ENDIF.

  CALL METHOD lo_http_client->receive
    EXCEPTIONS
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
    r_code = 2.
    RETURN.
  ENDIF.

  CALL METHOD lo_http_client->response->get_status( IMPORTING code = lv_status ).

  IF lv_status NE 200.
    r_code = 2.
    RETURN.
  ENDIF.
ENDFORM.

* Path Check
FORM check_path USING path_name TYPE zl2h_param-pathintern
             CHANGING r_code TYPE i .
  CALL FUNCTION 'FILE_GET_NAME_USING_PATH'
    EXPORTING
      logical_path               = path_name
      file_name                  = 'dummy.txt'
    EXCEPTIONS
      path_not_found             = 1
      missing_parameter          = 2
      operating_system_not_found = 3
      file_system_not_found      = 4
      OTHERS                     = 5.
  IF sy-subrc <> 0.
    r_code = 1.
    RETURN.
  ENDIF.
ENDFORM.

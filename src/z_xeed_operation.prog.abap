*&---------------------------------------------------------------------*
*& Report Z_XEED_OPERATION
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_operation.

TABLES: zxeed_param.

DATA: lt_rul_map    LIKE TABLE OF iuuc_ass_rul_map,
      ls_rul_map    LIKE LINE OF lt_rul_map,
      lt_xeed_param LIKE TABLE OF zxeed_param,
      ls_xeed_param LIKE LINE OF lt_xeed_param.

SELECT-OPTIONS: o_mtid FOR zxeed_param-mt_id NO INTERVALS NO-EXTENSION.
SELECT-OPTIONS: o_tabnam FOR zxeed_param-tabname NO INTERVALS.
SELECT-OPTIONS: o_rfc_m FOR zxeed_param-rfcdest NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_file FOR zxeed_param-pathintern NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_rfc_b FOR zxeed_param-rfcdest_b NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_srctyp FOR zxeed_param-src_flag DEFAULT 'R' NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_fgsize FOR zxeed_param-frag_size DEFAULT 1000 NO INTERVALS NO-EXTENSION MODIF ID ins.
SELECT-OPTIONS: o_basis FOR zxeed_param-basisversion OBLIGATORY DEFAULT '750' NO INTERVALS NO-EXTENSION MODIF ID ins.

PARAMETERS p_adv AS CHECKBOX DEFAULT '' USER-COMMAND adv MODIF ID ins.
SELECTION-SCREEN BEGIN OF BLOCK grp02 WITH FRAME TITLE TEXT-b02.
SELECT-OPTIONS: o_sid FOR zxeed_param-src_sysid NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECT-OPTIONS: o_db FOR zxeed_param-src_db NO INTERVALS NO-EXTENSION MODIF ID adv.
SELECT-OPTIONS: o_schema FOR zxeed_param-src_schema NO INTERVALS NO-EXTENSION MODIF ID adv.
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
  IF add = 'X' AND o_mtid-low IS NOT INITIAL. " Add Data
    LOOP AT o_tabnam WHERE low IS NOT INITIAL.
      SELECT SINGLE mt_id FROM zxeed_param
        INTO ls_xeed_param-mt_id
        WHERE mt_id = o_mtid-low
          AND tabname = o_tabnam-low.
      IF sy-subrc IS INITIAL.
        WRITE 'Entry Exists - Do Nothing'(w01).
        CONTINUE. "Entries Exist, No need to do anything
      ENDIF.
      ls_xeed_param-mt_id = o_mtid-low.
      ls_xeed_param-tabname = o_tabnam-low.
      ls_xeed_param-rfcdest = o_rfc_m-low.
      ls_xeed_param-pathintern = o_file-low.
      ls_xeed_param-rfcdest_b = o_rfc_b-low.
      ls_xeed_param-src_flag = o_srctyp-low.
      ls_xeed_param-frag_size = o_fgsize-low.
      ls_xeed_param-basisversion = o_basis-low.

      APPEND ls_xeed_param TO lt_xeed_param.

      ls_rul_map-mt_id   = o_mtid-low.
      ls_rul_map-tabname = o_tabnam-low.
      ls_rul_map-basisversion = o_basis-low.
      ls_rul_map-event = 'EOT'.
      ls_rul_map-include = 'Z_XEED_LOAD'.
      ls_rul_map-status = '02'.
      CONCATENATE '''' o_mtid-low '''' INTO ls_rul_map-imp_param_1.
      CONCATENATE '''' o_tabnam-low '''' INTO ls_rul_map-imp_param_2.
      APPEND ls_rul_map TO lt_rul_map.
    ENDLOOP.
    IF lt_xeed_param[] IS NOT INITIAL AND lt_rul_map[] IS NOT INITIAL.
      MODIFY zxeed_param FROM TABLE lt_xeed_param.
      MODIFY iuuc_ass_rul_map FROM TABLE lt_rul_map.
      WRITE 'Add Successfully'(s01).
    ENDIF.

  ELSEIF upd = 'X'. " Update Data
    LOOP AT o_tabnam WHERE low IS NOT INITIAL.
      SELECT SINGLE mt_id FROM zxeed_param
        INTO ls_xeed_param-mt_id
        WHERE mt_id = o_mtid-low
          AND tabname = o_tabnam-low.
      IF sy-subrc IS NOT INITIAL.
        WRITE 'Entry Not Exists'(w02).
        CONTINUE. "Entries Exist, No need to do anything
      ENDIF.
      ls_xeed_param-mt_id = o_mtid-low.
      ls_xeed_param-tabname = o_tabnam-low.
      ls_xeed_param-rfcdest = o_rfc_m-low.
      ls_xeed_param-pathintern = o_file-low.
      ls_xeed_param-rfcdest_b = o_rfc_b-low.
      APPEND ls_xeed_param TO lt_xeed_param.

    ENDLOOP.
    IF lt_xeed_param[] IS NOT INITIAL.
      MODIFY zxeed_param FROM TABLE lt_xeed_param.
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

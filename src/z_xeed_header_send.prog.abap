*&---------------------------------------------------------------------*
*& Report  Z_XEED_HEADER_SEND
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_header_send.

TABLES: zxeed_settings.

  DATA: ls_settings    TYPE zxeed_settings,
        lv_current_age TYPE numc10.

SELECT-OPTIONS: o_mtid FOR zxeed_settings-mt_id NO INTERVALS NO-EXTENSION.
SELECT-OPTIONS: o_tabnam FOR zxeed_settings-tabname NO INTERVALS NO-EXTENSION.

START-OF-SELECTION.
  CALL FUNCTION 'Z_XEED_SETTINGS_LOAD'
    EXPORTING
      i_mt_id       = o_mtid-low
      i_tabname     = o_tabnam-low
      i_check_guid  = abap_false
    IMPORTING
      e_settings    = ls_settings
      e_current_age = lv_current_age
    EXCEPTIONS
      not_found     = 1
      OTHERS        = 2.
  IF sy-subrc = 1.
* Implement suitable error handling here
    WRITE 'Replication Setting not found'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'Z_XEED_TABINFO_SEND'
    EXPORTING
      i_settings       = ls_settings
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ELSE.
    WRITE 'Table header has been sent'.
  ENDIF.

*&---------------------------------------------------------------------*
*& Report  Z_XEED_DOWNLOAD_META
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT z_xeed_download_meta.

TABLES: zxeed_settings.

DATA: lt_meta   TYPE TABLE OF zxeed_s_tabinfo,
      lx_meta   TYPE xstring,
      lo_header TYPE REF TO data,
      lo_meta   TYPE REF TO data,
      lv_size   TYPE i,
      lt_data   TYPE STANDARD TABLE OF tbl1024.

SELECT-OPTIONS: o_mtid FOR zxeed_settings-mt_id NO INTERVALS NO-EXTENSION.
SELECT-OPTIONS: o_tabnam FOR zxeed_settings-tabname NO INTERVALS NO-EXTENSION.
PARAMETERS: p_fname TYPE text255.

START-OF-SELECTION.
  CALL FUNCTION 'Z_XEED_TABINFO_GET'
    EXPORTING
      i_mt_id          = o_mtid-low
      i_tabname        = o_tabnam-low
    TABLES
      et_tabinfo       = lt_meta
    EXCEPTIONS
      rfc_error        = 1
      connection_error = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    WRITE 'Error while reading table information'.
    RETURN.
  ENDIF.

  GET REFERENCE OF lt_meta INTO lo_meta.
  CREATE DATA lo_header TYPE string.

  CALL FUNCTION 'Z_XEED_JSON_CONV'
    EXPORTING
      i_header  = lo_header
      i_data    = lo_meta
    IMPORTING
      e_content = lx_meta.

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lx_meta
    IMPORTING
      output_length = lv_size
    TABLES
      binary_tab    = lt_data.

  CALL FUNCTION 'SCMS_DOWNLOAD'
    EXPORTING
      filename = p_fname
*      binary   = 'X'
      frontend = 'X'
    TABLES
      data     = lt_data
    EXCEPTIONS
      error    = 1
      OTHERS   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            RAISING error_file.
  ENDIF.

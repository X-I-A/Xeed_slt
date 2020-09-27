FUNCTION Z_XEED_GET_INILOAD.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     REFERENCE(I_TABNAME) TYPE  TABNAME
*"     REFERENCE(I_SEQ_NO) TYPE  CHAR20
*"  EXPORTING
*"     REFERENCE(E_HEADERS) TYPE  DDFIELDS
*"     REFERENCE(E_DASHBOARD) TYPE  ZXEED_DASHBOARD
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------
  DATA: ls_dashboard TYPE zxeed_dashboard,
        lv_ident     TYPE iuuc_tab_ident,
        lv_tabname   TYPE tabname,
        lt_fields    TYPE ddfields.

  DATA: lrs_descr TYPE REF TO cl_abap_structdescr.

* Get Data From ID Table
  SELECT SINGLE ident INTO lv_ident
    FROM iuuc_tab_id
   WHERE mt_id = i_mt_id
     AND tabname = i_tabname
     AND system_type = 'R'
     AND ident_type  = 'S'.
  IF sy-subrc IS NOT INITIAL.
    RAISE not_found.
  ENDIF.

  SELECT SINGLE * FROM zxeed_dashboard INTO CORRESPONDING FIELDS OF ls_dashboard
    WHERE mt_id       = i_mt_id
      AND tabname     = i_tabname.

* Case 1: First Initial Load
  IF ls_dashboard IS INITIAL.
    ls_dashboard-mt_id     = i_mt_id.
    ls_dashboard-tabname   = i_tabname.
    ls_dashboard-s_ident   = lv_ident.
    ls_dashboard-start_seq = i_seq_no.
    MOVE 1 TO ls_dashboard-current_age.
* Case 2: Initial Load With Structure Changes
  ELSEIF ls_dashboard-s_ident NE lv_ident.
    ls_dashboard-s_ident   = lv_ident.
    ls_dashboard-start_seq = i_seq_no.
    MOVE 1 TO ls_dashboard-current_age.
* Case 3: No Structure Changes
  ELSE.
    e_dashboard = ls_dashboard.
    RETURN. "Just send back the dashboard entry
  ENDIF.

* Case 1-2 : Should sendback the data structure
  CONCATENATE '/1LT/' lv_ident INTO lv_tabname.
  lrs_descr ?= cl_abap_typedescr=>describe_by_name( lv_tabname ).
  e_headers = lrs_descr->get_ddic_field_list( ).
  e_dashboard = ls_dashboard.

ENDFUNCTION.

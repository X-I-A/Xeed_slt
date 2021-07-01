FUNCTION z_xeed_keytab_create .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_FULLTAB) TYPE REF TO  DATA OPTIONAL
*"     REFERENCE(I_KEYLIST) TYPE
*"        IF_BADI_IUUC_REPL_OLO_EXIT=>GTY_T_KEYFIELD OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_KEYTAB) TYPE REF TO  DATA
*"  EXCEPTIONS
*"      NO_DATA
*"----------------------------------------------------------------------
  DATA: lv_line_nb   TYPE i,
        lv_keyvalue  LIKE LINE OF i_keylist,
        lo_line_data TYPE REF TO data,
        lo_line_key  TYPE REF TO data,
        lo_table_des TYPE REF TO cl_abap_structdescr,
        ls_component TYPE abap_compdescr,
        ls_linedef   TYPE lvc_s_fcat,
        lt_linedef   LIKE TABLE OF ls_linedef.

  FIELD-SYMBOLS: <fs_fulltab>  TYPE STANDARD TABLE,
                 <fs_fullline> TYPE any,
                 <fs_keytab>   TYPE STANDARD TABLE,
                 <fs_keyline>  TYPE any.

  ASSIGN i_fulltab->* TO <fs_fulltab>.
  CREATE DATA lo_line_data LIKE LINE OF <fs_fulltab>.
  lo_table_des ?= cl_abap_typedescr=>describe_by_data_ref( lo_line_data ).

  LOOP AT i_keylist INTO lv_keyvalue.
    READ TABLE lo_table_des->components INTO ls_component WITH KEY name = lv_keyvalue.
    IF sy-subrc IS INITIAL.
      CLEAR ls_linedef.
      ls_linedef-fieldname = ls_component-name .
      CASE ls_component-type_kind.
        WHEN 'C'.
          ls_linedef-datatype = 'CHAR'.
        WHEN 'N'.
          ls_linedef-datatype = 'NUMC'.
        WHEN 'D'.
          ls_linedef-datatype = 'DATE'.
        WHEN 'P'.
          ls_linedef-datatype = 'PACK'.
        WHEN OTHERS.
          ls_linedef-datatype = ls_component-type_kind.
      ENDCASE.
      ls_linedef-inttype = ls_component-type_kind.
      ls_linedef-intlen = ls_component-length.
      ls_linedef-decimals = ls_component-decimals.
      APPEND ls_linedef TO lt_linedef.
    ENDIF.
  ENDLOOP.

  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog  = lt_linedef
      i_length_in_byte = 'X' "added by Paul Robert Oct 28, 2009 17:04
    IMPORTING
      ep_table         = e_keytab.

  ASSIGN e_keytab->* TO <fs_keytab>.
  CREATE DATA lo_line_key LIKE LINE OF <fs_keytab>.
  ASSIGN lo_line_key->* TO <fs_keyline>.

  LOOP AT <fs_fulltab> ASSIGNING <fs_fullline>.
    MOVE-CORRESPONDING <fs_fullline> TO <fs_keyline>.
    APPEND <fs_keyline> TO <fs_keytab>.
  ENDLOOP.

ENDFUNCTION.

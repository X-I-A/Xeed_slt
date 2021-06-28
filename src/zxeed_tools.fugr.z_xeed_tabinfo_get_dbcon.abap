FUNCTION z_xeed_tabinfo_get_dbcon .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"     VALUE(I_GUID) TYPE  IUUC_REPL_CONFIG_GUID
*"     VALUE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"  TABLES
*"      ET_TABINFO STRUCTURE  ZXEED_S_TABINFO OPTIONAL
*"  EXCEPTIONS
*"      RFC_ERROR
*"      CONNECTION_ERROR
*"----------------------------------------------------------------------
  DATA: lo_dbcon        TYPE REF TO cl_iuuc_snd_conn,
        lv_tabname      TYPE tabname,
        lt_dd03p        TYPE STANDARD TABLE OF dd03p,
        lv_count_target TYPE i,
        lt_fields       TYPE dmc_database_ddic_fields_tab,
        lt_keyfields    TYPE dmc_database_ddic_fields_tab,
        ls_keyfield     TYPE LINE OF dmc_database_ddic_fields_tab,
        ls_dd03p        LIKE LINE OF lt_dd03p,
        ls_tabinfo      LIKE LINE OF et_tabinfo.

  FIELD-SYMBOLS: <ls_dd03p> TYPE dd03p,
                 <ls_field> TYPE LINE OF dmc_database_ddic_fields_tab.

  TRY.
      lo_dbcon = cl_iuuc_snd_conn_factory=>get_snd_conn( iv_config_guid = i_guid
                                                     iv_mt_id       = i_mt_id ).
      IF lo_dbcon IS BOUND.
        MOVE i_tabname TO lv_tabname.

        CALL METHOD lo_dbcon->get_table_definition
          EXPORTING
            iv_tabname   = lv_tabname
            iv_language  = sy-langu
          IMPORTING
            et_fields    = lt_fields
            et_keyfields = lt_keyfields
            et_dd03p     = lt_dd03p.
      ENDIF.
    CATCH cx_iuuc_db_conn.
      lo_dbcon->close( ).
      RAISE connection_error.
  ENDTRY.
  lo_dbcon->close( ).

  CLEAR lv_count_target.
  DESCRIBE TABLE lt_dd03p LINES lv_count_target.
  lv_count_target = lv_count_target + 1.
  DELETE lt_fields INDEX lv_count_target.
  LOOP AT lt_fields ASSIGNING <ls_field>.
    CLEAR ls_tabinfo.
    ls_tabinfo-tabname = i_tabname.
    ls_tabinfo-fieldname = <ls_field>-col_name.
    ls_tabinfo-position = <ls_field>-position.
    ls_tabinfo-datatype = <ls_field>-data_type.
    IF <ls_field>-data_length IS NOT INITIAL.
      MOVE <ls_field>-data_length TO ls_tabinfo-leng.
    ELSE.
      MOVE <ls_field>-data_precision TO ls_tabinfo-leng.
    ENDIF.
    ls_tabinfo-decimals = |{ CONV string( <ls_field>-decimals ) WIDTH = 6 ALPHA = IN }|.
    READ TABLE lt_keyfields INTO ls_keyfield WITH KEY col_name = <ls_field>-col_name.
    IF sy-subrc = 0.
      ls_tabinfo-keyflag =  abap_true.
    ENDIF.
    IF <ls_field>-is_nullable = abap_true.
      ls_tabinfo-nullable = abap_true.
    ELSE.
      ls_tabinfo-nullable = abap_false.
    ENDIF.
    APPEND ls_tabinfo TO et_tabinfo.
  ENDLOOP.
ENDFUNCTION.

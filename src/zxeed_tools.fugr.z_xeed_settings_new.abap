FUNCTION Z_XEED_SETTINGS_NEW .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     REFERENCE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"  EXPORTING
*"     REFERENCE(E_SETTINGS) TYPE  ZXEED_SETTINGS
*"  EXCEPTIONS
*"      NOT_FOUND
*"      NO_NUMBER_RANGE
*"----------------------------------------------------------------------
  DATA: ls_nriv     TYPE nriv,
        ls_default  TYPE zxeed_default,
        lv_new_guid TYPE zxeed_settings-guid.

  DATA: lv_timestamp  TYPE timestampl,
        lv_seq_no_tmp TYPE char32,
        lv_seq_no     TYPE char20.

* Primary Key
  MOVE i_mt_id TO e_settings-mt_id.
  MOVE i_tabname TO e_settings-tabname.

* Default settings
  SELECT SINGLE * INTO ls_default
    FROM zxeed_default
   WHERE mt_id = i_mt_id.
  IF sy-subrc IS NOT INITIAL.
    SELECT SINGLE * INTO ls_default
      FROM zxeed_default.
    MOVE i_mt_id TO ls_default-mt_id.
    IF sy-subrc IS NOT INITIAL.
      RAISE not_found.
    ENDIF.
  ENDIF.
  MOVE-CORRESPONDING ls_default TO e_settings.

* Guid definition
  SELECT SINGLE guid INTO lv_new_guid
    FROM dmc_cobj
   WHERE source_id = i_mt_id
     AND cobj_alias = i_tabname.
  IF sy-subrc IS NOT INITIAL.
    RAISE not_found.
  ENDIF.
  MOVE lv_new_guid TO e_settings-guid.

* Reserve an available number range
  SELECT SINGLE * INTO ls_nriv
    FROM nriv
   WHERE object LIKE 'ZXEED%'
     AND nrlevel = 0.
  IF sy-subrc IS NOT INITIAL.
    RAISE no_number_range.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = ls_nriv-nrrangenr
      object      = ls_nriv-object
    IMPORTING
      number      = ls_nriv-nrlevel.

  MOVE ls_nriv-object TO e_settings-number_obj.
  MOVE ls_nriv-nrrangenr TO e_settings-number_nr.

* Get Sequence Number (Timestamp)
  GET TIME STAMP FIELD lv_timestamp.
  MOVE lv_timestamp TO lv_seq_no_tmp.
  CONDENSE lv_seq_no_tmp.
  CONCATENATE lv_seq_no_tmp(14) lv_seq_no_tmp+15(6) INTO e_settings-start_seq.

  MODIFY zxeed_settings FROM e_settings.
ENDFUNCTION.

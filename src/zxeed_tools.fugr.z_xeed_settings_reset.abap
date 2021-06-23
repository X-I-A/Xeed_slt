FUNCTION Z_XEED_SETTINGS_RESET .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     REFERENCE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"     REFERENCE(I_GUID) TYPE  DMC_CONVOBJECT_GUID
*"  CHANGING
*"     REFERENCE(E_SETTINGS) TYPE  ZXEED_SETTINGS
*"  EXCEPTIONS
*"      NOT_FOUND
*"      NO_NUMBER_RANGE
*"----------------------------------------------------------------------
  DATA: ls_nriv     TYPE nriv,
        lv_new_no   TYPE zxeed_d_nbrang,
        lv_new_guid TYPE zxeed_settings-guid.

  DATA: lv_timestamp  TYPE timestampl,
        lv_seq_no_tmp TYPE char32,
        lv_seq_no     TYPE char20.


* Guid definition
  SELECT SINGLE guid INTO lv_new_guid
    FROM dmc_cobj
   WHERE source_id = i_mt_id
     AND cobj_alias = i_tabname.
  IF sy-subrc IS NOT INITIAL.
    RAISE not_found.
  ENDIF.
  MOVE lv_new_guid TO e_settings-guid.

* Reset NRIV
  MOVE e_settings-number_nr TO lv_new_no.
  lv_new_no = lv_new_no * 10000000000 + 1.
  UPDATE NRIV SET nrlevel = lv_new_no
   WHERE object = e_settings-number_obj
     AND nrrangenr = e_settings-number_nr.

* Get Sequence Number (Timestamp)
  GET TIME STAMP FIELD lv_timestamp.
  MOVE lv_timestamp TO lv_seq_no_tmp.
  CONDENSE lv_seq_no_tmp.
  CONCATENATE lv_seq_no_tmp(14) lv_seq_no_tmp+15(6) INTO e_settings-start_seq.

  MODIFY zxeed_settings FROM e_settings.
ENDFUNCTION.

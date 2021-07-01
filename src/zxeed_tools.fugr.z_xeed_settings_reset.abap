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

* Lock before continue (lock by default = 5 seconds, we will wait 1 minutes)
  DO 12 TIMES.
    CALL FUNCTION 'ENQUEUE_EZXEED'
      EXPORTING
        mt_id          = i_mt_id
        tabname        = i_tabname
        _wait          = abap_true
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc = 1.
* Wait for the lock
      CONTINUE.
    ELSEIF sy-subrc > 1.
* Real exception code here
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.

* Should retry to make sure that nothing has been changed during the lock acquire
  SELECT SINGLE * INTO e_settings
    FROM zxeed_settings
   WHERE mt_id   = i_mt_id
     AND tabname = i_tabname
     AND guid    = i_guid.
  IF sy-subrc IS INITIAL.
* Entry found with the new guid, means entries has been changed
    RETURN.
  ENDIF.

* Guid definition
  MOVE i_guid TO e_settings-guid.

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

* Unlock at the end
  CALL FUNCTION 'DEQUEUE_EZXEED'
    EXPORTING
      mt_id   = i_mt_id
      tabname = i_tabname.
ENDFUNCTION.

FUNCTION z_xeed_settings_load .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_MT_ID) TYPE  DMC_MT_IDENTIFIER
*"     REFERENCE(I_TABNAME) TYPE  DMC_DB_TABNAME
*"     REFERENCE(I_CHECK_GUID) TYPE  BOOLE_D DEFAULT ABAP_TRUE
*"  EXPORTING
*"     REFERENCE(E_SETTINGS) TYPE  ZXEED_SETTINGS
*"     REFERENCE(E_CURRENT_AGE) TYPE  NUMC10
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------
  DATA: ls_settings TYPE zxeed_settings,
        lv_new_guid TYPE zxeed_settings-guid.

  SELECT SINGLE * INTO ls_settings
    FROM zxeed_settings
   WHERE mt_id = i_mt_id
     AND tabname = i_tabname.
  IF sy-subrc IS NOT INITIAL.
* Case 1: Nothing is found, should create a new
    CALL FUNCTION 'Z_XEED_SETTINGS_NEW'
      EXPORTING
        i_mt_id         = i_mt_id
        i_tabname       = i_tabname
      IMPORTING
        e_settings      = e_settings
      EXCEPTIONS
        not_found       = 1
        no_number_range = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ELSEIF i_check_guid EQ abap_true.

    SELECT SINGLE cobj_guid INTO lv_new_guid
      FROM dmc_mt_tables
     WHERE id = i_mt_id
       AND tabname = i_tabname.
    IF sy-subrc IS NOT INITIAL.
* Case 2: Nothing is found => Abnormal
      RAISE not_found.
    ELSEIF lv_new_guid EQ ls_settings-guid.
* Case 3: Old guid == New Guid => It means the same replication
      MOVE-CORRESPONDING ls_settings TO e_settings.
    ELSE.
* Case 4: A new replication is started.
      CALL FUNCTION 'Z_XEED_SETTINGS_RESET'
        EXPORTING
          i_mt_id         = i_mt_id
          i_tabname       = i_tabname
          i_guid          = lv_new_guid
        CHANGING
          e_settings      = ls_settings
        EXCEPTIONS
          not_found       = 1
          no_number_range = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      MOVE-CORRESPONDING ls_settings TO e_settings.
    ENDIF.
  ELSE.
* Case 5: Normal replication => Assumpting that the guid is not changed
    MOVE-CORRESPONDING ls_settings TO e_settings.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = e_settings-number_nr
      object      = e_settings-number_obj
    IMPORTING
      number      = e_current_age.

ENDFUNCTION.

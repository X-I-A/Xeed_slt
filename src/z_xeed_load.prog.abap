*&---------------------------------------------------------------------*
*&  Include           Z_XEED_LOAD
*&---------------------------------------------------------------------*
*& Prequistes: Transaction LTRS:
*& Parameter 1 = SYSID
*& Parameter 2 = Table Name
*&---------------------------------------------------------------------*
DATA: lo_data      TYPE REF TO data,
      lv_name(40)  TYPE c,
      lv_seq_no    TYPE numc10,
      lv_table(30) TYPE c,
      lv_mt_id     TYPE dmc_mt_identifier.

FIELD-SYMBOLS: <fs_data_src> TYPE ANY TABLE,
               <fs_data_ori> TYPE ANY TABLE.

* Get Table Reference (Source Table Only)
CONCATENATE '<it_s_' i_p2 '>' INTO lv_name.
ASSIGN (lv_name) TO <fs_data_src>.
IF sy-subrc IS NOT INITIAL.
  RETURN. " Should Add Error Log
ENDIF.

* Get Data
CREATE DATA lo_data LIKE <fs_data_src>.
ASSIGN lo_data->* TO <fs_data_ori>.
MOVE-CORRESPONDING <fs_data_src> TO <fs_data_ori>.

* Call Treatement Process
CALL FUNCTION 'Z_XEED_COCKPIT'
*IN BACKGROUND TASK
*  AS SEPARATE UNIT
  EXPORTING
    i_data    = lo_data
    i_mt_id   = i_p1
    i_tabname = i_p2.

*&---------------------------------------------------------------------*
*&  Include           Z_XEED_LOAD
*&---------------------------------------------------------------------*
*& Prequistes: Transaction LTRS:
*& Parameter 1 = SYSID
*& Parameter 2 = Table Name
*&---------------------------------------------------------------------*
DATA: lo_data      TYPE REF TO data,
      lv_name(40)  TYPE c,
      lv_table(30) TYPE c,
      lv_mt_id     TYPE dmc_mt_identifier,
      ls_param     TYPE zxeed_param.

FIELD-SYMBOLS: <fs_data_src> TYPE ANY TABLE,
               <fs_data_ori> TYPE ANY TABLE.

* Get the parameter
SELECT SINGLE * FROM zxeed_param
  INTO CORRESPONDING FIELDS OF ls_param.
IF sy-subrc IS NOT INITIAL.
  RETURN. " Something goes wrong, do nothing.
ENDIF.

* Get Table Reference (Source Table)
IF ls_param-src_flag = 'S'.
  CONCATENATE '<it_s_' i_p2 '>' INTO lv_name.
ELSEIF ls_param-src_flag = 'R'.
  CONCATENATE '<it_r_' i_p2 '>' INTO lv_name.
ELSE.
  RETURN. " Something goes wrong, do nothing.
ENDIF.

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
  EXPORTING
    i_param   = ls_param
    i_data    = lo_data
    i_mt_id   = i_p1
    i_tabname = i_p2.

FUNCTION z_xeed_fill_ranges.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_NB_OBJECT) TYPE  NROBJ
*"  EXCEPTIONS
*"      HORS_SCOPE
*"----------------------------------------------------------------------
  DATA: lt_tnro TYPE TABLE OF tnro,
        ls_nriv TYPE nriv,
        lv_nbrg TYPE numc2 VALUE 0.

* Step 1: Check input
  IF i_nb_object+0(5) NE 'ZXEED'.
    RAISE hors_scope.
  ENDIF.

  SELECT * FROM tnro INTO TABLE lt_tnro WHERE object EQ i_nb_object.
  IF sy-subrc IS NOT INITIAL.
    RAISE hors_scope.
  ENDIF.

* Step 2: Update the table => No need to worry about the performance, this is a rarely used function
  DO 100 TIMES.
    CLEAR ls_nriv.
    MOVE i_nb_object TO ls_nriv-object.
    MOVE lv_nbrg TO ls_nriv-nrrangenr.
    SELECT single * INTO CORRESPONDING FIELDS OF ls_nriv
      FROM nriv
     WHERE object EQ ls_nriv-object
       AND nrrangenr EQ ls_nriv-nrrangenr.
    IF sy-subrc IS NOT INITIAL. "Not found
      CONCATENATE ls_nriv-nrrangenr '0000000000' INTO ls_nriv-fromnumber.
      CONCATENATE ls_nriv-nrrangenr '9999999999' INTO ls_nriv-tonumber.
      INSERT INTO nriv VALUES ls_nriv.
    ENDIF.
    lv_nbrg = lv_nbrg + 1.
  ENDDO.

ENDFUNCTION.

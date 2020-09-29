FUNCTION z_xeed_get_data_frag_size.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_DATA) TYPE REF TO  DATA
*"     REFERENCE(I_SIZE_LIMIT) TYPE  I
*"  EXPORTING
*"     REFERENCE(E_FRAG_SIZE) TYPE  I
*"----------------------------------------------------------------------
  FIELD-SYMBOLS: <fs_data_tab>    TYPE ANY TABLE,
                 <fs_data_sample> TYPE ANY TABLE,
                 <fs_data_line>   TYPE any.

  DATA: lv_total_nb  TYPE i,
        lv_sample_nb TYPE i,
        lv_frag_size TYPE i.
  DATA: lo_data_sample TYPE REF TO data.
  DATA: lv_json    TYPE string,
        lv_gzip    TYPE xstring,
        lv_content TYPE string.

  ASSIGN i_data->* TO <fs_data_tab>.

* Get total_nb
  DESCRIBE TABLE <fs_data_tab> LINES lv_total_nb.

* Case 1: A Small Total Number. No need to go further
  IF lv_total_nb <= 100.
    RETURN.
  ENDIF.

* Case 2: First Root Line as Sampling Fields.
  lv_sample_nb = lv_total_nb ** ( 1 / 2 ).

  CREATE DATA lo_data_sample LIKE <fs_data_tab>.
  ASSIGN lo_data_sample->* TO <fs_data_sample>.

  LOOP AT <fs_data_tab> ASSIGNING <fs_data_line>.
    IF sy-tabix MOD lv_sample_nb NE 1.
      CONTINUE.
    ENDIF.
    INSERT <fs_data_line> INTO TABLE <fs_data_sample>.
  ENDLOOP.

  lv_json = /ui2/cl_json=>serialize( data = lo_data_sample compress = abap_true pretty_name = /ui2/cl_json=>pretty_mode-none ).
  CALL METHOD cl_abap_gzip=>compress_text
    EXPORTING
      text_in  = lv_json
    IMPORTING
      gzip_out = lv_gzip.

* 1. The final coding will be base64 => so 133% of zipped size => reduce 1024 to 768
* 2. lv_sample_nb could be lv_sample_nb + 1, however, no need to be so precised
* 3. Reduce 768 to 512 to reduce the potential overflow
  lv_frag_size = i_size_limit * 512 / ( xstrlen( lv_gzip ) / lv_sample_nb ).
  IF lv_frag_size >= lv_total_nb.
    RETURN.
  ELSE.
    e_frag_size = lv_frag_size.
  ENDIF.
ENDFUNCTION.

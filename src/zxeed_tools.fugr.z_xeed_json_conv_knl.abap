FUNCTION Z_XEED_JSON_CONV_KNL.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_HEADER) TYPE REF TO  DATA
*"     REFERENCE(I_DATA) TYPE REF TO  DATA
*"  EXPORTING
*"     REFERENCE(E_CONTENT) TYPE  XSTRING
*"  EXCEPTIONS
*"      CONV_FAILED
*"----------------------------------------------------------------------
  FIELD-SYMBOLS: <fs_header>   TYPE any,
                 <fs_data_tab> TYPE any.

  DATA(lo_json_writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json no_empty_elements = 'X' ).

  ASSIGN i_header->* TO <fs_header>.
  ASSIGN i_data->* TO <fs_data_tab>.

  TRY.
      CALL TRANSFORMATION id
            SOURCE header = <fs_header> data = <fs_data_tab>
            RESULT XML lo_json_writer.
      e_content = lo_json_writer->get_output( ).
    CATCH cx_root.
      RAISE conv_failed.
  ENDTRY.

ENDFUNCTION.

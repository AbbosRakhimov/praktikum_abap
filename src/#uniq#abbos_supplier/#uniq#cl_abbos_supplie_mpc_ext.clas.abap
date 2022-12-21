class /UNIQ/CL_ABBOS_SUPPLIE_MPC_EXT definition
  public
  inheriting from /UNIQ/CL_ABBOS_SUPPLIE_MPC
  create public .

public section.

  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS /UNIQ/CL_ABBOS_SUPPLIE_MPC_EXT IMPLEMENTATION.


  METHOD define.

    super->define( ).

    DATA: lo_entity   TYPE REF TO /iwbep/if_mgw_odata_entity_typ,

          lo_property TYPE REF TO /iwbep/if_mgw_odata_property.


    lo_entity = model->get_entity_type( iv_entity_name = 'Product' ).


    IF lo_entity IS BOUND.

      lo_entity->get_cmplx_type_property( iv_name = 'Image' )->get_complex_type( )->get_property( iv_property_name = 'Mimitype' )->set_as_content_type( ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.

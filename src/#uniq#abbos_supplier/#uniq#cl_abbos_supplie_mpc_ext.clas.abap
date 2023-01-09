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

*    DATA io_tech_request_context  TYPE REF TO /iwbep/if_mgw_req_entityset.

*    DATA(lt_nav_path) = io_tech_request_context->get_navigation_path( ).
*
    DATA: lo_entity   TYPE REF TO /iwbep/if_mgw_odata_entity_typ,
          lo_entityb  TYPE REF TO /iwbep/if_mgw_odata_entity_typ,
          lo_property TYPE REF TO /iwbep/if_mgw_odata_property.


    lo_entity = model->get_entity_type( iv_entity_name = 'Product' ).

    lo_entityb = model->get_entity_type( iv_entity_name = 'Product_Image' ).


    IF lo_entity IS BOUND.

      lo_entity->get_property( 'Mimitype' )->set_as_content_type( ).
*      lo_entity->get_cmplx_type_property( iv_name = 'Image' )->get_complex_type( )->get_property( iv_property_name = 'Mimitype' )->set_as_content_type( ).

    ENDIF.

    IF lo_entityb IS BOUND.
      lo_entityb->get_property( 'Mimitype' )->set_as_content_type( ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.

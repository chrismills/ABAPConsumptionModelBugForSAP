CLASS zcl_test_read_attach DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_test_read_attach IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    "This can be exected directly on the dev-dev tenant as no data is read from the S4 system DB and no data is persisted.
    "Just run as a console app.

    DATA:
      lo_http_client   TYPE REF TO if_web_http_client,
      lo_resource      type ref to /iwbep/if_cp_resource_function,
      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request        type ref to /iwbep/if_cp_request_function  ,
      lo_response      TYPE REF TO /iwbep/if_cp_response_function.

      data function_params type zattachment_api_consumption=>tys_parameters_3.
      data function_resp type zattachment_api_consumption=>tyt_attachment_content.

    TRY.
        "This is a Postman mock server URL - No auth is required and it will respond with different payloads depending on the input.
        data(lo_destination) = cl_http_destination_provider=>create_by_url( 'https://79a1e9d8-a01f-4fcc-b18f-e0707c3adb52.mock.pstmn.io'  ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).


        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
          EXPORTING
             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                 proxy_model_id      = 'ZATTACHMENT_API_CONSUMPTION'
                                                 proxy_model_version = '0001' )
            io_http_client             = lo_http_client
            iv_relative_service_root   = '/sap/opu/odata/sap/API_CV_ATTACHMENT_SRV/' ).

        ASSERT lo_http_client IS BOUND.

        lo_resource = lo_client_proxy->create_resource_for_function( iv_function_name     = zattachment_api_consumption=>gcs_function_import-get_all_originals ).

         "If you send this parameter an exception will be raised in the SAP JSON processing code (/IWCOR/CL_DS_EP_READER_JSON)
        function_params = value #(
            linked_sapobject_key = '00010000272'
            business_object_type_name = 'PMQMEL' ).

        "If you comment the above and send the below it will work
*        function_params = value #(
*            linked_sapobject_key = '00010000273'
*            business_object_type_name = 'PMQMEL' ).

        lo_resource->set_parameter( function_params ).

        lo_request = lo_resource->create_request(  ).
        lo_response = lo_resource->create_request(  )->execute( 'GET' ).

        lo_response->get_business_data( importing ea_response_data = function_resp ).
        out->write( 'Sucessfully called api' ).
        out->write( |Total records { lines( function_resp ) }| ).
        out->write( function_resp ).

      CATCH cx_root INTO DATA(lx_exception).
        out->write( 'Exception Occured' ).
        out->write( lx_exception ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

# encoding: utf-8
# Code generated by Microsoft (R) AutoRest Code Generator.
# Changes may cause incorrect behavior and will be lost if the code is
# regenerated.

module Haipa::Client::Compute::V1_0
  module Models
    #
    # Model object.
    #
    #
    class ODataValueIEnumerableOperation

      include Haipa::Client

      # @return [Array<Operation>]
      attr_accessor :value


      #
      # Mapper for ODataValueIEnumerableOperation class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'ODataValue[IEnumerable[Operation]]',
          type: {
            name: 'Composite',
            class_name: 'ODataValueIEnumerableOperation',
            model_properties: {
              value: {
                client_side_validation: true,
                required: false,
                serialized_name: 'value',
                type: {
                  name: 'Sequence',
                  element: {
                      client_side_validation: true,
                      required: false,
                      serialized_name: 'OperationElementType',
                      type: {
                        name: 'Composite',
                        class_name: 'Operation'
                      }
                  }
                }
              }
            }
          }
        }
      end
    end
  end
end
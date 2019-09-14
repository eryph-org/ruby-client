# encoding: utf-8
# Code generated by Microsoft (R) AutoRest Code Generator.
# Changes may cause incorrect behavior and will be lost if the code is
# regenerated.

module Haipa::Client::Compute::V1
  module Models
    #
    # Model object.
    #
    #
    class MachineSubnetConfig

      include MsRestAzure

      # @return [String]
      attr_accessor :type


      #
      # Mapper for MachineSubnetConfig class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'MachineSubnetConfig',
          type: {
            name: 'Composite',
            class_name: 'MachineSubnetConfig',
            model_properties: {
              type: {
                client_side_validation: true,
                required: false,
                serialized_name: 'type',
                type: {
                  name: 'String'
                }
              }
            }
          }
        }
      end
    end
  end
end

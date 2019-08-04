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
    class VirtualMachineProvisioningConfig

      include Haipa::Client

      # @return [String]
      attr_accessor :hostname

      # @return
      attr_accessor :user_data


      #
      # Mapper for VirtualMachineProvisioningConfig class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'VirtualMachineProvisioningConfig',
          type: {
            name: 'Composite',
            class_name: 'VirtualMachineProvisioningConfig',
            model_properties: {
              hostname: {
                client_side_validation: true,
                required: false,
                serialized_name: 'hostname',
                type: {
                  name: 'String'
                }
              },
              user_data: {
                client_side_validation: true,
                required: false,
                serialized_name: 'userData',
                type: {
                  name: 'Object'
                }
              }
            }
          }
        }
      end
    end
  end
end

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
    class VirtualMachineMemoryConfig

      include Haipa::Client

      # @return [Integer]
      attr_accessor :startup

      # @return [Integer]
      attr_accessor :minimum

      # @return [Integer]
      attr_accessor :maximum


      #
      # Mapper for VirtualMachineMemoryConfig class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'VirtualMachineMemoryConfig',
          type: {
            name: 'Composite',
            class_name: 'VirtualMachineMemoryConfig',
            model_properties: {
              startup: {
                client_side_validation: true,
                required: false,
                serialized_name: 'startup',
                type: {
                  name: 'Number'
                }
              },
              minimum: {
                client_side_validation: true,
                required: false,
                serialized_name: 'minimum',
                type: {
                  name: 'Number'
                }
              },
              maximum: {
                client_side_validation: true,
                required: false,
                serialized_name: 'maximum',
                type: {
                  name: 'Number'
                }
              }
            }
          }
        }
      end
    end
  end
end

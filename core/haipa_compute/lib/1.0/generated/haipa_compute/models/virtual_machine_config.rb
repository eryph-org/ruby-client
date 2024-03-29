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
    class VirtualMachineConfig

      include Haipa::Client

      # @return [String]
      attr_accessor :slug

      # @return [String]
      attr_accessor :data_store

      # @return [VirtualMachineCpuConfig]
      attr_accessor :cpu

      # @return [VirtualMachineMemoryConfig]
      attr_accessor :memory

      # @return [Array<VirtualMachineDriveConfig>]
      attr_accessor :drives

      # @return [Array<VirtualMachineNetworkAdapterConfig>]
      attr_accessor :network_adapters


      #
      # Mapper for VirtualMachineConfig class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'VirtualMachineConfig',
          type: {
            name: 'Composite',
            class_name: 'VirtualMachineConfig',
            model_properties: {
              slug: {
                client_side_validation: true,
                required: false,
                serialized_name: 'slug',
                type: {
                  name: 'String'
                }
              },
              data_store: {
                client_side_validation: true,
                required: false,
                serialized_name: 'dataStore',
                type: {
                  name: 'String'
                }
              },
              cpu: {
                client_side_validation: true,
                required: false,
                serialized_name: 'cpu',
                type: {
                  name: 'Composite',
                  class_name: 'VirtualMachineCpuConfig'
                }
              },
              memory: {
                client_side_validation: true,
                required: false,
                serialized_name: 'memory',
                type: {
                  name: 'Composite',
                  class_name: 'VirtualMachineMemoryConfig'
                }
              },
              drives: {
                client_side_validation: true,
                required: false,
                serialized_name: 'drives',
                type: {
                  name: 'Sequence',
                  element: {
                      client_side_validation: true,
                      required: false,
                      serialized_name: 'VirtualMachineDriveConfigElementType',
                      type: {
                        name: 'Composite',
                        class_name: 'VirtualMachineDriveConfig'
                      }
                  }
                }
              },
              network_adapters: {
                client_side_validation: true,
                required: false,
                serialized_name: 'networkAdapters',
                type: {
                  name: 'Sequence',
                  element: {
                      client_side_validation: true,
                      required: false,
                      serialized_name: 'VirtualMachineNetworkAdapterConfigElementType',
                      type: {
                        name: 'Composite',
                        class_name: 'VirtualMachineNetworkAdapterConfig'
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

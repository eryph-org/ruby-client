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
    class Agent

      include MsRestAzure

      # @return [String]
      attr_accessor :name

      # @return [Array<AgentNetwork>]
      attr_accessor :networks

      # @return [Array<Machine>]
      attr_accessor :machines


      #
      # Mapper for Agent class as Ruby Hash.
      # This will be used for serialization/deserialization.
      #
      def self.mapper()
        {
          client_side_validation: true,
          required: false,
          serialized_name: 'Agent',
          type: {
            name: 'Composite',
            class_name: 'Agent',
            model_properties: {
              name: {
                client_side_validation: true,
                required: false,
                serialized_name: 'name',
                type: {
                  name: 'String'
                }
              },
              networks: {
                client_side_validation: true,
                required: false,
                serialized_name: 'networks',
                type: {
                  name: 'Sequence',
                  element: {
                      client_side_validation: true,
                      required: false,
                      serialized_name: 'AgentNetworkElementType',
                      type: {
                        name: 'Composite',
                        class_name: 'AgentNetwork'
                      }
                  }
                }
              },
              machines: {
                client_side_validation: true,
                required: false,
                serialized_name: 'machines',
                type: {
                  name: 'Sequence',
                  element: {
                      client_side_validation: true,
                      required: false,
                      serialized_name: 'MachineElementType',
                      type: {
                        name: 'Composite',
                        class_name: 'Machine'
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

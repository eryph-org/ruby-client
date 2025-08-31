require 'spec_helper'

RSpec.describe Eryph::Compute::OperationResult do
  let(:operation_id) { 'test-op-123' }
  let(:client) { double('Client') }
  let(:catlets_api) { double('CatletsApi') }
  let(:virtual_disks_api) { double('VirtualDisksApi') }
  let(:virtual_networks_api) { double('VirtualNetworksApi') }
  let(:logger) { double('Logger', debug: nil, warn: nil, error: nil, info: nil) }

  let(:basic_operation) do
    double('Operation',
      id: operation_id,
      status: 'Completed',
      status_message: 'Success',
      log_entries: [],
      tasks: [],
      resources: []
    )
  end

  subject { described_class.new(basic_operation, client) }

  before do
    allow(client).to receive(:catlets).and_return(catlets_api)
    allow(client).to receive(:virtual_disks).and_return(virtual_disks_api)  
    allow(client).to receive(:virtual_networks).and_return(virtual_networks_api)
    allow(client).to receive(:logger).and_return(logger)
  end

  describe '#initialize' do
    it 'creates a new result with operation and client' do
      result = described_class.new(basic_operation, client)
      expect(result.operation).to eq(basic_operation)
      expect(result.instance_variable_get(:@client)).to eq(client)
    end
  end

  describe '#status' do
    it 'returns operation status' do
      expect(subject.status).to eq('Completed')
    end
  end

  describe '#status_message' do
    it 'returns operation status message' do
      expect(subject.status_message).to eq('Success')
    end
  end

  describe '#id' do
    it 'returns operation id' do
      expect(subject.id).to eq(operation_id)
    end
  end

  describe '#completed?' do
    it 'returns true when status is Completed' do
      expect(subject.completed?).to be true
    end

    it 'returns false when status is not Completed' do
      running_operation = double('Operation', status: 'Running')
      result = described_class.new(running_operation, client)
      expect(result.completed?).to be false
    end
  end

  describe '#failed?' do
    it 'returns false when status is not Failed' do
      expect(subject.failed?).to be false
    end

    it 'returns true when status is Failed' do
      failed_operation = double('Operation', status: 'Failed')
      result = described_class.new(failed_operation, client)
      expect(result.failed?).to be true
    end
  end

  describe '#resources' do
    it 'returns empty array when no resources' do
      expect(subject.resources).to eq([])
    end

    it 'returns operation resources when available' do
      resource1 = double('Resource', resource_type: 'Catlet', resource_id: 'cat-1')
      resource2 = double('Resource', resource_type: 'VirtualDisk', resource_id: 'disk-1')
      operation_with_resources = double('Operation', 
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        resources: [resource1, resource2]
      )
      
      result = described_class.new(operation_with_resources, client)
      expect(result.resources).to eq([resource1, resource2])
    end
  end

  describe '#log_entries' do
    it 'returns empty array when no log entries' do
      expect(subject.log_entries).to eq([])
    end

    it 'returns operation log entries when available' do
      log1 = double('LogEntry', message: 'First log')
      log2 = double('LogEntry', message: 'Second log')
      operation_with_logs = double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        log_entries: [log1, log2]
      )
      
      result = described_class.new(operation_with_logs, client)
      expect(result.log_entries).to eq([log1, log2])
    end
  end

  describe '#tasks' do
    it 'returns empty array when no tasks' do
      expect(subject.tasks).to eq([])
    end

    it 'returns operation tasks when available' do
      task1 = double('Task', name: 'First task')
      task2 = double('Task', name: 'Second task')
      operation_with_tasks = double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        tasks: [task1, task2]
      )
      
      result = described_class.new(operation_with_tasks, client)
      expect(result.tasks).to eq([task1, task2])
    end
  end

  describe 'resource extraction methods' do
    let(:catlet_resource) { double('Resource', resource_type: 'Catlet', resource_id: 'catlet-123') }
    let(:disk_resource) { double('Resource', resource_type: 'VirtualDisk', resource_id: 'disk-456') }
    let(:network_resource) { double('Resource', resource_type: 'VirtualNetwork', resource_id: 'net-789') }
    
    let(:operation_with_resources) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        resources: [catlet_resource, disk_resource, network_resource]
      )
    end

    subject { described_class.new(operation_with_resources, client) }

    describe '#catlets' do
      it 'fetches and returns catlet resources' do
        catlet_data = { 'id' => 'catlet-123', 'name' => 'test-catlet' }
        expect(catlets_api).to receive(:catlets_get).with('catlet-123').and_return(catlet_data)
        
        catlets = subject.catlets
        expect(catlets).to eq([catlet_data])
      end

      it 'caches fetched catlets' do
        catlet_data = { 'id' => 'catlet-123', 'name' => 'test-catlet' }
        expect(catlets_api).to receive(:catlets_get).with('catlet-123').once.and_return(catlet_data)
        
        # Call twice, should only fetch once
        first_call = subject.catlets
        second_call = subject.catlets
        
        expect(first_call).to eq([catlet_data])
        expect(second_call).to eq([catlet_data])
      end

      it 'handles API errors gracefully' do
        expect(catlets_api).to receive(:catlets_get).with('catlet-123').and_raise(StandardError, 'API Error')
        expect(logger).to receive(:error).with(/Error fetching catlet catlet-123: API Error/)
        
        catlets = subject.catlets
        expect(catlets).to eq([])
      end

      it 'returns empty array when no catlet resources' do
        operation_without_catlets = double('Operation',
          id: operation_id,
          status: 'Completed',
          status_message: 'Success',
          resources: [disk_resource, network_resource] # No catlets
        )
        
        result = described_class.new(operation_without_catlets, client)
        expect(result.catlets).to eq([])
      end
    end

    describe '#virtual_disks' do
      it 'fetches and returns virtual disk resources' do
        disk_data = { 'id' => 'disk-456', 'name' => 'test-disk' }
        expect(virtual_disks_api).to receive(:virtual_disks_get).with('disk-456').and_return(disk_data)
        
        disks = subject.virtual_disks
        expect(disks).to eq([disk_data])
      end

      it 'caches fetched virtual disks' do
        disk_data = { 'id' => 'disk-456', 'name' => 'test-disk' }
        expect(virtual_disks_api).to receive(:virtual_disks_get).with('disk-456').once.and_return(disk_data)
        
        # Call twice, should only fetch once
        first_call = subject.virtual_disks
        second_call = subject.virtual_disks
        
        expect(first_call).to eq([disk_data])
        expect(second_call).to eq([disk_data])
      end

      it 'handles API errors gracefully' do
        expect(virtual_disks_api).to receive(:virtual_disks_get).with('disk-456').and_raise(StandardError, 'API Error')
        expect(logger).to receive(:error).with(/Error fetching virtualdisk disk-456: API Error/)
        
        disks = subject.virtual_disks
        expect(disks).to eq([])
      end
    end

    describe '#virtual_networks' do
      it 'fetches and returns virtual network resources' do
        network_data = { 'id' => 'net-789', 'name' => 'test-network' }
        expect(virtual_networks_api).to receive(:virtual_networks_get).with('net-789').and_return(network_data)
        
        networks = subject.virtual_networks
        expect(networks).to eq([network_data])
      end

      it 'caches fetched virtual networks' do
        network_data = { 'id' => 'net-789', 'name' => 'test-network' }
        expect(virtual_networks_api).to receive(:virtual_networks_get).with('net-789').once.and_return(network_data)
        
        # Call twice, should only fetch once
        first_call = subject.virtual_networks
        second_call = subject.virtual_networks
        
        expect(first_call).to eq([network_data])
        expect(second_call).to eq([network_data])
      end

      it 'handles API errors gracefully' do
        expect(virtual_networks_api).to receive(:virtual_networks_get).with('net-789').and_raise(StandardError, 'API Error')
        expect(logger).to receive(:error).with(/Error fetching virtualnetwork net-789: API Error/)
        
        networks = subject.virtual_networks
        expect(networks).to eq([])
      end
    end
  end

  describe '#find_resources_by_type' do
    let(:catlet_resource1) { double('Resource', resource_type: 'Catlet', resource_id: 'cat-1') }
    let(:catlet_resource2) { double('Resource', resource_type: 'Catlet', resource_id: 'cat-2') }
    let(:disk_resource) { double('Resource', resource_type: 'VirtualDisk', resource_id: 'disk-1') }
    
    let(:mixed_operation) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        resources: [catlet_resource1, disk_resource, catlet_resource2]
      )
    end

    subject { described_class.new(mixed_operation, client) }

    it 'returns resources matching the specified type' do
      catlet_resources = subject.find_resources_by_type('Catlet')
      expect(catlet_resources).to eq([catlet_resource1, catlet_resource2])
    end

    it 'returns empty array when no matching resources' do
      network_resources = subject.find_resources_by_type('VirtualNetwork')
      expect(network_resources).to eq([])
    end

    it 'is case sensitive for resource type matching' do
      lower_resources = subject.find_resources_by_type('catlet')
      expect(lower_resources).to eq([])
    end
  end

  describe '#summary' do
    let(:log1) { double('LogEntry', message: 'Log 1') }
    let(:log2) { double('LogEntry', message: 'Log 2') }
    let(:task1) { double('Task', name: 'Task 1') }
    let(:resource1) { double('Resource', resource_type: 'Catlet', resource_id: 'cat-1') }
    
    let(:detailed_operation) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        log_entries: [log1, log2],
        tasks: [task1],
        resources: [resource1],
        result: nil
      )
    end

    it 'returns a summary hash with counts' do
      result = described_class.new(detailed_operation, client)
      summary = result.summary
      
      expect(summary).to be_a(Hash)
      expect(summary[:operation_id]).to eq(operation_id)
      expect(summary[:status]).to eq('Completed')
      expect(summary[:status_message]).to eq('Success')
      expect(summary[:log_entries_count]).to eq(2)
      expect(summary[:tasks_count]).to eq(1)
      expect(summary[:resources_count]).to eq(1)
      expect(summary[:resource_types]).to eq({ 'Catlet' => 1 })
    end

    it 'groups resources by type' do
      catlet_resource = double('Resource', resource_type: 'Catlet', resource_id: 'cat-1')
      disk_resource1 = double('Resource', resource_type: 'VirtualDisk', resource_id: 'disk-1')
      disk_resource2 = double('Resource', resource_type: 'VirtualDisk', resource_id: 'disk-2')
      
      multi_resource_operation = double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        resources: [catlet_resource, disk_resource1, disk_resource2],
        log_entries: [],
        tasks: [],
        result: nil
      )
      
      result = described_class.new(multi_resource_operation, client)
      summary = result.summary
      
      expect(summary[:resource_types]).to eq({ 
        'Catlet' => 1, 
        'VirtualDisk' => 2 
      })
    end
  end
  
  describe 'operation result extraction' do
    let(:catlet_config_result) do
      double('CatletConfigOperationResult',
        result_type: 'CatletConfig',
        configuration: { 'name' => 'test-catlet', 'cpu' => 2, 'memory' => '4GB' }
      )
    end
    
    let(:operation_with_result) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        result: catlet_config_result,
        resources: [],
        log_entries: [],
        tasks: []
      )
    end
    
    let(:operation_without_result) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        result: nil,
        resources: [],
        log_entries: [],
        tasks: []
      )
    end

    describe '#result' do
      it 'returns the raw operation result object' do
        result = described_class.new(operation_with_result, client)
        expect(result.result).to eq(catlet_config_result)
      end
      
      it 'returns nil when no result' do
        result = described_class.new(operation_without_result, client)
        expect(result.result).to be_nil
      end
    end

    describe '#has_result?' do
      it 'returns true when operation has a result' do
        result = described_class.new(operation_with_result, client)
        expect(result.has_result?).to be true
      end
      
      it 'returns false when operation has no result' do
        result = described_class.new(operation_without_result, client)
        expect(result.has_result?).to be false
      end
    end

    describe '#result_type' do
      it 'returns the result type when result exists' do
        result = described_class.new(operation_with_result, client)
        expect(result.result_type).to eq('CatletConfig')
      end
      
      it 'returns nil when no result' do
        result = described_class.new(operation_without_result, client)
        expect(result.result_type).to be_nil
      end
    end

    describe '#typed_result' do
      it 'returns a CatletConfigResult struct for CatletConfig type' do
        result = described_class.new(operation_with_result, client)
        typed_result = result.typed_result
        
        expect(typed_result).to be_a(Eryph::Compute::CatletConfigResult)
        expect(typed_result.result_type).to eq('CatletConfig')
        expect(typed_result.configuration).to be_nil # No raw JSON provided
      end
      
      it 'returns nil when no result' do
        result = described_class.new(operation_without_result, client)
        expect(result.typed_result).to be_nil
      end
      
      it 'logs warning for unknown result types and returns nil' do
        unknown_result = double('UnknownOperationResult', result_type: 'UnknownType')
        operation_with_unknown_result = double('Operation',
          id: operation_id,
          status: 'Completed',
          result: unknown_result
        )
        
        expect(logger).to receive(:warn).with('Unknown operation result type: UnknownType')
        
        result = described_class.new(operation_with_unknown_result, client)
        expect(result.typed_result).to be_nil
      end
      
      it 'caches the typed result' do
        result = described_class.new(operation_with_result, client)
        
        first_call = result.typed_result
        second_call = result.typed_result
        
        expect(first_call).to be_a(Eryph::Compute::CatletConfigResult)
        expect(second_call).to equal(first_call) # Same object reference due to caching
      end
    end


    describe 'summary with result information' do
      it 'includes result information in summary' do
        result = described_class.new(operation_with_result, client)
        summary = result.summary
        
        expect(summary[:has_result]).to be true
        expect(summary[:result_type]).to eq('CatletConfig')
      end
      
      it 'includes nil result information when no result' do
        result = described_class.new(operation_without_result, client)
        summary = result.summary
        
        expect(summary[:has_result]).to be false
        expect(summary[:result_type]).to be_nil
      end
    end
  end

  describe 'typed result handling with raw JSON' do
    let(:catlet_config_raw_json) do
      JSON.generate({
        id: operation_id,
        status: 'Completed',
        result: {
          result_type: 'CatletConfig',
          configuration: {
            name: 'test-catlet',
            parent: 'dbosoft/ubuntu-22.04/starter',
            cpu: { count: 2 },
            memory: { startup: 2048 }
          }
        }
      })
    end

    let(:incomplete_operation_result) do
      double('OperationResult', result_type: 'CatletConfig')
    end

    let(:operation_with_incomplete_result) do
      double('Operation',
        id: operation_id,
        status: 'Completed',
        status_message: 'Success',
        result: incomplete_operation_result,
        resources: [],
        log_entries: [],
        tasks: []
      )
    end

    describe '#typed_result' do
      context 'with CatletConfig result and raw JSON' do
        it 'returns CatletConfigResult Struct with configuration' do
          result = described_class.new(operation_with_incomplete_result, client, catlet_config_raw_json)
          
          expect(logger).to receive(:info).with(/Creating typed CatletConfigResult/)
          
          typed = result.typed_result
          expect(typed).to be_a(Eryph::Compute::CatletConfigResult)
          expect(typed.result_type).to eq('CatletConfig')
          expect(typed.configuration).to be_a(Hash)
          expect(typed.name).to eq('test-catlet')
          expect(typed.parent).to eq('dbosoft/ubuntu-22.04/starter')
          expect(typed.has_configuration?).to be true
        end

        it 'caches the typed result' do
          result = described_class.new(operation_with_incomplete_result, client, catlet_config_raw_json)
          
          expect(logger).to receive(:info).with(/Creating typed CatletConfigResult/).once
          
          first_call = result.typed_result
          second_call = result.typed_result
          
          expect(first_call).to eq(second_call)
        end
      end

      context 'with CatletConfig result but no raw JSON' do
        it 'returns CatletConfigResult Struct without configuration' do
          result = described_class.new(operation_with_incomplete_result, client)
          
          expect(logger).to receive(:warn).with(/No raw JSON available/)
          
          typed = result.typed_result
          expect(typed).to be_a(Eryph::Compute::CatletConfigResult)
          expect(typed.result_type).to eq('CatletConfig')
          expect(typed.configuration).to be_nil
          expect(typed.has_configuration?).to be false
          expect(typed.name).to be_nil
          expect(typed.parent).to be_nil
        end
      end

      context 'with unknown result type' do
        let(:unknown_result) do
          double('UnknownResult', result_type: 'UnknownType')
        end

        let(:operation_with_unknown_result) do
          double('Operation',
            id: operation_id,
            status: 'Completed',
            result: unknown_result
          )
        end

        it 'returns nil for unknown result types' do
          result = described_class.new(operation_with_unknown_result, client)
          expect(result.typed_result).to be_nil
        end
      end

      context 'with invalid raw JSON' do
        let(:invalid_json) { 'invalid json' }

        it 'handles JSON parse errors gracefully' do
          result = described_class.new(operation_with_incomplete_result, client, invalid_json)
          
          typed = result.typed_result
          expect(typed).to be_a(Eryph::Compute::CatletConfigResult)
          expect(typed.configuration).to be_nil
          expect(typed.has_configuration?).to be false
        end
      end
    end

  end

  describe Eryph::Compute::CatletConfigResult do
    describe '.from_raw_json' do
      let(:valid_raw_json) do
        JSON.generate({
          result: {
            result_type: 'CatletConfig',
            configuration: {
              name: 'test-catlet',
              parent: 'dbosoft/ubuntu-22.04/starter',
              cpu: { count: 1 },
              memory: { startup: 1024 }
            }
          }
        })
      end

      it 'creates Struct from valid JSON' do
        result = described_class.from_raw_json(valid_raw_json)
        
        expect(result.result_type).to eq('CatletConfig')
        expect(result.configuration).to be_a(Hash)
        expect(result.name).to eq('test-catlet')
        expect(result.parent).to eq('dbosoft/ubuntu-22.04/starter')
        expect(result.has_configuration?).to be true
      end

      it 'handles missing configuration gracefully' do
        json_without_config = JSON.generate({
          result: { result_type: 'CatletConfig' }
        })
        
        result = described_class.from_raw_json(json_without_config)
        expect(result.result_type).to eq('CatletConfig')
        expect(result.configuration).to be_nil
        expect(result.has_configuration?).to be false
      end

      it 'handles invalid JSON gracefully' do
        result = described_class.from_raw_json('invalid json')
        
        expect(result.result_type).to eq('CatletConfig')
        expect(result.configuration).to be_nil
        expect(result.has_configuration?).to be false
      end
    end

    describe 'convenience methods' do
      let(:config_data) do
        {
          'name' => 'my-catlet',
          'parent' => 'dbosoft/ubuntu-22.04/starter',
          'cpu' => { 'count' => 4 }
        }
      end

      subject { described_class.new(result_type: 'CatletConfig', configuration: config_data) }

      describe '#name' do
        it 'returns configuration name' do
          expect(subject.name).to eq('my-catlet')
        end

        it 'returns nil when no configuration' do
          empty_result = described_class.new(result_type: 'CatletConfig', configuration: nil)
          expect(empty_result.name).to be_nil
        end
      end

      describe '#parent' do
        it 'returns configuration parent' do
          expect(subject.parent).to eq('dbosoft/ubuntu-22.04/starter')
        end

        it 'returns nil when no configuration' do
          empty_result = described_class.new(result_type: 'CatletConfig', configuration: nil)
          expect(empty_result.parent).to be_nil
        end
      end

      describe '#has_configuration?' do
        it 'returns true when configuration is present' do
          expect(subject.has_configuration?).to be true
        end

        it 'returns false when configuration is nil' do
          empty_result = described_class.new(result_type: 'CatletConfig', configuration: nil)
          expect(empty_result.has_configuration?).to be false
        end
      end
    end
  end
end
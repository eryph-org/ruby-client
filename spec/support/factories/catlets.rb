FactoryBot.define do
  factory :catlet_data, class: 'Hash' do
    initialize_with do
      {
        'id' => Faker::Internet.uuid,
        'name' => "catlet-#{Faker::Lorem.word}",
        'status' => 'Stopped',
        'vmId' => Faker::Internet.uuid,
        'path' => "C:\\ProgramData\\eryph\\catlets\\#{Faker::Internet.uuid}",
        'project' => 'default',
        'environment' => 'default',
        'dataStore' => 'default',
        'fodderName' => nil,
        'metadata' => [],
      }
    end

    trait :running do
      initialize_with do
        attributes.merge('status' => 'Running')
      end
    end

    trait :pending do
      initialize_with do
        attributes.merge('status' => 'Pending')
      end
    end

    trait :error do
      initialize_with do
        attributes.merge('status' => 'Error')
      end
    end

    trait :with_fodder do
      initialize_with do
        attributes.merge(
          'fodderName' => "#{Faker::Lorem.word}-fodder",
          'metadata' => [
            {
              'name' => 'eryph.org/catlet',
              'value' => 'dbosoft/winsrv2022-standard/20230901',
            },
          ]
        )
      end
    end
  end

  factory :project_data, class: 'Hash' do
    initialize_with do
      {
        'id' => Faker::Internet.uuid,
        'name' => Faker::Lorem.word,
        'tenantId' => Faker::Internet.uuid,
      }
    end

    trait :default do
      initialize_with do
        attributes.merge('name' => 'default')
      end
    end
  end

  factory :operation_data, class: 'Hash' do
    initialize_with do
      {
        'id' => Faker::Internet.uuid,
        'status' => 'Completed',
        'statusMessage' => 'Operation completed successfully',
        'createdAt' => (Time.now - 300).iso8601,
        'modifiedAt' => (Time.now - 60).iso8601,
        'resources' => [
          {
            'resourceType' => 'catlet',
            'resourceId' => Faker::Internet.uuid,
          },
        ],
        'logEntries' => [],
      }
    end

    trait :running do
      initialize_with do
        attributes.merge(
          'status' => 'Running',
          'statusMessage' => 'Operation in progress'
        )
      end
    end

    trait :failed do
      initialize_with do
        attributes.merge(
          'status' => 'Failed',
          'statusMessage' => 'Operation failed with error'
        )
      end
    end
  end

  factory :virtual_disk_data, class: 'Hash' do
    initialize_with do
      {
        'id' => Faker::Internet.uuid,
        'name' => "disk-#{Faker::Lorem.word}",
        'project' => 'default',
        'environment' => 'default',
        'dataStore' => 'default',
        'path' => "C:\\ProgramData\\eryph\\disks\\#{Faker::Internet.uuid}",
        'sizeBytes' => 10_737_418_240, # 10 GB
        'usedSizeBytes' => 1_073_741_824, # 1 GB
        'status' => 'Online',
        'attachedCatlets' => [],
      }
    end

    trait :attached do
      initialize_with do
        attributes.merge(
          'attachedCatlets' => [
            {
              'id' => Faker::Internet.uuid,
              'name' => "catlet-#{Faker::Lorem.word}",
            },
          ]
        )
      end
    end
  end
end

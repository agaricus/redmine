require_dependency 'utils/uuid'

module EasyUtils

  module BlockUtils
  
    def generate_uuid
      UUID.create_random.to_s
    end

    # "test" => "test_f33e5940_9a51_4749_b8c0_821ee5fdbd11"
    def get_new_block_name(block_name)
      "#{block_name}_#{generate_uuid.underscore}"
    end

    # "test-f33e5940-9a51-4749-b8c0-821ee5fdbd11" => "test"
    def get_real_block_name(block_name)
      (block_name.length > 37 && block_name.split("_").length > 5) ? block_name[0..block_name.length-38] : block_name
    end

  end

end
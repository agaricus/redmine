module EasyPatch
  module TokenPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        validates_length_of :value, :in => 6..40, :allow_nil => false

        after_initialize :default_values

        alias_method_chain :generate_new_token, :easy_extensions

        def default_values
          self.value = Token.generate_token_value if self.value.blank?
        end

      end
    end

    module InstanceMethods

      def generate_new_token_with_easy_extensions
        
      end

    end

    module ClassMethods

    end
    
  end
  
end
EasyExtensions::PatchManager.register_model_patch 'Token', 'EasyPatch::TokenPatch'

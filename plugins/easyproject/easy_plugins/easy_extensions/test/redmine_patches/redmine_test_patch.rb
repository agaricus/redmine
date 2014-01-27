module EasyExtensions
  module RedmineTestPatch

    def included(base)
      suffix = self.name.split('::').last.underscore.to_sym
      repairs.each do |al|
        base.send(:define_method, "#{al.first}_with_#{suffix}", &al.second)
        base.send(:alias_method_chain, al.first, suffix)
      end

      prepares.each do |prep|
        base.send(:define_method, "prepare_#{prep.first}", &prep.second)
        base.send(:define_method, "#{prep.first}_with_#{suffix}") do
          send("prepare_#{prep.first}")
          send("#{prep.first}_without_#{suffix}")
        end
        base.send(:alias_method_chain, prep.first, suffix)
      end

      disables.each do |dis|
        base.send(:define_method, "#{dis}_with_#{suffix}") do
        end
        base.send(:alias_method_chain, dis, suffix)
      end

      if @setup_block
        base.send(:define_method, "easy_setup", &@setup_block)
        base.send(:define_method, "setup_with_#{suffix}") do
          easy_setup
          setup
        end
      end

      super
    end

    def repairs
      @repairs ||= []
    end

    def prepares
      @prepares ||= []
    end

    def disables
      @disables ||= []
    end

    def repair_test(name, &block)
      if name.is_a?(String)
        name.tr!(' ', '_')
        name = "test_#{name}".to_sym
      end

      repairs << [name, block]
    end

    def prepare_test(name, &block)
      name = get_test_name(name)
      prepares << [name, block]
    end

    def disable_test(name)
      disables << get_test_name(name)
    end

    def disable_tests(tests=[])
      tests.each {|t| disable_test(t) }
    end

    def setup(&block)
      @setup_block = block
    end

    private
      def get_test_name(name)
        if name.is_a?(String)
          name.tr!(' ', '_')
          name = "test_#{name}".to_sym
        end
        name
      end

  end
end
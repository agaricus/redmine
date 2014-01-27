require 'rake/testtask'

module EasyExtensions
  module Tests

    class RedmineRakeTask < Rake::TestTask

      attr_accessor :test_helper

      def define
        #before_define_hook
        @libs << 'test'
        @test_helper ||= "#{Rails.root}/plugins/easyproject/easy_plugins/easy_extensions/test/test_helper"
        @ruby_opts << "-r \"#{test_helper}\""
        @pattern = 'test/**/*test.rb' if @pattern == 'test/test*.rb'
        super
      end

    end

  end
end
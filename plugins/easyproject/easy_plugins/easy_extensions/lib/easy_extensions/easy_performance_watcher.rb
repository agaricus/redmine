module EasyExtensions
  module EasyPerformanceWatcher

    def self.performance_logger
      @@performance_logger ||= Logger.new(File.join(Rails.root, 'log', 'easy_performance_watcher.log'), 'weekly')
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def performance_watcher(options = {})
        current_class = options[:current_class] || self
        parent_class = options[:parent_class] || current_class.superclass
        min_time = options[:min_time] || 0.01
        ((public_instance_methods | protected_instance_methods | private_instance_methods) -
            (parent_class.public_instance_methods | parent_class.protected_instance_methods | parent_class.private_instance_methods)).each do |method_name|

          current_class.instance_eval do
            if method_name.to_s.end_with?('?')
              new_method_name = :"#{method_name[0..-2]}_with_easy_performance_watcher?"
              old_method_name = :"#{method_name[0..-2]}_without_easy_performance_watcher?"
            elsif method_name.to_s.end_with?('=')
              new_method_name = :"#{method_name[0..-2]}_with_easy_performance_watcher="
              old_method_name = :"#{method_name[0..-2]}_without_easy_performance_watcher="
            elsif method_name.to_s.end_with?('!')
              new_method_name = :"#{method_name[0..-2]}_with_easy_performance_watcher!"
              old_method_name = :"#{method_name[0..-2]}_without_easy_performance_watcher!"
            else
              new_method_name = :"#{method_name}_with_easy_performance_watcher"
              old_method_name = :"#{method_name}_without_easy_performance_watcher"
            end

            send(:define_method, new_method_name) do |*args|
              t = Time.now

              ret = send(old_method_name, *args)

              elapsed_time = Time.now - t

              if elapsed_time >= min_time
                args_values = args.collect do |avalue|
                  if avalue.is_a?(ActiveRecord::Base)
                    avalue.class.name
                  else
                    avalue
                  end
                end
                s = "#{current_class.name}->#{method_name}(#{args_values.join(', ')}): #{Time.now - t}s"
                EasyExtensions::EasyPerformanceWatcher.performance_logger.info(s)
                puts s
                logger.info s
              end

              ret
            end

            current_class.send(:alias_method_chain, method_name, :easy_performance_watcher)
          end

        end
      end

    end

  end
end

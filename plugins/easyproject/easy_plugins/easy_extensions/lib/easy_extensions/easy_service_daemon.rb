require 'eventmachine'

module EasyExtensions
  class EasyServiceDaemon

    def self.run(options={})
      logger.info "#{Time.now} EasyExtensions::EasyServiceDaemon started ..."

      EventMachine::run {

        EventMachine.add_periodic_timer(300) {

          EasyRakeTask.execute_scheduled(false)

        }

      }
    end

    def self.logger
      @@logger ||= ActiveSupport::BufferedLogger.new(File.join(Rails.root, 'log', 'easy_service_daemon.log'))
    end
  end
end

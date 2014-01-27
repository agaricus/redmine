require 'easy_extensions/scheduler_tasks/easy_project_heater_scheduler_task'

module EasyExtensions

  class EasyProjectPageHeaterMyPage < EasyExtensions::EasyProjectPageHeater

    def initialize(parameters = nil, session = nil, flash = nil)
      super(:page, parameters, session, flash)
    end

    def reset_variables
      super
      @controller = MyController.new
    end

    def hit_page

      User.active.each do |user|
        reset_variables
        @request.session[:user_id] = user.id

        begin
          r = hit_page_with_get
        rescue Exception => e
          logger.error "hit_page_with_get:#{e.message}" if logger
          logger.error "hit_page_with_get:#{e.backtrace.inspect}" if logger
        end
      end

    end

  end

end
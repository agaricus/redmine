class EasyRakeTaskRepeatingEntities < EasyRakeTask

  def execute

    log_info 'RepeatingEntitiesTask excuting...'
    total = 0

    EasyExtensions::EntityRepeater.all_repeaters.each do |repeater|
      log_info "executing #{repeater.class.name}..."

      count = 0

      repeater.entities_to_repeat.each do |entity|

        next if repeater.skip_entity?(entity)
        next unless entity.easy_repeat_settings['repeat_hour'].to_i <= Time.now.hour #repeat_hour
        next unless entity.should_repeat?

        if entity.repeat
          count += 1
        end

      end
      total += count

      log_info "#{repeater.class.name} repeated #{count} entities"
    end

    log_info 'RepeatingEntitiesTask done. ' + total.to_s + ' entities was created.'

    total
  end

end

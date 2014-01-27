module ApiCustomFieldsHelper

  def render_api_custom_field(api, custom_field)
    api.custom_field do
      api.id(custom_field.id)
      api.internal_name(custom_field.internal_name)
      api.type(custom_field.type)
      api.name(custom_field.translated_name)
      api.field_format(custom_field.field_format)

      api.array :possible_values do
        custom_field.possible_values.each do |possible_value|
          api.possible_value(possible_value)
        end
      end

      api.regexp(custom_field.regexp)
      api.min_length(custom_field.min_length)
      api.max_length(custom_field.max_length)
      api.is_required(custom_field.is_required)
      api.is_for_all(custom_field.is_for_all)
      api.is_filter(custom_field.is_filter)
      api.position(custom_field.position)
      api.searchable(custom_field.searchable)
      api.default_value(custom_field.default_value)
      api.editable(custom_field.editable)
      api.is_primary(custom_field.is_primary)
      api.show_empty(custom_field.show_empty)
      api.show_on_list(custom_field.show_on_list)
      api.computed_token(custom_field.computed_token)
      api.visible(custom_field.visible)
      api.non_deletable(custom_field.non_deletable)
      api.non_editable(custom_field.non_editable)
      api.show_on_more_form(custom_field.show_on_more_form)
      api.multiple(custom_field.multiple)
      api.easy_external_id(custom_field.easy_external_id)
    end
  end

end
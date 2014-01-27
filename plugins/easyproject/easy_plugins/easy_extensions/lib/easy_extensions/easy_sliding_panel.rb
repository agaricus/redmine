module EasyExtensions
  class EasySlidingPanel

    attr_reader :name, :panel_content, :data, :html_options
    attr_accessor :clicker_text, :dom_id

    def initialize(name, view, options={})
      @view = view
      @name = name
      @data = {:panel_name => @name, :save_location_url => @view.url_for({:controller => 'easy_sliding_panels', :action => 'save_location'})}

      zone = User.current.easy_sliding_panels_locations.where(:name => @name).first
      @location = zone && zone.zone || options[:default_zone] || 'left'

      options[:js] ||= {}
      options[:js][:position] = "'#{@location}'"

      @js_options = {}
      @js_functions = options[:js].map{|k,v| "'#{k.to_s}':#{v}"}

      @html_options = options.delete(:html)
    end

    def dom_id
      @dom_id || "easy_sliding_panel_#{@name}"
    end

    def data_attribute=(hsh={})
      @data.merge!(hsh)
    end

    def js_options=(hsh={})
      @js_options.merge!(hsh)
    end

    def js_options
      '{' + [@js_functions + @js_options.map{|k,v| "\"#{k.to_s}\":\"#{v}\""}].join(',') + '}'
    end

    def render_data_attribute
      @render_data_attribute ||= @data.collect{|k,v| "data-#{k.to_s.dasherize}=\"#{v}\""}
      @render_data_attribute.join(' ')
    end

    def content(&block)
      @panel_content = @view.content_tag(:div, {:class => 'expander-panel-content'}, &block)
    end

  end
end

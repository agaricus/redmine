class EpmRedmineModule < EasyPageModule

  def self.ensure_all
    return unless EasyPage.table_exists?

    delete_oldies

    Redmine::Views::MyPage::Block.additional_blocks.each do |module_name, caption|
      klass_name = "EpmRedmine#{module_name}Module"

      redmine_module_klass = create_redmine_module_class(klass_name, module_name, caption)

      redmine_module_klass.install_to_page('my-page') if redmine_module_klass.count == 0
    end
  end

  def self.delete_oldies
    return unless EasyPageModule.column_names.include?('type')
    ActiveRecord::Base.connection.execute("SELECT type FROM #{EasyPageModule.table_name} WHERE type like 'Kernel::EpmRedmine%Module'").each do |row|
      m = row.first.match(/\AKernel::EpmRedmine(\S+)Module\z/)
      next unless m

      module_name = m[1]
      
      next if Redmine::Views::MyPage::Block.additional_blocks.keys.include?(module_name)

      m = row.first.match(/\AKernel::(EpmRedmine\S+Module)\z/)
      klass_name = m[1]

      redmine_module_klass = create_redmine_module_class(klass_name)
      r = redmine_module_klass.first
      r.destroy if r

      Kernel.send(:remove_const, klass_name.to_sym)
    end
  end

  def self.create_redmine_module_class(klass_name, module_name = nil, caption = nil)
    redmine_module_klass = Class.new(EpmRedmineModule) do

      define_method(:module_name) do
        @module_name ||= module_name
      end

      define_method(:translated_name) do
        @translated_name ||= l(caption).html_safe
      end

    end
    Kernel.const_set(klass_name, redmine_module_klass)
    return redmine_module_klass
  end

  def category_name
    @category_name ||= 'redmine'
  end

  def show_path
    @show_path ||= "my/blocks/#{module_name}"
  end

  def edit_path
    @edit_path ||= "my/blocks/#{module_name}"
  end

end
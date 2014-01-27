require 'utils/shell_utils'
class EasyApplicationManagerController < ApplicationController

  before_filter :require_admin

  accept_api_auth :plugins_list, :create_package, :download_package, :update_site

  def plugins_list
    @plugins = EasyExtensions::PackageMaker.all_plugins.select{|p| p.id != :easy_extensions}.sort_by{|p| p.name.to_s}

    respond_to do |format|
      format.api
    end
  end

  def create_package
    pl = Array.wrap(params[:plugins])
    plugins = EasyExtensions::PackageMaker.all_plugins.select{|p| pl.include?(p.id.to_s)}.collect(&:id)

    @pm = EasyExtensions::PackageMaker.new(plugins)
    @pm.create_package(:include_redmine => (params[:include_redmine] == '1'), :include_sql => (params[:include_sql] == '1'), :zip_method => params[:zip_method])

    if @pm.errors.blank?
      respond_to do |format|
        format.api
      end
    else
      respond_to do |format|
        format.api do
          @error_messages = @pm.errors
          render :template => 'common/error_messages'
        end
      end
    end
  end

  def download_package
    package_name = params[:package_name]

    file_path = File.join(EasyExtensions::PackageMaker::TMP_FOLDER, package_name)

    if File.exist?(file_path)
      send_file(file_path, :type => Redmine::MimeType.of('zip'))
    else
      render :nothing => true
    end
  end

  def update_site
    @message = ''

    begin
      @message = EasyUtils::ShellUtils.shellout('ep-update'){ |io| io.read }.to_s
    rescue Exception => ex
      @message = ex.message.to_s
    end

    if @message.match(/Updated :-\)/)
      render :text => 'OK!'
    else
      render :text => @message
    end
  end

end

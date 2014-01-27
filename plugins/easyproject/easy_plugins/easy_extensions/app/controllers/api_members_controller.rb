class ApiMembersController < ApplicationController

  before_filter :find_project_by_project_id
  before_filter :find_member, :only => [:show, :update, :destroy]
  before_filter :check_permissions

  helper :custom_fields
  include CustomFieldsHelper
  helper :users
  include UsersHelper
  helper :api_members
  include ApiMembersHelper

  accept_api_auth :index, :show, :create, :update, :destroy

  def index
    @members = @project.member_principals

    respond_to do |format|
      format.api
    end
  end

  def show
    respond_to do |format|
      format.api
    end
  end

  def create
    @member = Member.new(get_attrs_from_params)
    @member.project = @project

    if @member.save
      respond_to do |format|
        format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'api_members', :action => 'show', :project_id => @project, :id => @member.id) }
      end
    else
      respond_to do |format|
        format.api  { render_validation_errors(@member) }
      end
    end
  end

  def update
    if @member.update_attributes(get_attrs_from_params)
      respond_to do |format|
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.api  { render_validation_errors(@member) }
      end
    end
  end

  def destroy
    @member.destroy
    respond_to do |format|
      format.api  { head :ok }
    end
  end

  private

  def find_member
    @member = @project.member_principals.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def get_attrs_from_params
    attrs = {}

    if params[:member]
      if params[:member][:user] && params[:member][:user][:id]
        attrs[:user_id] = params[:member][:user][:id]
      elsif params[:member][:group] && params[:member][:group][:id]
        attrs[:user_id] = params[:member][:group][:id]
      end

      if params[:member][:roles]
        attrs[:role_ids] = params[:member][:roles].collect{|r| r[:id]}
      elsif params[:member][:role]
        if params[:member][:role].is_a?(Array)
          attrs[:role_ids] = params[:member][:role].collect{|r| r[:id]}
        elsif params[:member][:role][:id]
          attrs[:role_ids] = params[:member][:role][:id]
        end
      end
    end
    attrs
  end

  def check_permissions
    deny_access unless User.current.allowed_to?(:manage_members, @project)
  end

end
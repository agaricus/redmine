module ApiMembersHelper

  def render_api_member(api, member)
    api.member do
      api.id(member.id)
      api.mail_notification(member.mail_notification)

      render_api_principal(api, member.principal)

      api.array :roles do
        member.roles.each do |role|
          api.role :id => role.id, :name => role.name
        end
      end
    end
  end

end
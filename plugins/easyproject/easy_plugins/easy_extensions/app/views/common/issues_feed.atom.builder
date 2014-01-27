xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title   truncate_single_line(@title, :length => 100)
  xml.link    "rel" => "self", "href" => url_for(params.merge(:only_path => false))
  xml.link    "rel" => "alternate", "href" => url_for(params.merge(:only_path => false, :format => nil, :key => nil))
  xml.id      url_for(:controller => 'welcome', :only_path => false)
  xml.updated((@items.first ? @items.first.event_datetime : Time.now).xmlschema)
  xml.author  { xml.name "#{Setting.app_title}" }
  xml.generator(:uri => Redmine::Info.url) { xml.text! Redmine::Info.app_name; }
  @items.each do |item|
    xml.entry do
      url = url_for(item.event_url(:only_path => false))
      if @project
        xml.title truncate_single_line(item.event_title, :length => 100)
      else
        xml.title truncate_single_line("#{item.project} - #{item.event_title}", :length => 100)
      end
      xml.link "rel" => "alternate", "href" => url
      xml.id url
      xml.updated item.event_datetime.xmlschema
      author = item.event_author if item.respond_to?(:event_author)
      xml.author do
        xml.name(author)
        xml.email(author.mail) if author.is_a?(User) && !author.mail.blank? && !author.pref.hide_mail
      end if author
      xml.content "type" => "html" do
        xml.text! textilizable(item, :event_description, {:headings => false, :only_path => false})
      end
      # added for my_page modul issues_rss_reader
      xml.project_name item.project.name
      xml.link_project "rel" => "alternate", "href" => url_for(:controller => 'projects', :action => 'show', :id => item.project.id, :only_path => false)
      xml.issue_subject item.subject     
      xml.link_issue "rel" => "alternate", "href" => url_for(item.event_url(:only_path => false))
      xml.issue_priority_position item.priority.position
      xml.issue_done_ratio item.done_ratio.to_s
      xml.issue_due_date item.due_date
      xml.issue_status_closed item.status.is_closed? ? 1 : 0
      xml.link_timelog "rel" => "alternate", "href" => url_for(:controller => 'timelog', :action => 'edit', :issue_id => item.id, :only_path => false)
      xml.link_issues "rel" => "alternate", "href" => url_for(:controller => 'issues', :action => 'edit', :id => item.id, :only_path => false)
    end
  end
end

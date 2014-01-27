# encoding: utf-8
class FixDiacritics < ActiveRecord::Migration

  def self.up
    #Issue
    Issue.update_all("description = REPLACE(description,'&scaron;','š')", "description like '%&scaron;%'")
    Issue.update_all("description = REPLACE(description,'&Scaron;','Š')", "description like '%&Scaron;%'")

    Issue.update_all("description = REPLACE(description,'&yacute;','ý')", "description like '%&yacute;%'")
    Issue.update_all("description = REPLACE(description,'&Yacute;','Ý')", "description like '%&Yacute;%'")

    Issue.update_all("description = REPLACE(description,'&aacute;','á')", "description like '%&aacute;%'")
    Issue.update_all("description = REPLACE(description,'&Aacute;','Á')", "description like '%&Aacute;%'")

    Issue.update_all("description = REPLACE(description,'&iacute;','í')", "description like '%&iacute;%'")
    Issue.update_all("description = REPLACE(description,'&Iacute;','Í')", "description like '%&Iacute;%'")

    Issue.update_all("description = REPLACE(description,'&eacute;','é')", "description like '%&eacute;%'")
    Issue.update_all("description = REPLACE(description,'&Eacute;','É')", "description like '%&Eacute;%'")

    Issue.update_all("description = REPLACE(description,'&uacute;','ú')", "description like '%&uacute;%'")
    Issue.update_all("description = REPLACE(description,'&Uacute;','Ú')", "description like '%&Uacute;%'")

    #Journal
    Journal.update_all("notes = REPLACE(notes,'&scaron;','š')", "notes like '%&scaron;%'")
    Journal.update_all("notes = REPLACE(notes,'&Scaron;','Š')", "notes like '%&Scaron;%'")

    Journal.update_all("notes = REPLACE(notes,'&yacute;','ý')", "notes like '%&yacute;%'")
    Journal.update_all("notes = REPLACE(notes,'&Yacute;','Ý')", "notes like '%&Yacute;%'")

    Journal.update_all("notes = REPLACE(notes,'&aacute;','á')", "notes like '%&aacute;%'")
    Journal.update_all("notes = REPLACE(notes,'&Aacute;','Á')", "notes like '%&Aacute;%'")

    Journal.update_all("notes = REPLACE(notes,'&iacute;','í')", "notes like '%&iacute;%'")
    Journal.update_all("notes = REPLACE(notes,'&Iacute;','Í')", "notes like '%&Iacute;%'")

    Journal.update_all("notes = REPLACE(notes,'&eacute;','é')", "notes like '%&eacute;%'")
    Journal.update_all("notes = REPLACE(notes,'&Eacute;','É')", "notes like '%&Eacute;%'")

    Journal.update_all("notes = REPLACE(notes,'&uacute;','ú')", "notes like '%&uacute;%'")
    Journal.update_all("notes = REPLACE(notes,'&Uacute;','Ú')", "notes like '%&Uacute;%'")

    #News
    News.update_all("description = REPLACE(description,'&scaron;','š')", "description like '%&scaron;%'")
    News.update_all("description = REPLACE(description,'&Scaron;','Š')", "description like '%&Scaron;%'")

    News.update_all("description = REPLACE(description,'&yacute;','ý')", "description like '%&yacute;%'")
    News.update_all("description = REPLACE(description,'&Yacute;','Ý')", "description like '%&Yacute;%'")

    News.update_all("description = REPLACE(description,'&aacute;','á')", "description like '%&aacute;%'")
    News.update_all("description = REPLACE(description,'&Aacute;','Á')", "description like '%&Aacute;%'")

    News.update_all("description = REPLACE(description,'&iacute;','í')", "description like '%&iacute;%'")
    News.update_all("description = REPLACE(description,'&Iacute;','Í')", "description like '%&Iacute;%'")

    News.update_all("description = REPLACE(description,'&eacute;','é')", "description like '%&eacute;%'")
    News.update_all("description = REPLACE(description,'&Eacute;','É')", "description like '%&Eacute;%'")

    News.update_all("description = REPLACE(description,'&uacute;','ú')", "description like '%&uacute;%'")
    News.update_all("description = REPLACE(description,'&Uacute;','Ú')", "description like '%&Uacute;%'")

    #Document
    Document.update_all("description = REPLACE(description,'&scaron;','š')", "description like '%&scaron;%'")
    Document.update_all("description = REPLACE(description,'&Scaron;','Š')", "description like '%&Scaron;%'")

    Document.update_all("description = REPLACE(description,'&yacute;','ý')", "description like '%&yacute;%'")
    Document.update_all("description = REPLACE(description,'&Yacute;','Ý')", "description like '%&Yacute;%'")

    Document.update_all("description = REPLACE(description,'&aacute;','á')", "description like '%&aacute;%'")
    Document.update_all("description = REPLACE(description,'&Aacute;','Á')", "description like '%&Aacute;%'")

    Document.update_all("description = REPLACE(description,'&iacute;','í')", "description like '%&iacute;%'")
    Document.update_all("description = REPLACE(description,'&Iacute;','Í')", "description like '%&Iacute;%'")

    Document.update_all("description = REPLACE(description,'&eacute;','é')", "description like '%&eacute;%'")
    Document.update_all("description = REPLACE(description,'&Eacute;','É')", "description like '%&Eacute;%'")

    Document.update_all("description = REPLACE(description,'&uacute;','ú')", "description like '%&uacute;%'")
    Document.update_all("description = REPLACE(description,'&Uacute;','Ú')", "description like '%&Uacute;%'")

    #Project
    Project.update_all("description = REPLACE(description,'&scaron;','š')", "description like '%&scaron;%'")
    Project.update_all("description = REPLACE(description,'&Scaron;','Š')", "description like '%&Scaron;%'")

    Project.update_all("description = REPLACE(description,'&yacute;','ý')", "description like '%&yacute;%'")
    Project.update_all("description = REPLACE(description,'&Yacute;','Ý')", "description like '%&Yacute;%'")

    Project.update_all("description = REPLACE(description,'&aacute;','á')", "description like '%&aacute;%'")
    Project.update_all("description = REPLACE(description,'&Aacute;','Á')", "description like '%&Aacute;%'")

    Project.update_all("description = REPLACE(description,'&iacute;','í')", "description like '%&iacute;%'")
    Project.update_all("description = REPLACE(description,'&Iacute;','Í')", "description like '%&Iacute;%'")

    Project.update_all("description = REPLACE(description,'&eacute;','é')", "description like '%&eacute;%'")
    Project.update_all("description = REPLACE(description,'&Eacute;','É')", "description like '%&Eacute;%'")

    Project.update_all("description = REPLACE(description,'&uacute;','ú')", "description like '%&uacute;%'")
    Project.update_all("description = REPLACE(description,'&Uacute;','Ú')", "description like '%&Uacute;%'")
  end

  def self.down
  end

end

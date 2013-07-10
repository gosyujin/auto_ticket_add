require 'nokogiri'

class AutoTicketController < ApplicationController
  unloadable
  def index
    puts "call index"

    adapter = Redmine::Scm::Adapters::SubversionAdapter
    project_name = Project.find(params[:id])

    log_xml = ""
    project_name.repositories.each do |repo|
       log_xml = `svn log --xml #{repo.url}`
    end
    @log = parse(log_xml)
  end

  def add
    puts "call add"
  end


private
  def parse(xml)
    log = {}
    doc = Nokogiri::XML(xml)
    doc.xpath('/log/logentry').each do |item|
      item.xpath('./msg').each do |msg|
        log[item["revision"]] = msg.text
      end
    end
    return log
  end
end

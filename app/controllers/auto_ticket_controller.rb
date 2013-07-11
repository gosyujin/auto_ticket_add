require 'nokogiri'

class AutoTicketController < ApplicationController
  unloadable
  def index
    puts "call index"
    project_name = Project.find(params[:id])

    log_xml = ""
    repositories = project_name.repositories
    if repositories.empty? then
      @nothing = "repository is nothing..."
      return
    end

    repositories.each do |repository|
       require 'pp'; pp repository
       # only default scm
       next unless repository["is_default"]

       case repository["type"]
       when Repository::Subversion.to_s
         log = `svn log --xml #{repository.url}`
         @log = parse(log)
         return
       when Repository::Git.to_s
         splitter = "||"
     log = {}
     pre = `git --git-dir=#{repository.url} log --pretty=format:"%h#{splitter}%s"`
     pre.split("\n").each do |l|
           k,v = l.split(splitter)
       log[k] = v
     end
     @log = log
         return
       else
         @nothing = "It have support only Subversion"
         return
       end
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

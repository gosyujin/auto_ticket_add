require 'nokogiri'

class AutoTicketController < ApplicationController
  unloadable

  before_filter :find_project
  menu_item :exec_add

  helper :issues
  include IssuesHelper

  def index
    puts "call index"

    log_xml = ""
    repositories = @project.repositories
    if repositories.empty? then
      @nothing = "repository is nothing..."
      return
    end

    repositories.each do |repository|
       # only default scm
       next unless repository["is_default"]

       case repository["type"]
       when Repository::Subversion.to_s
         log = `svn log --xml #{repository.url}`
         @log = parse(log)
         @log.each do |revision, log|
           tickets_no = log.scan(/#[1-9]*/)
           next if tickets_no.empty?
           tickets_no.each do |ticket_no|
             puts "kono ticket no [#{ticket_no}] ni revision no log [r#{revision}: #{log}]"
           end
         end
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

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

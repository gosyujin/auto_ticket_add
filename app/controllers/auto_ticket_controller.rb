# -*- encoding: utf-8 -*-
require 'nokogiri'
require 'pp'
require 'open-uri'

class AutoTicketController < ApplicationController
  unloadable

  before_filter :find_project
  menu_item :exec_add

  helper :issues
  include IssuesHelper

  Git_Splitter = "|||"

  def index
    puts "call index"
    commit_log
  end

  def add
    puts "call add"
    commit_log
    @log.each do |revision, log|
      # scan commit log: if include issue no => "#n"
      issues_id = log.scan(/#[1-9]*/)
      next if issues_id.empty?

      issues_id.each do |issue_id|
        issue_id_only_num = issue_id.delete("#")

        project_id = @project.id
        issue = Issue.find(:first, :conditions => ["id = ?", issue_id_only_num])
        issue.init_journal(User.current, "r#{revision}: #{log}")
        success = issue.save
        unless success then
          @error_message
        end
      end
    end
  end

private
  def commit_log
    repositories = @project.repositories
    if repositories.empty? then
      @error_message = "repository is nothing..."
      return
    end

    repositories.each do |repository|
       # ONLY default scm exec
       next unless repository["is_default"]

       scm_type = repository["type"]
       case scm_type
       when Repository::Subversion.to_s
         # case param["xxx"].to_i when NOT a number return 0
         from = params["from"].to_i.to_s
         to = params["to"].to_i.to_s

         if from != "0" or to != "0" then
           since = ""
           since << from.to_s unless from == "0"
           since << ":"       unless from == "0"
           since << to.to_s   unless to == "0"
           revision_opt = "-r #{since}"
         else
           revision_opt = "--limit 5"
         end

         @repository_url = repository.url
         log = `svn log -v --xml #{@repository_url} #{revision_opt}`
         @log = parse(scm_type, log)
         return
       when Repository::Git.to_s
         log = `git --git-dir=#{@repository_url} log --pretty=format:"%h#{Git_Splitter}%s"`
         @log = parse(scm_type, log)
         return
       else
         @error_message = "It have support only Subversion"
         return
       end
    end
  end

  def parse(scm, log)
    hash = {}
    case scm
    when Repository::Subversion.to_s
      doc = Nokogiri::XML(log)
      doc.xpath('/log/logentry').each do |item|
        msg_text = ""
        item.xpath('./msg').each do |msg|
          msg_text = msg.text
        end

        path_array = []
        item.xpath('paths/path').each do |path|
            path_array << path.text
        end
        hash[item["revision"]] = { "msg" => msg_text, "path" => path_array }
      end
    when Repository::Git.to_s
      log.split("\n").each do |lo|
        k,v = lo.split(Git_Splitter)
        hash[k] = v
      end
    end
    return hash
  rescue ex
    puts ex
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

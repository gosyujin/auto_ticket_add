# -*- encoding: utf-8 -*-
require 'nokogiri'
require 'pp'

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

       case repository["type"]
       when Repository::Subversion.to_s
         if params["revision"].nil? or params["revision"] == "" then
           revision = "--limit 1"
         else
           revision = "-r #{params["revision"]}"
         end

         log = `svn log --xml #{repository.url} #{revision}`
         @log = parse(:svn, log)
         return
       when Repository::Git.to_s

         log = `git --git-dir=#{repository.url} log --pretty=format:"%h#{Git_Splitter}%s"`
         @log = parse(:git, log)
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
    when :svn
      doc = Nokogiri::XML(log)
      doc.xpath('/log/logentry').each do |item|
        item.xpath('./msg').each do |msg|
          hash[item["revision"]] = msg.text
        end
      end
    when :git
      log.split("\n").each do |lo|
        k,v = lo.split(Git_Splitter)
        hash[k] = v
      end
    end
    return hash
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

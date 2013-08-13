# -*- encoding: utf-8 -*-
require 'nokogiri'
require 'pp'
require 'open3'

# Exception class
class RepositoryNoSupport < Exception; end
class RepositoryNotFound < Exception; end

class AutoTicketController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :find_repository
  menu_item :exec_add

  helper :issues
  include IssuesHelper

  def index
    puts "call index"
    @log = commit_log
  end

  def add
    puts "call add"
    @log = commit_log
    @log.each do |revision, log|
      # scan commit log: if include issue no => "#nn"
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

  def download
    puts "call download"
    json = commit_log
    plain_txt = log_to_plain(json)

    filename = "diff.txt"
    send_data plain_txt, :filename => filename, :type => "text/plain", :description => "attachment"
  end

private
  def commit_log
    scm_type = @repository["type"]
    case scm_type
    when Repository::Subversion.to_s
      # case param["xxx"].to_i when NOT a number return 0
      from = params["from"].to_i.to_s
      to = params["to"].to_i.to_s

      if from != "0" or to != "0" then
        since = ""
        since << from.to_s if from != "0"
        since << ":"       if from != "0" and to != "0"
        since << to.to_s   if to   != "0"
        revision_opt = "-r #{since}"
      else
        # DEFAULT
        revision_opt = "--limit 5"
      end

      command = "svn log -v --xml #{@repository.url} #{revision_opt}"
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        error = stderr.read

        error = to_utf8(error)
        raise error unless error == ""

        log = stdout.read
        return parse(scm_type, log)
      end
    when Repository::Git.to_s
      # FIXME get log
      from = params["from"].to_s
      to = params["to"].to_s

      if from != "" or to != "" then
        since = ""
        since << from.to_s if from != ""
        since << ".."      if from != "" and to != ""
        since << to.to_s   if to   != ""
        revision_opt = "#{since}"
      else
        # DEFAULT
        revision_opt = "HEAD~6..HEAD"
      end

      command = %{git --git-dir=#{@repository.url} log #{revision_opt} --name-only --pretty=format:"GitHash:%h%nGitSub:%s"}
      puts command
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        error = stderr.read

        error = to_utf8(error)
        raise error unless error == ""

        log = stdout.read
        return parse(scm_type, log)
      end
    else
      raise RepositoryNoSupport, "This scm is no support... (#{scm_type})"
    end
  rescue RepositoryNoSupport => ex
    render_404(:message => ex)
  rescue RuntimeError => ex
    @error_message = ex
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
      revision = ""
      msg_text = ""
      path_array = []

      to_utf8(log).split("\n").each do |l|
        case l
        when /^GitHash:*/
          revision = l.split(":")[1]
        when /^GitSub:*/
          msg_text = l.split(":")[1]
        else
          if l == "" then
            hash[revision] = { "msg" => msg_text, "path" => path_array }
            path_array = []
          else
            path_array << l
          end
        end
      end
    end
    return hash
  rescue => ex
    @error_message = ex
  end

  def log_to_plain(json)
    json = JSON.load(JSON.generate(json))

    crlf = ""
    crlf << "\r" if windows?
    crlf << "\n"

    plain_txt = ""
    json.each do |revision,value|
      plain_txt << "revision #{revision}:#{crlf}"
      plain_txt << "#{value["msg"]}#{crlf}"
      value["path"].each do |path|
        plain_txt << "  - #{path}#{crlf}"
      end
      plain_txt << "------------------------------#{crlf}"
    end
    return plain_txt
  end

  def to_utf8(str)
    if windows? then
      str = str.encode("utf-8", "windows-31j").encode("utf-8")
    else
      str = str.encode("utf-8").encode("utf-8")
    end
  end

  def windows?
    if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/
      puts "windows"
      true
    else
      puts "not windows"
      false
    end
  end

  def find_repository
    repositories = @project.repositories
    if repositories.empty? then
      raise RepositoryNotFound, "Repository is nothing..."
    end

    repositories.each do |repository|
       # FIXME ONLY default scm exec
       if repository["is_default"] then
         @repository = repository
         @repository_identifier = @repository.identifier
         @repository_url = @repository.url
       else
         next
       end
    end
  rescue RepositoryNotFound => ex
    render_404(:message => ex)
  end

  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

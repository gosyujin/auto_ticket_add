Redmine::Plugin.register :auto_ticket_add do
  name 'Auto Ticket Add plugin'
  author 'kk_Ataka'
  description 'Auto Ticket Add Plugin'
  version '0.0.1'
  url 'http://github.com/gosyujin/'
  author_url 'http://github.com/gosyujin/'

  project_module :auto_ticket_add do
    permission :ok, :auto_ticket => [:index, :add]
  end
  menu :project_menu, :exec_add, {:controller => 'auto_ticket', :action => 'index'}
end

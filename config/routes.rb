# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
match 'projects/:id/auto_ticket/:action', :controller => 'auto_ticket'

#Rails.application.routes.draw do
#  resources :projects do
#    resources :auto_ticket
#  end
#end
#project_auto_ticket_index GET    /projects/:project_id/auto_ticket(.:format)          auto_ticket#index
#                          POST   /projects/:project_id/auto_ticket(.:format)          auto_ticket#create
#  new_project_auto_ticket GET    /projects/:project_id/auto_ticket/new(.:format)      auto_ticket#new
# edit_project_auto_ticket GET    /projects/:project_id/auto_ticket/:id/edit(.:format) auto_ticket#edit
#      project_auto_ticket GET    /projects/:project_id/auto_ticket/:id(.:format)      auto_ticket#update
#                          DELETE /projects/:project_id/auto_ticket/:id(.:format)      auto_ticket#destroy

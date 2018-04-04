require 'redmine'

Redmine::Plugin.register :redmine_create_issue_watchers_from_email do
  name 'Redmine Create Issue Watchers From Email plugin'
  author 'Alex Shulgin <ash@commandprompt.com>'
  description 'Adds users on TO/CC email fields to issue watcher list, creates new user accounts if needed'
  version '0.2.1'
  url 'https://github.com/commandprompt/redmine_create_issue_watchers_from_email'
  author_url 'https://www.commandprompt.com'

  settings :default => {},
    :partial => 'settings/redmine_create_issue_watchers_from_email'
end

prepare_block = Proc.new do
  Issue.send(:include, RedmineCreateIssueWatchersFromEmail::IssuePatch)
  User.send(:include, RedmineCreateIssueWatchersFromEmail::UserPatch)
  MailHandler.send(:include, RedmineCreateIssueWatchersFromEmail::MailHandlerPatch)
end

if Rails.env.development?
  ActionDispatch::Reloader.to_prepare { prepare_block.call }
else
  prepare_block.call
end

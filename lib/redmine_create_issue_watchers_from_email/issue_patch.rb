module RedmineCreateIssueWatchersFromEmail
  module IssuePatch
    unloadable

    def self.included(base)
      base.send(:prepend, InstanceMethods)
      base.class_eval do
        alias_method_chain :update, :activate_watchers
      end
    end

    module InstanceMethods
      # Returns true if usr or current user is allowed to view the issue
      # patches original method to return true for issue author and watchers
      def visible?(usr=nil)
        usr ||= User.current
        # issue is always visible to its author
        return true if usr.logged? && self.author == usr

        usr.allowed_to?(:view_issues, self.project) do |role, user|
          visible = if user.logged?
            case role.issues_visibility
            when 'all'
              true
            when 'default'
              !self.is_private? || (self.author == user || user.is_or_belongs_to?(assigned_to))
            when 'own'
              self.author == user || user.is_or_belongs_to?(assigned_to) || self.watcher_users.exists?(user.id)
            else
              false
            end
          else
            !self.is_private?
          end
          unless role.permissions_all_trackers?(:view_issues)
            visible &&= role.permissions_tracker_ids?(:view_issues, tracker_id)
          end
          visible
        end
      end
    end

    def update_with_activate_watchers(*args)
      update_without_activate_watchers(*args).tap do |x|
        activate_watchers if x && !closed?
      end
    end

    private

    def activate_watchers
      activate_user(author)
      watcher_users.each {|u| activate_user(u)}
    end

    def activate_user(user)
      user.activate! unless user.locked? || user.active?
    end
  end
end

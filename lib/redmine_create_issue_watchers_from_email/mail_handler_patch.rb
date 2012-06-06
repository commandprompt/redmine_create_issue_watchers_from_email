module RedmineCreateIssueWatchersFromEmail
  module MailHandlerPatch
    unloadable

    def self.included(base)
      base.class_eval do
        alias_method_chain :add_watchers, :create
      end
    end

    def add_watchers_with_create(obj)
      # check our emission email to avoid self-notify hell cycles
      project = obj.project
      emission_email = (project.respond_to?(:email) ? project.email : Setting.mail_from).strip.downcase

      handler_options = MailHandler.send(:class_variable_get, :@@handler_options)
      unknown_user_action = handler_options[:unknown_user]

      (email.to_addrs.to_a + email.cc_addrs.to_a).each do |addr|
        next if addr.spec == emission_email
        watcher = User.find_by_mail(addr.spec)
        unless watcher
          unless unknown_user_action == 'create' # TODO: 'register'?
            logger.info "MailHandler: not adding watcher: #{addr.spec}" if logger
            next
          else
            watcher = MailHandler.new_user_from_attributes(addr.spec, addr.name)
            unless watcher.process_registration
              logger.error "MailHandler: failed to create User: #{watcher.errors.full_messages}" if logger
              next
            end
          end
        end
        unless project.users.exists?(watcher)
          member = Member.new(:user_id => watcher.id, :role_ids => [watcher_role.id])
          project.members << member
        end
      end

      add_watchers_without_create(obj)
    end

    def watcher_role
      @watcher_role ||= Role.find_by_name("Issue Watcher") # XXX: hard-coded value
    end
  end
end
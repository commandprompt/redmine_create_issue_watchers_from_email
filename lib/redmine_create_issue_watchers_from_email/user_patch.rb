module RedmineCreateIssueWatchersFromEmail
  module UserPatch
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def process_registration(notify=true)
        case Setting.self_registration
        when '1'
          register_by_email_activation
        when '3'
          register_automatically
        else
          register_manually_by_administrator(notify)
        end
      end

      private
        def register_by_email_activation
          token = Token.new(:user => self, :action => "register")
          if Redmine::VERSION::MAJOR >= 4
            Mailer.deliver_register(self, token) if self.save and token.save
          else
            Mailer.register(token).deliver if self.save and token.save
          end
        end

        def register_automatically
          self.activate
          self.last_login_on = Time.now
          self.save
        end

        def register_manually_by_administrator(notify=true)
          # Sends an email to the administrators
          if self.save
            if Redmine::VERSION::MAJOR >= 4
              Mailer.deliver_account_activation_request(self) if notify
            else
              Mailer.account_activation_request(self).deliver if notify
            end
            # report success regardless of the notification status
            true
          end
        end
    end
  end
end

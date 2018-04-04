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
          Mailer.register(token).deliver if self.save and token.save
        end

        def register_automatically
          self.activate
          self.last_login_on = Time.now
          self.save
        end

        def register_manually_by_administrator(notify=true)
          # Sends an email to the administrators
          if self.save
            Mailer.account_activation_request(self).deliver if notify
            # report success regardless of the notification status
            true
          end
        end
    end
  end
end

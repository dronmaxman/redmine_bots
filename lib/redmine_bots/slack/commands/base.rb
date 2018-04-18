module RedmineBots::Slack::Commands
  class Base
    class << self
      def inherited(klass)
        klass.prepend(
          Module.new do
            def call
              (not_authorized && return) unless authorized?
              (private_only && return) if private_only? && !private?
              (group_only && return) if group_only? && !group?
              super
            end
          end
        )
      end

      def to_proc
        ->(client, data, match) { new(client, data, match).call }
      end

      def private_only
        define_method(:private_only?) { true }
      end

      def group_only
        define_method(:group_only?) { true }
      end

      def private_only?
        false
      end

      def group_only?
        false
      end
    end

    def initialize(client, data, match)
      @client, @data, @match = client, data, match
    end

    protected

    attr_reader :client, :data, :match

    def reply(**attrs)
      client.say(attrs.merge(channel: data.channel))
    end

    def current_user
      SlackAccount.find_by(slack_id: data.user)&.user || User.anonymous
    end

    def authorized?
      true
    end

    def not_authorized
      client.say(text: 'Not authorized', channel: data.channel)
    end

    def private_only
      client.say(text: 'Private only', channel: data.channel)
    end

    def group_only
      client.say(text: 'Group only', channel: data.channel)
    end

    def channel
      channel ||= client.web_client.conversations_info(channel: data.channel).channel
    end

    def private?
      channel.is_im
    end

    def group?
      !channel.is_im
    end

    def private_only?
      self.class.private_only?
    end

    def group_only?
      self.class.group_only?
    end
  end
end
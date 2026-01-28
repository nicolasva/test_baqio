module Service
  class Base
    attr_reader :result, :errors, :messages, :verbose

    def initialize(**args, &block)
      args.each { |k, v| instance_variable_set("@#{k}", v) }
      @callbacks = ::Service::Callbacks.new(&block) if block
      @errors = []
      @messages = []
    end

    def self.call(**args, &block)
      new(**args, &block).execute
    end

    def execute
      @result = call
      self
    end

    def error
      errors.first
    end

    def successful?
      errors.empty?
    end

    private

    def append_error(type, message, verbose: false)
      caller_info = caller.first
      errors << ::Service::Error.new(type, message, caller_info)
      if verbose
        puts "#{type} : #{message} [#{caller_info}]"
      end
    end

    def append_message(message, verbose: false)
      messages << ::Service::Message.new(message)
      if verbose
        puts message
      end
    end

    def call_back(callback_name, *args)
      @callbacks.call(callback_name, *args)
    end
  end

  class Callbacks
    def initialize(&block)
      block&.call(self)
    end

    def call(callback_name, *args)
      if callbacks.has_key?(callback_name)
        callbacks[callback_name].call(*args)
      else
        raise NoMethodError, "the callback \"#{callback_name}\" is defined."
      end
    end

    private

    def method_missing(m, *args, &block)
      if block
        callbacks[m] = block
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def callbacks
      @callbacks ||= {}
    end
  end

  class Error
    attr_reader :type, :message, :caller_info

    def initialize(type, message, caller_info)
      @type = type
      @caller_info = caller_info
      @message = message
    end
  end

  class Message
    attr_reader :time, :message

    def initialize(message)
      @time = Time.now
      @message = message
    end
  end
end

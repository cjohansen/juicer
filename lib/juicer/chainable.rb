module Juicer
  #
  # Facilitates the chain of responsibility pattern. Wraps given methods and
  # calls them in a chain.
  #
  # To make an object chainable, simply include the module and call the class
  # method chain_method for each method that should be chained.
  #
  # Example is a simplified version of the Wikipedia one
  # (http://en.wikipedia.org/wiki/Chain-of-responsibility_pattern)
  #
  #  class Logger
  #    include Juicer::Chainable
  #
  #    ERR = 3
  #    NOTICE = 5
  #    DEBUG = 7
  #
  #    def initialize(level)
  #      @level = level
  #    end
  #
  #    def log(str, level)
  #      if level <= @level
  #        write str
  #      else
  #        abort_chain
  #      end
  #    end
  #
  #    def write(str)
  #      puts str
  #    end
  #
  #    chain_method :message
  #  end
  #
  #  class EmailLogger < Logger
  #    def write(str)
  #      p "Logging by email"
  #      # ...
  #    end
  #  end
  #
  #  logger = Logger.new(Logger::NOTICE)
  #  logger.next_in_chain = EmailLogger.new(Logger::ERR)
  #
  #  logger.log("Some message", Logger::DEBUG) # Ignored
  #  logger.log("A warning", Logger::NOTICE)   # Logged to console
  #  logger.log("An error", Logger::ERR)       # Logged to console and email
  #
  module Chainable

    #
    # Add the chain_method to classes that includes the module
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    #
    # Sets the next command in the chain
    #
    def next_in_chain=(next_obj)
      @_next_in_chain = next_obj
      next_obj || self
    end

    alias_method :set_next, :next_in_chain=

    #
    # Get next command in chain
    #
    def next_in_chain
      @_next_in_chain ||= nil
      @_next_in_chain
    end

   private
    #
    # Abort the chain for the current message
    #
    def abort_chain
      @_abort_chain = true
    end

    module ClassMethods
      #
      # Sets up a method for chaining
      #
      def chain_method(method)
        original_method = "execute_#{method}".to_sym
        alias_method original_method, method

        self.class_eval <<-RUBY
          def #{method}(*args, &block)
            @_abort_chain = false
            #{original_method}(*args, &block)
            next_in_chain.#{method}(*args, &block) if !@_abort_chain && next_in_chain
            @_abort_chain = false
          end
        RUBY
      end
    end
  end
end

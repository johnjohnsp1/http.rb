require 'delegate'

require 'http/response/status/reasons'

module HTTP
  class Response
    class Status < ::Delegator
      class << self
        # Coerces given value to Status.
        #
        # @example
        #
        #   Status.coerce(:bad_request) # => Status.new(400)
        #   Status.coerce("400")        # => Status.new(400)
        #   Status.coerce(true)         # => raises HTTP::Error
        #
        # @raise [Error] if coercion is impossible
        # @param [Symbol, #to_i] object
        # @return [Status]
        def coerce(object)
          code = case
                 when object.is_a?(String)  then SYMBOL_CODES[symbolize object]
                 when object.is_a?(Symbol)  then SYMBOL_CODES[object]
                 when object.is_a?(Numeric) then object.to_i
                 else                            nil
                 end

          return new code if code

          fail Error, "Can't coerce #{object.class}(#{object}) to #{self}"
        end
        alias_method :[], :coerce

      private

        # Symbolizes given string
        #
        # @example
        #
        #   symbolize "Bad Request"           # => :bad_request
        #   symbolize "Request-URI Too Long"  # => :request_uri_too_long
        #   symbolize "I'm a Teapot"          # => :im_a_teapot
        #
        # @param [#to_s] str
        # @return [Symbol]
        def symbolize(str)
          str.to_s.downcase.gsub(/-/, ' ').gsub(/[^a-z ]/, '').gsub(/\s+/, '_').to_sym
        end
      end

      # Code to Symbol map
      #
      # @example Usage
      #
      #   SYMBOLS[400] # => :bad_request
      #   SYMBOLS[414] # => :request_uri_too_long
      #   SYMBOLS[418] # => :im_a_teapot
      #
      # @return [Hash<Fixnum => Symbol>]
      SYMBOLS = Hash[REASONS.map { |k, v| [k, symbolize(v)] }].freeze

      # Reversed {SYMBOLS} map.
      #
      # @example Usage
      #
      #   SYMBOL_CODES[:bad_request]           # => 400
      #   SYMBOL_CODES[:request_uri_too_long]  # => 414
      #   SYMBOL_CODES[:im_a_teapot]           # => 418
      #
      # @return [Hash<Symbol => Fixnum>]
      SYMBOL_CODES = Hash[SYMBOLS.map { |k, v| [v, k] }].freeze

      # @return [Fixnum] status code
      attr_reader :code

      if RUBY_VERSION < '1.9.0'
        # @param [#to_i] code
        def initialize(code)
          super __setobj__ code
        end
      end

      # @see REASONS
      # @return [String, nil] status message
      def reason
        REASONS[code]
      end

      # Symbolized {#reason}
      #
      # @return [nil] unless code is well-known (see REASONS)
      # @return [Symbol]
      def symbolize
        SYMBOLS[code]
      end

      # Printable version of HTTP Status, surrounded by quote marks,
      # with special characters escaped.
      #
      # (see String#inspect)
      def inspect
        "#{code} #{reason}".inspect
      end

      SYMBOLS.each do |code, symbol|
        class_eval <<-RUBY, __FILE__, __LINE__
          def #{symbol}?      # def bad_request?
            #{code} == code   #   400 == code
          end                 # end
        RUBY
      end

      def __setobj__(obj)
        @code = obj.to_i
      end

      def __getobj__
        @code
      end
    end
  end
end

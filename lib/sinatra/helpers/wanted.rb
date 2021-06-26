require_relative 'wanted/version'

# {include:file:README.md}

module Sinatra::Helpers::Wanted
    # Define a "No Value" object.
    # It is used to signal that a parameter exists but as no associated value.
    NO_VALUE = Object.new.then {|o|
                   def o.insect
                       "No_Value"
                   end
               }.freeze

    # Generic exception.
    # Only the inherited exceptions are raised.
    class WantedError < StandardError
        def initialize(msg=nil, value: nil, id: nil)
            super(msg)
            @value = value
            @id    = id
        end
        attr_reader :id
        attr_reader :value
    end

    # Exception to notify of syntax error
    class WantedSyntaxError < WantedError
        def initialize(msg=nil, id: nil, value: nil)
            super(msg || "syntax error", id: id, value: value)
        end
    end

    # Exception to notify of missing parameter
    class WantedMissing < WantedError
        def initialize(msg=nil, id: nil)
            super(msg || "missing parameter", id: id)
        end
    end

    # Exception to notify of object not found
    class WantedNotFound < WantedError
        def initialize(msg=nil, id: nil, value: nil)
            super(msg || "object not found", id: id, value: value)
        end
    end

    
    # Retrieve value/object associated with a parameter.
    #
    # @param param [Symbol, Object, nil, NO_VALUE]  parameter key or parameter value
    # @param type      [#[], #call]                     type checking / coercion
    # @param getter    [#[], #get, #fetch, #call, #new] object getter
    # @param id        [Symbol] name of the parameter being processed
    # @param default   [Object] default value to use if parameter is missing
    # @param no_value  [Obejct] default value to use if object is not found
    # @param missing   [:raise, :ignore, :return]       how to deal with missing parameter
    # @param not_found [:false, :ignore, :not_found, :pass]   how to deal with object not found
    #
    # @yieldparam  obj [Object]  retrieve parameter value/object
    # @yieldreturn [Object]      modified value/object
    #
    # @return [Object]           parameter value/object
    # @return [nil]              parameter is missing or it's value is nil
    # @return [NO_VALUE]         parameter has no associated value
    #
    # @raise [WantedMissing]     parameter is missing
    # @raise [WantedNotFound]    object not found
    # @raise [WantedSyntaxError] syntax error
    #
    def want(param, type=nil, getter=nil, id: nil,
             default: nil, no_value: NO_VALUE,
             missing: :ignore, not_found: :ignore, &block)
        error_handler do
            _want(param, type, getter, id: id,
                  default: default, no_value: no_value,
                  missing: missing, not_found: not_found, &block)
        end
    end
    
    # (see #want)
    def want!(param, type=nil, getter=nil, id: nil,
              default: nil, no_value: NO_VALUE,
              missing: :raise, not_found: :raise, &block)
        want(param, type, getter, id: id,
             default: default, no_value: no_value,
             missing: missing, not_found: not_found, &block)
    end
              
    # (see #want)
    def want?(param, type=nil, getter=nil, id: nil,
              default: nil, no_value: NO_VALUE,
              missing: :return, not_found: :ignore, &block)
        want(param, type, getter,
             default: default, id: id, no_value: no_value,
             missing: missing, not_found: not_found, &block)
    end


    private
    
    def _want(param, type, getter, id:,
              default:, no_value:, missing:, not_found:)
        type_method = if type
                          [ :[], :call ]
                              .find {|m| type.respond_to?(m)   } ||
                              raise(ArgumentError)
                       end
        get_method  = if getter
                          [ :[], :get, :fetch, :call, :new ]
                              .find {|m| getter.respond_to?(m) } ||
                              raise(ArgumentError)
                      end
        value, id   = if param.kind_of?(Symbol)
                          if params.include?(param)
                          then [ params[param] || NO_VALUE, param ]
                          else [ nil,                       param ]
                          end
                      else
                          [ param, nil ]
                      end

        # Check for missing param
        # Note: we consider the case where `param` is nil to be
        #       a missing parameter, otherwise the user should
        #       have explicitly passed NO_VALUE
        if value.nil?
            case missing
            when :raise  then raise WantedMissing, id: id
            when :return then return default
            when :ignore then value = default
            else raise ArgumentError
            end
        end

        # If the parameter has no value, replace it with the
        # user-supplied no_value
        # Note: if type is a dry-type, NO_VALUE will be replaced
        #       with Dry::Types::Undefined
        if value == NO_VALUE
            value = no_value
            if value == NO_VALUE &&
               defined?(Dry::Types) && type.kind_of?(Dry::Types::Type)
                value = Dry::Types::Undefined
            end
        end
        
        # Build value from various check/conversion
        if type_method
            value = type.public_send(type_method, value) 
        end
        if !value.nil? && get_method
            value = getter.public_send(get_method, value)
            # Check if we consider it as not found
            if value.nil?
                case not_found
                when :raise     then raise WantedNotFound, id: id
                when :not_found then self.not_found
                when :pass      then self.pass
                when :ignore
                else raise ArgumentError
                end
            end
        end
        if block_given?
            value = yield(value)
        end

        # Return value
        value
    rescue Dry::Types::CoercionError, Dry::Types::ConstraintError
        raise WantedSyntaxError, value: value, id: id
    end

    def error_handler
        if defined?(Dry::Types)
            begin
                yield
            rescue Dry::Types::CoercionError, Dry::Types::ConstraintError
                raise WantedSyntaxError, value: value, id: id
            end
        else
            yield
        end
    end
   
end


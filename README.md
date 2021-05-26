sinatra-wanted
==============

Parameter processing for Sinatra framework

Allow to easily expressing parameter requirements, such as:

* required/optional
* type checking/coercion (best done using dry-types)
* object retrieval (using Sequel, LOM, or class instantiating)
* further processing (such as conversion) using block

Examples
========

Note that in URL query `?param` as no value but `?param=` as the
empty string value (ie: "").


~~~ruby
# Retrieve a required VM model from Sequel
vm       = want! :vm,       Types::VM::Name, VM

# Retrieve a require public key (in rfc4716 or openssh format)
# and ensure the final result is in openssh format:
pubkey   = want! :pubkey,   Types::SSHPublicKey do |k|
                                SSHPublicKey.to_openssh(k)
                            end

# Get an optional parameter called locked which is a boolean,
# if the parameter is present but as no value use true
locked   = want? :locked,   Types::Params::Bool.default(true)

# Parameter is optional but in this case we require a default value
# which will be processed
type     = want  :type,     Types::VM::Stop, default: 'savestate'
~~~

Parameter processing
====================
Parameter value retrieval will be processed as follow, please
read carefully:

1. Retrieve parameter value
   If `param` is a symbol, it's key will be looked up
   in the sinatra parameter list and assign special value:
   * nil      : key not found
   * NO_VALUE : key found but no value (ie: nil) associated

2. Check for missing parameter (ie: nil)
   According to named-parameter `missing`:
   * :raise     : raise exception WantedMissing
   * :ignore    : use the `default` value and continue processing
   * :return    : return the `default` value (all processing stops here)

3. Check for missing value (ie: NO_VALUE)
   * If value is missing use instead the value from the
     named parameter `no_value` (default to NO_VALUE)
   * If the type checking/coercion is one of dry-type, the NO_VALUE
     is changed for the Dry::Types::Undefined so that DRY can
     correctly processed undefined value.

4. Perform the type checking / coercion
   This is done by using the first available method: [], call.

   The easiest (but not required) is to use the dry-types library

5. Unless value is already nil, use a getter to retrieve the real
   value object. Object retrieval will be considered as not found,
   if the getter returns nil
   This is done by using the first available method: [], get,
   fetch, call, new.

   Usually getter will be Sequel Model, LDAP Object Model,
   Class, ...

   If not found (ie: nil), according to named-parameter `not_found`:
   
   * :raise     : raise exception WantedNotFound
   * :ignore    : keep the value as nil and continue processing
   * :not_found : execute the sinatra #not_found action
   * :pass      : execute the sinatra #pass action

6. Apply block processing

\#want, #want!, and #want? are the same methods with different default
for the `missing` and `not_found` named parameter

| method | missing | not_found  |
|--------|---------|------------|
| want   | :ignore | :ignore    |
| want!  | :raise  | :raise     |
| want?  | :return | :ignore    |


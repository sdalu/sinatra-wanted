# -*- encoding: utf-8 -*-

require_relative 'lib/sinatra/helpers/wanted/version'

Gem::Specification.new do |s|
    s.name        = 'sinatra-wanted'
    s.version     = Sinatra::Helpers::Wanted::VERSION
    s.summary     = "Parameters processing for Sinatra framework"
    s.description =  <<~EOF
      Ease processing of parameters in Sinatra framework.
      Integrates well with dry-types, sequel, ...

      Example:
        want! :user,    Dry::Types::String, User
        want? :expired, Dry::Types::Params::Bool.default(true)
      EOF

    s.homepage    = 'https://gitlab.com/sdalu/sinatra-wanted'
    s.license     = 'MIT'

    s.authors     = [ "Stéphane D'Alu" ]
    s.email       = [ 'stephane.dalu@insa-lyon.fr' ]

    s.files       = %w[ README.md sinatra-wanted.gemspec ] +
                    Dir['lib/**/*.rb']

    s.add_dependency 'sinatra'
    s.add_development_dependency 'yard', '~>0'
    s.add_development_dependency 'rake', '~>13'
end

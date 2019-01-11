require 'active_support/all'
require 'cgi'
require 'haml'
require 'jwt'
require 'pathname'
require 'rest-client'
require 'sinatra/base'
require 'yaml'


$logger = Logger.new(STDOUT)
$logger.level = Logger::WARN

################################################################################
### options and config #########################################################
################################################################################
 

$config = YAML.load_file(
  File.expand_path('config.yml', File.dirname(__FILE__))
).with_indifferent_access.tap do |c|
  c[:my_private_key] = OpenSSL::PKey.read(c[:my_private_key])
  c[:my_public_key] = OpenSSL::PKey.read(c[:my_public_key])
  c[:leihs_public_key] = OpenSSL::PKey.read(c[:leihs_public_key])
end
 
################################################################################
### the web app ################################################################
################################################################################

class AuthenticatorApp <  Sinatra::Base


	# some helpers ###############################################################

  def html_layout
    Haml::Engine.new <<-HAML.strip_heredoc
      %html
        %head 
          %title ZHdK AAI-Shibboleth Leihs Authentication-System
      %body
        %h1 ZHdK AAI-Shibboleth Leihs Authentication-System
        = yield
    HAML
  end

  def env_table
    Haml::Engine.new(
    <<-HAML.strip_heredoc
      %table
        - @env.to_hash.each do |k, v|
          %tr
            %td
              %pre= k
            %td
              %pre= v
    HAML
    )
  end


  ### error handling and error messages ########################################

  def expired_message sign_in_request_token
    sign_in_request = JWT.decode sign_in_request_token, 
      $config[:leihs_public_key], false, { algorithm: 'ES256' }

    <<-HTML.strip_heredoc
        <html>
          <head></head>
          <body>
            <h1>Error: Token Expired </h1>
            <p> Please <a href="#{sign_in_request[0]['server_base_url']}"> try again. </a></p>
          </body>
        </html>
    HTML
  end

  def generic_error_message e
    $logger.error "#{e} #{e.backtrace}"
    <<-HTML.strip_heredoc
        <html>
          <head></head>
          <body>
            <h1> Unspecified Error in leihs-AAI Authentication Service </h1>
            <p> Please try again. </p>
            <p> Contact your leihs administrator if this problem occurs again. </p>
          </body>
        </html>
    HTML
  end

	### routes ####################################################################


  get '/status' do
    'OK'
  end

  get '/' do
    html_layout.render do
    Haml::Engine.new(<<-HAML.strip_heredoc
      %p 
        See 
        %a{href: '/Shibboleth.sso/Session'} 
          %code /Shibboleth.sso/Session
     HAML
    ).render
    end
  end

	get '/debug' do
		if ENV['RACK_ENV'] == 'development'
			require 'pry'
			require 'pry-remote'
			binding.pry_remote
		end
		status 404
		'Error 404'
	end


  get '/sign-in' do

    begin 

      sign_in_request_token = params[:token]
      sign_in_request = JWT.decode sign_in_request_token, 
        $config[:leihs_public_key], true, { algorithm: 'ES256' }
      email = sign_in_request.first["email"].presence.try(:downcase)

      throw ArgumentError, "email must be present" unless email

      token = JWT.encode({
        sign_in_request_token: sign_in_request_token
        # and more if we ever need it
      }, $config[:my_private_key], 'ES256')

      url = $config[:my_external_base_url] + "/Shibboleth.sso/Login?target=" \
        + CGI::escape("#{$config[:my_external_base_url]}/callback?token=#{token}")

      redirect url

    rescue JWT::ExpiredSignature => e
      expired_message sign_in_request_token
    rescue StandardError => e
      generic_error_message e
    end

  end



  ### callback ##################################################################

  get '/callback' do

    begin 

      token_data = JWT.decode(params[:token], 
                              $config[:my_public_key], true, { algorithm: 'ES256'}) \
        .first.with_indifferent_access

      sign_in_request_token = token_data[:sign_in_request_token]

      sign_in_request = JWT.decode sign_in_request_token, 
        $config[:leihs_public_key], true, { algorithm: 'ES256' }

      raise 'Env var `mail` must be present in callback' unless @env['mail'].presence

      token = JWT.encode({
        sign_in_request_token: sign_in_request_token,
        email: @env['mail'].downcase,
        success: true}, $config[:my_private_key], 'ES256')

      url = sign_in_request.first["server_base_url"] \
        + sign_in_request.first['path'] + "?token=#{token}"

      redirect url

    rescue JWT::ExpiredSignature => e
      expired_message sign_in_request_token
    rescue StandardError => e
      generic_error_message e
    end

  end


  get '/*' do
    pass if /\/Shibboleth/ =~ request.path_info 
    status 404
    html_layout.render do
      Haml::Engine.new(
        <<-HAML.strip_heredoc
          %h2{ style: "color: red;"} Error 404 
          %p The requested resource does not exist.
        HAML
      ).render
    end
  end

end

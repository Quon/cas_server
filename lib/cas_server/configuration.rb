module CasServer
  module Configuration
    mattr_accessor :ticket_expiration
    @@ticket_expiration = 3.minutes
    
    mattr_accessor :service_manager
    @@service_manager = :mock
    
    mattr_accessor :exception_handler
    @@exception_handler = :default_exception_handler
    
    mattr_accessor :ssl_enabled
    @@ssl_enabled = false
    
    mattr_accessor :logger
    @@logger = CasServer::MockLogger.new
  end
end
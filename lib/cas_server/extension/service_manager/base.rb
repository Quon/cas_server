require 'uri'

module CasServer
  module Extension
    module ServiceManager
      class Base
        class << self       
          def implementations
            @@implementations ||= []
          end

          def inherited(subklass)
            implementations << subklass
            super
          end

          def model
            @model ||= name.demodulize.underscore.to_sym
          end
        end
        
        attr_reader :service_url
        attr_reader :server
      
        def initialize(service_url, rack_server)
          @server = rack_server
          @service_url = service_url.is_a?(URI) ? service_url : (URI.parse(service_url.to_s) rescue nil)
          raise CasServer::InvalidServiceURL.new(service_url) unless self.service_url.is_a?(URI::HTTP)
        end
      
        # This method has to be overridden
        def valid?
          raise NotImplementedError.new("#{self.class.name}#valid?")
        end
        
        def validate!
          raise CasServer::InvalidServiceURL.new(service_url) unless valid?
          true
        end        
      end #Base
    end #ServiceManager
  end #Extension
end #CasServer
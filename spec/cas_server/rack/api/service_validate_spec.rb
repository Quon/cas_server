require File.dirname(__FILE__) + '/../../../spec_helper'

describe CasServer::Rack::Api::ServiceValidate do
  before do
    @service_url = 'http://toto.com'
    @tgc= CasServer::Entity::TicketGrantingCookie.generate_for('username')
    @ts = CasServer::Entity::ServiceTicket.generate_for(@tgc,@service_url)
    @params = {'service' => @service_url, 'ticket' => @ts.value}
    @cookies = {}
    @env = Rack::MockRequest.env_for("http://example.com:8080/")
    @rack = CasServer::Rack::Api::ServiceValidate.new
    @rack.stub!(:cookies).and_return(@cookies)
    @rack.stub!(:params).and_return(@params)
  end
  
  #2.5
  it "checks the validity of a service ticket and returns an XML-fragment response" do
    CasServer::Entity::ServiceTicket.should_receive(:validate_ticket!).with(@ts.value,@service_url).and_return(@ts)
    @rack.call(@env)
  end
  
  #2.5
  it "MUST also generate and issue proxy-granting tickets when requested"
  
  #2.5
  it "is recommanded that the error explain that validation failed when a proxy ticket was passed"
  
  
  describe "on successful serviceValidate" do
    #2.5.2
    it "MUST return xml with <cas:authenticationSuccess>" do
      response = @rack.call(@env)
      response[2].body.should match(Regexp.new("<cas:authenticationSuccess>.*</cas:authenticationSuccess>",Regexp::MULTILINE))
    end
    
    #2.5.2
    it "MUST return the username in the xml" do
      response = @rack.call(@env)
      response[2].body =~ %r{<cas:user>(.*)</cas:user>}
      $1.should == 'username'
    end
    
    #Not in the CasSpec
    it "Could provides extended attributes along with the user under <sc:profile>, this is an XML has" do
      @ts.should_receive(:extra_attributes).and_return({:firstname => 'toto'})
      CasServer::Entity::ServiceTicket.should_receive(:validate_ticket!).and_return(@ts)
      response = @rack.call(@env)
      response[2].body.should match(%r{<firstname>toto</firstname>})
    end
  end
  
  describe "on failed serviceValidate" do
    #2.5.2
    it "MUST return xml with <cas:authenticationFailure>, the error code and the error description" do
      @params.delete('service')
      response = @rack.call(@env)
      response[2].body.should match(Regexp.new("<cas:authenticationFailure.*</cas:authenticationFailure>",Regexp::MULTILINE))
      response[2].body.should match(/#{CasServer::MissingMandatoryParams.new(:service).error_identifier}/)
      response[2].body.should match(/#{CasServer::MissingMandatoryParams.new(:service).message}/)
    end
  end
  
  #2.5.1
  it "should display an error in case of invalid params" do
    @params.delete('service')
    @rack.call(@env)
    @rack.should be_error
    @rack.errors.first.class.should == CasServer::MissingMandatoryParams
  end
  
  describe 'when parameters new is set' do
    #2.5.2
    it "MUST not validate service ticket that has been created via sso"
  
    #2.5.3
     it "may use INVALID_TICKET 'code' when service ticket has been created via sso"
  end
  
  #2.5.3
  it "may use INVALID_REQUEST 'code' in case missing mandatory params" do
    @params.delete('service')
    @rack.call(@env)
    @rack.should be_error
    @rack.errors.first.error_identifier.should == 'INVALID_REQUEST'
  end
  
  #2.5.3
  it "may use INVALID_TICKET 'code' when ticket provided was not valid" do
    @params['ticket'] = 'bad'
    @rack.call(@env)
    @rack.should be_error
    @rack.errors.first.error_identifier.should == 'INVALID_TICKET'
  end
  
  #2.5.3
  it "may use INVALID_SERVICE 'code' when the ticket provided was valid, but the service specified was not" do
    @params['service'] = 'http://tata.com'
    @rack.call(@env)
    @rack.should be_error
    @rack.errors.first.error_identifier.should == 'INVALID_SERVICE'
  end
  
  #2.5.3
  it "MUST invalidate the ticket and disallow future validation of that same ticket in case of INVALID_SERVICE" do
    @params['service'] = 'http://tata.com'
    @rack.call(@env)
    @rack.should be_error
    lambda {
      @ts.class.validate_ticket!(@ts.value,@ts.service)
    }.should raise_error(CasServer::InvalidTicket)
  end
end
require File.dirname(__FILE__) + '/../../spec_helper'

describe OmniAuth::Strategies::Crowd, :type=>:strategy do
  include OmniAuth::Test::StrategyTestCase
  def strategy
    @crowd_server_url ||= 'https://crowd.example.org'
    @application_name ||= 'bogus_app'
    @application_password ||= 'bogus_app_password'
    [OmniAuth::Strategies::Crowd, {:crowd_server_url => @crowd_server_url, :application_name=>@application_name, :application_password=>@application_password}]
  end

    describe 'GET /auth/crowd' do
      before do
        get '/auth/crowd'
      end

      it 'should show the login form' do
        last_response.should be_ok
      end
    end

    describe 'POST /auth/crowd' do
      before do
        post '/auth/crowd', :username=>'foo', :password=>'bar'
      end

      it 'should redirect to callback' do
        last_response.should be_redirect
        last_response.headers['Location'].should == '/auth/crowd/callback'
      end
    end

    describe 'GET /auth/crowd/callback without any credentials' do
      before do
        get '/auth/crowd/callback'
      end
      it 'should fail' do
        last_response.should be_redirect
        last_response.headers['Location'].should =~ /no_credentials/
      end
    end

      describe 'GET /auth/crowd/callback with credentials can be successful' do
        before do
          stub_request(:post, "https://bogus_app:bogus_app_password@crowd.example.org/rest/usermanagement/latest/authentication?username=foo").
            to_return(:body => File.read(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'success.xml')))
          get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
        end
        it 'should call through to the master app' do
          last_response.body.should == 'true'
        end
          it 'should have an auth hash' do
            auth = last_request.env['omniauth.auth']
            auth.should be_kind_of(Hash)
          end
          it 'should have good data' do
            auth = last_request.env['omniauth.auth']['provider'].should == :crowd
            auth = last_request.env['omniauth.auth']['uid'].should == 'foo'
            auth = last_request.env['omniauth.auth']['user_info'].should be_kind_of(Hash)
          end
      end

      describe 'GET /auth/crowd/callback with credentials will fail' do
        before do
          stub_request(:post, "https://bogus_app:bogus_app_password@crowd.example.org/rest/usermanagement/latest/authentication?username=foo").
            to_return(:code=>400)
          get '/auth/crowd/callback', nil, 'rack.session'=>{'omniauth.crowd'=> {"username"=>"foo", "password"=>"ba"}}
        end
        it 'should fail' do
          last_response.should be_redirect
          last_response.headers['Location'].should =~ /invalid_credentials/
        end
      end
end

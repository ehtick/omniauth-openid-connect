class StrategyTestCase < Minitest::Test
  class DummyApp
    def call(env); end
  end

  attr_accessor :identifier, :secret

  def setup
    @identifier = '1234'
    @secret = '1234asdgat3'
  end

  def client
    strategy.client
  end

  def user_info
    @user_info ||= OpenIDConnect::ResponseObject::UserInfo.new(
      sub: SecureRandom.hex(16),
      name: Faker::Name.name,
      email: Faker::Internet.email,
      nickname: Faker::Name.first_name,
      preferred_username: Faker::Internet.user_name,
      given_name: Faker::Name.first_name,
      family_name: Faker::Name.last_name,
      gender: 'female',
      picture: Faker::Internet.url + '.png',
      phone_number: Faker::PhoneNumber.phone_number,
      website: Faker::Internet.url,
      # custom claim
      foobar: 'bar',
      isAdmin: false
    )
  end

  def request
    @request ||= stub('Request').tap do |request|
      request.stubs(:params).returns({})
      request.stubs(:cookies).returns({})
      request.stubs(:env).returns({})
      request.stubs(:scheme).returns({})
      request.stubs(:ssl?).returns(false)
      request.stubs(:path).returns('/')
    end
  end

  def strategy
    @strategy ||= OmniAuth::Strategies::OpenIDConnect.new(DummyApp.new).tap do |strategy|
      strategy.options.client_options.identifier = @identifier
      strategy.options.client_options.secret = @secret
      strategy.stubs(:request).returns(request)
      strategy.stubs(:user_info).returns(user_info)
    end
  end

  # Allows to test that properly handled authentication errors occured within the scope of the passed block
  def catching_failures
    original_failure_handler = OmniAuth.config.on_failure
    @failure_env = nil
    OmniAuth.config.on_failure = ->(env) { @failure_env = env; [400, {}, "sad sad"] }
    yield
  ensure
    OmniAuth.config.on_failure = original_failure_handler
  end

  def expect_authentication_error(type, exception_class: nil, message: nil)
    assert_equal(@failure_env["omniauth.error.type"], type)
    assert_equal(@failure_env["omniauth.error"].class, exception_class) if exception_class
    assert_equal(@failure_env["omniauth.error"]&.message, message) if message
  end

  def expect_no_authentication_error
    assert(@failure_env.nil?, "expected no authentication errors")
  end
end

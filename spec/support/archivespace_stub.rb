# frozen_string_literal: true
module AspaceStubbing
  def stub_aspace_login
    stub_request(:post, "https://aspace.test.org/staff/api/users/test/login?password=password").to_return(status: 200, body: { session: "1" }.to_json, headers: { "Content-Type": "application/json" })
  end
end

RSpec.configure do |config|
  config.include AspaceStubbing
end

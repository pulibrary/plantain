# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver(:selenium) do |app|
  capability_args = %w[disable-gpu disable-setuid-sandbox]
  capability_args << "headless" unless ENV['RUN_IN_BROWSER'] == 'true'
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: capability_args }
  )
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless" unless ENV['RUN_IN_BROWSER'] == 'true'
  browser_options.args << "--disable-gpu"

  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.read_timeout = 120
  http_client.open_timeout = 120
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities,
                                 http_client: http_client,
                                 options: browser_options)
end

Capybara.javascript_driver = :selenium
Capybara.default_max_wait_time = 60

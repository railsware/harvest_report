require 'capybara'
require 'capybara/dsl'
require 'capybara/selenium/driver'
require 'cgi'
require 'optparse'

module HarvestReport
  class Runner
    include Capybara::DSL

    def self.run(*args)
      new(ARGV).run
    end

    def initialize(args)
      @options = {
        :download_dir     => '/tmp/harvest_report',
        :download_timeout => 60
      }

      parse_options!(args)
      validate_options!
    end

    attr_reader :options

    def run
      Capybara.register_driver :chrome do |app|
        profile = ::Selenium::WebDriver::Chrome::Profile.new
        profile["download.default_directory"] = options[:download_dir]
        Capybara::Selenium::Driver.new(app, :browser => :chrome, :profile => profile)
      end
      Capybara.current_driver = :chrome
      Capybara.reset_sessions!

      page.visit "https://#{options[:domain]}.harvestapp.com/account/login"
      page.click_link "Or sign in with your Harvest account"

      page.fill_in "Email", :with => options[:email]
      page.fill_in "Password", :with => options[:password]
      page.click_button "Sign In"

      element = page.find_link("My Profile")
      user_id = element[:href].scan(/\d+/).first

      export_url = "https://#{options[:domain]}.harvestapp.com/xlsx/export/user/#{user_id}"
      export_url << "?"
      export_url << "start_date=#{CGI.escape(options[:start_date])}&"
      export_url << "end_date=#{CGI.escape(options[:stop_date])}"

      page.visit export_url

      wait_for_download

      puts "Report downloaded to #{options[:download_dir]}"

      sleep 1
    end

    protected

    def parse_options!(args)
      OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [OPTIONS]"

        opts.on("--email EMAIL", "your harvest email") { |v| options[:email] = v }
        opts.on("--password PASSWORD", "your harvest password") { |v| options[:password] = v }
        opts.on("--domain DOMAIN", "harvest domain") { |v| options[:domain] = v }
        opts.on("--start-date START_DATE", "report start date (e.g 2012-01-01)") { |v| options[:start_date] = v }
        opts.on("--stop-date STOP_DATE",  "report stop date (e.g 2012-01-31)")  { |v| options[:stop_date] = v  }
        opts.on("--directory DIRECTORY", "reports directory (default #{options[:download_dir]})")  { |v| options[:download_dir] = v  }

        opts.on_tail("-h", "--help", "Show this message") { puts opts; exit }
      end.parse!(args)
    end

    def validate_options!
      [:email, :password, :domain, :start_date, :stop_date].each do |name|
        raise ArgumentError, "#{name.inspect} required" unless options[name]
      end
    end

    def wait_for_download
      Timeout.timeout(@download_timeout) do
        sleep 0.1 until downloaded?
      end
    end

    def downloaded?
      !downloading? && downloads.any?
    end

    def downloading?
      downloads.grep(/\.crdownload$/).any?
    end

    def downloads
      Dir["#{@download_dir}/*"]
    end
  end
end

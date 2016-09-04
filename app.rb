require "sinatra"

URLS = {"http://dashingdemo.herokuapp.com/sample" => {zoom_factor: 4}}
set :bind, "0.0.0.0"
set :host, "http://10.10.25.222:4567"


require_relative 'lib/screenshot_refresher'
screenshot_refresher = ScreenshotRefresher.new(URLS, directory: 'public/screenshots')
screenshot_refresher.start

require_relative 'lib/dlna_pusher'
dlna_pusher = DlnaPusher.new(host: Sinatra::Application.settings.host)
dlna_pusher.start_scanning

get '/' do
  @urls_count = URLS.size
  @latest_screenshots = URLS.map do |url, _options|
    screenshot_refresher.most_recent_screenshot_for(url).sub('public/', '')
  end
  @devices = dlna_pusher.devices
  erb :index
end

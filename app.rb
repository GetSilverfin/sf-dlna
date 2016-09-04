require "sinatra"

URLS = {"http://dashingdemo.herokuapp.com/sample" => {zoom_factor: 4}}
set :bind, "0.0.0.0"
set :host, "http://10.10.25.222:4567"


Thread.abort_on_exception = true

require_relative 'lib/screenshot_refresher'
screenshot_refresher = ScreenshotRefresher.new(URLS, directory: 'public/screenshots')
screenshot_refresher.start

require_relative 'lib/dlna_pusher'
dlna_pusher = DlnaPusher.new(host_path: "#{Sinatra::Application.settings.host}/screenshots", image_path_prefixes: screenshot_refresher.file_path_prefixes)
dlna_pusher.start_scanning
dlna_pusher.start_pushing

get '/' do
  @urls_count = URLS.size
  @latest_screenshots = URLS.map do |url, _options|
    screenshot_refresher.most_recent_screenshot_for(url).sub('public/', '')
  end
  @devices = dlna_pusher.devices
  erb :index
end

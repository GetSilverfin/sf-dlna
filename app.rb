require "sinatra"

URLS = {"http://dashingdemo.herokuapp.com/sample" => {zoom_factor: 4}}

require_relative 'lib/screenshot_refresher'
screenshot_refresher = ScreenshotRefresher.new(URLS, directory: 'public/screenshots')
screenshot_refresher.start

get '/' do
  @urls_count = URLS.size
  @latest_screenshots = URLS.map do |url, _options|
    screenshot_refresher.most_recent_screenshot_for(url).sub('public/', '')
  end
  erb :index
end

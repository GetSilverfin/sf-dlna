class ScreenshotRefresher
  SCRIPT = File.expand_path('../capture_screenshot.js', __FILE__)

  def initialize(urls)
    @urls = urls
  end

  def take_screenshot(url, path:, zoom_factor: 1, width: 3840, height: 2160)
    `phantomjs --ssl-protocol=any #{SCRIPT} #{url} #{path} #{width} #{height} #{zoom_factor}`
  end
end

class ScreenshotRefresher
  SCRIPT = File.expand_path('../capture_screenshot.js', __FILE__)

  def initialize(urls, interval: 120, directory: 'screenshots', format: 'jpg')
    @urls = urls
    @interval = interval
    @directory = directory
    @format = format
  end

  def start
    Thread.new do
      while true
        clean_directory
        @urls.each do |url, options|
          filename_with_timestamp = "#{file_prefix_for_url(url)}_#{Time.new.strftime("%Y%m%d-%H%M%L")}"
          path = "#{@directory}/#{filename_with_timestamp}.#{@format}"
          take_screenshot(url, options.merge(path: path))
        end
        sleep @interval
      end
    end
  end

  def take_screenshot(url, path:, zoom_factor: 1, width: 3840, height: 2160)
    `phantomjs --ssl-protocol=any #{SCRIPT} #{url} #{path} #{width} #{height} #{zoom_factor}`
  end

  def file_prefix_for_url(url)
    uri = URI.parse(url)
    "#{uri.host.tr('.','-')}-#{uri.path.tr('./','--')}"
  end

  def clean_directory
    Dir.glob("#{@directory}/*.#{@format}").each do |filename|
      file_age = (Time.now - File.ctime(filename))
      File.delete(filename) if file_age > 100 * @interval
    end
  end
end

require 'easy_upnp'

class DlnaPusher
  attr_reader :devices
  SEARCH_INTERVAL = 5 * 60
  def initialize(host: )
    @host = host
    @devices = []
    @device_lock = Mutex.new
  end

  def start_scanning
    Thread.new do
      searcher = EasyUpnp::SsdpSearcher.new
      while true
        devices_found = searcher.search("urn:schemas-upnp-org:service:AVTransport:3")
        @device_lock.synchronize do
          @devices = devices_found.dup
        end
        sleep SEARCH_INTERVAL
      end
    end
  end

  def push_image_to_all_devices(uri)
    @device_lock.synchronize do
      uri = "#{@host}/dog.jpg"
      metadata = <<-METADATA
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/"><item restricted="1"><dc:title>Pushed Image</dc:title><res protocolInfo="http-get:*:image/jpeg" resolution="600x400" size="163267">#{uri}</res><upnp:class>object.item.imageItem.photo</upnp:class></item></DIDL-Lite>
        METADATA

      @devices.each do |device|
        service = device.service("urn:schemas-upnp-org:service:AVTransport:3")
        service.Stop(InstanceID: 0) if service.GetCurrentTransportActions(InstanceID: 0)[:Actions].include?('Stop')
        sleep 0.1
        service.SetAVTransportURI(InstanceID: 0, CurrentURI: uri, CurrentURIMetaData: metadata)
        service.Play(InstanceID: 0, Speed: 1)
      end
    end
  end
end

require 'easy_upnp'

class DlnaPusher
  attr_reader :devices
  SEARCH_INTERVAL = 5
  UPDATE_SCREEN_INTERVAL = 60

  def initialize(host_path:, image_path_prefixes:)
    @host_path = host_path
    @image_path_prefixes = image_path_prefixes
    @devices = []
    @devices_lock = Mutex.new
  end

  def start_scanning
    Thread.new do
      searcher = EasyUpnp::SsdpSearcher.new
      while true
        devices_found = searcher.search("urn:schemas-upnp-org:service:AVTransport:3")
        unless @devices.map(&:host).sort == devices_found.map(&:host).sort
          @devices_lock.synchronize do
            @devices = devices_found.dup
          end
          # give the TV some time to boot
          sleep 10
          push_next_image
        end
        sleep SEARCH_INTERVAL
      end
    end
  end

  def start_pushing
    Thread.new do
      while true
        push_next_image
        sleep UPDATE_SCREEN_INTERVAL
      end
    end
  end

  def push_image_to_all_devices(path)
    @devices_lock.synchronize do
      uri = "#{@host_path}/#{File.basename(path)}"
      metadata = <<-METADATA
        <DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:dlna="urn:schemas-dlna-org:metadata-1-0/"><item restricted="1"><dc:title>Pushed Image</dc:title><res protocolInfo="http-get:*:image/jpeg" resolution="600x400" size="163267">#{uri}</res><upnp:class>object.item.imageItem.photo</upnp:class></item></DIDL-Lite>
        METADATA

      @devices.each do |device|
        begin
          service = device.service("urn:schemas-upnp-org:service:AVTransport:3")
          allowed_actions = service.GetCurrentTransportActions(InstanceID: 0)[:Actions]
          service.Stop(InstanceID: 0) if allowed_actions && allowed_actions.include?('Stop')
          sleep 0.1
          service.SetAVTransportURI(InstanceID: 0, CurrentURI: uri, CurrentURIMetaData: metadata)
          service.Play(InstanceID: 0, Speed: 1)
        rescue Savon::SOAPFault => e
          error_hash = e.to_hash
          if error_hash[:fault] && error_hash[:fault][:detail] && error_hash[:fault][:detail][:u_pn_p_error] && error_hash[:fault][:detail][:u_pn_p_error][:error_code] == "705"
            retry
          else
            raise "#{error_hash}"
          end
        rescue StandardError => e
          puts e
        end
      end
    end
  end

  def push_next_image
    next_image_path = @image_path_prefixes.rotate!.first
    latest_filename = Dir.glob("#{next_image_path}*").max_by do |filename|
      File.mtime(filename)
    end
    push_image_to_all_devices(latest_filename)
  end
end

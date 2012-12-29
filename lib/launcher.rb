class Launcher
  DeviceNotFoundError = Class.new(IOError)

  DEVICE = {
    vendor_id:   0x2123,
    product_id:  0x1010
  }

  COMMANDS = {
    down:   0x01,
    up:     0x02,
    left:   0x04,
    right:  0x08,
    fire:   0x10,
    stop:   0x20
  }

 MISSILES = {
    number:             4,
    reload_delay_secs:  4.5
  }

  REQUEST_TYPE  = 0x21
  REQUEST       = 0x09
  PAYLOAD_START = 0x02
  MAX_DURATION  = 5 #seconds

  def self.connect
    usb = LIBUSB::Context.new
    launcher = usb.devices(
      idVendor: DEVICE[:vendor_id],
      idProduct: DEVICE[:product_id]
    ).first

    raise DeviceNotFoundError, 'Launcher was not found.' if launcher.nil?
    new(launcher)
  end

  def initialize(device)
    @device = device
    @handle = @device.open
  end

  def move(direction, duration = 0.5)
    send! direction

    if duration > 0
      sleep duration
      stop!
    end
  end

  [:up, :down, :left, :right].each do |direction|
    define_method direction do |duration=0.5|
      move direction, duration
    end

    define_method :"#{direction}!" do
      move direction, MAX_DURATION
    end
  end

  def fire!(number = 1)
    number = 1 unless (1..MISSILES[:number]).cover?(number)

    number.times do
      send! :fire
      sleep MISSILES[:reload_delay_secs]
    end
  end

  def stop!
    send! :stop
  end

private

  def send!(command)
    @handle.control_transfer(
      bmRequestType: REQUEST_TYPE,
      bRequest: REQUEST,
      wValue: 0,
      wIndex: 0,
      dataOut: build_payload(COMMANDS[command.to_sym]),
      timeout: 0
    )
  end

  def build_payload(command)
    [PAYLOAD_START, command, 0, 0, 0, 0, 0, 0].pack('CCCCCCCC')
  end
end
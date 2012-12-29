# Public: Controller for the thunder USB missile launcher
#
# Examples
#
#   l = Launcher.connect
#   l.move(:right, 1)     # move right 1 second
#   l.fire!(2)            # fire 2 missiles
#
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

  # Public: Scan the connected USB devices for the launcher
  #
  # Returns a new Launcher instance if found, otherwise raises DeviceNotFoundError
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

  # Public: Move the launcher.
  #
  # direction - The direction to move, should be :left, :right, :up or :down
  # duration  - How long to move for in seconds. Use -1 to keep moving until
  #             a #stop! command is manually issued
  #
  # Examples
  #
  #   move(:right, 1)   # move right for 1 second
  #
  #   move(:right, -1)  # start moving right
  #   sleep(1)          # pause for 1 second
  #   stop!             # stop moving
  #
  def move(direction, duration = 0.5)
    send! direction

    if duration > 0
      sleep duration
      stop!
    end
  end

  # Public: Wrappers around the #move method
  #
  # duration - How long to move for in seconds
  #
  # Examples
  #
  #   right(1)    # moves right for 1 second
  #
  #   right!      # move right until manually stopped
  #
  [:up, :down, :left, :right].each do |direction|
    define_method direction do |duration=0.5|
      move direction, duration
    end

    define_method :"#{direction}!" do
      move direction, -1
    end
  end

  # Public: Fire (n) missiles
  #
  # number - The number of missiles to fire (between 1 and 4)
  #
  # Examples
  #
  #   fire!(2)  # fire 2 missiles
  #
  def fire!(number = 1)
    number = 1 unless (1..MISSILES[:number]).cover?(number)

    number.times do
      send! :fire
      sleep MISSILES[:reload_delay_secs]
    end
  end

  # Public: Stops all movement to the Launcher
  def stop!
    send! :stop
  end

private

  # Private: Send a command to the launcher
  #
  # command - The command to send to the launcher
  #
  # Examples
  #
  #   send!(0x20)   # send the STOP command to the launcher
  #
  def send!(command)
    payload = build_payload(COMMANDS[command.to_sym])

    @handle.control_transfer(
      bmRequestType: REQUEST_TYPE,
      bRequest: REQUEST,
      wValue: 0,
      wIndex: 0,
      dataOut: payload,
      timeout: 0
    )
  end

  # Private: Build a USB formatted packet to send to the launcher
  #
  # Examples
  #
  #   build_payload(0x10)
  #
  # Returns the byte packet to send to the launcher
  def build_payload(command)
    [PAYLOAD_START, command, 0, 0, 0, 0, 0, 0].pack('CCCCCCCC')
  end
end
# Thunder USB Missile Launcher (Dream Cheeky)

A pretty small jruby swing app to put a UI on the Dream Cheeky Thunder USB Missile Launcher (Since their drivers are windows only -- and 50MB+!)

![UI](https://raw.github.com/robhurring/thunder/master/doc/images/ui.png)

## GUI Usage

The UI also responds to the arrow keys for movement as well as the `ENTER` key to fire the missile.

```
jruby app.rb
```

## Other Usage

```ruby
require 'libusb'
require './lib/launcher'

begin
  l = Launcher.connect
  l.right 0.5   # move right 0.5 seconds
  l.up 0.2      # move up 0.2 seconds
  l.fire!(2)    # fire 2 missiles
rescue Launcher::DeviceNotFoundError
  puts "Your launcher could not be found."
  puts "Make sure your launcher is connected!"
  exit 1
end
```

## Credits

The actual launcher code is in `lib/launcher.rb` and was a rewrite of the numberous other launcher apps out there. So all credit to those
who originally found out the codes to send to the launcher to make it do its thing (Not sure who the original author is.)

Also another big thanks to [profligacy LEL](http://ihate.rubyforge.org/profligacy/lel.html) for making swing much less painful to type :)
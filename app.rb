#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'profligacy/lel'
require './lib/launcher'

class App
  include_package 'javax.swing'
  include_package 'java.awt.event'
  include Profligacy

  class MoveAction < AbstractAction
    def initialize(delegate, start_or_stop, direction)
      super()
      @delegate = delegate
      @start_or_stop = start_or_stop
      @direction = direction
    end

    def actionPerformed(e)
      @delegate.move @start_or_stop, @direction
    end
  end

  class FireAction < AbstractAction
    def initialize(delegate)
      super()
      @delegate = delegate
    end

    def actionPerformed(e)
      @delegate.fire
    end
  end

  def initialize
    @launcher = Launcher.connect
    @buttons = {
      up:     JButton.new('up'),
      down:   JButton.new('down'),
      left:   JButton.new('left'),
      right:  JButton.new('right'),
      fire:   JButton.new('fire!')
    }

    setup_ui
  end

  # Public: Move the launcher
  #
  # start_or_stop - Send :start or :stop to start or stop moving
  # direction     - Send :up, :down, :left, :right for the direction
  #
  # Examples
  #
  #   move(:start, :right)
  #
  def move(start_or_stop, direction)
    case start_or_stop.to_sym
    when :start, :mousePressed
      # Passing a non negative instead of -1 will move for that number of seconds
      @launcher.move(direction, -1)
    when :stop, :mouseReleased
      @launcher.stop!
    end
  end

  # Public: Fire the launcher
  def fire
    @launcher.fire!
  end

private

  # Public: Build our swing UI using LEL (LEL is awesome)
  # See: http://ihate.rubyforge.org/profligacy/lel.html
  #
  # TODO: breakup into smaller chunks or abstract out into different class
  def setup_ui
    app_layout = %{
      [ (200,200)^direction_pad ]
      [ (50,100)>fire_button    ]
    }

    # FIXME: LEL parser doesn't like this spaced out for some reason
    direction_pad_layout = %{
      [_|up|_]
      [left|_|right]
      [_|down|_]
    }

    # Build directional pad group layout
    direction_pad = Swing::LEL.new(JPanel, direction_pad_layout) do |c, i|
      # Inject our buttons into the layout
      c.up    = @buttons[:up]
      c.down  = @buttons[:down]
      c.left  = @buttons[:left]
      c.right = @buttons[:right]

      # Inject our button actions
      # TODO: hook these into existing MoveAction
      i.up    = {mouse: proc{ |t, e| move(t, :up) } }
      i.down  = {mouse: proc{ |t, e| move(t, :down) } }
      i.left  = {mouse: proc{ |t, e| move(t, :left) } }
      i.right = {mouse: proc{ |t, e| move(t, :right) } }
    end.build

    # Build main layout
    main_ui = Swing::LEL.new(JFrame, app_layout) do |c, i|
      c.direction_pad = direction_pad
      c.fire_button = @buttons[:fire]

      i.fire_button = {action: proc{ fire } }
    end.build(args: 'Fire Ze Missiles!!')

    root      = main_ui.getRootPane
    inputMap  = root.getInputMap(JComponent::WHEN_ANCESTOR_OF_FOCUSED_COMPONENT)
    actionMap = root.getActionMap

    # Bind our arrow keys for movement
    [:up, :down, :left, :right].each do |direction|
      inputMap.put(KeyStroke.getKeyStroke(direction.to_s.upcase), "key-#{direction}")
      inputMap.put(KeyStroke.getKeyStroke("released #{direction.to_s.upcase}"), "key-#{direction}-released")

      actionMap.put("key-#{direction}", MoveAction.new(self, :start, direction))
      actionMap.put("key-#{direction}-released", MoveAction.new(self, :stop, direction))
    end

    # Bind ENTER to the fire action
    inputMap.put(KeyStroke.getKeyStroke("ENTER"), "key-fire")
    actionMap.put("key-fire", FireAction.new(self))
  end
end

# Boot it up
SwingUtilities.invoke_later proc { App.new }.to_runnable

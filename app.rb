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

  class JIdentifiedButton < JButton
    attr_reader :identifier

    def initialize(name, identifier)
      super(name)
      @identifier = identifier
    end
  end

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
      up:     JIdentifiedButton.new('up', :up),
      down:   JIdentifiedButton.new('down', :down),
      left:   JIdentifiedButton.new('left', :right),
      right:  JIdentifiedButton.new('right', :left),
      fire:   JButton.new('fire!')
    }

    setup_ui
  end

  def move(start_or_stop, direction)
    case start_or_stop.to_sym
    when :start, :mousePressed
      @launcher.move(direction, -1)
    when :stop, :mouseReleased
      @launcher.stop!
    end
  end

  def fire
    @launcher.fire!
  end

private

  def setup_ui
    app_layout = %{
      [ (200,200)^direction_pad ]
      [ (50,100)>fire_button  ]
    }

    direction_pad_layout = %{
      [_|up|_]
      [left|_|right]
      [_|down|_]
    }

    direction_pad = Swing::LEL.new(JPanel, direction_pad_layout) do |c, i|
      c.up    = @buttons[:up]
      c.down  = @buttons[:down]
      c.left  = @buttons[:left]
      c.right = @buttons[:right]

      i.up    = {mouse: proc{ |t, e| move(t, :up) } }
      i.down  = {mouse: proc{ |t, e| move(t, :down) } }
      i.left  = {mouse: proc{ |t, e| move(t, :left) } }
      i.right = {mouse: proc{ |t, e| move(t, :right) } }
    end.build

    main_ui = Swing::LEL.new(JFrame, app_layout) do |c, i|
      c.direction_pad = direction_pad
      c.fire_button = @buttons[:fire]

      i.fire_button = {action: proc{ fire } }
    end.build(:args => "Simple LEL Example")

    root = main_ui.getRootPane

    [:up, :down, :left, :right].each do |direction|
      root.getInputMap(JComponent::WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke(direction.to_s.upcase), "key-#{direction}")
      root.getActionMap.put("key-#{direction}", MoveAction.new(self, :start, direction))

      root.getInputMap(JComponent::WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke("released #{direction.to_s.upcase}"), "key-#{direction}-released")
      root.getActionMap.put("key-#{direction}-released", MoveAction.new(self, :stop, direction))
    end

    root.getInputMap(JComponent::WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke("ENTER"), "key-fire")
    root.getActionMap.put("key-fire", FireAction.new(self))
  end
end

SwingUtilities.invoke_later proc { App.new }.to_runnable
module Tiler
  class AppDelegate
    attr_accessor :window
    def initialize
      @tiled = []
    end

    def applicationDidFinishLaunching(a_notification)
      puts "Tiler running..."
      # Insert code here to initialize your application
      @hotkeys = HotKeys.new

      @hotkeys.addHotString("T+CONTROL+OPTION+COMMAND") do
        puts "Tiling window " + Window.active.title
        @tiled << Window.active
        @tiled.uniq!
      end

      @hotkeys.addHotString("H+CONTROL+OPTION+COMMAND") do
        puts "Splitting horizontal"
        puts @tiled.inspect
        Layout.hsplit(@tiled[0], @tiled[1]).implement
      end
    end
  end
end

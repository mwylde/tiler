#
#  Window.rb
#  Tiler
#
#  Created by Micah Wylde on 2/19/12.
#  Copyright 2012 __MyCompanyName__. All rights reserved.
#

framework "Carbon"
framework "ApplicationServices"
framework "AppKit"

module Tiler
  class Rect
    attr_accessor :x, :y, :w, :h
    def initialize x, y, w, h
      @x = x; @y = y; @w = w; @h = h
    end

    def subdivide fraction, dir
      case dir
      when :horizontal
        w = @w * fraction
        [Rect.new(@x,    @y, w,    @h),
         Rect.new(x + w, @y, @w-w, @h)]
      when :vertical
        h = @h * fraction
        [Rect.new(@x, @y,     @w, @h-h),
         Rect.new(@x, @y + h, @w, @h)]
      else
        raise ArgumentException.new("Dir must be either :horizontal or :vertical")
      end
    end

    def subdivisions fractions, dir
      rects = []
      rect_rem = self
      f_rem = 1.0
      fractions.reverse.each{|f|
        rect_rem,b = rect_rem.subdivide(f/f_rem, dir)
        rects << b
        f_rem -= f
      }
      rects.reverse
    end

    def inspect
      "<#{x}, #{y}, #{w}, #{h}>"
    end
  end


  class Application
    def self.active
      info = NSWorkspace.sharedWorkspace.activeApplication
      pid = info["NSApplicationProcessIdentifier"]
      new pid
    end

    def self.all
      NSWorkspace.sharedWorkspace.runningApplications.map{|app|
        new app.processIdentifier
      }
    end
    
    def initialize pid
      @pid = pid
      @app = AXUIElementCreateApplication pid
    end

    def focused_window
      window = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@app,
                                          NSAccessibilityFocusedWindowAttribute,
                                          window)
      Window.new window[0]
    end

    def windows
      windows = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@app,
                                          KAXWindowsAttribute,
                                          windows)
      (windows[0] || []).map{|w| Window.new w} || []
    end

    def title
      title = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@app, "AXTitle", title)
      title[0]
    end
  end

  class Window
    attr_accessor :window
    
    def self.active
      Application.active.focused_window
    end

    def self.all
      Application.all.map(&:windows).flatten
    end

    def initialize window
      @window = window
    end

    def position
      position_ref = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@window,
                                          NSAccessibilityPositionAttribute,
                                          position_ref)
      pos_pt = Pointer.new("{CGPoint=dd}")
      err = AXValueGetValue(position_ref[0], KAXValueCGPointType, pos_pt)
      pos_pt[0]
    end

    def position= a
      x, y = a
      position = Pointer.new("{CGPoint=dd}")
      position.assign(NSPoint.new(x, y))
      position_ref = AXValueCreate(KAXValueCGPointType, position)
      AXUIElementSetAttributeValue(@window,
                                   NSAccessibilityPositionAttribute,
                                   position_ref)
    end

    def size
      size_ref = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@window,
                                          NSAccessibilitySizeAttribute,
                                          size_ref)
      size_pt = Pointer.new("{CGSize=dd}")
      err = AXValueGetValue(size_ref[0], KAXValueCGSizeType, size_pt)
      size_pt[0]
    end

    def size= a
      w, h =a
      size = Pointer.new("{CGSize=dd}")
      size.assign(NSSize.new(w,h))
      size_ref = AXValueCreate(KAXValueCGSizeType, size)
      AXUIElementSetAttributeValue(@window,
                                   NSAccessibilitySizeAttribute,
                                   size_ref)
    end

    def rect
      r = position + size
      Rectangle.new(*r)
    end

    def rect= r
      position = [r.x, r.y]
      size = [r.w, r.h]
    end

    def title
      title = Pointer.new(:id)
      err = AXUIElementCopyAttributeValue(@window, "AXTitle", title)
      title[0]
    end
  end
end

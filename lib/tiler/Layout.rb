module Tiler
  class LayoutNode
    attr_accessor :fraction, :children, :direction

    def initialize fraction, direction, children = []
      @fraction = fraction
      @children = children
      @direction = direction
    end

    def leaf?; false; end
  end

  class LayoutLeafNode < LayoutNode
    attr_accessor :window
    
    def initialize window, fraction = 0.0
      @window = window
      @fraction = fraction
      @children = []
    end

    def leaf?; true; end
  end

  class Layout
    def self.fullscreen window
      new LayoutLeafNode.new(window, 0.0)
    end

    def self.hsplit window1, window2
      split window1, window2, :horizontal
    end

    def self.vsplit window1, window2
      split window1, window2, :vertical
    end

    def self.split window1, window2, direction
      l1 = LayoutLeafNode.new(window1, 0.0)
      l2 = LayoutLeafNode.new(window2, 0.5)
      new LayoutNode.new(0.0, direction, [l1, l2])
    end
    
    def initialize tree
      @tree = tree
    end

    # Propogates the layout settings to the window manager
    def implement
      implement_rec(@tree, Rect.new(2048.0, 0, 1440.0, 900.0))
    end

    private
    def implement_rec node, rect
      if node.leaf?
        if w = node.window
          puts "Setting #{w.title} to #{rect.inspect}"
          #w.rect = rect
          w.position = [rect.x, rect.y]
          w.size = [rect.w, rect.h]
        end
      else
        subdivisions = rect.subdivisions(node.children.map(&:fraction), node.direction)
        node.children.zip(subdivisions).each{|n|
          implement_rec n[0], n[1]
        }
      end
    end
  end
end

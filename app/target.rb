class Target
  attr_reader :x, :y, :size, :color

  def initialize(x, y, size, color = RED)
    @x = x
    @y = y
    @size = size
    @color = color
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_solid(size + x * size, size + y * size, size, size, *color, 255)
  end

  def xy
    [x, y]
  end
end

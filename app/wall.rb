class Wall
  attr_reader :x, :y, :size

  def initialize(x, y, size)
    @x = x
    @y = y
    @size = size
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_solid(size + x * size, size + y * size, size, size, *YELLOW, 255)
  end

  def xy
    [x, y]
  end
end

class Agent
  attr_accessor :x, :y
  attr_reader :size, :logic_x, :logic_y, :state

  def initialize(x, y, size)
    @logic_x = x
    @logic_y = y
    @size = size
    @x = x * size + size_half.half
    @y = y * size + size_half.half
    @state = [:source, :target].shuffle
  end

  def size_half
    @size_half ||= size.half
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_solid(size + x - size_half.half, size + y- size_half.half, size_half, size_half, *GREEN, 255)
  end

  def toggle_state
    @state = if state == :source
      :target
    else
      :source
    end
  end

  def move(target_vector_map, source_vector_map, walls_hash)
    dx, dy = if state == :source
      source_vector_map.cell(logic_x, logic_y)
    else
      target_vector_map.cell(logic_x, logic_y)
    end

    if rand(3) == 2
      dx *= 2 + rand(3)
    end

    if rand(3) == 2
      dy *= 2 + rand(3)
    end

    self.x += dx
    self.y += dy
    @logic_x = x.idiv(size)
    @logic_y = y.idiv(size)

    if dx == 0 && dy == 0
      toggle_state
    end
  end
end

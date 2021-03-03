class VectorMap
  attr_reader :w, :h, :cells, :size, :type

  def initialize(w, h, size, type)
    @w = w
    @h = h
    @size = size
    @cells = Array.new(w) { Array.new(h) { [0, 0] } }
    @type = type
  end

  def cell(x, y)
    return [0, 0] if y < 0 || y >= h || x < 0 || x >= w
    cells[y][x]
  end

  def cell_set(x, y, value)
    cells[y][x] = value
  end

  def draw_override(ffi_draw)
    return unless $gtk.args.state.show_vectors == type

    cells.each.with_index do |row, y|
      row.each.with_index do |cell, x|
        dx, dy = cell
        dx_scaled = dx * size.idiv(3)
        dy_scaled = dy * size.idiv(3)
        cell_y = size + y * size + size_half
        cell_x = size + x * size + size_half

        ddx, ddy = case
        when dy.zero?
          [0, 1]
        when dx.zero?
          [1, 0]
        else
          [1, 0]
        end
        ffi_draw.draw_line(cell_x + (ddx), cell_y + (ddy), cell_x + dx_scaled + (ddx), cell_y + dy_scaled + (ddy), *DARK_BLUE, 255)
        ffi_draw.draw_line(cell_x, cell_y, cell_x + dx_scaled, cell_y + dy_scaled, *DARK_BLUE, 255)
        ffi_draw.draw_line(cell_x - (ddx), cell_y - (ddy), cell_x + dx_scaled - (ddx), cell_y + dy_scaled - (ddy), *DARK_BLUE, 255)
      end
    end
  end

  def size_half
    @size_half ||= size.half
  end
end

class Map
  attr_reader :w, :h, :cells, :size

  def initialize(w, h, size)
    @w = w
    @h = h
    @size = size
    @cells = Array.new(w) { Array.new(h) { -1 } }
  end

  def cell(x, y)
    return if y < 0 || y >= h || x < 0 || x >= w
    cells[y][x]
  end

  def cell_set(x, y, value)
    cells[y][x] = value
  end

  def draw_override(ffi_draw)
    ffi_draw.draw_border(size, size - 1, w * size, h * size, 0, 0, 0, 255)

    if $gtk.args.state.show_weight
      cells.each.with_index do |row, y|
        row.each.with_index do |cell, x|
          cell_y = size + size + y * size - size.idiv(4)
          cell_x = size + x * size + size.idiv(2)
          ffi_draw.draw_label(cell_x, cell_y, cell.to_s, -5, 1, 0, 0, 0, 255, nil)
        end
      end
    end
  end
end

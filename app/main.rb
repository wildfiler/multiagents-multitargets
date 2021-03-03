require 'app/agent.rb'
require 'app/map.rb'
require 'app/target.rb'
require 'app/vector_map.rb'
require 'app/wall.rb'

SIZE = 16
MAP_WIDTH = 40
MAP_HEIGHT = 40

RED = [239, 71, 111]
YELLOW = [255, 209, 102]
GREEN = [6, 214, 160]
BLUE = [17, 138, 178]
DARK_BLUE = [7, 59, 76]

ALL_DIRS = [[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]]
DIRS = ALL_DIRS.cycle.each_cons(3).take(8).map { |dirs| [dirs[1], dirs] }.to_h.merge([0, 0] => ALL_DIRS)

WALL = 99999

def fill_step(nodes, map, candidates)
  node = nodes.shift
  return unless node

  node_x, node_y, distance = node

  return if node_x < 0 || node_x >= map.w || node_y < 0 || node.y >= map.h

  map_distance = map.cell(node_x, node_y)

  return if map_distance != -1 && map_distance < distance

  candidates[map.w * node_x + node_y] = nil
  map.cell_set(node_x, node_y, distance)

  ALL_DIRS.each do |(dx, dy)|
    new_x = node_x + dx
    new_y = node_y + dy
    next if new_x < 0 || new_x >= map.w || new_y < 0 || new_y >= map.h
    new_map_distance = map.cell(new_x, new_y)
    next if new_map_distance == WALL
    candidate = candidates[map.h * new_y + new_x]

    d_distance = if dx.zero? || dy.zero?
      2
    else
      3
    end

    if candidate
      if candidate[2] > distance + d_distance
        candidate[2] = distance + d_distance
      end
    else
      next if new_map_distance != -1 && new_map_distance <= distance + d_distance
      new_node = [new_x, new_y, distance + d_distance]
      candidates[map.h * new_y + new_x] = new_node
      nodes.push(new_node)
    end
  end
end

def fill(map, targets)
  nodes = targets.map { |target| [*target.xy, 0] }
  candidates = {}

  until nodes.empty?
    fill_step(nodes, map, candidates)
  end
end

def calc_flow(map, vector_map, targets)
  map.cells.each.with_index do |row, y|
    row.each.with_index do |cell, x|
      diff_map = ALL_DIRS.map do |dir|
        dx, dy = dir
        if dx.abs == dy.abs
          if map.cell(x + dx, y) == WALL || map.cell(x, y + dy) == WALL
            next [dir, -99]
          end
        end

        neighbour = map.cell(x + dx, y + dy)

        next [dir, -99] unless neighbour

        diff = cell - neighbour

        [dir, diff]
      end

      vec, diff = diff_map.max_by(&:last)
      if diff.positive?
        vector_map.cell_set(x, y, vec)
      else
        vector_map.cell_set(x, y, [0, 0])
      end
    end
  end
end




def rebuild_map(args)
  args.state.map = Map.new(MAP_WIDTH, MAP_HEIGHT, SIZE)
  source_map = Map.new(MAP_WIDTH, MAP_HEIGHT, SIZE)
  start_at = Time.now
  place_walls(args.state.map, args.state.walls)
  place_walls(source_map, args.state.walls)
  puts "place_walls: #{Time.now - start_at}"
  start_at = Time.now
  fill(args.state.map, args.state.targets)
  fill(source_map, args.state.sources)
  puts "fill§: #{Time.now - start_at}"
  start_at = Time.now
  calc_flow(args.state.map, args.state.target_vector_map, args.state.targets)
  calc_flow(source_map, args.state.source_vector_map, args.state.sources)
  puts "calc_flow: #{Time.now - start_at}"
end

def place_walls(map, walls)
  walls.each do |wall|
    map.cell_set(wall.x, wall.y, WALL)
  end
end

def place_agent(args, x, y)
  return if x < 0 || y < 0 || x >= MAP_WIDTH || y >= MAP_HEIGHT
  args.state.agents << Agent.new(x, y, SIZE)
end

def add_wall(args, x, y)
  wall = Wall.new(x, y, SIZE)
  args.state.walls << wall
  args.state.walls_hash[x * MAP_WIDTH + y] = wall
end

def remove_wall(args, wall)
  args.state.walls.delete(wall)
  args.state.walls_hash[wall.x * MAP_WIDTH + wall.y] = nil
end

def tick(args)
  if args.state.tick_count.zero?
    args.state.show_vectors = nil
    $gtk.args.state.show_weight = false
    args.state.map = Map.new(MAP_WIDTH, MAP_HEIGHT, SIZE)
    $gtk.args.state.target_vector_map = VectorMap.new(MAP_WIDTH, MAP_HEIGHT, SIZE, :target)
    $gtk.args.state.source_vector_map = VectorMap.new(MAP_WIDTH, MAP_HEIGHT, SIZE, :source)

    args.state.targets = [
      Target.new(17, 3, SIZE),
      Target.new(5, 15, SIZE),
      Target.new(8, 14, SIZE),
      Target.new(0, 2, SIZE),
    ]

    args.state.sources = [
      Target.new(30, 17, SIZE, DARK_BLUE),
      Target.new(15, 35, SIZE, DARK_BLUE),
      Target.new(14, 28, SIZE, DARK_BLUE),
    ]

    args.state.walls = []
    add_wall(args, 10, 14)
    add_wall(args, 30, 20)

    args.state.agents = [
      Agent.new(13, 13, SIZE),
    ]

    args.state.type = :agent

    rebuild_map(args)
  end

  if args.inputs.keyboard.key_down.t
    args.state.type = case args.state.type
    when :wall
      :target
    when :target
      :agent
    when :agent
      :source
    else
      :wall
    end
  end

  if args.inputs.mouse.click
    args.state.mouse_clicked = args.state.type

    click = args.inputs.mouse.click
    x, y = click.point.x.idiv(SIZE) - 1, click.point.y.idiv(SIZE) - 1

    target = args.state.targets.find { |target| target.x == x && target.y == y }
    source = args.state.sources.find { |source| source.x == x && source.y == y }
    wall = args.state.walls_hash[MAP_WIDTH * x + y]

    if args.state.type == :wall
      if target
        args.state.targets.delete(target)
      end
      if source
        args.state.targets.delete(source)
      end

      if wall
        remove_wall(args, wall)
        args.state.mouse_clicked_type = :remove
      else
        add_wall(args, x, y)
        args.state.mouse_clicked_type = :place
      end
    elsif args.state.type == :target
      if wall
        remove_wall(args, wall)
      end
      if source
        args.state.targets.delete(source)
      end

      if target
        args.state.targets.delete(target)
        args.state.mouse_clicked_type = :remove
      else
        args.state.mouse_clicked_type = :place
        args.state.targets << Target.new(x, y, SIZE, )
      end
      rebuild_map(args)
    elsif args.state.type == :source
      if wall
        remove_wall(args, wall)
      end
      if target
        args.state.targets.delete(target)
      end

      if source
        args.state.sources.delete(source)
        args.state.mouse_clicked_type = :remove
      else
        args.state.mouse_clicked_type = :place
        args.state.sources << Target.new(x, y, SIZE, DARK_BLUE)
      end
      rebuild_map(args)
    else
      args.state.mouse_clicked_type = :place
      place_agent(args, x, y)
    end
  end

  if args.inputs.mouse.up
    args.state.mouse_clicked = nil
    args.state.mouse_clicked_type = nil
    rebuild_map(args)
  end

  if args.inputs.mouse.moved && args.state.mouse_clicked
    click = args.inputs.mouse
    x, y = click.point.x.idiv(SIZE) - 1, click.point.y.idiv(SIZE) - 1

    target = args.state.targets.find { |target| target.x == x && target.y == y }
    wall = args.state.walls_hash[MAP_WIDTH * x + y]

    case args.state.mouse_clicked
    when :wall
      if args.state.mouse_clicked_type == :place
        unless target || wall
          add_wall(args, x, y)
        end
      else
        if wall
          remove_wall(args, wall)
        end
      end
    when :target
    when :agent
      if args.state.tick_count.zmod?(2)
        place_agent(args, x, y)
      end
    end
  end

  if args.inputs.keyboard.key_down.w
    $gtk.args.state.show_weight = !$gtk.args.state.show_weight
  end

  if args.inputs.keyboard.key_down.v
    $gtk.args.state.show_vectors = case $gtk.args.state.show_vectors
    when :target then :source
    when :source then nil
    else :target
    end
  end

  # if args.state.tick_count.zmod?(30)
    args.state.agents.each do |agent|
      agent.move(args.state.target_vector_map, args.state.source_vector_map, args.state.walls_hash)
    end
  # end

  args.outputs.sprites << [
    args.state.map,
    *args.state.targets,
    *args.state.sources,
    *args.state.walls,
    * args.state.agents,
    args.state.source_vector_map,
    args.state.target_vector_map,
  ]
  args.outputs.background_color = BLUE
  args.outputs.labels << [20, $args.grid.top - 20, "FPS: " + $gtk.current_framerate.to_i.to_s]
  args.outputs.labels << [20, $args.grid.top - 40, args.state.type]
end

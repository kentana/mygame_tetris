DEFAULT_SCREEN_W = 300
DEFAULT_SCREEN_H = 600

require 'mygame/boot'

class Tetris
  COLS, ROWS = 10, 20
  BLOCK_SIDE = DEFAULT_SCREEN_W / COLS

  attr_reader :time_counter

  class Block_info
    class << self
      def shapes
        [
          { 0 => { 0 => 1, 1 => 1, 2 => 1, 3 => 1 } },
          { 0 => { 0 => 1, 1 => 1, 2 => 1, 3 => 0 },
            1 => { 0 => 1, 1 => 0, 2 => 0, 3 => 0} },
          { 0 => { 0 => 1, 1 => 1, 2 => 1, 3 => 0 },
            1 => { 0 => 0, 1 => 0, 2 => 1, 3 => 0} },
          { 0 => { 0 => 1, 1 => 1, 2 => 0, 3 => 0 },
            1 => { 0 => 1, 1 => 1, 2 => 0, 3 => 0} },
          { 0 => { 0 => 1, 1 => 1, 2 => 0, 3 => 0 },
            1 => { 0 => 0, 1 => 1, 2 => 1, 3 => 0} },
          { 0 => { 0 => 0, 1 => 1, 2 => 1, 3 => 0 },
            1 => { 0 => 1, 1 => 1, 2 => 0, 3 => 0} },
          { 0 => { 0 => 0, 1 => 1, 2 => 0, 3 => 0 },
            1 => { 0 => 1, 1 => 1, 2 => 1, 3 => 0} },
        ]
      end

      def colors
        [
         [255, 0, 0],
         [0, 255, 0],
         [0, 0, 255],
         [255, 0, 255],
         [255, 255, 0],
         [0, 255, 255],
         [255, 255, 255]
        ]
      end
    end
  end


  def initialize
    @time_counter = 0
    @field = []
    make_block
  end

  # 描画処理
  def render
    (@current + @field).each {|sq| sq.render}
  end

  # 毎フレーム処理するもの
  def update
    exit(0) if gameover?
    @time_counter += 1
    if move?(:down)
      @current.each {|sq| sq.y += 1}
    else
      reach_bottom
      clear_line
      make_block
    end
  end

  def control
    @current.each {|sq| sq.x += BLOCK_SIDE} if key_pressed?(Key::RIGHT) and move?(:right)
    @current.each {|sq| sq.x -= BLOCK_SIDE} if key_pressed?(Key::LEFT) and move?(:left)
    @current.each {|sq| sq.y += 10} if key_pressed?(Key::DOWN) and move?(:down)
    rotate if key_pressed?(Key::UP) and !hit(:rotate)
    exit(0) if key_pressed?(Key::ESCAPE)
  end

  # 現在の位置ではなく、移動後の座標で当たり判定
  def move?(direction)
    case direction
    when :left then @current.map {|sq| sq.x}.min > 0 and not hit(direction)
    when :right then @current.map {|sq| sq.x}.max + BLOCK_SIDE < 300 and not hit(direction)
    when :down then @current.map {|sq| sq.y}.max + BLOCK_SIDE < 600 and not hit(direction)
    end
  end

  private

  # 引数なしで呼び出した場合、新しいブロックを作成
  # 引数有りで呼び出した場合、回転後のブロックを作成
  def make_block(x=BLOCK_SIDE*3, y=0, shape=nil)
    id = rand(Block_info.shapes.size)
    @current_color = Block_info.colors[id] unless shape
    @current = []
    @current_shape = shape ? shape : Block_info.shapes[id]
    @current_shape.each do |row, cols|
      cols.each do |col, flag|
        if flag == 1
          pop_x = x + col * BLOCK_SIDE
          pop_y = y + row * BLOCK_SIDE
          @current <<  FillSquare.new(pop_x, pop_y, BLOCK_SIDE, BLOCK_SIDE, :color => @current_color)
          @current << Square.new(pop_x, pop_y, BLOCK_SIDE, BLOCK_SIDE, :color => [0, 0, 0])
        end
      end
    end
  end

  def hit(direction)
    @current.each do |sq|
      termination = position(sq)
      case direction
      when :left then termination[:x] -= BLOCK_SIDE
      when :right then termination[:x] += BLOCK_SIDE
      when :down then termination[:y] += BLOCK_SIDE
      end
      return true if @field.map {|square| {x:square.x, y:square.y}}.include?(termination)
    end
    return false
  end

  # 座標が半端な値のとき、整形
  def position(sq)
    col = sq.x / BLOCK_SIDE
    row = sq.y / BLOCK_SIDE
    return { x: col * BLOCK_SIDE, y: row * BLOCK_SIDE}
  end

  def reach_bottom
    @current.each do |sq|
      set_position = position(sq)
      sq.x = set_position[:x]
      sq.y = set_position[:y]
      @field << sq
    end
    @current = []
  end

  # きれいに回らない
  def rotate
    @rotated = Hash.new {|k, v| k[v] = {}}

    @current_shape.each do |row, cols|
      cols.each {|col, flag| @rotated[1-col][row] = @current_shape[row][col] if @current_shape[row][col]}
    end

    make_block @current[0].x, @current[0].y, @rotated
  end

  def clear_line
    rows = @field.map {|sq| sq.y}
    delete_lines = []
    rows.each {|i| delete_lines << i if rows.count(i) >= COLS*2 and !delete_lines.include?(i)}
    @field.delete_if {|sq| delete_lines.include?(sq.y)}

    if delete_lines.size > 0
      @field.each do |sq|
        start_y = sq.y
        delete_lines.each {|line| sq.y += BLOCK_SIDE if start_y <= line}
      end
    end
  end

  def gameover?
    @field.each {|sq| return true if [sq.x, sq.y] == [BLOCK_SIDE*3, 0]}
    return false
  end
end


tetris = Tetris.new

main_loop do
  tetris.update
  tetris.control if tetris.time_counter % 6 == 0
  tetris.render
end

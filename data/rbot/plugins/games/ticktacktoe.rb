#-- vim:sw=2:et
#++
#
# :title: Tic-Tac-Toe
#
# Author:: Lite <degradinglight@gmail.com>
# Copyright:: (C) 2012 gfax.ch
# License:: GPL
# Version:: 2012-06-24
#

class TicTacToePlugin < Plugin

  Config.register Config::BooleanValue.new('tictactoe.bot',
    :default => true,
    :desc => "Enables/disables bot's AI.")
  Config.register Config::BooleanValue.new('tictactoe.public',
    :default => true,
    :desc => "Is this game playable in a channel as well or only in a private message?")
  Config.register Config::BooleanValue.new('tictactoe.unicode',
    :default => false,
    :desc => "Enables/disables prettier board grid drawing, " +
             "(may not display right on certain IRC clients.)")

  def help(plugin, topic="")
    case (topic.intern rescue nil)
    when /pla(y|ying)/
      "Mark a box by typing a number between 1 and 9. Get 3 boxes in a row to win."
    when /scor(e|es)/, /sta(t|ts)/
      "!#{plugin} stats <chan|user> -- displays the stats and scores for a channel or user"
    when /sto(p|pping)/, /cance(l|ling)/
      "!#{plugin} stop -- stops the current game"
    else
      "!#{plugin} <# of players> -- starts a game of tic-tac-toe, with the option of playing against " +
      "your lovely robot pal, #{@bot.nick}. (This config option for being able to verse the robot is " +
      "currently set to \002#{@bot.config['tictactoe.bot']}\002). Other help topics: playing, stats, stop"
    end
  end

  Blocking = [[(/  X . X  /),1],[(/ XX....../),0],[(/X..X.. ../),6],
              [(/......XX /),8],[(/.. ..X..X/),2],[(/ ..X..X../),0],
              [(/...... XX/),6],[(/..X..X.. /),8],[(/XX ....../),2],
              [(/ ...X...X/),0],[(/..X.X. ../),6],[(/X...X... /),8],
              [(/.. .X.X../),2],[(/X X....../),1],[(/X.. ..X../),3],
              [(/......X X/),7],[(/..X.. ..X/),5],[(/. ..X..X./),1],
              [(/... XX.../),3],[(/.X..X.. ./),7],[(/...XX .../),5],
              [(/ X X.. ../),0],[(/ ..X.. X /),6],[(/.. ..X X /),8],
              [(/ X ..X.. /),2],[(/  XX.. ../),0],[(/X.. .. X /),6],
              [(/.. .XX   /),8],[(/X  ..X.. /),2],[(/ X  ..X../),0],
              [(/ ..X..  X/),6],[(/..X..  X /),8],[(/X  ..X.. /),2]]

  Winning =  [[(/ OO....../),0],[(/O..O.. ../),6],
              [(/......OO /),8],[(/.. ..O..O/),2],
              [(/ ..O..O../),0],[(/...... OO/),6],
              [(/..O..O.. /),8],[(/OO ....../),2],
              [(/ ...O...O/),0],[(/..O.O. ../),6],
              [(/O...O... /),8],[(/.. .O.O../),2],
              [(/O O....../),1],[(/O.. ..O../),3],
              [(/......O O/),7],[(/..O.. ..O/),5],
              [(/. ..O..O./),1],[(/... OO.../),3],
              [(/.O..O.. ./),7],[(/...OO .../),5]]

  Won =      [[(/OOO....../),:O], [(/...OOO.../),:O],
              [(/......OOO/),:O], [(/O..O..O../),:O],
              [(/.O..O..O./),:O], [(/..O..O..O/),:O],
              [(/O...O...O/),:O], [(/..O.O.O../),:O],
              [(/XXX....../),:X], [(/...XXX.../),:X],
              [(/......XXX/),:X], [(/X..X..X../),:X],
              [(/.X..X..X./),:X], [(/..X..X..X/),:X],
              [(/X...X...X/),:X], [(/..X.X.X../),:X]]

  def display(m, chan)
    n = 0
    if @bot.config['tictactoe.unicode'] == false
      if empty_board?(chan)
        m.reply " 1 | 2 | 3 "
        m.reply "---+---+---"
        m.reply " 4 | 5 | 6 "
        m.reply "---+---+---"
        m.reply " 7 | 8 | 9 "
      else
        while n < 7
          m.reply " #{Bold + @board[chan][n + 0] + Bold} |" +
                  " #{Bold + @board[chan][n + 1] + Bold} |" +
                  " #{Bold + @board[chan][n + 2] + Bold} "
          m.reply "---+---+---" if n < 6
          n += 3
        end
      end
    else
      if empty_board?(chan)
        m.reply "1┃2┃3"
        m.reply "━╋━╋━"
        m.reply "4┃5┃6"
        m.reply "━╋━╋━"
        m.reply "7┃8┃9"
      else
        while n < 7
          m.reply "#{Bold + @board[chan][n + 0] + Bold}┃" +
                  "#{Bold + @board[chan][n + 1] + Bold}┃" +
                  "#{Bold + @board[chan][n + 2] + Bold}"
          m.reply "━╋━╋━" if n < 6
          n += 3
        end
      end
    end
  end

  def draw?(chan)
    space = 0
    while space < 9
      return false unless occupied?(chan, space)
      space += 1
    end
    return true
  end

  def empty_board?(chan)
    space = 0
    while space < 9
      return false if occupied?(chan, space)
      space += 1
    end
    return true
  end

  def occupied?(chan, space)
    if valid_move?(space)
      return (@board[chan].at(space) == " ") ? false : true
    end
    false
  end

  def someone_win?(chan)
    array = Won.find { |p| p.first =~ @board[chan].join }
    if array
      @winner[chan] = (array.last === :X) ? 'X' : 'O'
      return true
    end
    false
  end

  def valid_move?(space)
    (0..8) === space
  end

  def get_chan(m)
    if m.public?
      m.channel.name.downcase
      else m.sourcenick.downcase
      end
  end

  def new_game(m, params)
    player = case params[:bot].downcase
             when @bot.nick.downcase, "bot" then false
             when 1 then false
             else true
             end
    player = true if @bot.config['tictactoe.bot'] == false
    if m.public? && @bot.config['tictactoe.public'] == false
      m.reply "Sorry, this game is set to private-message-only."
      return
    end
    chan = get_chan(m)
    @ttter1 = Hash.new if @ttter1.nil?
    @ttter2 = Hash.new if @ttter2.nil?
    # Return unless no other tic-tac-toe-er is in the channel
    return unless @ttter1[chan].nil?
    @ttter1[chan] = m.sourcenick
    @board = Hash.new if @board.nil?
    @board[chan] = [].fill(0, 9) { " " }
    @players = { :X => 'X', :O => 'O' }
    @turn = Hash.new if @turn.nil?
    @turn[chan] = 1
    @winner = Hash.new if @winner.nil?
    unless player
      m.reply "You are X. Please go first:"
      play(m, chan)
    else
      @ttter2[chan] = true
      m.reply "Awaiting second player for tic-tac-toe. Type 'jo' to join."
    end
  end

  def play(m, chan)
    if @turn[chan] == 1
      display(m, chan)
    elsif @turn[chan] == 2
      if @ttter2[chan].nil?
        cpu_move(m, chan)
      else
        display(m, chan)
      end
    end
  end

  def message(m)
    return if @ttter1.nil? or @turn.nil?
    chan = get_chan(m)
    return if @turn[chan].nil?
    if m.message.match(/^jo\b/i)
      return if @ttter2.nil?
      return unless @ttter2[chan] == true
      @ttter2[chan] = m.sourcenick
      m.reply "First player is X. Second player is O:"
      play(m, chan)
    end
    return unless m.message.match(/^\d\b/)
    if @turn[chan] == 1
      return unless @ttter1[chan] == m.sourcenick
      mark = 'X'
    else
      return unless @ttter2[chan] == m.sourcenick
      mark = 'O'
    end
    move_pos = m.message[0].to_i
    move_pos -= 1 # so messages match 0-8, not 1-9
    return unless valid_move?(move_pos)
    player_move(m, chan, move_pos, mark)
  end

  def player_move(m, chan, move_pos, mark)
    if occupied?(chan, move_pos)
      m.reply "Space is already occupied. Pick another."
      return
    end
    move(m, chan, move_pos, mark)
  end

  def move(m, chan, space, mark)
    if valid_move?(space)
      @board[chan].delete_at(space)
      @board[chan].insert(space, mark)
    else return
    end
    if someone_win?(chan)
      display(m, chan)
      m.reply "#{@winner[chan][0].to_s} is the winner!"
      update_stats(m, chan, true)
      return
    end
    if draw?(chan)
      display(m, chan)
      m.reply "Game is a draw."
      update_stats(m, chan, false)
      return
    end
    if @turn[chan] == 1
      @turn[chan] = 2
      play(m, chan)
    else
      @turn[chan] = 1
      play(m, chan)
    end
  end

  def cpu_move(m, chan)
    # Get Winning pattern move
    array = Winning.find { |p| p.first =~ @board[chan].join }
    unless array.nil?
      move_pos = array.last
    end
    if move_pos.nil?
      # Then get Blocking pattern move
      array = Blocking.find { |p| p.first =~ @board[chan].join }
      unless array.nil?
        move_pos = array.last
      end
      if move_pos.nil?
        # Then just get the first available move
        unless occupied?(chan, 4)
          move_pos = 4
        else
          move_pos = @board[chan].index(' ')
        end
      end
    end
    move(m, chan, move_pos, 'O')
  end

  def stop(m, params)
    m.okay
    chan = get_chan(m)
    clear(m, chan)
  end

  def update_stats(m, chan, win)
    if win == true
      update_chan_stats(chan, 1, 0) if m.public?
      if @winner[chan][0] == "X"
        update_user_stats(chan, @ttter1[chan], 1, 0)
        update_user_stats(chan, @ttter2[chan], 0, 1) unless @ttter2[chan].nil?
      else
        update_user_stats(chan, @ttter1[chan], 0, 1)
        update_user_stats(chan, @ttter2[chan], 1, 0) unless @ttter2[chan].nil?
      end
    else
      update_chan_stats(chan, 0, 1) if m.public?
      update_user_stats(chan, @ttter1[chan], 0, 0)
      update_user_stats(chan, @ttter2[chan], 0, 0) unless @ttter2[chan].nil?
    end
    clear(m, chan)
  end

  def update_chan_stats(chan, win, draw)
    if @registry.has_key? chan
      @registry[chan] = [ @registry[chan][0] + 1,
                          @registry[chan][1] + win,
                          @registry[chan][2] + draw ]
    else @registry[chan] = [1, win, draw]
    end
  end

  def update_user_stats(chan, player, win, lose)
    user = "n" + player.downcase
    if @registry.has_key? user
      # Update user stats - [Nick, Games, Wins, Losses]
      @registry[user] = [ player,
                          @registry[user][1].to_i + 1,
                          @registry[user][2].to_i + win,
                          @registry[user][3].to_i + lose ]
    else # else, write a new record for the new user.
      @registry[user] = [player, 1, win, lose]
    end
  end

  def clear(m, chan)
    @board[chan] = nil
    @ttter1[chan] = nil
    @ttter2[chan] = nil
    @turn[chan] = nil
    @winner[chan] = nil
  end

  def reset_everything(m, params)
    @registry.clear
    m.reply "You ruined EVERYTHING."
  end

  def show_stats(m, params)
    if params[:x][0].to_s == "#"
      chan = params[:x].downcase
      if @registry.has_key? chan
        m.reply "#{chan}: #{@registry[chan][0]} games played, " +
        "#{@registry[chan][1]} wins, #{@registry[chan][2]} draws."
      else m.reply "No stats."
      end
      return
      end
    user = if params[:x] == "x" then "n" + m.sourcenick.downcase
             else "n" + params[:x].downcase
             end
    if @registry.has_key? user
      m.reply "#{@registry[user][0]}: #{@registry[user][1]} games played, " +
      "#{@registry[user][2]} wins, #{@registry[user][3]} losses."
    else m.reply "No stats for THAT guy..."
    end
  end
end

p = TicTacToePlugin.new
p.map 'ttt reset', :action => "reset_everything", :auth_path => 'reset'
p.map 'tictactoe reset', :action => "reset_everything", :auth_path => 'reset'
p.map 'ttt stop', :action => "stop", :auth_path => 'stop'
p.map 'tictactoe stop', :action => "stop", :auth_path => 'stop'
p.map 'ttt stat[s] [:x]', :action => "show_stats", :defaults => { :x => "x" }
p.map 'tictactoe stat[s] [:x]', :action => "show_stats", :defaults => { :x => "x" }
p.map 'ttt score[s] [:x]', :action => "show_stats", :defaults => { :x => "x" }
p.map 'tictactoe score[s] [:x]', :action => "show_stats", :defaults => { :x => "x" }
p.map 'ttt [:bot]', :action => "new_game", :defaults => { :bot => "bot" }, :requirements => { :num => /^\d+$/ }
p.map 'tictactoe [:bot]', :action => "new_game", :defaults => { :bot => "bot" }, :requirements => { :num => /^\d+$/ }
p.default_auth('reset', false)
p.default_auth('stop', true)

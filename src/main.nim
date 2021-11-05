import std/[random, enumerate]
import pkg/[oolib, nico]
import pkg/print

const
  orgName* = "org"
  appName* = "TicTacToe"

type
  GridValue* = enum
    none = " ", naught = "O", cross = "X"


class pub Position:
  var
    i*, score*, depth*: int

  proc `new`(i: int, score, depth: int = 0) = 
    self.i = i
    self.score = score
    self.depth = depth


## proc for checking equality between Positions
proc `==`(a, b: Position): bool = system.`==`(a, b) or (a.i == b.i)


## proc for checking score between Positions, enables `min` / `max`
proc `<` (a, b: Position): bool = a.score < b.score


## proc for converting 2D array coordinates to a 1D array index
proc xyIndex*(x, y: int, dimension: int = 3): int = y * dimension + x


proc debugPrint(position: Position): string =
  let str = "i " & $position.i & " score " & $position.score & " depth " & $position.depth
  return str

proc debugGrid(grid: seq[GridValue]): string =
  for y in 0 ..< 3:
    for x in 0 ..< 3:
      result.add $grid[xyIndex(x, y)] & " "
    result.add "\n"

proc debug(positions: seq[Position]): string =
  for position in positions:
    result.add "\n" & debugPrint(position)


class pub Board:
  var
    dimension*: int
    grid*: seq[GridValue]
    availablePositions*: seq[Position]

  proc `new`(dimension: int = 3): Board =
    self.dimension = dimension
    for i in 0 ..< self.dimension * self.dimension:
      self.grid.add(GridValue.none)
      self.availablePositions.add(newPosition(i))

  proc find(pos: Position, positions: seq[Position]): int =
    ## Find a Position object in a sequence of Positions
    var ind = -1
    for i, position in enumerate(positions):
      if position == pos:
        ind = i
    return ind

  proc getAvailablePositions*(grid: seq[GridValue]): seq[Position] =
    var
      # ind = -1
      pos: Position
    for i in 0 ..< self.dimension * self.dimension:
      if grid[i] == GridValue.none:
        pos = newPosition(i)
        # ind = self.find(pos, availablePositions)
        # if ind > -1:
        #   result.add availablePositions[ind]
        # else:
        result.add pos

  proc placePiece*(pos: Position, player: GridValue): bool =
    var ind = -1    
    if self.grid[pos.i] == GridValue.none:
      self.grid[pos.i] = player
      ind = self.find(pos, self.availablePositions)
      if ind > -1:
        self.availablePositions.del(ind)
      return true
    else:
      return false

  proc hasPlayerWon*(player: GridValue, grid: seq[GridValue]): bool =
    ## assertions for diagonal wins
    let
      diagonalWinLeft = grid[0] == player and grid[4] == player and grid[8] == player
      diagonalWinRight = grid[2] == player and grid[4] == player and grid[6] == player
    if diagonalWinLeft or diagonalWinRight:
      result = true

    var rowWin, columnWin: bool
    for i in 0 ..< self.dimension:
      ## assertions for each row / column win
      rowWin = grid[xyIndex(0, i)] == player and grid[xyIndex(1, i)] == player and grid[xyIndex(2, i)] == player
      columnWin = grid[xyIndex(i, 0)] == player and grid[xyIndex(i, 1)] == player and grid[xyIndex(i, 2)] == player
      if rowWin or columnWin:
        result = true

  proc isGameOver*(grid: seq[GridValue], availablePositions: seq[Position]): (bool, GridValue) =
    # checks whether the board is full
    var
      winner = GridValue.none
      boardFull = false
    
    if availablePositions.len == 0:
      boardFull = true

    for player in {GridValue.cross, GridValue.naught}:
      if self.hasPlayerWon(player, grid):
        winner = player
    result = (boardFull, winner)

  proc minimax(player: GridValue, grid: seq[GridValue], depth: int): int =
    let
      availablePositions = self.getAvailablePositions(grid)
      (gameOver, winner) = self.isGameOver(grid, availablePositions)
 
    if gameOver:
      if winner == GridValue.naught:
        return 1
      elif winner == GridValue.cross:
        return -1
      else:
        return 0

    var
      gridCopy: seq[GridValue]
      bestScore: int
      ind = -1

    if player == GridValue.naught:
      bestScore = -1
    else:
      bestScore = 1

    for pos in availablePositions:
      # Copy the current state of the board
      gridCopy = grid
      # Add a move on the next empty spot
      gridCopy[pos.i] = player
      # Call this method recursively on the current move changing the player
      if player == GridValue.naught:
        bestScore = max(bestScore, self.minimax(GridValue.cross, gridCopy, depth + 1))
      else:
        bestScore = min(bestScore, self.minimax(GridValue.naught, gridCopy, depth + 1))
      
      if depth == 0:
        ind = self.find(pos, self.availablePositions)
        if ind > -1:
          self.availablePositions[ind] = pos
      
    # echo "minmax", debug self.availablePositions
    return bestScore

  proc getBestScore*(player: GridValue, depth = 0): Position =
    discard self.minimax(player, self.grid, depth)
    echo "bestscore", debug self.availablePositions
    
    if player == GridValue.naught:
      return max(self.availablePositions)
    else:
      return min(self.availablePositions)

class pub Square:
  var
    x*, y*, x1*, y1*: int


class pub TicTacToe:
  var
    gridBounds: seq[Square]
    gridSquare: Square
    board: Board = newBoard()
    offset = 16
    size = 32
    outOfBounds = false
    successfulMove = true
    gameOver = false
    gameResult = GridValue.none
    turn = GridValue.cross

  proc `new`: TicTacToe =
    var
      x, y, x1, y1: int = self.offset
    for row in 0 ..< self.board.dimension:
      x = self.offset
      x1 = self.offset
      y1 = y + self.size
      for column in 0 ..< self.board.dimension:
        x1 = x + self.size
        self.gridBounds.add(newSquare(x, y, x1, y1))
        x = x1
      y = y1
    self.gridSquare = newSquare(self.offset, self.offset, y, y)

  proc isOutOfBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] <= square.x or pos[0] >= square.x1) or (pos[1] <= square.y or pos[1] >= square.y1):
      result = true

  proc drawPiece*(val: GridValue, gridBound: Square, offset: int = 5) =
    let
      x = gridBound.x + offset
      y = gridBound.y + offset
      x1 = gridBound.x1 - offset
      y1 = gridBound.y1 - offset
    setColor(7)
    if val == GridValue.cross:
      line(x, y, x1, y1)
      line(x1, y, x, y1)
    elif val == GridValue.naught:
      let
        x2 = (x1 + x) div 2
        y2 = (y1 + y) div 2
        r = (x1 - x) div 2
      circ(x2, y2, r)

  proc gameOverMessage*(message: string, color: int) =
    let
      xCenter = screenWidth div 2
      yCenter = screenHeight div 2
      x = xCenter - 22
      x1 = xCenter + 20
      y = yCenter - 2
      y1 = yCenter + 6

    setColor(color)
    rrectfill(x, y, x1, y1)
    setColor(7)
    printc(message, xCenter, yCenter)


var ttt = newTicTacToe()
randomize()


proc gameInit*() =
  loadFont(0, "font.png")


proc gameDraw*() =
  cls()
  setColor(7)
  printc("Tic Tac Toe", screenWidth div 2, 8)

  for i, square in enumerate(ttt.gridBounds):
    setColor(i+1)
    rect(square.x, square.y, square.x1, square.y1)
    ttt.drawPiece(ttt.board.grid[i], square)

  if ttt.outOfBounds:
    setColor(4)
    printc("Please click within the grid!", screenWidth div 2, 120)

  if not ttt.successfulMove:
    setColor(4)
    printc("This position has been played!", screenWidth div 2, 120)

  if ttt.gameResult == GridValue.cross:
    ttt.gameOverMessage("You Win!", 3)
  elif ttt.gameResult == GridValue.naught:
    ttt.gameOverMessage("You Lose!", 4)
  elif ttt.gameResult == GridValue.none and ttt.gameOver == true:
    ttt.gameOverMessage("Game Over.", 4)


proc gameUpdate*(dt: float32) =
  setColor(7)
  # ttt.board.availablePositions = ttt.board.getAvailablePositions(ttt.board.grid)
  (ttt.gameOver, ttt.gameResult) = ttt.board.isGameOver(ttt.board.grid, ttt.board.availablePositions)
  if ttt.turn == GridValue.cross and ttt.gameOver == false:
    if mousebtnp(0):
      let pos = mouse()
      ttt.outOfBounds = ttt.isOutOfBounds(pos, ttt.gridSquare)
      if not ttt.outOfBounds:
        let
          x = (pos[0] - ttt.offset) div ttt.size
          y = (pos[1] - ttt.offset) div ttt.size
          i = xyIndex(x, y)
        ttt.successfulMove = ttt.board.placePiece(newPosition(i), GridValue.cross)
        if ttt.successfulMove:
          ttt.turn = GridValue.naught
  elif ttt.turn == GridValue.naught and ttt.gameOver == false:
    let move = ttt.board.getBestScore(GridValue.naught)
    ttt.successfulMove = ttt.board.placePiece(newPosition(move.i), GridValue.naught)
    if ttt.successfulMove:
      ttt.turn = GridValue.cross

  


nico.init(orgName, appName)
fixedSize(true)
integerScale(true)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)

import std/enumerate
import pkg/[nico, oolib]

type
  GridValue* = enum
    none = " ", naught = "O", pNaught = "O", cross = "X", pCross = "X"


class pub Position:
  var
    i*, depth*: int
    score*: BiggestInt

  proc `new`(i: int, score: BiggestInt = 0, depth: int = 0) =
    self.i = i
    self.score = score
    self.depth = depth


## func for checking equality between Positions
func `==`*(a, b: Position): bool = system.`==`(a, b) or (a.i == b.i)

## convenience funcs for comparing Positions, `<` enables min/max comparisons
func `>`*(a, b: Position): bool = system.`>`(a.score, b.score)
func `<`*(a, b: Position): bool = system.`<`(a.score, b.score)

## func for converting 2D array coordinates to a 1D array index
func xyIndex*(x, y: int, dimension: int = 3): int = y * dimension + x

proc debugPrint*(position: Position): string =
  let str = "i " & $position.i & " score " & $position.score & " depth " & $position.depth
  return str

proc debugGrid*(grid: seq[GridValue]): string =
  for y in 0 ..< 3:
    for x in 0 ..< 3:
      result.add $grid[xyIndex(x, y)] & " "
    result.add "\n"

proc debug*(positions: seq[Position]): string =
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
      self.grid.add GridValue.none
      self.availablePositions.add newPosition(i)

  proc find*(pos: Position, positions: seq[Position]): int =
    ## Find a Position object in a sequence of Positions
    var ind = -1
    for i, position in enumerate(positions):
      if position == pos:
        ind = i
    return ind

  proc cleanGrid* =
    for i in 0 ..< self.grid.len:
      if self.grid[i] in {GridValue.pNaught, GridValue.pCross}:
        self.grid[i] = GridValue.none

  proc getAvailablePositions*(grid: seq[GridValue]): seq[Position] =
    var
      ind = -1
      pos: Position
    for i in 0 ..< grid.len:
      if grid[i] in {GridValue.none, GridValue.pNaught, GridValue.pCross}:
        pos = newPosition(i)
        ind = self.find(pos, result)
        if ind >= 0:
          result[ind] = pos
        else:
          result.add pos

  proc placePiece*(pos: Position, player: GridValue): bool =
    var ind = -1
    if self.grid[pos.i] in {GridValue.none, GridValue.pNaught, GridValue.pCross}:
      self.grid[pos.i] = player
      ind = self.find(pos, self.availablePositions)
      if ind >= 0:
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
      gameOver = availablePositions.len == 0

    for player in {GridValue.cross, GridValue.naught}:
      if self.hasPlayerWon(player, grid):
        winner = player
        gameOver = true
    result = (gameOver, winner)

  proc minimax*(player: GridValue, grid: seq[GridValue], depth: int, alpha, beta: BiggestInt): Position =
    var
      gridCopy: seq[GridValue]
      minPos = newPosition(-1, score = beta)
      maxPos = newPosition(-1, score = alpha)
      currentPos: Position
      alpha = alpha
      beta = beta
      ind = -1

    let
      availablePositions = self.getAvailablePositions(grid)
      (gameOver, winner) = self.isGameOver(grid, availablePositions)

    if gameOver:
      if winner == GridValue.naught:
        return newPosition(-1, score = 1, depth = depth)
      elif winner == GridValue.cross:
        return newPosition(-1, score = -1, depth = depth)
      else:
        return newPosition(-1, score = 0, depth = depth)

    for pos in availablePositions:
      gridCopy = grid
      gridCopy[pos.i] = player

      if player == GridValue.naught:
        currentPos = self.minimax(GridValue.cross, gridCopy, depth + 1, alpha, beta)
        currentPos.i = pos.i
        if maxPos.i == -1 or currentPos.score > maxPos.score:
          maxPos.i = currentPos.i
          maxPos.score = currentPos.score
          maxPos.depth = depth
          alpha = max(currentPos.score, alpha)
      elif player == GridValue.cross:
        currentPos = self.minimax(GridValue.naught, gridCopy, depth + 1, alpha, beta)
        currentPos.i = pos.i
        if minPos.i == -1 or currentPos.score < minPos.score:
          minPos.i = currentPos.i
          minPos.score = currentPos.score
          minPos.depth = depth
          beta = min(currentPos.score, beta)

      if alpha >= beta:
        break

      if depth == 0:
        ind = self.find(currentPos, self.availablePositions)
        self.availablePositions[ind] = currentPos

    if player == GridValue.naught:
      return maxPos
    elif player == GridValue.cross:
      return minPos

  proc getBestMove*(player: GridValue, depth = 0, alpha = low(BiggestInt), beta = high(BiggestInt)): Position =
    discard self.minimax(player, self.grid, depth, alpha, beta)
    if player == GridValue.naught:
      return max(self.availablePositions)
    elif player == GridValue.cross:
      return min(self.availablePositions)


class pub Square:
  var
    x*, y*, x1*, y1*: int


class pub TicTacToe:
  var
    gridBounds*: seq[Square]
    gridSquare*: Square
    board*: Board = newBoard()
    offset* = 16
    size* = 32
    outOfBounds* = false
    successfulMove* = true
    gameOver* = false
    gameResult* = GridValue.none
    turn* = GridValue.cross
    showRules* = false

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
    if val == GridValue.cross or val == GridValue.pCross:
      if val == GridValue.pCross:
        setColor(5)
      line(x, y, x1, y1)
      line(x1, y, x, y1)
    elif val == GridValue.naught or val == GridValue.pNaught:
      if val == GridValue.pNaught:
        setColor(5)
      let
        x2 = (x1 + x) div 2
        y2 = (y1 + y) div 2
        r = (x1 - x) div 2
      circ(x2, y2, r)

  proc drawRuleButton* =
    setColor(7)
    boxfill(118, 118, 7, 7)
    setColor(0)
    printc("?", 122, 119)

  proc displayRules* =
    setColor(0)
    rectfill(16, 16, 112, 112)
    setColor(7)
    rect(16, 16, 112, 112)
    printc("Rules:", screenWidth div 2, 24)
    printc("You may make a move", screenWidth div 2, 36)
    printc("where naught hasn't.", screenWidth div 2, 44)
    printc("You win if you can", screenWidth div 2, 60)
    printc("get three of your", screenWidth div 2, 68)
    printc("symbols in a row,", screenWidth div 2, 76)
    printc("horizontally,", screenWidth div 2, 84)
    printc("vertically,", screenWidth div 2, 92)
    printc("or diagonally.", screenWidth div 2, 100)

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
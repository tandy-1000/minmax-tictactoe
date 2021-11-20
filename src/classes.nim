import std/[enumerate, random]
import pkg/[nico, oolib]


type
  GridValue* = enum
    none = " ", naught, pNaught, cNaught = "O", cross, pCross, cCross = "X"
  Difficulty* = enum
    easy = 6, medium = 7, hard = 8, impossible = 9

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


proc debugPrint*(position: Position): string =
  let str = "i " & $position.i & " score " & $position.score & " depth " & $position.depth
  return str

proc debugGrid*(grid: seq[GridValue]): string =
  for y in 0 ..< 3:
    for x in 0 ..< 3:
      result.add $grid[y * 3 + x] & " "
    result.add "\n"

proc debug*(positions: seq[Position]): string =
  for position in positions:
    result.add "\n" & debugPrint(position)


class pub Board:
  var
    dimension*: int
    grid*: seq[GridValue]
    availablePositions*: seq[Position]
    gameOver* = false
    gameResult* = GridValue.none
    ai* = GridValue.naught
    human* = GridValue.cross
    humanPotential* = GridValue.pCross
    turn* = GridValue.cross
    difficulty*: Difficulty

  proc `new`(difficulty: Difficulty, dimension: int = 3): Board =
    self.dimension = dimension
    self.difficulty = difficulty
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

  ## proc for converting 2D array coordinates to a 1D array index
  proc xyIndex*(x, y: int): int = y * self.dimension + x

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
      rowWin = grid[self.xyIndex(0, i)] == player and grid[self.xyIndex(1, i)] == player and grid[self.xyIndex(2, i)] == player
      columnWin = grid[self.xyIndex(i, 0)] == player and grid[self.xyIndex(i, 1)] == player and grid[self.xyIndex(i, 2)] == player
      if rowWin or columnWin:
        result = true

  proc isGameOver*(
    grid: seq[GridValue],
    availablePositions: seq[Position]
  ): (bool, GridValue) =
    # checks whether the board is full
    var
      winner = GridValue.none
      gameOver = availablePositions.len == 0

    for player in {GridValue.cross, GridValue.naught}:
      if self.hasPlayerWon(player, grid):
        winner = player
        gameOver = true
    result = (gameOver, winner)

  proc getClueValue*(player: GridValue): GridValue =
    if player == GridValue.cross:
      return GridValue.cCross
    elif player == GridValue.naught:
      return GridValue.cNaught

  proc opposingPlayer*(player: GridValue): GridValue =
    if player == GridValue.cross:
      return GridValue.naught
    elif player == GridValue.naught:
      return GridValue.cross

  proc minimax*(
    player: GridValue,
    grid: seq[GridValue],
    depth: int,
    alpha, beta: BiggestInt
  ): Position =
    var
      gridCopy: seq[GridValue]
      minPos = newPosition(-1, score = beta)
      maxPos = newPosition(-1, score = alpha)
      currentPos: Position
      nextPlayer: GridValue
      alpha = alpha
      beta = beta
      ind = -1

    let
      availablePositions = self.getAvailablePositions(grid)
      (gameOver, winner) = self.isGameOver(grid, availablePositions)

    if gameOver:
      if winner == self.ai:
        return newPosition(-1, score = 1, depth = depth)
      elif winner == self.human:
        return newPosition(-1, score = -1, depth = depth)
      else:
        return newPosition(-1, score = 0, depth = depth)

    for pos in availablePositions:
      gridCopy = grid
      gridCopy[pos.i] = player
      nextPlayer = self.opposingPlayer(player)

      if player == self.ai:
        currentPos = self.minimax(nextplayer, gridCopy, depth + 1, alpha, beta)
        currentPos.i = pos.i
        if maxPos.i == -1 or currentPos.score > maxPos.score:
          maxPos.i = currentPos.i
          maxPos.score = currentPos.score
          maxPos.depth = depth
          alpha = max(currentPos.score, alpha)
      elif player == self.human:
        currentPos = self.minimax(nextplayer, gridCopy, depth + 1, alpha, beta)
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

    if player == self.ai:
      return maxPos
    elif player == self.human:
      return minPos

  proc getBestMove*(
    player: GridValue,
    depth = 0,
    alpha = low(BiggestInt),
    beta = high(BiggestInt)
  ): Position =
    discard self.minimax(player, self.grid, depth, alpha, beta)
    if player == self.ai:
      return max(self.availablePositions)
    elif player == self.human:
      return min(self.availablePositions)

  proc getRandMove*: Position =
    return sample(self.availablePositions)

  proc moveAI*(player: GridValue, difficulty: Difficulty): bool =
    var move: Position
    if self.availablePositions.len <= ord difficulty:
      move = self.getBestMove(player)
    else:
      move = self.getRandMove()

    return self.placePiece(newPosition(move.i), player)


class pub Square:
  var
    x*, y*, x1*, y1*: int


class pub TicTacToe:
  var
    gridBounds*: seq[Square]
    gridSquare*: Square
    board*: Board
    offset* = 16
    size* = 32
    started* = false
    showRules* = false
    showClues* = false
    outOfBounds* = false
    successfulMove* = true

  proc `new`(difficulty: Difficulty): TicTacToe =
    self.board = newBoard(difficulty = difficulty)
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

  proc drawStartPage* =
    cls()
    let
      hCenter = screenWidth div 2
      padding = 20
      r = 6
      d = r * 2
      diffRowY = (padding * 2) + padding div 2
      playerRowY = (padding * 4)

    setColor(3)
    rect(hCenter - d, (screenHeight - padding) - r, hCenter + d, (screenHeight - padding) + r)

    setColor(1)
    if self.board.difficulty == Difficulty.easy:
      rectfill(hCenter - (3*d) - 1, diffRowY - r, hCenter - d - 3, diffRowY + r)
    else:
      rect(hCenter - (3*d) - 1, diffRowY - r, hCenter - d - 3, diffRowY + r)
    setColor(4)
    if self.board.difficulty == Difficulty.medium:
      rectfill(hCenter - d - 2, diffRowY - r, hCenter + d + 2, diffRowY + r)
    else:
      rect(hCenter - d - 2, diffRowY - r, hCenter + d + 2, diffRowY + r)
    setColor(8)
    if self.board.difficulty == Difficulty.hard:
      rectfill(hCenter + d + 3, diffRowY - r, hCenter + (3*d) + 1, diffRowY + r)
    else:
      rect(hCenter + d + 3, diffRowY - r, hCenter + (3*d) + 1, diffRowY + r)

    setColor(7)
    if self.board.human == GridValue.naught:
      rectfill(hCenter - d, playerRowY - r, hCenter, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter - d, playerRowY - r, hCenter, playerRowY + r)
    printc("O", hCenter - r + 1, playerRowY - 2)

    setColor(7)
    if self.board.human == GridValue.cross:
      rectfill(hCenter, playerRowY - r, hCenter + d, playerRowY + r)
      setColor(0)
    else:
      rect(hCenter, playerRowY - r, hCenter + d, playerRowY + r)
    printc("X", hCenter + r + 1, playerRowY - 2)

    setColor(7)
    printc("Tic Tac Toe", hCenter, padding)
    printc("easy", hCenter - (2*d) - 1, diffRowY - 3)
    printc("medium", hCenter + 1, diffRowY - 3)
    printc("hard", hCenter + (2*d) + 3, diffRowY - 3)
    printc("Start", hCenter + 1, (screenHeight - padding) - 3)

  proc isInBounds*(pos: (int, int), square: Square): bool =
    if (pos[0] >= square.x and pos[0] <= square.x1) and (pos[1] >= square.y and pos[1] <= square.y1):
      result = true

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
    if val in {GridValue.cross, GridValue.pCross, GridValue.cCross}:
      if val == GridValue.pCross:
        setColor(5)
      elif val == GridValue.cCross:
        setColor(3)
      line(x, y, x1, y1)
      line(x1, y, x, y1)
    elif val in {GridValue.naught, GridValue.pNaught, GridValue.cNaught}:
      if val == GridValue.pNaught:
        setColor(5)
      elif val == GridValue.cNaught:
        setColor(3)
      let
        x2 = (x1 + x) div 2
        y2 = (y1 + y) div 2
        r = (x1 - x) div 2
      circ(x2, y2, r)

  proc drawHelpButton* =
    setColor(7)
    boxfill(118, 118, 7, 7)
    setColor(0)
    printc("?", 122, 119)

  proc displayClues* =
    if self.showClues:
      let pos = self.board.getBestMove(self.board.human)
      self.drawPiece(self.board.getClueValue(self.board.human), self.gridBounds[pos.i])

  proc displayRules* =
    if self.showRules:
      setColor(0)
      rectfill(16, 16, 112, 112)
      setColor(7)
      rect(14, 16, 114, 112)
      printc("Rules:", screenWidth div 2, 26)
      printc("You may make a move", screenWidth div 2, 40)
      printc("where naught hasn't.", screenWidth div 2, 48)
      printc("You win if you can get", screenWidth div 2, 64)
      printc("three of your symbols", screenWidth div 2, 72)
      printc("in a row, horizontally,", (screenWidth div 2) + 2, 80)
      printc("vertically, or", screenWidth div 2, 88)
      printc("diagonally.", screenWidth div 2, 96)

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

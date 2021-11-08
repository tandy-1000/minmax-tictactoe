import std/[random, enumerate]
import pkg/nico
import classes

const
  orgName* = "org"
  appName* = "TicTacToe"

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
  ttt.board.availablePositions = ttt.board.getAvailablePositions(ttt.board.grid)
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
    let move = ttt.board.getBestMove(GridValue.naught)
    ttt.successfulMove = ttt.board.placePiece(newPosition(move.i), GridValue.naught)
    if ttt.successfulMove:
      ttt.turn = GridValue.cross

nico.init(orgName, appName)
fixedSize(true)
integerScale(true)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)

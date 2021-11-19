import std/[random, enumerate]
import pkg/nico
import classes

const
  orgName* = "org"
  appName* = "TicTacToe"

var ttt = newTicTacToe(difficulty = Difficulty.medium)
randomize()

proc gameInit*() =
  loadFont(0, "font.png")

proc gameDraw*() =
  if not ttt.started:
    ttt.drawStartPage()
    ttt.drawHelpButton()
    ttt.displayRules()
  else:
    cls()
    setColor(7)
    printc("Tic Tac Toe", screenWidth div 2, 8)

    for i, square in enumerate(ttt.gridBounds):
      setColor(i+1)
      rect(square.x, square.y, square.x1, square.y1)
      ttt.drawPiece(ttt.board.grid[i], square)

    ttt.drawHelpButton()
    ttt.displayClues()

    if ttt.outOfBounds:
      setColor(4)
      printc("Please click within the grid!", screenWidth div 2, 120)

    if not ttt.successfulMove:
      setColor(4)
      printc("This position has been played!", screenWidth div 2, 120)

    if ttt.board.gameResult == ttt.board.human:
      ttt.gameOverMessage("You Win!", 3)
    elif ttt.board.gameResult == ttt.board.ai:
      ttt.gameOverMessage("You Lose!", 4)
    elif ttt.board.gameResult == GridValue.none and ttt.board.gameOver == true:
      ttt.gameOverMessage("Game Over.", 4)

proc gameUpdate*(dt: float32) =
  var
    pos: (int, int)
    pressed = false
  if not ttt.started:
    pressed = mousebtnp(0)
    if pressed:
      pos = mouse()
      if ttt.isInBounds(pos, newSquare(27, 44, 49, 56)):
        ttt.board.difficulty = Difficulty.easy
      elif ttt.isInBounds(pos, newSquare(50, 44, 78, 56)):
        ttt.board.difficulty = Difficulty.medium
      elif ttt.isInBounds(pos, newSquare(79, 44, 101, 56)):
        ttt.board.difficulty = Difficulty.hard
      elif ttt.isInBounds(pos, newSquare(52, 74, 64, 86)):
        ttt.board.human = GridValue.naught
        ttt.board.humanPotential = GridValue.pNaught
        ttt.board.ai = GridValue.cross
        ttt.board.turn = ttt.board.human
      elif ttt.isInBounds(pos, newSquare(64, 74, 76, 86)):
        ttt.board.human = GridValue.cross
        ttt.board.humanPotential = GridValue.pCross
        ttt.board.ai = GridValue.naught
        ttt.board.turn = ttt.board.human
      elif ttt.isInBounds(pos, newSquare(52, 102, 76, 114)):
        ttt.started = true
      elif ttt.isInBounds(pos, newSquare(118, 118, 125, 125)):
        ttt.showRules = not ttt.showRules
  else:
    ttt.board.cleanGrid()
    ttt.board.availablePositions = ttt.board.getAvailablePositions(ttt.board.grid)
    (ttt.board.gameOver, ttt.board.gameResult) = ttt.board.isGameOver(ttt.board.grid, ttt.board.availablePositions)
    if ttt.board.turn == ttt.board.human and ttt.board.gameOver == false:
      pos = mouse()
      if not ttt.isOutOfBounds(pos, ttt.gridSquare):
        let
          x = (pos[0] - ttt.offset) div ttt.size
          y = (pos[1] - ttt.offset) div ttt.size
          i = xyIndex(x, y)
        if ttt.board.grid[i] == GridValue.none:
          ttt.board.grid[i] = ttt.board.humanPotential

      pressed = mousebtnp(0)
      if pressed:
        pos = mouse()
        if ttt.isOutOfBounds(pos, ttt.gridSquare):
          if ttt.isInBounds(pos, newSquare(118, 118, 125, 125)):
            ttt.showClues = not ttt.showClues
            ttt.outOfBounds = false
          else:
            ttt.outOfBounds = true
        else:
          let
            x = (pos[0] - ttt.offset) div ttt.size
            y = (pos[1] - ttt.offset) div ttt.size
            i = xyIndex(x, y)
          ttt.successfulMove = ttt.board.placePiece(newPosition(i), ttt.board.human)
          if ttt.successfulMove:
            ttt.board.turn = ttt.board.ai
    elif ttt.board.turn == ttt.board.ai and ttt.board.gameOver == false:
      ttt.successfulMove = ttt.board.moveAI(ttt.board.ai, ttt.board.difficulty)
      if ttt.successfulMove:
        ttt.board.turn = ttt.board.human

nico.init(orgName, appName)
fixedSize(true)
integerScale(true)
nico.createWindow(appName, 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)

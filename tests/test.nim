import std/unittest
import std/enumerate
import ../src/classes

suite "Position tests":
  setup:
    let
      pos = newPosition(0)
      pos1 = newPosition(0)
    pos.score = 1

  test "Position equality":
    check pos == pos1

  test "Position comparison":
    check pos1 < pos

suite "Board tests":
  setup:
    let
      board = newBoard()
      player = GridValue.cross
      positions = @[newPosition(0), newPosition(1)]

  test "Find position":
    let pos = newPosition(1)
    pos.score = 1
    let ind = board.find(pos, positions)
    board.availablePositions[ind] = pos
    check ind == 1 and board.availablePositions[ind] == pos

  test "Get available positions":
    let
      grid = @[GridValue.none, GridValue.none]
      availablePositions = board.getAvailablePositions(grid)
    for i, pos in enumerate(availablePositions):
      check pos == positions[i]

  test "Place piece":
    let
      move = board.placePiece(newPosition(0), player)
      grid = @[GridValue.cross, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none, GridValue.none]
    check move == true and board.grid == grid

  test "Place piece in occupied position":
    discard board.placePiece(newPosition(0), player)
    let secondMove = board.placePiece(newPosition(0), player)
    check secondMove == false

  test "Vertical win: left column":
    let
      grid = @[
        GridValue.cross, GridValue.none, GridValue.naught,
        GridValue.cross, GridValue.naught, GridValue.none,
        GridValue.cross, GridValue.none, GridValue.none
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Vertical win: middle column":
    let
      grid = @[
        GridValue.naught, GridValue.cross, GridValue.naught,
        GridValue.naught, GridValue.cross, GridValue.cross,
        GridValue.cross, GridValue.cross, GridValue.naught
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Vertical win: right column":
    let
      grid = @[
        GridValue.naught, GridValue.naught, GridValue.cross,
        GridValue.naught, GridValue.naught, GridValue.cross,
        GridValue.cross, GridValue.cross, GridValue.cross
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: top row":
    let
      grid = @[
        GridValue.cross, GridValue.cross, GridValue.cross,
        GridValue.naught, GridValue.cross, GridValue.naught,
        GridValue.none, GridValue.naught, GridValue.naught
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: middle row":
    let
      grid = @[
        GridValue.naught, GridValue.none, GridValue.none,
        GridValue.cross, GridValue.cross, GridValue.cross,
        GridValue.none, GridValue.naught, GridValue.naught
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Horizontal win: bottom row":
    let
      grid = @[
        GridValue.naught, GridValue.none, GridValue.none,
        GridValue.cross, GridValue.naught, GridValue.naught,
        GridValue.cross, GridValue.cross, GridValue.cross
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Diagonal win: left":
    let
      grid = @[
        GridValue.cross, GridValue.none, GridValue.naught,
        GridValue.none, GridValue.cross, GridValue.naught,
        GridValue.none, GridValue.none, GridValue.cross
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Diagonal win: right":
    let
      grid = @[
        GridValue.naught, GridValue.none, GridValue.cross,
        GridValue.none, GridValue.cross, GridValue.naught,
        GridValue.cross, GridValue.none, GridValue.naught
      ]
      win = board.hasPlayerWon(player, grid)
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check win == true and gameOver == true and winner == player

  test "Full board and no winner":
    let
      grid = @[
        GridValue.cross, GridValue.cross, GridValue.naught,
        GridValue.naught, GridValue.naught, GridValue.cross,
        GridValue.cross, GridValue.naught, GridValue.cross
      ]
      (gameOver, winner) = board.isGameOver(grid, board.getAvailablePositions(grid))

    check gameOver == true and winner == GridValue.none

  test "Game not over":
    let (gameOver, winner) = board.isGameOver(board.grid, board.getAvailablePositions(board.grid))

    check gameOver == false and winner == GridValue.none

  test "Minimax: minimise loss":
    let
      alpha = low(BiggestInt)
      beta = high(BiggestInt)
      depth = 0
      grid = @[
        GridValue.cross, GridValue.none, GridValue.none,
        GridValue.cross, GridValue.none, GridValue.none,
        GridValue.none, GridValue.none, GridValue.naught
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.minimax(GridValue.naught, grid, depth, alpha, beta, true)
    check position.i == 6

  test "Get best move: minimise loss":
    let
      grid = @[
        GridValue.cross, GridValue.none, GridValue.none,
        GridValue.cross, GridValue.none, GridValue.none,
        GridValue.none, GridValue.none, GridValue.naught
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.getBestMove(GridValue.naught)
    check position.i == 6

  test "Minimax: maximise win":
    let
      alpha = low(BiggestInt)
      beta = high(BiggestInt)
      depth = 0
      grid = @[
        GridValue.naught, GridValue.cross, GridValue.none,
        GridValue.naught, GridValue.cross, GridValue.none,
        GridValue.none, GridValue.none, GridValue.cross
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.minimax(GridValue.naught, grid, depth, alpha, beta, true)
    check position.i == 6

  test "Get best move: maximise win":
    let
      grid = @[
        GridValue.naught, GridValue.cross, GridValue.none,
        GridValue.naught, GridValue.cross, GridValue.none,
        GridValue.none, GridValue.none, GridValue.cross
      ]
    board.grid = grid
    board.availablePositions = board.getAvailablePositions(grid)
    let position = board.getBestMove(GridValue.naught)
    check position.i == 6

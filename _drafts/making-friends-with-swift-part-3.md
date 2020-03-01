---
layout: single
title: Making friends with Swift, part 3
---
As promised [previously]({ post_url 2020-02-22-making-friends-with-swift-part-2 }), we'll look at some things we could improve in our current state of the project and add some more functionality.

Just to make sure we're on the same page, my snake module currently looks like

```swift
// Snake.swift

struct Snake {
    static func spawn(x: Int, y: Int) -> [Point] {
        return [Point(x: x, y: y)]
    }

    static func move(_ snake: [Point], in direction: Direction) -> [Point] {
        return updateTail(updateHead(snake, in: direction))
    }

    static func grow(_ snake: [Point], in direction: Direction) -> ([Point]) {
            return updateHead(snake, in: direction)
    }

    // MARK: - Private

    private static func updateHead(_ snake: [Point], in direction: Direction) -> [Point] {
        guard let head = snake.first else {
            return snake
        }
        let delta = direction.asDelta()
        return [Point(x: head.x + delta.x, y: head.y + delta.y)] + snake
    }

    private static func updateTail(_ snake: [Point]) -> [Point] {
       return Array(snake.prefix(upTo: snake.count - 1))
    }
}
```

the tests for this snake module all pass and look like

```swift
import XCTest
@testable import SnakeCorePackage

final class SnakeTests: XCTestCase {

    // MARK: - Test Spawning

    func testSnakeSpawns() {
        let snake = Snake.spawn(x: 4, y: 4)

        XCTAssertEqual([Point(x: 4, y: 4)], snake)
    }

    // MARK: - Test Moving

    func testSnakeMovesLeft() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.move(snake, in: Direction.left)

        XCTAssertEqual([Point(x: 1, y: 5)], updatedSnake)
    }

    func testSnakeMovesRight() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.move(snake, in: Direction.right)

        XCTAssertEqual([Point(x: 3, y: 5)], updatedSnake)
    }

    func testSnakeMovesUp() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.move(snake, in: Direction.up)

        XCTAssertEqual([Point(x: 2, y: 4)], updatedSnake)
    }

    func testSnakeMoveDown() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.move(snake, in: Direction.down)

        XCTAssertEqual([Point(x: 2, y: 6)], updatedSnake)
    }

    // MARK: Test Growing

    func testSnakeGrowsLeft() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.grow(snake, in: Direction.left)

        XCTAssertEqual([
            Point(x: 1, y: 5),
            Point(x: 2, y: 5)
        ], updatedSnake)
    }

    func testSnakeGrowsRight() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.grow(snake, in: Direction.right)

        XCTAssertEqual([
            Point(x: 3, y: 5),
            Point(x: 2, y: 5)
        ], updatedSnake)
    }

    func testSnakeGrowsUp() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.grow(snake, in: Direction.up)

        XCTAssertEqual([
            Point(x: 2, y: 4),
            Point(x: 2, y: 5)
        ], updatedSnake)
    }

    func testSnakeGrowsDown() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake = Snake.grow(snake, in: Direction.down)

        XCTAssertEqual([
            Point(x: 2, y: 6),
            Point(x: 2, y: 5)
        ], updatedSnake)
    }

    // MARK: - Test Long Snake

    func testSnakeChangesDirection() {
        let snake = Snake.spawn(x: 2, y: 5)

        let updatedSnake1 = Snake.grow(snake, in: Direction.down) // adds 2,6 as head
        let updatedSnake2 = Snake.grow(updatedSnake1, in: Direction.down) // adds 2,7 as head

        let updatedSnake3 = Snake.move(updatedSnake2, in: Direction.left) // adds 1,7 as head

        XCTAssertEqual([
            Point(x: 1, y: 7),
            Point(x: 2, y: 7),
            Point(x: 2, y: 6),
            // Point(x: 2, y: 5) // tails should be discarded when not growing i.e snake length should be the same.
        ], updatedSnake3)
    }
}
```

## Swift linter

Lets add a linter to our project so whoever is working on this particular project will use the same code style as we do. Especially since I try avoid using xcode I need to setup the linter to run whenver needed. For now let's add a few scripts to our Makefile.

```Makefile
#!make

# Default target for watch to run on file changes.
WATCHTARGET ?= unit-tests

# Requires: brew install fswatch
watch:
	while true; do \
		clear; \
		make $(WATCHTARGET); \
		fswatch -1 .; \
	done

# Requires: brew install swiftlint
linter:
	swiftlint

# Requires: brew install swiftlint
linter-fix:
	swiftlint autocorrect

# Requires: xcpretty
unit-tests:
	swift test --enable-test-discovery 2>&1 | xcpretty --simple --color

.PHONY: watch, unit-tests
```

For these targets to work you need to first install [SwifLint](https://github.com/realm/SwiftLint). SwiftLint has some sensible defaults for Swift code styles based on community input. It might be possible you might not be in favour of one or more of the defaults, in that case you can add your custom rules in a `.swiftlint.yml` file. 

I changed some rules for this project with regard to identifier lenghts. I'd rather not have SwiftLint nagging about an `x` or `y` here and there, they make perfect sense as property names for a Point.

```yaml
# SwiftLint default overrides.
identifier_name:
    min_length: # only min_length
      error: 4 # only error
    excluded: # excluded via string array
      - id
      - x
      - y
      - up
      - down
reporter: "markdown" # reporter type (xcode, json, csv, checkstyle, junit, html, emoji, sonarqube, markdown)
```

When you run `make linter`, SwiftLint might give you a bunch of warnings and errors. Some of these might be autocorrectable by running `make linter-fix`. Please fix the rest by hand and try to adhere to our standards. Note though that its good practice to commit your work to git *before* you let scripts do some magic accross your project. This way  you can revert these changes whenever something breaks.

## Cleaner FP

Now, I'd like to introduce something called a pipe operator. This operator, as it name suggests, makes it possible to chain functions in a more readable way, just as you could chain output from different command line utilities by piping them with the  `|` operator . I first came accross this operator when I started with [Elixir](https://elixir-lang.org/), and when I learned from one of the [pointfree.co (referral link)](https://www.pointfree.co/subscribe/personal?ref=Ce841l0i) episodes that it is possible to also create one in Swift I of course wanted to introduce it to my code as well.

We'll put the code for this custom operator in a file called `PipeOperator.swift`.

```swift
/// PipeOperator.swift

/// Pipe operator declaration.
infix operator |>: ForwardApplication

/// Specify the Pipe operator bindings to its operands when grouping parentheses are missing.
precedencegroup ForwardApplication {
    associativity: left
}

/// Pipe operator definition.
func |> <A, B>(a: A, f: (A) -> B) -> B {
    return f(a)
}
```

The operator is first declared as being infix so it can be placed between two operands. Then we make it adhere to the ForwardApplication precedencegroup which is defined next. The ForwardApplication precedencegroup associates its left operand first and we can pipe without the need for parentheses. Of course this operator won't be able to do anything meaningfull when we don't define it's actual functionality. The last bit of code does just that: it defines the  function body that takes two parameters a, a value of type A and f, a function that takes type A and returns type B. The pipe operator itself then returns type B.

Let see how we can use this in our snake code without breaking the tests.

```swift
// Snake.swift

static func move(_ snake: [Point], in direction: Direction) -> [Point] {
		return snake 
        |> updateHead(in: direction)
        |> updateTail
}
```

Here I refactored the `move` function to use our new operator instead of nesting function calls. It looks much better, it clearly shows that we have a snake, update its head, update its tail and return the result.

In the current state it does break our tests. 

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Sources/SnakeCorePackage/Snake.swift:8:30: extraneous argument label 'in:' in call

                |> updateHead(in: direction)
                             ^~~~~
```

Thats not that informative. But clearly our `updateHead` function does not adhere to how the `|>` operator should be used. We try to pipe type `A`, which is a `Snake`, to a function `updateHead` which takes a `Direction` type. We need to be able to control the direction but this is in fact an example of a side-effect. The direction will be controlled by the player and needs to be resolved or set each time this function is called. So, how do we get a `(Snake) -> B type`in this pipeline but also inject the current direction? We'll need to change the signature of the function to

```swift
updateHead(in direction: Direction) -> ([Point]) -> [Point]	
```

Here we basically configure the function with a direction to then return a function ([Point]) -> [Point] basically in our domain (Snake) -> Snake. We also need changes in the `updateHead` body to adhere to our new signature. The next snippet shows the updated function.

 ```swift
 private static func updateHead(in direction: Direction) -> ([Point]) -> [Point] {
 		return { snake in
    		guard let head = snake.first else {
        		return snake
        }
        let delta = direction.asDelta()
        return [Point(x: head.x + delta.x, y: head.y + delta.y)] + snake
    }
 }
 ```

Nothing changed much, we only wrapped the original body into a clojure and return it. Thus the client will get the (Snake) -> Snake type returned. As the client code was the pipe operator, it can now continue to pipe the snake. The test will not pass yet, we need to change the other dependent API call as well.

```swift
static func grow(_ snake: [Point], in direction: Direction) -> ([Point]) {
    return snake
        |> updateHead(in: direction)
}
```

## The Game

The Snake module is good enough for now. We should start looking at a game module which responsibility is to control the different aspect of our game. A first list of things it might be repsonsible for

- Start a game
- Keep a score/tally
- Place food/items (to be eaten by the snake)
- Place snake
- Monitor elapsed time
- Update the Game
- Monitor collisions
- End a game

Before we can play a Game it needs to be created. The first tests for our Game is all about that. The Game will have some state, like score, current food item places, the snake and maybe the player data. 

```swift
// GameTests.swift

import XCTest
@testable import SnakeCorePackage

final class GameTests: XCTestCase {
    func testGameScoreStartAtZero() {
        let game = Game()

        XCTAssertEqual(game.score, 0)
    }

    func testGameDefaultSize() {
        let game = Game()

        XCTAssertEqual(game.size, 8)
    }

    func testSnakePlacement() {
        let position = Point(x: 2, y: 5)
        
        let updatedGame = Game() |> Game.place(snake: position)

        XCTAssertEqual([position, Point(x: 3, y: 5), Point(x: 4, y: 5)], updatedGame.snake)
    }

    func testFoodPlacement() {
        let position = Point(x: 2, y: 5)
        
        let updatedGame = Game() |> Game.place(item: position)

        XCTAssertEqual([position], updatedGame.items)
    }
}
```

Here we start making use of the pipe operator in our tests. I could have place the fisrt two test together but I feel that this way make the intent of the code more clear. Basically we test that the initializer sets default values for the score (0) and the size of the game field (8x8). The implementation making the test green is as follows

```swift
// Game.swift
struct Game {
    let snake: [Point]
    let items: [Point]
    let score: Int
    let size: Int

   init(snake: [Point] = [], items: [Point] = [], score: Int = 0, size: Int = 8, state: Bool = false) {
        self.snake = snake
        self.items = items
        self.score = score
        self.size = size
    }

    static func place(item position: Point) -> (Game) -> Game {
        return { state in
            Game(items: [position])
        }
    }
    
    static func place(snake position: Point) -> (Game) -> Game {
        return { state in
            Game(snake: [
                position,
                Point(x: position.x + 1, y: position.y),
                Point(x: position.x + 2, y: position.y)
            ])
        }
    }
```

The Game struct keeps track of the snake, the items it can potentially eat, the score and the game field size. All properties are `let` constants so that we cannot change the game directly but always need to construct a new game from a previously know state. The initialiser is rather simple, there are defaults set for each property. Then we have two `place` functions, one to add a snake into the game field which is used once at the start of the game and a second to place items into the field which the snake could interact with (currently we treat these items as food).

We are one step further in getting a simple game core. Next article I'll start to cover how we could handle the game loop which we need to have the game update its state.

## Attribution

I've used some ideas found from the following resources and documentation.

\- [Running tests from the terminal](https://www.mokacoding.com/blog/running-tests-from-the-terminal/)

\- [Make phony target](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)

\- [Unit testing with Swift](https://akrabat.com/unit-testing-with-swift-pm/)




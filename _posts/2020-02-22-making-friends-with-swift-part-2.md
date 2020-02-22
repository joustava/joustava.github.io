---
title: Making friends with Swift, part 2
categories:
- Series
- Programming
- Swift
tags:
- Swift
- FP
- TDD
date: 2020-02-22 16:53 +0100
---
In the [first part]({% post_url 2020-02-18-making-friends-with-swift-part-1 %}) of this series, we prepared our environment. This time we'll tackle the initial implementation of our Snake. But before we make our hands dirty, lets make a list of Snake behaviour that we need in our game.

**A snake:**

- [ ] is a dot controlled by the player.
- [ ] moves on the player field.
- [ ] leaves a trail behind
- [ ] dies when it hits itself
- [ ] dies when it hits the edge of the player field.

We might need more features, but for now this is something we can work with. We can always edit this list if needed.

## Spawning a Snake

Everytime a game starts a snake needs to be created in order for the game to place it on the field. Let's start designing that first. First boot up your watcher with `$ make watch`. Nothing has changed since the last time: we should be all green. Then make the 'SnakeTests' look like the following.

```swift
import XCTest
@testable import SnakeCorePackage

final class SnakeTests: XCTestCase {
    func testSnakeSpawns() {
        let snake = Snake.spawn(x: 4, y: 4)
    }
}
```

In our 'testSnakeSpawns' test lets try to spawn a snake with the help of a spawn function in the Snake 'module'. The x and y parameters are the coordinates on the player field where we want the 'head' of the snake to appear.

When you look at the tests, you'll see that that they are trying to be helpful by telling us that something is missing

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:6:21: use of unresolved identifier 'Snake'

        let snake = Snake.spawn(x: 4, y: 4)
                    ^~~~~
```

That should be pretty obvious, we didn't create this module yet. Create a 'Snake.swift' file with the following content

```swift
struct Snake {}
```

The test are now informing about a 'spawn' function not being available on our Snake type. Add this function so that it now looks like

```swift
struct Snake {
    func spawn() {}
}
```

Now our test result are kind enough to suggest something:

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:6:27: instance member 'spawn' cannot be used on type 'Snake'; did you mean to use a value of this type instead?

        let snake = Snake.spawn(x: 4, y: 4)
                    ~~~~~ ^
```

But no, I would like to avoid using a value of type Snake here, especially because this function will create snake data for us. At least for now we will tag the function as being static and we'll also make the function return a list of int tuples which contains only one point: the 'head' of our snake.

```swift
struct Snake {
    static func spawn(x: Int, y: Int) -> [(Int, Int)] {
        return [(x, y)]
    }
}
```

This gives a nice result, we have passing tests and one warning.

```shell
⚠️  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:6:13: initialization of immutable value 'snake' was never used; consider replacing with assignment to '_' or removing it

        let snake = Snake.spawn(x: 4, y: 4)
        ~~~~^~~~~


All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeTests
    ✓ testSnakeSpawns (0.195 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.195 (0.195) seconds
```

However, this test does not assert anything. It does not tell us what is expected.
As the player field is a grid of coordinates, let's assert that the function returns a point with the supplied coordinates.

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:8:25: use of unresolved identifier 'Point'

        XCTAssertEqual([Point(x: 4, y: 4)], snake)
                        ^~~~~
```

Because we need to create a Point struct with the properties x and y.

```swift
struct Point {
    let x: Int
    let y: Int
}
```

Our test are still not happy, as they cannot apply the equatable on the tuple.

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:8:9: protocol type 'Any' cannot conform to 'Equatable' because only concrete types can conform to protocols

        XCTAssertEqual([Point(x: 4, y: 4)], snake)
        ^
```

And if we return an array of Points we get told that the test requires Point to be [equatable](https://developer.apple.com/documentation/swift/equatable).
We wil listen to the test, we will definitely need to compare points later in order to detect if the snake is eating food, itself, or is tired of this world and runs of the player field. 

```shell
❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:8:9: global function 'XCTAssertEqual(_:_:_:file:line:)' requires that 'Point' conform to 'Equatable'

        XCTAssertEqual([Point(x: 4, y: 4)], snake)
        ^
```

It is enough to just conform our Point struct to Equatable, because both x and y properties also conform to Equatable.

```swift
struct Point: Equatable {
    let x: Int
    let y: Int
}
```

Now everything is green. For good measure and before I forget, lets also test that we expect Points to be equatable. Create a new `PointTest.swift` with this content  

```swift
import XCTest
@testable import SnakeCorePackage

final class PointTests: XCTestCase {
    func testPointsAreEquatable() {
        XCTAssertEqual(Point(x: 4, y: 4), Point(x: 4, y: 4))
        XCTAssertNotEqual(Point(x: 3, y: 4), Point(x: 4, y: 4))
    }
}
```

I think it is ok to add this test afterwards. We are not designing anything new here and just want to clarify that the point equatabilty is an important trait we will depend upon later.

## Making the Snake change position

Now that we have a way to spawn a snake it's time to make it look alive by moving it on the player board. Make a new test function right under the `testSnakeSpawns` function, just like

```swift
//...

func testSnakeMovesLeft() {
		let snake = Snake.spawn(x: 2, y: 5)
}

//...
```

This behaviour has been tested already and it is no surprise that the test still pass with a friendly warning which we will get rid of soon.

```shell

⚠️  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:12:13: initialization of immutable value 'snake' was never used; consider replacing with assignment to '_' or removing it

        let snake = Snake.spawn(x: 2, y: 5)
        ~~~~^~~~~


All tests
Test Suite SnakeCorePackagePackageTests.xctest started
PointTests
    ✓ testPointsAreEquatable (0.194 seconds)
SnakeTests
    ✓ testSnakeMovesLeft (0.003 seconds)
    ✓ testSnakeSpawns (0.001 seconds)


	 Executed 3 tests, with 0 failures (0 unexpected) in 0.197 (0.199) seconds

```

Our snake should be able to move in all directions on the board: up, down, left and right. Our test introduces this concept modelled as a Direction.

```swift 
func testSnakeMovesLeft() {
    let snake = Snake.spawn(x: 2, y: 5)
          
    let updatedSnake = Snake.move(snake, in: Direction.left)
}
```

If you follow along, you will see the tests fail again because a Direction implementation is missing. From now on I'll be leaving out the testing output and assume you have the watcher script running on your machine. We'll implement Direction as an enum with the four directions as its cases and also add a move function to snake as thats what's next on the menu according to the test output. When the move function is in place, the test will tell you that the arguments are missing. Here is the code that makes the test green again.

```swift
/// Direction.swift
enum Direction {
    case up
    case right
    case down
    case left
}

/// Snake.swift
// ...
static func move(_ snake: [Point], in: Direction) {
	
}
// ...
```

Moving the snake basically mean that we need to shift its current position into the chosen direction. Lets finish the test for the 'moving left' case.

```swift
func testSnakeMovesLeft() {
  	let snake = Snake.spawn(x: 2, y: 5)
          
  	let updatedSnake = Snake.move(snake, in: Direction.left)

  	XCTAssertEqual([Point(x: 1, y: 5)], updatedSnake)
}
```

Moving left just means we need to update `x` to be one step closer to the normal, `y` does not change. 

This causes `cannot convert value of type '()' to expected argument type '[Point]'`, as we are not returning the expected value. When we follow the tests advice, we will end up declaring a return value and as our test expects a specific point, we will return that exact point.

```swift
/// Snake.swift
// ...
static func move(_ snake: [Point], in: Direction) -> [Point] {
  	return [Point(x: 1, y: 5)]
}
// ...
```

Again, green! The test for moving right is next. The only difference with the previous test is the direction and the expected value for point. Which of course fails as our `move` implementation returns a canned response.

```swift
func testSnakeMovesLeft() {
  	let snake = Snake.spawn(x: 2, y: 5)

  	let updatedSnake = Snake.move(snake, in: Direction.right)

  	XCTAssertEqual([Point(x: 3, y: 5)], updatedSnake)
}
```

Back to our snake design! We want to update a point in a certain direction, lets call this first point of the snake its head.

```swift
/// Snake.swift
// ...
static func move(_ snake: [Point], in direction: Direction) -> [Point] {
   return updateHead(snake, in: direction)
 }

private static func updateHead(_ snake: [Point], in direction: Direction) -> [Point] {
  	guard let head = snake.first else {
    	return snake
  	}
  	let delta = direction.asDelta()
  	return [Point(x: head.x + delta.x, y: head.y + delta.y)]
}
// ...
```

Here we get the head of the array, if we cannot find it we'll just pass the array back to the caller. If we do find the snakes head, we determine what the delta is for the current Direction. At the moment the value of type 'Direction' has no member 'asDelta' as our test suggests. The delta is just a point where x and y are either 0, 1 or -1, 0 means stationary, and 1 or -1 mean opposite directions on either the x or y axis. It would look something like this

```swift
/// Direction.swift
// ...
func asDelta() -> Point {
		switch self {
		case .left: return Point(x: -1, y: 0)
    default: return Point(x: 0, y: 0)
		}
}
// ...
```

The other cases should be quite trivial to implement and I encourage you to write the tests and implementation for the other three directions yourself to get a feel of the red/green cycle. Do note that in this implementation the origins of both axii are in the top left corner of the player field.

## Making the Snake grow

The next behaviour we tackle is growing. Each time the Snake encounters or collides with food the snake will grow by one section or point. We only take care of making the snake grow at the moment we will not look at actual collision detection with a point that represents food. Simple first. in the new test we will again spawn a new snake and create a call to our future api.

```swift
/// Snake.swift
func testSnakeGrows() {
  	let snake = Snake.spawn(x: 2, y: 5)

  	// ❌ type 'Snake' has no member 'grow' (yet)
  	let updatedSnake = Snake.grow(snake, in: Direction.down)

  	XCTAssertEqual([
      	Point(x: 2, y: 6),
    		Point(x: 2, y: 5)
    ], updatedSnake)
}
```

As the snake will grow while encountering food we need to concider the direction it is travelling. The concept of eating in my implementation would go something like this while moving e.g downward

1.  snake moves down.
2. snake collides with food item.
3. snake grows downward 'over' food as to make it seem to swallow the item.
4. food is gone, and snake is a section bigger.

This means that growing just means adding a point to the snake in the direction it moves.

```swift
/// Snake.swift
// ...
 static func grow(_ snake: [Point], in direction: Direction) -> ([Point]) {
 		return updateHead(snake, in: direction) + snake
 }
 // ...
```

We reuse the updateHead function and add the previous head as it body, or, the rest of the snake. Now that it can grow officially (through our api) we probably should reiterate its movement behaviour to see if we might have broken our design or that we need to add some extra checks. One thing we certainly should check is the behaviour when direction of movement changes. Lets commit first though, to safeguard our work!

The next test first spawns a snake and then makes it grow a couple of times. The thing we test is the change of direction of movement to another axis.

```swift
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
```

This test fails with `XCTAssertEqual failed: ("[SnakeCorePackage.Point(x: 1, y: 7), SnakeCorePackage.Point(x: 2, y: 7), SnakeCorePackage.Point(x: 2, y: 6)]") is not equal to ("[SnakeCorePackage.Point(x: 1, y: 7)]")`  as we know that the `grow` function works, i.e it increases the snake lenght, we can assume that the thing that breaks our tests is in the move function. If we have a closer look it indeed seems to be so. We're discarding the body of the snake in `updateHead`.  

One way to fix this is to see the act of moving as a combination of adding a point to the beginning of the snake and at the same time remove a point from the end. This keeps the lenght constant but moves the complete line (we'd draw with the points) over the player field (coordinate system). 

1. function `updateHead` should now just append the new snake head and not care about the increasing lenght. 
2. function `grow` keeps using the updated `upadateHead` function.
3. function `move` wraps the `updateHead` function to control the lenght.
4. function `updateTail` returns the first count - 1 points of the snake.

```swift
struct Snake {
    static func spawn(x: Int, y: Int) -> [Point] {
        return [Point(x: x, y: y)]
    }

    static func move(_ snake: [Point], in direction: Direction) -> [Point] {
        return updateTail(updateHead(snake, in: direction)) // 3.
    }

    static func grow(_ snake: [Point], in direction: Direction) -> ([Point]) {
            return updateHead(snake, in: direction) // 2.
    }

    // MARK: - Private

    private static func updateHead(_ snake: [Point], in direction: Direction) -> [Point] {
        guard let head = snake.first else {
            return snake
        }
        let delta = direction.asDelta()
        return [Point(x: head.x + delta.x, y: head.y + delta.y)] + snake // 1.
    }
		
  	// 4.
    private static func updateTail(_ snake: [Point]) -> [Point] {
       return Array(snake.prefix(upTo: snake.count - 1))
    }
}
```

All test pass once more!

```shell
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
PointTests
    ✓ testPointsAreEquatable (0.099 seconds)
SnakeTests
    ✓ testSnakeChangesDirection (0.002 seconds)
    ✓ testSnakeGrowsDown (0.000 seconds)
    ✓ testSnakeGrowsLeft (0.000 seconds)
    ✓ testSnakeGrowsRight (0.001 seconds)
    ✓ testSnakeGrowsUp (0.000 seconds)
    ✓ testSnakeMoveDown (0.000 seconds)
    ✓ testSnakeMovesLeft (0.000 seconds)
    ✓ testSnakeMovesRight (0.000 seconds)
    ✓ testSnakeMovesUp (0.000 seconds)
    ✓ testSnakeSpawns (0.000 seconds)


	 Executed 11 tests, with 0 failures (0 unexpected) in 0.103 (0.104) seconds
```

That should be it for the Snake behaviour, at least for what we know we need at this time. There are some little details left in the implementation which I'm not content with. But as bedtime was closing in, I'll keep those fixes for the next post.

## Attribution

I've used some ideas found from the following resources and documentation.

- [Running tests from the terminal](https://www.mokacoding.com/blog/running-tests-from-the-terminal/)
- [Make phony target](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)
- [Unit testing with Swift](https://akrabat.com/unit-testing-with-swift-pm/)

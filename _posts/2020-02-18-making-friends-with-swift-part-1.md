---
title: Making friends with Swift, part 1
categories:
- Series
- Programming
- Swift
tags:
- Swift
- FP
- TDD
date: 2020-02-18 08:09 +0100
---
I have been dabbling in iOS for about a year now. Using XCode for development, Carthage or Swift Package Manager for dependency management. Unfortunately, I have not come to like the development feedback cycle mainly due to Xcode, and in any case, I'm not a fan of most IDE's, there is always some specific way to configure projects, or dabbling around in UI to find some particular build settings that might as well have been put in a human readable file. Don't get me wrong though, IDE's have their place, I just don't like to become dependent on them. 

The following set of articles is my attempt to become a happier [Swift](https://developer.apple.com/swift/#open-source) developer by trying out another approach to development and leave out xcode as much as possible. I'll be trying to create a project from scratch while following [TDD](https://en.wikipedia.org/wiki/Test-driven_development) and [FP](https://en.wikipedia.org/wiki/Functional_programming) principles.

I am no seasoned Swift or Mobile developer by any means. If you read this and you think 'jeez why would you do that', please tell me what you would do differently and why your approach would make more sense in your opinion. I'm open to suggestions. Future readers will be thankful.

As example, we'll be creating the well known Snake game which is defined in Wikipedia as

> ***Snake*** is the common name for a video game concept where the player maneuvers a line which grows in length, with the line itself being a primary obstacle.

Our variant will have the following initial specification

> The player controls a dot, square, or object on a bordered plane. As it moves forward, it leaves a trail behind, resembling a moving snake. The snake has a specific length, so there is a moving tail a fixed number of units away from the head. The player loses when the snake runs into the screen border, a trail or other obstacle, or itself. The player attempts to eat items by running into them with the head of the snake. Each item eaten makes the snake longer, so controlling is progressively more difficult.

Let's get started with this information.

## Project setup

The fist thing we'll be working on will be the engine or core of our snake game. The goal is to keep the core implementation self contained.

Create a library package as described in the [SPM](https://swift.org/package-manager/) usage [documentation](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md)

```shell
$ mkdir SnakeCorePackage
$ cd SnakeCorePackage
$ swift package init
Creating library package: SnakeCorePackage
Creating Package.swift
Creating README.md
Creating .gitignore
Creating Sources/
Creating Sources/SnakeCorePackage/SnakeCorePackage.swift
Creating Tests/
Creating Tests/LinuxMain.swift
Creating Tests/SnakeCorePackageTests/
Creating Tests/SnakeCorePackageTests/SnakeCorePackageTests.swift
Creating Tests/SnakeCorePackageTests/XCTestManifests.swift
```

Then build it for good measure

```shell
$ swift build
[2/2] Merging module SnakeCorePackage
```

And before we go further, run the tests.

```shell
$ swift test
[4/4] Linking SnakeCorePackagePackageTests
Test Suite 'All tests' started at 2020-02-15 16:59:41.856
Test Suite 'SnakeCorePackagePackageTests.xctest' started at 2020-02-15 16:59:41.857
Test Suite 'SnakeCorePackageTests' started at 2020-02-15 16:59:41.857
Test Case '-[SnakeCorePackageTests.SnakeCorePackageTests testExample]' started.
Test Case '-[SnakeCorePackageTests.SnakeCorePackageTests testExample]' passed (0.180 seconds).
Test Suite 'SnakeCorePackageTests' passed at 2020-02-15 16:59:42.037.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.180 (0.181) seconds
Test Suite 'SnakeCorePackagePackageTests.xctest' passed at 2020-02-15 16:59:42.038.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.180 (0.181) seconds
Test Suite 'All tests' passed at 2020-02-15 16:59:42.038.
	 Executed 1 test, with 0 failures (0 unexpected) in 0.180 (0.182) seconds
```

If the dummy test doesn't pass, please check your output for errors  and fix your setup before going further. If you have all green you're good to go. It's common practice to commit working changes to Git.

```bash
$ git init
$ git add .
$ git commit -m 'Initial package setup'
```

The output of `swift test` is informative but a little hard on the eyes. We'll be using [`xcpretty`](https://github.com/xcpretty/xcpretty) to make the output a little easier to parse. Install it and then run

```bash
$ swift test 2>&1 | xcpretty --simple --color
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeCorePackageTests
    ✓ testExample (0.141 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.141 (0.141) seconds
```

There are a few other options to generate different styles of reports. The command has some oddity going on as swift test output needs to be redirected to stdin but I'll wrap this into a Makefile, so we won't have to remember this. In the project root add a file named `Makefile` with the following content

```makefile
#!make

unit-tests:
	swift test 2>&1 | xcpretty --simple --color

.PHONY: unit-tests

```

now you can run the test instead with

```shell
$ make unit-tests
swift test 2>&1 | xcpretty --simple --color
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeCorePackageTests
    ✓ testExample (0.140 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.140 (0.140) seconds


```

Tests are only valuable if they give a developer fast feedback so I'd like to run them all every time a file has changed. We can do this also with the help of the Makefile by adding an extra phony target to it that watches for changes in our current directory and executes our test target every time a change occurs. our Makefile should now look like

```makefile
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

# Requires: xcpretty
unit-tests:
	swift test 2>&1 | xcpretty --simple --color

.PHONY: watch, unit-tests

```

Now, open a new terminal window and run

```shell
$ make watch
swift test 2>&1 | xcpretty --simple --color
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeCorePackageTests
    ✓ testExample (0.135 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.135 (0.135) seconds

```

Every time changes are detected, the console is cleared and new test results are presented. Lets see how this works in practice, after you've commited the Makefile to your Git repo.

## Preparing the first Snake test

As mentioned, we will not have and UI related code in our Core package. The specs mention the snake being a dot that moves over a bordered field, that it grows when eating and has a constant length in between meals. My mind tells me that we can represent the snake within our logic with an array of x, y coordinates and that we can manipulate this list by e.g pusing and popping to this list. Before my mind start wandering off into over-engineering nirvana, lets start writing some tests first to design our first iteration of the Snake logic.

While your watcher script is runnig, crete a new file test file by running

```shell
$ cp Tests/SnakeCorePackageTests/SnakeCorePackageTests.swift Tests/SnakeCorePackageTests/SnakeTests.swift
```

This new file will contain all our unit tests for our Snake. When you check the watcher output you will see an error.

```shell
swift test 2>&1 | xcpretty --simple --color

❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:4:13: invalid redeclaration of 'SnakeCorePackageTests'

final class SnakeCorePackageTests: XCTestCase {
            ^
```

Fix it by renaming the class to SnakeTests.

```swift

import XCTest
@testable import SnakeCorePackage

final class SnakeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SnakeCorePackage().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

```

You should see the following watching output

```shell
swift test 2>&1 | xcpretty --simple --color
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeCorePackageTests
    ✓ testExample (0.173 seconds)
SnakeTests
    ✓ testExample (0.000 seconds)


	 Executed 2 tests, with 0 failures (0 unexpected) in 0.173 (0.174) seconds


```

From now on I'll try to have an iterative workflow while creating an initial implementation of our Snake. All test pass, this means form an TDD perspective that I can start adding test again.

First rename the `testExample` test function to `testSnake`, oh... this fails our tests

```shell
swift test 2>&1 | xcpretty --simple --color

❌  /Users/joustava/Workspace/spikes/SnakeCorePackage/Tests/SnakeCorePackageTests/SnakeTests.swift:13:25: use of unresolved identifier 'testExample'

        ("testExample", testExample),
                        ^~~~~~~~~~~
```

Hmm, the allTests seems to be there for test discovery when running on other platforms than Apple. However in Swift 5.1 this has been fixed in this [PR](https://github.com/apple/swift-package-manager/pull/2174). It seems we can remove `XCTestManifests.swift`, remove all occurences of the `allTests` properties and remove the references to those allTest properties from `LinuxMain.swift`. Enabling of the new discovery feature we'd need to add the flag `--enable-test-discovery` to our test command whenever we need to run them on a Linux machine. I added the flag to the Makefile, it seems to have no ill effect when running on a Mac as I do. For good measure I also delete the `SnakeCorePackageTests` as we don't need this anymore. 

All tests (one) still pass.

```shell
swift test --enable-test-discovery 2>&1 | xcpretty --simple --color
All tests
Test Suite SnakeCorePackagePackageTests.xctest started
SnakeTests
    ✓ testSnake (0.096 seconds)


	 Executed 1 test, with 0 failures (0 unexpected) in 0.096 (0.096) seconds


```

For clarity, here my current git status of my repo

```shell
$ git status
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	renamed:    Tests/SnakeCorePackageTests/SnakeCorePackageTests.swift -> Tests/SnakeCorePackageTests/SnakeTests.swift
	deleted:    Tests/SnakeCorePackageTests/XCTestManifests.swift

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   Makefile
	modified:   Tests/LinuxMain.swift
```

And here the modifications I made

```diff
$ git diff
diff --git a/Makefile b/Makefile
index 4e32d9c..85f6ff0 100644
--- a/Makefile
+++ b/Makefile
@@ -13,6 +13,6 @@ watch:

 # Requires: xcpretty
 unit-tests:
-       swift test 2>&1 | xcpretty --simple --color
+       swift test --enable-test-discovery 2>&1 | xcpretty --simple --color

 .PHONY: watch, unit-tests
\ No newline at end of file
diff --git a/Tests/LinuxMain.swift b/Tests/LinuxMain.swift
index 9798f3f..039eae4 100644
--- a/Tests/LinuxMain.swift
+++ b/Tests/LinuxMain.swift
@@ -3,5 +3,5 @@ import XCTest
 import SnakeCorePackageTests

 var tests = [XCTestCaseEntry]()
-tests += SnakeCorePackageTests.allTests()
+tests
 XCTMain(tests)
```

Well, we diverged a little here. We probably could have fixed the allTest issue by just removing the properties only. I however like to give my fellow developers a smooth setup experience, even if they choose to run Linux. I have no means to actually check this setup on a Linux machine (sorry!) so if you do, please let me know if this works for you.

It's that time to commit again. We didn't get far with designing our Snake core but we have tackled our setup and from now on we should be able to proceed relatively smooth. I need a breather. In [part 2]({% post_url 2020-02-22-making-friends-with-swift-part-2 %}) we will start creating our snake module. See you there!

## Attribution

I've used some ideas found from the following resources and documentation.

- [Running tests from the terminal](https://www.mokacoding.com/blog/running-tests-from-the-terminal/)
- [Make phony target](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html)
- [Unit testing with Swift](https://akrabat.com/unit-testing-with-swift-pm/)

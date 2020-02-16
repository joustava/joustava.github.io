---
title: Code Quality
---
I’ve been working full-time in the IT industry for about 10 years as a software engineer in both big and small projects built with different technologies. I’ve seen open source projects, startup projects and enterprise software. I might have been very unlucky but to me it seems that often open source software is of much better quality then proprietary software.

Why?! Well of course no-one really sees your proprietary code except for you and your colleagues and hey, it works right? So, how is it that you actually ARE able to write qualitative code on that OS project you contribute to?

## My guess

- Closed source is not usually seen by many developers
- Prototyping is seen as an excuse for ‘hacking’
- Lack of time
- Lack of interest
- Too much changes going on at the same time
- Tech is not fitting the project, developing becomes clumsy
- Lacking tests
- No consensus on architecture/code style/framework
- Other peoples code is alway shitty ;)

## Change of attitude

You get paid for your job so produce code as you would do in OS. You have colleagues who might need to work on/with your code and heck you even might have to code on it yourself.. duh!

## Level 1

- Have a README. one based on e.g this github [template](https://gist.github.com/jxson/1784669) will do or something like described [here](https://github.com/repat/README-template) or [here](https://dbader.org/blog/write-a-great-readme-for-your-github-project)
- have at least a testing setup with some smoke tests. this invites for testing
- try to organize your code. don’t have everything smacked in one big folder/file
- use some sensible naming scheme (naming is difficult, at least try to make some sense anyway)
- order your code to do things for you, instead of do_something_incredibly_awesome_when_you_feel_like_it()
- keep lines per functionality small, divide.
- write sensible commit messages [](http://who-t.blogspot.nl/2009/12/on-commit-messages.html)
- do not reinvent the wheel

## Level 2

- Unit test. don’t let someone waste time on your untested complicated method which just broke due to some library updates (which you find out after 3 hours of headbanging)
- test public API, makes you think about usage from outside.
- Don’t get all the guns out, just use the default testing strategy, tests are tests.

## Level 3

- refactor complicated code, now that you have those tests lying around.
- benchmark, nice to have on heavy traffic apps or apps for limited devices
- code coverage, have you missed testing some code branch
- inline doc, see in a glance what it does, and most of the time you can generate docs from this for 3rd parties.
- acceptance tests, tests which are readable by non-tech
- configure automated code linting
- apply the style guide automatically

#######
This is my view on quality in the context of the 'How to measure quality of a source code file automatically.'

## Test Coverage

When a piece of software has a high test coverage, a developer can feel more relaxed when implementing new features. Existing tests will give the possibility of running regression tests which will convince the developer that he or she has not broken any existing features. Test also serve as a source of API documentation, so in general it is easier to implement or change a feature.

## Test Speed

When developing, it is great to have immediate feedback on what you just created. No developer likes tests suits that run for hours. Of course running a complete set of test encompassing an entire system might take longer but this could be done on a CI server.

## Readability

First of all, in my experience typos can be very irritating. Language keywords can be automatically tracked by the IDE of choice. However, typos in naming or wrong use of language can make it sometimes difficult to find what you are looking for.
Naming conventions are also very important, so you know what to expect when you look for certain functionality. Using the technologies or languages best practices as much as possible also makes it easier to understand and know what to look for.
A high number of lines of code (per cohesive unit or function) could indicate a high complexity or lack of cohesion. Spending time on refactoring this areas of the application can result in higher quality.

## Costs

Cost per feature, with this I mean how much of resources are spend on a certain feature. You would not want to spend time on features that probably won't be used in the near future. Of course they can be planned or be listed in some form of backlog. However, having developers having to create tests/make changes to code which in effect is barely used is a waste.
Bugs, they occur in every project, but the rate in which they are received could mean untested code, incomplete understanding of the domain model or unintended and misuse of the code. I put this under costs, as a big part of time spend on software is done during maintenance.
Number of changes of a certain unit could refer to the previous metric, and a bug fix is under way. It could also mean however that a certain unit of code has more responsibilities than it should have. It can become a bottleneck or single point of failure.
When there is more than one person working on a certain feature then there exists a certain level of peer reviewing. This can be a good thing because people with different experiences and backgrounds will be able to give feedback which can be used to improve the code, and also improves the teams know-how.
The time spend on implementing features and maintenance should be as minimum as possible. It is a waste to spend months of development time and lose customers because of a competitor that has already something better.

## Measuring code quality.

Check if it has sufficient testing coverage. Many technology stacks include some sort of library with which test coverage can be calculated. These can simply be run together or separately from the test runs. The results from these test runs can be represented and stored in e.g HTML format.
Testing includes unit testing, functional testing, acceptance testing and performance/stress testing.
The source code can be checked agains a specific Lint library to check if it conforms to guidelines and to catch certain constructs which could cause problems at runtime.
Inline documentation…
Automate the style guide…
Code review. When work is pushed to a repository, a review tool can be used so that interested parties will be notified, can review the code, and according to certain review rules can be merged with the production branch. The source commits can be linked to a ticketing system to be able to check if the change implements a required feature (according to requirements/acceptance tests). The process is automatic, the review itself is actually going through the code manually. but this can increase quality significantly.
Check performance on places that are known to be possible bottlenecks(before it becomes a problem, but don't over engineer) with performance or stress testing. Bottlenecks could be those files or source that are referenced/included from many places in a software project.
With the help of SCM logs it is possible to give visibility to who and what has been done to source code.
Analysis can be done by a CI server, which runs on each push certain hooks and stores and or reports the metrics that are of interest.
As all gathered quality data depends on some kind of measurements there is of course a need for reference data. We need to be able to compare our previous quality with the current quality in order to be able to say e.g 'now this piece of code performs 10ms faster'. This way we can prove that the quality has improved or that there is still need for improvement.


## Sources

* [link](url)

## More

* [link](url)

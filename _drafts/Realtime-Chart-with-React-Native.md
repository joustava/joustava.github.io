---
title: Realtime Chart with React-Native
tags:
  - d3.js
  - React
  - React-Native
  - react-native-svg
  - SVG
series: react-native
abbrlink: a33fa3ec
---

This time we're going to make a chart in React-Native that updates based on time.
I'll focus on Android as the target platform as I don't own an iOS device.

## Setting it up

In case you haven't done this already, install the react-native-cli according to the Building Projects with Native Code in the [getting started docs](https://facebook.github.io/react-native/docs/getting-started.html) of React-Native.

When installed, create a new project and jump into its directory

```
  $ react-native init MyRealtimeChart
  $ cd MyRealtimeChart
```

Before you continue make sure you have a device attached via USB or a running emulator.
Then to check if everything is setup correctly let run our newly created app.

```
  $ react-native run-android
```

If everything is set up correctly you should see React-Natives welcome message on screen.

## Basic Project adjustments

When starting from scratch on a React-Native project I usually create a `./scr` directory to which I move the `App.js` file and I change the import in `index.js` accordingly. Your project structure should now look like this

```
RealtimeChart/
├── android/
├── app.json
├── index.js
├── ios/
├── node_modules/
├── package.json
├── src/
└── yarn.lock
```

Now is a good time to setup git and commit your work for safekeeping.

```
$ git init
$ git add .
$ git commit -m 'initial commit'
```

## Storybook for component development

We will be using [storybook.js](https://storybook.js.org/) for development of our components.
It is a tool that enables you to develop and showcase all the different components and their states that you might need in your application. I install it slightly different as described in the link, as I do not want to install it globally. First, install it as development dependency

```
$ yarn add @storybook/cli -D
```

Second, initialise it for you project
```
$./node_modules/.bin/getstorybook
```

To check if it works, first kill your running metro bundler and then run
```
$ yarn run storybook
```

and run
```
$ react-native run-android
```

When you visit http://localhost:7007/ you should see the storybook interface and it should load
a couple of examples which you can chose from in order to display them on the device.

Again, this is a good time to make a commit for safekeeping.

```
$ git add .
$ git commit -m 'Add storybook.js'
```

## Customising Storybook

By default, storybook will look for stories in a `<project>/storybook/stories` directory.
I prefer to keep the stories with the components they represent and to do this we can install
[react-native-storybook-loader](https://github.com/elderfo/react-native-storybook-loader)

```
yarn add react-native-storybook-loader -D
```
to make use of react-native-storybook-loader some changes have to be made to
`./package.json` and `./storybook/storybook.js`

```
{
  ...
  "scripts": {
    ...
    "prestorybook": "rnstl"
    ...
  }


  "config": {
      "react-native-storybook-loader": {
        "searchDir": [
          "./src"
        ],
        "pattern": "**/*.stories.js",
        "outputFile": "./storybook/storyLoader.js"
      }
    }

  ...
}
```
This will make storybook resolve files in `./src` that match the `*.stories.js` pattern.

```
...
import { loadStories } from './storyLoader';

configure(loadStories, module);
...
```
And this will make storybook load the files that are resolved by react-native-storybook-loader.
To check if this works we can move the existing story examples into `./src`, [check this commit for details](link to commit)

Don't forget to make your own git commit!

## Creating the Chart

Finally, we come to the real story of this post. From now on together with [d3.js](https://github.com/d3/d3) and [react-native-svg](https://github.com/react-native-community/react-native-svg) we will try to create a real time chart.

To get the dependencies out of the way, lets first install the before mentioned packages and then link the native code of react-native-svg

```
$ yarn add d3 react-native-svg
$ react-native link
```

### Margins

Because need margins in order to display axes around the graphed data view, the top level component we create will calculate the remaining drawing space based on the margins we supply to it. This component
is based on the excellent information [from the d3.js author](https://bl.ocks.org/mbostock/3019563).

The component takes a margin object and children, based on the margins it will calculate an inner dimension for our graph 'canvas'. When there are no children it will simply render a default placeholder.
As the real screen dimensions might not yet be available when the component renders, we listen to the onLayout event of the wrapping View and only render the inner children when the dimensions are known to us as we have a guard clause within the wrapping View.

It also conveniently passes the inner width and height to it children component so that we do not need to care about the margins anymore further down the component tree.

SEE commits at tag v0.1.0 for details.

### Axis




## Todo

- [ ] Clean up dependencies warnings
- [ ] Add eslint configuration
- [ ] Add flow configuration
- [ ] Add tests, jest unit/snapshot

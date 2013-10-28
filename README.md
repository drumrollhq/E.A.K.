Erase All Kittens
=============

`Erase All Kittens` is a new open source `HTML`/`CSS` game about an _evil rebellion, intent on destroying all kittens on the Internet_. Learn to code whilst playing to help **save the kittens**, and consequently save the world!

## Try it online
We have an *early* demo you can play at [http://eraseallkittens.com/play.html](http://eraseallkittens.com/play.html) that we demonstrate during the [#MozFest 2013]().

## Team & project
We’re a team of one developer, one creative and one designer who are trying to **teach kids to code with the best game we can build**.

We’ve created the story, structure and look of the game, and we’d like some help to develop it further, specifically from developers, illustrators, and level designers.

If you’re interested in what we’ve done so far or would like to help out, we’d love to hear from you. Fill out the form on [our website](http://eraseallkittens.com/), and we'll get in touch :)

## Installing

Start by cloning the project:
```bash
git clone git@github.com:SomeHats/Erase-All-Kittens.git
cd Erase-All-Kittens
```
Then install dependendies and initialize submodule:
```bash
# install dependecies
npm install
bower install
# init and install submodule
git submodule init
git submodule update
```
You will also need to install [`brunch`](https://github.com/brunch/brunch) to be able to build the project:
```bash
# installing it globally (may require 'sudo' privileges)
npm install -g brunch
brunch build
```

## Usage
If no errors happen during build a new `public/` directory would be present. So, now you can run the app with:
```bash
brunch watch --server
```
Then, go to the app local server using [http://localhost:3333/](http://localhost:3333/). If you want to reach the game directly, add the `play.html` suffix to reach the game:

    http://localhost:3333/play.html

Enjoy hack-learning ;)

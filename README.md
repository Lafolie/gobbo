# Gobbo
An interpreted programming langauge based on Lox, written in Nim.

This is my follow-along project to to [Crafting Interpreters](https://craftinginterpreters.com/).

## Building
Since this project is not intended to be used seriously, I will not be providing a nimble package.

1. Clone the repo
2. Build with `nim -c gobbo.nim`

## Running Gobbo
To run `.gob` source simply pass the path to file to gobbo.

```sh
$ gobbo src.gob
```

Gobbo uses a basic stdin REPL if no source file is given.

## Differences from Lox
As a bit of a challenge I have decided to stray from the source material a little:

* Does not have `class`, has `struct` instead
* Has arrays (dynamic)
* Has hashmaps
* Significant whitespace?
* Optional semi-colons?
* Supports multiple numerical notations (decimal, hex, binary, scientific)

## Syntax
to-do

* Line endings must be LF (CRLF is erroneous)

Example programs can be found in `gobsrc/`
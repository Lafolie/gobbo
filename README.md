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
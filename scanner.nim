#? replace(sub = "\t", by = "  ")

import token
import error
import std/unicode

type
	ScanState = object
		path: string
		source: string
		start: int
		current: int
		line: int
		tokens: seq[Token]

proc rune(str: static string): Rune =
	when str.runeLen != 1:
		{.error: "Provide a single rune".}
	str.runeAt(0)

proc add(state: var ScanState, kind: TokenType) =
	state.tokens.add(Token(kind: kind, lexeme: "", literal: RootObj(), line: state.line))

proc advance(state: var ScanState): Rune =
	result = state.source.runeAtPos(state.current)
	state.current += 1

proc hasReachedEnd(state: ScanState): bool =
	state.current >= state.source.runeLen

proc scanToken(state: var ScanState) =
	let nextRune = state.advance()
	case nextRune
	of rune"(": state.add ParenOpen
	of rune")": state.add ParenClose
	of rune"{": state.add BraceOpen
	of rune"}": state.add BraceClose
	of rune"[": state.add SquareOpen
	of rune"]": state.add SquareClose
	of rune",": state.add Comma
	of rune".": state.add Dot
	of rune"+": state.add Plus
	of rune"-": state.add Minus
	of rune";": state.add Semicolon
	of rune"/": state.add Slash
	of rune"*": state.add Star

	else:
		gobError(state.path, state.line, "Unexpected character")


proc scanTokens*(source: string, path: string): seq[Token] =
	var state = ScanState(source: source, path: path, start: 0, current: 0, line: 1)

	while not state.hasReachedEnd():
		state.start = state.current
		state.scanToken()
	
	state.add(EOF)
	return state.tokens

#? replace(sub = "\t", by = "  ")

import token
import std/unicode

type
	ScanState = object
		source: string
		start: int
		current: int
		line: int
		tokens: seq[Token]

proc add(state: var ScanState, kind: TokenType) =
	state.tokens.add(Token(kind: kind, lexeme: "", literal: RootObj(), line: state.line))

proc advance(state: var ScanState): Rune =
	result = state.source.runeAtPos(state.current)
	state.current += 1

proc hasReachedEnd(state: ScanState): bool =
	state.current >= state.source.runeLen()

proc scanToken(state: var ScanState) =
	let rune = state.advance()
	case rune
	of "(":
		state.add ParenOpen
	else:
		discard

	

proc scanTokens*(source: string): seq[Token] =
	var state = ScanState(source: source, start: 0, current: 0, line: 1)

	while not state.hasReachedEnd():
		state.start = state.current
		scanToken()
	
	result.add(Token(kind: TokenType.EOF, lexeme: "", literal: RootObj(), line: state.line))

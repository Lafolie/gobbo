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

# proc rune(str: static string): Rune =
# 	when str.runeLen != 1:
# 		{.error: "Provide a single rune".}
# 	str.runeAt(0)

proc add(state: var ScanState, kind: TokenType) =
	state.tokens.add(Token(kind: kind, lexeme: "", literal: RootObj(), line: state.line))

proc advance(state: var ScanState): char =
	result = state.source[state.current]
	state.current += 1

proc hasReachedEnd(state: ScanState): bool =
	state.current >= state.source.len

proc match(state: var ScanState, next: char): bool =
	if state.hasReachedEnd() or state.source[state.current] != next:
		return false

	state.current += 1
	return true

proc peek(state: ScanState): char =
	if state.hasReachedEnd:
		return '\0'

	return state.source[state.current]

proc scanToken(state: var ScanState) =
	let nextChar = state.advance()
	case nextChar
	of '(': state.add ParenOpen
	of ')': state.add ParenClose
	of '{': state.add BraceOpen
	of '}': state.add BraceClose
	of '[': state.add SquareOpen
	of ']': state.add SquareClose
	of ',': state.add Comma
	of '.': state.add Dot
	of '+': state.add Plus
	of '-': state.add Minus
	of ';': state.add Semicolon
	of '*': state.add Star
	of '!': state.add(if state.match('='): ExclamationEqual else: Exclamation)
	of '=': state.add(if state.match('='): EqualEqual else: Equal)
	of '<': state.add(if state.match('='): LessEqual else: Less)
	of '>': state.add(if state.match('='): GreaterEqual else: Greater)
	of '/':
		if state.match('/'):
			while state.peek() != '\n' and not state.hasReachedEnd():
				discard state.advance()
		else:
			state.add Slash

	else:
		gobError(state.path, state.line, "Unexpected character")


proc scanTokens*(source: string, path: string): seq[Token] =
	var state = ScanState(source: source, path: path, start: 0, current: 0, line: 1)

	while not state.hasReachedEnd():
		state.start = state.current
		state.scanToken()
	
	state.add(EOF)
	return state.tokens

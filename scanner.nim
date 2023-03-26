#? replace(sub = "\t", by = "  ")

import std/strutils
import token
import error

type
	ScanState = object
		path: string
		source: string
		start: int
		current: int
		line: int
		tokens: seq[Token]

const BinDigits = {'0', '1'}

# proc rune(str: static string): Rune =
# 	when str.runeLen != 1:
# 		{.error: "Provide a single rune".}
# 	str.runeAt(0)

proc add(state: var ScanState, kind: TokenKind) =
	state.tokens.add(Token(kind: kind, lexeme: state.source[state.start..state.current - 1], line: state.line))

proc addString(state: var ScanState, str: string) =
	state.tokens.add(Token(kind: String, lexeme: state.source[state.start..state.current - 1], line: state.line, str: str))

proc addNumber(state: var ScanState, number: float) =
	state.tokens.add(Token(kind: Number, lexeme: state.source[state.start..state.current - 1], line: state.line, number: number))

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

proc readString(state: var ScanState) =
	while state.peek() != '"' and not state.hasReachedEnd():
		if state.peek() == '\n':
			state.line += 1
		discard state.advance()
	
	if state.hasReachedEnd():
		gobError(state.path, state.line, "Unterminated string.")
		return
	
	# advance to the closing "
	discard state.advance()

	state.addString state.source[state.start + 1 .. state.current - 2]

proc readDecimal(state: var ScanState) =
	while isDigit(state.peek()):
		discard state.advance()

	var cur: int = state.current
	let next = state.peek()

	# check for decimal/sci
	if next == '.' or next == 'e':
		discard state.advance()
		while isDigit(state.peek()):
			discard state.advance()

	# check if additional digits were found
	if state.current > cur + 1:
		cur = state.current
	else:
		# failed to find more digits, so rewind
		state.current = cur

	echo "CUR:" & $cur

	state.addNumber parsefloat(state.source[state.start .. cur - 1])

proc readHex(state: var ScanState) =
	while state.peek() in HexDigits:
		discard state.advance()

	state.addNumber float(parseHexInt(state.source[state.start .. state.current - 1]))

proc readBin(state: var ScanState) =
	while state.peek() in BinDigits:
		discard state.advance()

	state.addNumber float(parseBinInt(state.source[state.start .. state.current - 1]))

proc readNumber(state: var ScanState, initialChar: char) =
	# check for non-decimal notation
	if initialChar == '0':
		case state.peek()
		of 'x':
			discard state.advance()
			state.readHex()
		of 'b':
			discard state.advance()
			state.readBin()
		else:
			discard state.advance()
			state.readDecimal()
	else:
		state.readDecimal()

proc scanToken(state: var ScanState) =
	let nextChar = state.advance()
	
	# start with basic tokens
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
	
	# comments
	of '/':
		if state.match('/'):
			# find & ignore comments
			while state.peek() != '\n' and not state.hasReachedEnd():
				discard state.advance()
		else:
			state.add Slash
	
	# string literals
	of '"':
		state.readString()

	# newlines
	of '\n':
		state.line += 1

	# other stuff to ignore
	of ' ', '\t':
		discard

	of '\r':
		gobError(state.path, state.line, "Carriage Return found. Gobbo source must use LF line endings.")
	else:
		if isDigit(nextChar):
			state.readNumber(nextChar)
		else:
			gobError(state.path, state.line, "Unexpected character '" & nextChar & "'")

proc scanTokens*(source: string, path: string): seq[Token] =
	var state = ScanState(source: source, path: path, start: 0, current: 0, line: 1)

	while not state.hasReachedEnd():
		state.start = state.current
		state.scanToken()
	
	state.start = state.current
	state.add(EOF)
	return state.tokens

#? replace(sub = "\t", by = "  ")

import std/strutils
import std/tables
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
const IdentBannedChars = {'(', ')', '{', '}', '[', ']', ',', '.', '+', ';', '/', '*', '!', '=', '<', '>', '\x00' .. '\x20', '\xff'}

const Keywords =
	{
		"if": If,
		"else": Else,
		"for": For,
		"while": While,
		"true": True,
		"false": False,
		"and": And,
		"or": Or,
		"var": Var,
		"fun": Fun,
		"struct": Struct,
		"self": Self,
		"return": Return,
		"echo": Echo,
		"exit": Exit,
		"nil": Nil
	}.toTable

# -- Token Creation -----------------------------------------------------------

proc add(state: var ScanState, kind: TokenKind) =
	state.tokens.add(Token(kind: kind, lexeme: state.source[state.start..state.current - 1], line: state.line))

proc addIdentifier(state: var ScanState, kind: TokenKind, lexeme: string) =
	state.tokens.add(Token(kind: kind, lexeme: lexeme, line: state.line))

proc addString(state: var ScanState, str: string) =
	state.tokens.add(Token(kind: String, lexeme: state.source[state.start..state.current - 1], line: state.line, str: str))

proc addNumber(state: var ScanState, number: float) =
	state.tokens.add(Token(kind: Number, lexeme: state.source[state.start..state.current - 1], line: state.line, number: number))

# -- Char Utils ---------------------------------------------------------------

proc advance(state: var ScanState): char {.discardable.} =
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

proc peekNext(state: ScanState): char =
	if state.hasReachedEnd:
		return '\0'

	return state.source[state.current + 1]

# -- Token Readers ------------------------------------------------------------

proc readString(state: var ScanState) =
	while state.peek() != '"' and not state.hasReachedEnd():
		if state.peek() == '\n':
			state.line += 1
		state.advance()
	
	if state.hasReachedEnd():
		gobError(state.path, state.line, "Unterminated string.")
		return
	
	# advance to the closing "
	state.advance()

	state.addString state.source[state.start + 1 .. state.current - 2]

# called by readNumber!
proc readDecimal(state: var ScanState) =
	while isDigit(state.peek()):
		state.advance()

	let next = state.peek()

	# check for decimal/sci
	if (next == '.' or next == 'e') and isDigit(state.peekNext()):
		state.advance()
		while isDigit(state.peek()):
			state.advance()

	state.addNumber parsefloat(state.source[state.start .. state.current - 1])

# called by readNumber!
proc readHex(state: var ScanState) =
	while state.peek() in HexDigits:
		state.advance()

	state.addNumber float(parseHexInt(state.source[state.start .. state.current - 1]))

# called by readNumber!
proc readBin(state: var ScanState) =
	while state.peek() in BinDigits:
		state.advance()

	state.addNumber float(parseBinInt(state.source[state.start .. state.current - 1]))

proc readNumber(state: var ScanState, initialChar: char) =
	# check for non-decimal notation
	if initialChar == '0':
		case state.peek()
		of 'x':
			if state.peekNext() in HexDigits:
				state.advance()
				state.readHex()
		of 'b':
			if state.peekNext() in BinDigits:
				state.advance()
				state.readBin()
		else:
			state.advance()
			state.readDecimal()
	else:
		state.readDecimal()

proc readIdentifier(state: var ScanState) =
	# advance once since the first char was checked already
	state.advance()
	
	while not IdentBannedChars.contains(state.peek()):
		state.advance()
	
	let txt = state.source[state.start .. state.current - 1]
	let kind = Keywords.getOrDefault(txt, Identifier)
	state.addIdentifier(kind, txt)

# -- Main Scanner -------------------------------------------------------------

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
	of '*': state.add Slash
	of '!': state.add(if state.match('='): ExclamationEqual else: Exclamation)
	of '=': state.add(if state.match('='): EqualEqual else: Equal)
	of '<': state.add(if state.match('='): LessEqual else: Less)
	of '>': state.add(if state.match('='): GreaterEqual else: Greater)
	
	# comments
	of '/':
		if state.match('*'):
			# multi-line comment
			while state.peek() != '*' and not state.hasReachedEnd():
				state.advance()

			if (not state.hasReachedEnd()) and state.peekNext() == '/':
				state.advance()
				state.advance()


		elif state.match('/'):
			# single-line comment
			while state.peek() != '\n' and not state.hasReachedEnd():
				state.advance()
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

		elif nextChar in IdentStartChars:
			state.readIdentifier()

		else:
			gobError(state.path, state.line, "Unexpected character '" & nextChar & "'")

# -- External API -------------------------------------------------------------

proc scanTokens*(source: string, path: string): seq[Token] =
	var state = ScanState(source: source, path: path, start: 0, current: 0, line: 1)

	while not state.hasReachedEnd():
		state.start = state.current
		state.scanToken()
	
	state.start = state.current
	state.add(EOF)
	return state.tokens

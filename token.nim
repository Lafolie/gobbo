#? replace(sub = "\t", by = "  ")

import std/tables

type
	TokenType* = enum
		# Single-char tokens
		ParenOpen = "(", ParenClose = ")", BraceOpen = "{", BraceClose = "}", SquareOpen = "[", SquareClose = "]"
		Comma = ",", Dot = ".", Plus = "+", Minus = "-", Semicolon = ";", Slash = "/", Star = "*",

		# One/Two-char tokens
		Exclamation = "!", ExclamationEqual = "!=",
		Equal = "=", EqualEqual = "==",
		Less = "<", LessEqual = "<=",
		Greater = ">", GreaterEqual = ">=",

		# Literals
		Identifier, String, Number,

		# Keywords
		If = "if", Else = "else", For = "for", While = "while",
		True = "true", False = "false",
		And = "and", Or = "or",
		Var = "var", Fun = "fun", Struct = "struct", Self = "self", Return = "return"
		Echo = "echo", Exit = "exit",
		Nil = "nil",

		# Misc
		EOF

	Token* = object
		kind*: TokenType
		lexeme*: string
		line*: int
		literal*: RootObj

# let test = Token(kind: TokenType.And, lexeme: "test", line: 1)
# echo test
#? replace(sub = "\t", by = "  ")

type
	TokenType* = enum
		# Single-char tokens
		ParenOpen, ParenClose, BraceOpen, BraceClose, SquareOpen, SquareClose
		Comma, Dot, Plus, Minus, Semicolon, Slash, Star,

		# One/Two-char tokens
		Exclamation, ExclamationEqual,
		Equal, EqualEqual,
		Less, LessEqual,
		Greater, GreaterEqual,

		# Literals
		Identifier, String, Number,

		# Keywords
		If, Else, For, While,
		True, False,
		And, Or,
		Var, Fun, Struct, Self, Return,
		Echo, Exit,
		Nil,

		# Misc
		EOF

	Token* = object
		kind*: TokenType
		lexeme*: string
		line*: int

# let test = Token(kind: TokenType.And, lexeme: "test", line: 1)
# echo test
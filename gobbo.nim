#? replace(sub = "\t", by = "  ")#? replace(sub = "\t", by = "  ")

from parseopt import nil
import std/strformat
import error
import scanner
import cmd/help
import cmd/version

# UNIX exit codes: https://man.freebsd.org/cgi/man.cgi?query=sysexits&apropos=0&sektion=0&manpath=FreeBSD+4.3-RELEASE&format=html

# -----------------------------------------------------------------------------
# Main Interpreter
# -----------------------------------------------------------------------------

proc run(code: string, path: string) =
	let tokens = scanTokens(code, path)
	echo tokens
	# Scanner scanner = new Scanner(source);
	# var tokens = newSeq[Token]()
	
	# for k, token in tokens:
	# 	echo token

	# gobError(1, "AAAAAAAAHHHHH!!!")

proc runFile(path: string) =
	var code: string
	try:
		code = readFile(path)
		
	except IOError:
		echo "Error reading file ", path
		quit(66) # input file issue

	run(code, path)
	if checkForError():
		quit(65) # input data incorrect

# REPL Prompt
proc prompt(): bool =
	write(stdout, "> ")
	var input: string

	try:
		input = readLine(stdin)
	except EOFError:
		result = true

	run(input, "stdin")
	# hadError = false
	echo input

# -----------------------------------------------------------------------------
# Super Gobbo, Activate!
# -----------------------------------------------------------------------------

var src: string
var p = parseopt.initOptParser("")

for kind, key, val in parseopt.getopt(p):
	case kind
	of parseopt.cmdArgument:
		src = key

	of parseopt.cmdLongOption, parseopt.cmdShortOption:
		case key
		of "help", "h":
			writeHelp()

		of "version", "v":
			writeVersion()

		else:
			echo "Unknown argument ", key, "\n"
			writeHelp()
			quit(64) # incorrect arg

	of parseopt.cmdEnd:
		assert(false)

# -- Run ------------------------------
if src == "":
	writeVersion()
	while not prompt(): discard

else:
	runFile(src)
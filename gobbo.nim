#? replace(sub = "\t", by = "  ")#? replace(sub = "\t", by = "  ")

from parseopt import nil
# import parseopt
import cmd/help
import cmd/version

proc prompt(): bool =
	write(stdout, "> ")
	let input = readLine(stdin)
	echo input
	if input == "quit":
		return true

# Super Gobbo, Activate!
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

	of parseopt.cmdEnd:
		assert(false)

if src == "":
	writeVersion()
	echo "Gobbo source: REPL"
	while not prompt(): discard

else:
	echo "Gobbo source: ", src
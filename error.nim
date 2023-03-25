#? replace(sub = "\t", by = "  ")
import std/strformat

var hadError: bool = false

type
	FeedbackType* = enum
		Info, Warning, Error

proc report*(ft: FeedbackType, path: string, line: int, message: string) =
	echo &"{ft}:{path}:{line}: {message}"

proc gobError*(path: string, line: int, message: string) =
	hadError = true
	report(FeedbackType.Error, path, line, message)

proc checkForError*(): bool =
	hadError
extends SceneTree

## Project-level entry point kept stable for CCGS commands and CI.
## Delegates execution to gdUnit4's official command-line tool so the test
## framework owns discovery, reports, and failure exit codes.
func _initialize() -> void:
	var gdunit_cli := "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"
	if not FileAccess.file_exists(gdunit_cli):
		push_error("gdUnit4 is missing. Expected %s." % gdunit_cli)
		quit(1)
		return

	var godot_executable := OS.get_executable_path()
	var project_root := ProjectSettings.globalize_path("res://")
	var arguments := PackedStringArray([
		"--headless",
		"--path",
		project_root,
		"--script",
		gdunit_cli,
		"--ignoreHeadlessMode",
		"-a",
		"res://tests",
	])
	var child_output: Array[String] = []
	var exit_code := OS.execute(godot_executable, arguments, child_output, true)
	for line in child_output:
		print(line)
	quit(exit_code)

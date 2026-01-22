@tool
@icon("./icon.svg")
class_name SourceEditorExportPlatform
extends ToolEditorExportPlatform

## SourceEditorExportPlatform
## 
## A super simple export plugin for godot that allows for
## source code to be coppied to another directory and optionally compressed.
## Usefull for making automatic source code exports.[br]
## Requires the NovaTools plugin as a dependency.

var _cached_icon:Texture2D = null

func _path_normalize(raw_path:Variant) -> String:
	var path:String = ""
	match typeof(raw_path):
		TYPE_STRING:
			path = raw_path
		TYPE_STRING_NAME, TYPE_NODE_PATH:
			path = str(raw_path)
		TYPE_PACKED_STRING_ARRAY:
			path = "/".join(raw_path)
		TYPE_ARRAY:
			path = "/".join(raw_path.map(str))

	path = path.strip_escapes().strip_edges()

	if path.is_empty():
		return ""

	if path.begins_with("file://"):
		path = path.trim_prefix("file://")
	elif path.begins_with("res://") or path.begins_with("user://"):
		path = ProjectSettings.globalize_path(path)
	elif path.is_relative_path():
		path = path.trim_prefix("./")
		path = ProjectSettings.globalize_path("res://").path_join(path)
	path = path.simplify_path()

	return path

func _has_valid_export_configuration(preset:EditorExportPreset, debug:bool):
	if debug:
		push_error("Debug exports not supported for source.")

	var preset_ok = super._has_valid_export_configuration(preset, debug)

	var source_dir := _path_normalize(preset.get_or_env("source_directory", ""))
	if source_dir.is_empty():
		add_config_error("Invalid source directory path.")
		preset_ok = false
	elif not DirAccess.dir_exists_absolute(source_dir):
		add_config_error("Non existent source directory.")
		preset_ok = false

	return preset_ok

func _get_name():
	return "SourceExport"

func _get_os_name() -> String:
	return "Source"

func _get_logo() -> Texture2D:
	if _cached_icon != null:
		return _cached_icon

	var target_size:Vector2i = Vector2i.ONE * floori(32 * EditorInterface.get_editor_scale())

	var ico := NovaTools.get_editor_icon_named("FileAccess")

	if ico == null or ico.get_size() <= Vector2.ZERO:
		ico = load("res://addons/source_export_platform/icon.svg") as Texture2D

	if ico == null or ico.get_size() <= Vector2.ZERO:
		return null

	if ico.get_size() != Vector2(target_size):
		if not ico.has_method("set_size_override"):
			var ico_image := ico.get_image()
			if ico_image == null:
				return ico
			ico = ImageTexture.create_from_image(ico_image)
		ico = ico.duplicate()
		ico.set_size_override(target_size)

	_cached_icon = ico
	return ico

func _get_platform_features() -> PackedStringArray:
	return super._get_platform_features() + PackedStringArray(["sourceonly"])

func _get_export_options():
	return [
		{
			"name": "source_directory",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"default_value": "res://"
		},
		{
			"name": "zipped",
			"type": TYPE_BOOL,
			"default_value": true,
			"update_visibility": true,
		},
		{
			"name": "show_after",
			"type": TYPE_BOOL,
			"default_value": true
		},
		{
			"name": "add_gdignore",
			"type": TYPE_BOOL,
			"default_value": true
		},
	] + super._get_export_options()

func _get_export_option_visibility(preset:EditorExportPreset, option:String) -> bool:
	match (option):
		"add_gdignore":
			return not preset.get_or_env("zipped", "")
		_:
			return true

func _get_export_option_warning(preset:EditorExportPreset, option:StringName):
	match (option):
		"source_directory":
			var parsed_source_dir := _path_normalize(preset.get_or_env("source_directory", ""))
			if parsed_source_dir.is_empty():
				return ""

			var warning_strings := PackedStringArray()
			if not parsed_source_dir.begins_with(ProjectSettings.globalize_path("res://").rstrip("/")):
				warning_strings.append("Source directory not local to project.")
			if DirAccess.dir_exists_absolute(parsed_source_dir):
				if (DirAccess.get_directories_at(parsed_source_dir) + DirAccess.get_files_at(parsed_source_dir)).is_empty():
					warning_strings.append("Source directory empty.")
			return "\n".join(warning_strings)

		_:
			return ""

func _export_hook(preset: EditorExportPreset, path:String):
	var zipped := bool(preset.get_or_env("zipped", ""))

	path = _path_normalize(path)
	if path.is_empty():
		return ERR_FILE_BAD_PATH
	if zipped:
		if path.ends_with("/"):
			return ERR_FILE_BAD_PATH
		if not path.get_file().is_valid_filename():
			return ERR_FILE_BAD_PATH

	var source_dir:String = _path_normalize(preset.get_or_env("source_directory", ""))
	if source_dir.is_empty():
		return ERR_FILE_BAD_PATH
	if not DirAccess.dir_exists_absolute(source_dir):
		return ERR_DOES_NOT_EXIST

	var f:Callable
	if zipped:
		f = NovaTools.compress_zip_async.bind(source_dir, path)
	else:
		f = NovaTools.copy_recursive.bind(source_dir, path)

	var err:int = await NovaTools.show_wait_window_while_async("[center]Copying...[/center]",
													f,
													Vector2i(250, 100)
													)

	if (not zipped) and preset.get_or_env("add_gdignore", ""):
		var gdignore_path := path.path_join(".gdignore")
		if DirAccess.dir_exists_absolute(path) and not FileAccess.file_exists(gdignore_path):
			var file := FileAccess.open(gdignore_path, FileAccess.WRITE)
			if file == null:
				err = FileAccess.get_open_error()
			file.close()

	if err != OK:
		return err

	if preset.get_or_env("show_after", ""):
		err = OS.shell_show_in_file_manager(path, false)

	return err

func _get_binary_extensions(preset: EditorExportPreset):
	if preset.get_or_env("zipped", ""):
		return PackedStringArray(["zip"])
	else:
		return PackedStringArray()

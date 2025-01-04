@tool
class_name SourceEditorExportPlatform
extends ToolEditorExportPlatform

## SourceEditorExportPlatform
## 
## A super simple export plugin for godot that allows for
## source code to be coppied to another directory and optionally compressed.
## Usefull for making automatic source code exports.[br]
## Requires the NovaTools plugin as a dependency.

func _get_name():
	return "Source"

func _get_logo():
	var size = Vector2i.ONE * floori(32 * EditorInterface.get_editor_scale())
	return NovaTools.get_editor_icon_named("FileAccess", size)

func _get_platform_features():
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
			"default_value": true
		},
	] + super._get_export_options()

func _has_valid_project_configuration(preset: EditorExportPreset):
	return true

func _export_hook(preset: EditorExportPreset, path: String):
	var ret := OK
	
	var f:Callable
	
	var source_dir = preset.get_or_env("source_directory", "").lstrip(".").lstrip("/").rstrip("/")
	if preset.get_or_env("zipped", ""):
		f = NovaTools.compress_zip_async.bind(source_dir, path)
	else:
		f = NovaTools.copy_recursive.bind(source_dir, path)
	
	return await NovaTools.show_wait_window_while_async("[center]Copying...[/center]",
													f,
													Vector2i(250, 100)
												   )

func _get_binary_extensions(preset: EditorExportPreset):
	if preset.get_or_env("zipped", ""):
		return PackedStringArray(["zip"])
	else:
		return PackedStringArray()

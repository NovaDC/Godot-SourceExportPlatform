@tool
@icon("./icon.svg")
extends EditorPlugin

const PLUGIN_NAME := "SourceExportPlatform"

const PLUGIN_NAME_INTERNAL := "source_export_platform"

const PLUGIN_ICON_FALLBACK := preload("./icon.svg")

var _export_platform_ref:SourceEditorExportPlatform = null

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	var ico := NovaTools.get_editor_icon_named("FileAccess")
	if ico == null or ico.get_size() <= Vector2.ZERO:
		ico = PLUGIN_ICON_FALLBACK
	return ico

func _enter_tree() -> void:
	if EditorInterface.is_plugin_enabled(PLUGIN_NAME_INTERNAL):
		_try_init_platform()

func _enable_plugin() -> void:
	_try_init_platform()

func _disable_plugin() -> void:
	_try_deinit_platform()

func _exit_tree() -> void:
	_try_deinit_platform()

func _try_init_platform() -> void:
	if _export_platform_ref == null:
		_export_platform_ref = SourceEditorExportPlatform.new()
		add_export_platform(_export_platform_ref)

func _try_deinit_platform() -> void:
	if _export_platform_ref != null:
		remove_export_platform(_export_platform_ref)
		_export_platform_ref = null

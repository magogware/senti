extends EditorImportPlugin

func get_importer_name():
	return "audiostreampd.patch"

func get_visible_name():
	return "Pure Data patch"

func get_recognized_extensions():
	return ["pd"]
	
func get_save_extension() -> String:
	return "tres"

func get_resource_type() -> String:
	return "Resource"
	
func get_import_options(preset) -> Array:
	return []

func get_preset_count() -> int:
	return 0
	
func import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str = '%s.%s' % [save_path, get_save_extension()]

	var patch_resource : PureDataPatch = null

	var existing_resource := load(save_path_str) as PureDataPatch
	if(existing_resource != null):
		patch_resource = existing_resource
		patch_resource.revision += 1
	else:
		patch_resource = PureDataPatch.new()

	return ResourceSaver.save(save_path_str, patch_resource)

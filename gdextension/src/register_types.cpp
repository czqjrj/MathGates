#include "register_types.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/godot.hpp>

#include "math_tex.h"

void initialize_math_tex_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(godot::MathTeX);
	godot::MathTeX::setup_singleton();
	godot::Engine::get_singleton()->register_singleton("MathTeX", godot::MathTeX::get_singleton());
}

void uninitialize_math_tex_module(godot::ModuleInitializationLevel p_level) {
	if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	godot::Engine::get_singleton()->unregister_singleton("MathTeX");
	godot::MathTeX::teardown_singleton();
}

extern "C" {

// GDExtension entry point.
GDExtensionBool GDE_EXPORT gdextension_initialize(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_math_tex_module);
	init_obj.register_terminator(uninitialize_math_tex_module);
	return init_obj.init();
}

} // extern "C"
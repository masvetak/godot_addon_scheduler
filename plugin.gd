@tool extends EditorPlugin

const AUTOLOAD_NAME = "Scheduler"

# ------------------------------------------------------------------------------
# Build-in methods
# ------------------------------------------------------------------------------

func _enter_tree() -> void:
	self.add_autoload_singleton(AUTOLOAD_NAME, "scheduler.gd")

func _exit_tree() -> void:
	self.remove_autoload_singleton(AUTOLOAD_NAME)

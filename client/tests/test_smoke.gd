extends GutTest
## Проверка, что проект и GUT запускаются.


func test_project_name_is_set() -> void:
	var project_name: String = ProjectSettings.get_setting("application/config/name")
	assert_eq(project_name, "Clockwork Bastion")

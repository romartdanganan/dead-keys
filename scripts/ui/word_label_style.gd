extends RefCounted

# sizes a zombie or crate word label from the large word text setting,
# the bottom edge stays put so bigger text grows up and away from the sprite

const NORMAL_HALF_WIDTH: float = 110.0
const LARGE_HALF_WIDTH: float = 150.0
# label height is the font size plus this much line padding
const LINE_PADDING: int = 13


static func apply(label: RichTextLabel) -> void:
	var font_size := SettingsState.get_word_font_size()
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.offset_top = label.offset_bottom - (font_size + LINE_PADDING)

	var centre := (label.offset_left + label.offset_right) / 2.0
	var half_width := LARGE_HALF_WIDTH if SettingsState.large_word_text else NORMAL_HALF_WIDTH
	label.offset_left = centre - half_width
	label.offset_right = centre + half_width

#include-once

Global Enum $GUI_STATE_WINDOW_VISIBLE = 0, _
            $GUI_STATE_MAIN_WINDOW, _
            $GUI_STATE_SAVE_BUTTON, _
            $GUI_STATE_STARTUP_CHECKBOX, _
            $GUI_STATE_CANCEL_BUTTON, _
            $GUI_STATE_CTRL_CHECKBOX, _
            $GUI_STATE_ALT_CHECKBOX, _
            $GUI_STATE_SHIFT_CHECKBOX, _
            $GUI_STATE_WIN_CHECKBOX, _
            $GUI_STATE_KEY_COMBO, _
            $GUI_STATE_LIST_VIEW, _
            $GUI_STATE_EDITOR_WINDOW, _
            $GUI_STATE_EDITOR_CTRL_CHECKBOX, _
            $GUI_STATE_EDITOR_ALT_CHECKBOX, _
            $GUI_STATE_EDITOR_SHIFT_CHECKBOX, _
            $GUI_STATE_EDITOR_WIN_CHECKBOX, _
            $GUI_STATE_EDITOR_KEY_COMBO, _
            $GUI_STATE_EDITOR_OK_BUTTON, _
            $GUI_STATE_EDITOR_CANCEL_BUTTON, _
            $GUI_STATE_SPECIAL_RADIO, _
            $GUI_STATE_SPECIAL_COMBO, _
            $GUI_STATE_ADMIN_CHECKBOX, _
            $GUI_STATE_SINGLETON_CHECKBOX, _
            $GUI_STATE_WINDOW_RADIO, _
            $GUI_STATE_WINDOW_COMBO, _
            $GUI_STATE_MOVE_CHECKBOX, _
            $GUI_STATE_X_LABEL, _
            $GUI_STATE_MOVE_X_INPUT, _
            $GUI_STATE_Y_LABEL, _
            $GUI_STATE_MOVE_Y_INPUT, _
            $GUI_STATE_RESIZE_CHECKBOX, _
            $GUI_STATE_WIDTH_LABEL, _
            $GUI_STATE_RESIZE_WIDTH_INPUT, _
            $GUI_STATE_HEIGHT_LABEL, _
            $GUI_STATE_RESIZE_HEIGHT_INPUT, _
            $GUI_STATE_FOLDER_RADIO, _
            $GUI_STATE_FOLDER_INPUT, _
            $GUI_STATE_FOLDER_BROWSE_BUTTON, _
            $GUI_STATE_FILE_RADIO, _
            $GUI_STATE_COMMAND_CHECKBOX, _
            $GUI_STATE_FILE_INPUT, _
            $GUI_STATE_FILE_BROWSE_BUTTON, _
            $GUI_STATE_FILE_PARAMETER_LABEL, _
            $GUI_STATE_FILE_PARAMETER_INPUT, _
            $GUI_STATE_URL_RADIO, _
            $GUI_STATE_URL_COMBO, _
            $GUI_STATE_URL_INPUT, _
            $GUI_STATE_TEXT_RADIO, _
            $GUI_STATE_TEXT_EDIT, _
            $GUI_STATE_COUNT

Global $g_aGuiState[$GUI_STATE_COUNT]
; Uninitialized array entries are empty strings, which do not compare equal to False.
$g_aGuiState[$GUI_STATE_WINDOW_VISIBLE] = False

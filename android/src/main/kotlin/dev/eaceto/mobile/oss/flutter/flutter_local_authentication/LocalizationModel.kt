package dev.eaceto.mobile.oss.flutter.flutter_local_authentication

data class LocalizationModel(
    val dialogTitle: String,
    val reason: String,
    val cancelButtonTitle: String,
) {
    companion object {
        val titleKey = "promptDialogTitle"
        val reasonKey = "promptDialogReason"
        val cancelKey = "cancelButtonTitle"

        val default = LocalizationModel(
            "Biometric Prompt",
            "Validate that you have access to this device.",
            "Cancel"
        )

        fun from(dictionary: Map<String, Any>?): LocalizationModel? {
            return dictionary?.let {
                val title = dictionary[titleKey] as? String ?: return null
                val reason = dictionary[reasonKey] as? String ?: return null
                val cancel = dictionary[cancelKey] as? String ?: return null
                return LocalizationModel(
                    title,
                    reason,
                    cancel
                )
            }
        }
    }
}

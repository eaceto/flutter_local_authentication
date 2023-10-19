/// A model class to store localization strings for prompts and buttons.
///
/// Author: Ezequiel (Kimi) Aceto
/// Email: ezequiel.aceto@gmail.com
/// Website: https://eaceto.dev
class LocalizationModel {
  /// The title for the authentication prompt dialog.
  final String promptDialogTitle;

  /// The reason displayed in the authentication prompt dialog.
  final String promptDialogReason;

  /// The title for the cancel button in the authentication prompt dialog.
  final String cancelButtonTitle;

  /// Creates a new instance of [LocalizationModel] with the provided strings.
  ///
  /// The [promptDialogTitle], [promptDialogReason], and [cancelButtonTitle] must not be null.
  LocalizationModel({
    required this.promptDialogTitle,
    required this.promptDialogReason,
    required this.cancelButtonTitle,
  });

  /// Creates a [LocalizationModel] instance from a JSON map.
  ///
  /// The keys 'promptDialogTitle', 'promptDialogReason', and 'cancelButtonTitle'
  /// in the [json] map should correspond to the respective properties in this class.
  factory LocalizationModel.fromJson(Map<String, dynamic> json) {
    return LocalizationModel(
      promptDialogTitle: json['promptDialogTitle'] ?? '',
      promptDialogReason: json['promptDialogReason'] ?? '',
      cancelButtonTitle: json['cancelButtonTitle'] ?? '',
    );
  }

  /// Converts the [LocalizationModel] instance to a JSON map.
  ///
  /// The keys 'promptDialogTitle', 'promptDialogReason', and 'cancelButtonTitle'
  /// in the returned map correspond to the respective properties in this class.
  Map<String, dynamic> toJson() {
    return {
      'promptDialogTitle': promptDialogTitle,
      'promptDialogReason': promptDialogReason,
      'cancelButtonTitle': cancelButtonTitle,
    };
  }
}

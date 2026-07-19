import Foundation

var isJa: Bool {
    (Locale.preferredLanguages.first ?? "en").hasPrefix("ja")
}

func L(_ ja: String, _ en: String) -> String {
    isJa ? ja : en
}

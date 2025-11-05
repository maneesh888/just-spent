import Foundation
import Intents
import IntentsUI

@available(iOS 12.0, *)
class AddToSiriDelegate: NSObject, INUIAddVoiceShortcutViewControllerDelegate {
    static let shared = AddToSiriDelegate()

    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {

        controller.dismiss(animated: true) {
            if let voiceShortcut = voiceShortcut {
                print("✅ Successfully added Siri shortcut: '\(voiceShortcut.invocationPhrase)'")

                // Show success message
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SiriExpenseReceived"),
                        object: nil,
                        userInfo: [
                            "message": "🎉 Siri shortcut created!\n\nNow say: 'Hey Siri, \(voiceShortcut.invocationPhrase)'\n\nThe app will open and you can speak your expense naturally like:\n'I just spent 20 dollars for tea'"
                        ]
                    )
                }
            } else if let error = error {
                print("❌ Error adding Siri shortcut: \(error.localizedDescription)")

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SiriExpenseReceived"),
                        object: nil,
                        userInfo: [
                            "message": "❌ Failed to create Siri shortcut: \(error.localizedDescription)"
                        ]
                    )
                }
            }
        }
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true) {
            print("ℹ️ User cancelled adding Siri shortcut")

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SiriExpenseReceived"),
                    object: nil,
                    userInfo: [
                        "message": "ℹ️ You can create a Siri shortcut anytime by tapping 'Enable Siri Support' again."
                    ]
                )
            }
        }
    }
}

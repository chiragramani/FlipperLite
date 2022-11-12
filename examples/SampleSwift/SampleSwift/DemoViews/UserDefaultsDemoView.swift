import SwiftUI

struct UserDefaultsDemoView: View {
    @State private var storageKey: String = ""
    @State private var storageValue: String = ""
    
    var body: some View {
        VStack {
            Text("User Defaults Demo").bold()
            
            TextField(
                "Storage key",
                text: $storageKey
            )
            .disableAutocorrection(true)
            .border(.primary)
            
            TextField(
                "Storage value",
                text: $storageValue
            )
            .disableAutocorrection(true)
            .border(.primary)
            
            
            Button("Save to user defaults") {
                UserDefaults.standard.set(storageValue, forKey: storageKey)
            }
            Spacer()
        }
        .textFieldStyle(.roundedBorder)
        .padding()
    }
}

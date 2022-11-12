import SwiftUI

struct NotificationsDemoView: View {
   
    var body: some View {
        VStack(spacing: 20) {
            Text("Notifications Demo").bold()
            Button("Trigger Notification") {
                ExamplePlugin.shared.triggerNotification()
            }
            Spacer()
        }.padding()
    }
}

struct NotificationsDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsDemoView()
    }
}

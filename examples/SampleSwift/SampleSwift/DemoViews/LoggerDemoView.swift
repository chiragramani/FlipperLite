import SwiftUI

struct LoggerDemoView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Logger Demo").bold()
            Text("You need to install RCLogger plugin in Flipper IDE to see the logs")
            Text("Once RCLogger plugin is installed, you will be able to see logs with random info sent by this application to Flipper IDE")
            Spacer()
        }.padding()
    }
}

struct LoggerDemoView_Previews: PreviewProvider {
    static var previews: some View {
        LoggerDemoView()
    }
}

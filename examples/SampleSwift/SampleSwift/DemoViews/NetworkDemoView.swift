import SwiftUI

struct NetworkDemoView: View {
    @State private var alertMessage: String?
    
    private var visibilityBinding: Binding<Bool>  {
        Binding<Bool>(
            get: { alertMessage != nil },
            set: { _ in alertMessage = nil }
        )
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Network Demo").bold()
            Text("Tap to execute network requests and then you can viz them in the Flipper IDE")
            Button("Get API") {
                tappedGetAPI()
            }
            Button("Post API") {
                tappedPOSTAPI()
            }
            Button("Fetch FB Litho") {
                tappedFetchFBLitho()
            }
            Spacer()
        }
        .padding()
        .buttonStyle(.borderedProminent)
            .alert(isPresented: visibilityBinding) {
                Alert(
                    title: Text("Important message"),
                    message: Text(alertMessage ?? ""),
                    dismissButton: .default(Text("Okay!"))
                )
            }
    }
    
    private func tappedFetchFBLitho() {
        let imageURL = URL(string: "https://raw.githubusercontent.com/facebook/litho/master/docs/static/logo.png")!
        let dataTask = URLSession.shared.dataTask(with: imageURL){ (data, response, error) in
            guard let _ = data else {
                alertMessage = "Received no data in Images API"
                return
            }
            
            if let errorUnwrapped = error {
                alertMessage = "Received error in Images API Error:\(errorUnwrapped.localizedDescription)"
                return
            }
            
            // As Flipper cannot detect print() in Logs
            NSLog("Got Image")
            alertMessage = "Received Litho Image"
        }
        dataTask.resume()
    }
    
    private func tappedPOSTAPI() {
        guard let postURL = URL(string: "https://demo9512366.mockable.io/FlipperPost") else {
            alertMessage = "Check the POST URL"
            return
        }
        var postRequest = URLRequest(url: postURL)
        postRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        postRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let dict = ["app" : "Flipper", "remarks": "Its Awesome"]
        postRequest.httpBody = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.init(rawValue: 0))
        postRequest.httpMethod = "POST"
        let dataTask = URLSession.shared.dataTask(with: postRequest){ (data, response, error) in
            guard let dataUnwrapped = data else {
                alertMessage = "Received no data in POST API"
                return
            }
            
            if let errorUnwrapped = error {
                alertMessage = "Received error in POST API Error:\(errorUnwrapped.localizedDescription)"
                return
            }
            
            let dict = try? JSONSerialization.jsonObject(with: dataUnwrapped, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: String]
            // As Flipper cannot detect print() in Logs
            NSLog("MSG-POST: \(dict?["msg"] ?? "Did not find msg key in the received response")")
            alertMessage = "Received response from POST API, please check the Flipper Network plugin for detailed response"
        }
        dataTask.resume()
    }
    
    private func tappedGetAPI() {
        let getURL = URL(string: "https://demo9512366.mockable.io/FlipperGet")!
        let dataTask = URLSession.shared.dataTask(with: getURL){ (data, response, error) in
            guard let dataUnwrapped = data else {
                self.alertMessage = "Received no data in GET API"
                return
            }
            
            if let errorUnwrapped = error {
                self.alertMessage = "Received error in GET API Error:\(errorUnwrapped.localizedDescription)"
                return
            }
            
            let dict = try? JSONSerialization.jsonObject(with: dataUnwrapped, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) as? [String: String]
            // As Flipper cannot detect print() in Logs
            NSLog("MSG-GET: \(dict?["msg"] ?? "Did not find msg key in the received response")")
            self.alertMessage = "Received response from GET API, please check the Flipper Network plugin for detailed response"
        }
        dataTask.resume()
    }
}

struct NetworkDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkDemoView()
    }
}

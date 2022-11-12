import Foundation
import FlipperLite

final class RCLoggerPlugin: FlipperPlugin {
    let id: String = "RCLogger"
    let runInBackground = true
    
    func didConnect(connection: FlipperConnection) {
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            connection.send(method: "entries",
                            params: try! Params().asDictionary())
        }
        RunLoop.main.add(timer, forMode: RunLoop.Mode.default)
    }
    
    func didDisconnect() { }
}

struct Entry: Codable {
    let app: String
    let message: String
    let tag: String
    let date: String
    let type: String
    let tid: Int
    let pid: Int
}

struct Params: Codable {
    var entries: [Entry] = [LogMessageProvider.random]
}

private extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any]
        else {
            throw NSError()
        }
        return dictionary
    }
}
struct LogMessageProvider {
    static let dateFormatter = DateFormatter()
    private static var messages = [
        (type: "info", message: "Network call started", tag: "networking"),
        (type: "info", message: "Analytics event triggered", tag: "analytics"),
        (type: "warning", message: "Detected memory leak for ABCViewController", tag: "leak"),
        (type: "error", message: "Received timeout for Core RPC Call", tag: "networking"),
        (type: "fatal", message: "Failed to initialize ABC SDK", tag: "sdk"),
        (type: "verbose", message: "Data payload sent - 1200 bytes...", tag: "analytics"),
        (type: "debug", message: "Router attached to the main core", tag: "routing"),
    ]
    
    static var random: Entry {
        let randomMessage = messages.randomElement()!
        return Entry(app: "FlipperLoggerExample",
                     message: randomMessage.message,
                     tag: randomMessage.tag,
                     date: Date().formatted(date: .omitted, time: .complete),
                     type: randomMessage.type,
                     tid: 0,
                     pid: 98702)
    }
}


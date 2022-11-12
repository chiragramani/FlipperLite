import Foundation

enum FlipperError: Error {
    case invalidURL(String, [URLQueryItem])
    case requireMinVersioniOS15
    case ideNotOpen
}

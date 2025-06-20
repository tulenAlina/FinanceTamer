import Foundation


enum FileError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidEncoding
    case writeFailed
    case directoryUnavailable
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .invalidEncoding:
            return "Invalid file encoding"
        case .writeFailed:
            return "Failed to write file"
        case .directoryUnavailable:
            return "Directory unavailable"
        }
    }
}

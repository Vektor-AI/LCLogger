import UIKit
import Combine

public protocol LCLoggerErrorProtocol {
    var errorMessage: String { get }
}

public final class LCLogger {

    /// The in-memory buffer is a tail, not an archive: it keeps at most this
    /// many entries so an 8-hour session with the logger enabled cannot grow
    /// memory without bound.
    internal static let maxStoredLogs = 1000
    internal static let logs = CurrentValueSubject<[LCLoggerLog], Never>([])
    
    public var enabled: Bool = true {
        didSet { outputStream.enabled = enabled }
    }
    private var outputStream: OutputStream
    private var countOfInit = 0
    private var countOfDeinit = 0
    
    private init(prefix: String?, suffix: String?) {
        outputStream = OutputStream(
            prefix: prefix,
            suffix: suffix
        )
    }
    
    public func construct(_ message: Any? = nil, type: String = "", filePath: String = #file, line: Int = #line) {
        let log = LCLoggerLog(message: message, type: type, filePath: filePath, line: line, logType: .construct(getInitCount()))
        outputStream.write(log.formattedMessage)
    }
    
    public func destruct(_ message: Any? = nil, type: String = "", filePath: String = #file, line: Int = #line) {
        let log = LCLoggerLog(message: message, type: type, filePath: filePath, line: line, logType: .desctruct(getDeinitCount()))
        outputStream.write(log.formattedMessage)
    }
    
    public func log(_ message: Any, type: String = "", filePath: String = #file, line: Int = #line) {
        let log = LCLoggerLog(message: message, type: type, filePath: filePath, line: line)
        outputStream.write(log.formattedMessage)
        guard enabled else { return }
        let logs = LCLogger.logs.value + [log]
        LCLogger.logs.send(Array(logs.suffix(LCLogger.maxStoredLogs)))
    }
    
    public func warning(_ message: Any, type: String = "", filePath: String = #file, line: Int = #line) {
        let message = "⚠️ Warning: \(message)"
        log(message, type: type, filePath: filePath, line: line)
    }
    
    public func error(_ error: Error, type: String = "", filePath: String = #file, line: Int = #line) {
        let errorMessage: String
        if let error = error as? LCLoggerErrorProtocol {
            errorMessage = error.errorMessage
        } else if let error = error as? DecodingError {
            errorMessage = error.debugDescription
        } else {
            errorMessage = error.localizedDescription
        }
        let message = "‼️ Error: \(errorMessage)"
        log(message, type: type, filePath: filePath, line: line)
    }
    
    public func spacer(filePath: String = #file, line: Int = #line) {
        let log = LCLoggerLog(message: "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-", type: "", filePath: filePath, line: line)
        outputStream.write(log.formattedMessage)
    }
    
    @available(iOS 14.0, *)
    public func showDebug(on viewController: UIViewController?) {
        guard let viewController else { return }
        let vc = UINavigationController(rootViewController: LCLoggerViewController())
        viewController.present(vc, animated: true)
    }
}

// MARK: - Shared
public extension LCLogger {
    private static func sharedInstance(prefix: String?, suffix: String?) -> LCLogger {
        let instance = LCLogger(prefix: prefix, suffix: suffix)
        return instance
    }
    
    static func shared(prefix: String? = nil, suffix: String? = nil) -> LCLogger {
        sharedInstance(prefix: prefix, suffix: suffix)
    }
}

// MARK: - Private Methods
private extension LCLogger {
    func getInitCount() -> Int {
        countOfInit += 1
        return countOfInit
    }
    
    func getDeinitCount() -> Int {
        countOfDeinit += 1
        return countOfDeinit
    }
    
    var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - OutputStream
private struct OutputStream {
    public var enabled: Bool = true
    
    let prefix: String?
    let suffix: String?
    
    func write(_ message: String) {
        guard enabled else { return }
        var message = message
        if let prefix { message = "\(prefix) - \(message)" }
        if let suffix { message.append(" \(suffix)") }
#if DEBUG
        print(message)
#endif
    }
}

private extension DecodingError {
    var debugDescription: String {
        switch self {
            case .typeMismatch(let any, let context): context.debugDescription
            case .valueNotFound(let any, let context): context.debugDescription
            case .keyNotFound(let codingKey, let context): context.debugDescription
            case .dataCorrupted(let context): context.debugDescription
            @unknown default: ""
        }
    }
}

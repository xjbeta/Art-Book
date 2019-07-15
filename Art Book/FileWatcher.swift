// https://github.com/futurelab/swift-utils/blob/master/Sources/Utils/file/filewatcher/FileWatcher.swift

import Cocoa

class FileWatcher {
    let filePaths: [String]  // -- paths to watch - works on folders and file paths

    var callback: ((_ fileWatcherEvent: FileWatcherEvent) -> Void)?
    var queue: DispatchQueue?

    private var streamRef: FSEventStreamRef?
    private var hasStarted: Bool { return streamRef != nil }

    init(_ paths:[String]) { self.filePaths = paths }

    /**
     * Start listening for FSEvents
     */
    func start() {
        guard !hasStarted else { return } // -- make sure we are not already listening!
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
            retain: retainCallback, release: releaseCallback,
            copyDescription:nil)

        streamRef = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventCallback,
            &context,
            filePaths as CFArray,FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))
        selectStreamScheduler()
        FSEventStreamStart(streamRef!)
    }

    /**
     * Stop listening for FSEvents
     */
    func stop() {
        guard hasStarted else { return } // -- make sure we are indeed listening!

        FSEventStreamStop(streamRef!)
        FSEventStreamInvalidate(streamRef!)
        FSEventStreamRelease(streamRef!)

        streamRef = nil
    }

    private let eventCallback: FSEventStreamCallback = {(
        stream: ConstFSEventStreamRef,
        contextInfo: UnsafeMutableRawPointer?,
        numEvents: Int,
        eventPaths: UnsafeMutableRawPointer,
        eventFlags: UnsafePointer<FSEventStreamEventFlags>,
        eventIds: UnsafePointer<FSEventStreamEventId>) in
        let fileSystemWatcher = Unmanaged<FileWatcher>.fromOpaque(contextInfo!).takeUnretainedValue()
        let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

        for index in 0..<numEvents {
            fileSystemWatcher.callback?(FileWatcherEvent(eventIds[index], paths[index], eventFlags[index]))
        }
    }

    private let retainCallback:CFAllocatorRetainCallBack = {(info:UnsafeRawPointer?) in
        _ = Unmanaged<FileWatcher>.fromOpaque(info!).retain()
        return info
    }

    private let releaseCallback:CFAllocatorReleaseCallBack = {(info:UnsafeRawPointer?) in
        Unmanaged<FileWatcher>.fromOpaque(info!).release()
    }

    private func selectStreamScheduler() {
        if let queue = queue {
            FSEventStreamSetDispatchQueue(streamRef!, queue)
        } else {
            FSEventStreamScheduleWithRunLoop(
                streamRef!, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue
            )
        }
    }
}

extension FileWatcher {
    convenience init(_ paths:[String], _ callback: @escaping ((_ fileWatcherEvent:FileWatcherEvent) -> Void)) {
        self.init(paths)
        self.callback = callback
    }
}

class FileWatcherEvent {
    var id: FSEventStreamEventId
    var path: String
    var flags: FSEventStreamEventFlags
    init(_ eventId: FSEventStreamEventId,
         _ eventPath: String,
         _ eventFlags: FSEventStreamEventFlags) {
        self.id = eventId
        self.path = eventPath
        self.flags = eventFlags
        print(description)
    }
}
/**
 * The following code is to differentiate between the FSEvent flag types (aka file event types)
 * NOTE: Be aware that .DS_STORE changes frequently when other files change
 */
extension FileWatcherEvent {
    /*general*/
    var fileChange: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)) != 0}
    var dirChange: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir)) != 0}
    /*CRUD*/
    var created: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) != 0}
    var removed: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0}
    var renamed: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0}
    var modified: Bool {return (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) != 0}
}
/**
 * Convenince
 */
extension FileWatcherEvent {
    /*File*/
    var fileCreated: Bool {return fileChange && created}
    var fileRemoved: Bool {return fileChange && removed}
    var fileRenamed: Bool {return fileChange && renamed}
    var fileModified: Bool {return fileChange && modified}
    /*Directory*/
    var dirCreated: Bool {return dirChange && created}
    var dirRemoved: Bool {return dirChange && removed}
    var dirRenamed: Bool {return dirChange && renamed}
    var dirModified: Bool {return dirChange && modified}
}
/**
 * Simplifies debugging
 * EXAMPLE: Swift.print(event.description)//Outputs: The file /Users/John/Desktop/test/text.txt was modified
 */
extension FileWatcherEvent{
    var description:String {
        var result = "The \(fileChange ? "file":"directory") \(self.path) was"
        if fileCreated { result += "fileCreated" }
        
        if fileRemoved { result += "fileRemoved" }
        
        if fileRenamed { result += "fileRenamed" }
        
        if fileModified { result += "fileModified" }
        
        if dirCreated { result += "dirCreated" }
        
        if dirRemoved { result += "dirRemoved" }
        
        if dirRenamed { result += "dirRenamed" }
        
        if dirModified { result += "dirModified" }
        return result
    }
}




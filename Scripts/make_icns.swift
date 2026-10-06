import Foundation

struct IconRepresentation {
    let type: String
    let fileName: String
}

enum IconPackingError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidChunkType(String)

    var description: String {
        switch self {
        case .invalidArguments:
            "Usage: make_icns <AppIcon.appiconset directory> <output.icns>"
        case let .invalidChunkType(type):
            "The ICNS chunk type must contain exactly four ASCII characters: \(type)"
        }
    }
}

let representations = [
    IconRepresentation(type: "icp4", fileName: "icon_16x16.png"),
    IconRepresentation(type: "icp5", fileName: "icon_32x32.png"),
    IconRepresentation(type: "icp6", fileName: "icon_32x32@2x.png"),
    IconRepresentation(type: "ic07", fileName: "icon_128x128.png"),
    IconRepresentation(type: "ic08", fileName: "icon_256x256.png"),
    IconRepresentation(type: "ic09", fileName: "icon_512x512.png"),
    IconRepresentation(type: "ic10", fileName: "icon_512x512@2x.png")
]

func bigEndianData(_ value: UInt32) -> Data {
    var bigEndian = value.bigEndian
    return Data(bytes: &bigEndian, count: MemoryLayout<UInt32>.size)
}

func asciiData(_ value: String) throws -> Data {
    guard value.utf8.count == 4, let data = value.data(using: .ascii) else {
        throw IconPackingError.invalidChunkType(value)
    }
    return data
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw IconPackingError.invalidArguments
    }

    let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: false)
    var chunks = Data()

    for representation in representations {
        let pngURL = sourceDirectory.appending(path: representation.fileName)
        let pngData = try Data(contentsOf: pngURL)
        chunks.append(try asciiData(representation.type))
        chunks.append(bigEndianData(UInt32(pngData.count + 8)))
        chunks.append(pngData)
    }

    var icns = Data()
    icns.append(try asciiData("icns"))
    icns.append(bigEndianData(UInt32(chunks.count + 8)))
    icns.append(chunks)
    try icns.write(to: outputURL, options: .atomic)
    print("Created \(outputURL.path)")
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(EXIT_FAILURE)
}

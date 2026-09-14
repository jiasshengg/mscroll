#!/usr/bin/swift

import AppKit

let canvasSize = NSSize(width: 660, height: 420)

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: render-dmg-background.swift <base-image> <output-image>\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let baseImage = NSImage(contentsOf: inputURL) else {
    fputs("Could not load base image at \(inputURL.path)\n", stderr)
    exit(1)
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvasSize.width),
    pixelsHigh: Int(canvasSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Could not create the background canvas\n", stderr)
    exit(1)
}

bitmap.size = canvasSize
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

let sourceAspect = baseImage.size.width / baseImage.size.height
let canvasAspect = canvasSize.width / canvasSize.height
var sourceRect = NSRect(origin: .zero, size: baseImage.size)

if sourceAspect < canvasAspect {
    let croppedHeight = baseImage.size.width / canvasAspect
    sourceRect.origin.y = (baseImage.size.height - croppedHeight) / 2
    sourceRect.size.height = croppedHeight
} else {
    let croppedWidth = baseImage.size.height * canvasAspect
    sourceRect.origin.x = (baseImage.size.width - croppedWidth) / 2
    sourceRect.size.width = croppedWidth
}

baseImage.draw(
    in: NSRect(origin: .zero, size: canvasSize),
    from: sourceRect,
    operation: .copy,
    fraction: 1
)

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 25, weight: .semibold),
    .foregroundColor: NSColor.white.withAlphaComponent(0.96),
    .paragraphStyle: paragraph
]

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .regular),
    .foregroundColor: NSColor.white.withAlphaComponent(0.58),
    .paragraphStyle: paragraph
]

NSString(string: "Drag Glide to Applications").draw(
    in: NSRect(x: 40, y: 352, width: 580, height: 34),
    withAttributes: titleAttributes
)

NSString(string: "Install once, then launch it from Applications.").draw(
    in: NSRect(x: 40, y: 325, width: 580, height: 22),
    withAttributes: subtitleAttributes
)

let arrow = NSBezierPath()
arrow.lineWidth = 3
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 275, y: 193))
arrow.line(to: NSPoint(x: 385, y: 193))
arrow.move(to: NSPoint(x: 366, y: 176))
arrow.line(to: NSPoint(x: 385, y: 193))
arrow.line(to: NSPoint(x: 366, y: 210))
NSColor.white.withAlphaComponent(0.72).setStroke()
arrow.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not encode the background as PNG\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)

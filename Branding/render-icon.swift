import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Matches the editable vector master in Branding/noma-icon.svg.
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.setFillColor(CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [1, 101.0/255, 78.0/255, 1])!)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setStrokeColor(CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [1, 252.0/255, 250.0/255, 1])!)
context.setLineWidth(104)
context.setLineCap(.round)
context.setLineJoin(.round)
context.move(to: CGPoint(x: 300, y: 300))
context.addLine(to: CGPoint(x: 300, y: 724))
context.addLine(to: CGPoint(x: 724, y: 300))
context.addLine(to: CGPoint(x: 724, y: 724))
context.strokePath()
let image = context.makeImage()!
let output = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
    UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(output, image, nil)
precondition(CGImageDestinationFinalize(output), "Couldn't write the app icon")

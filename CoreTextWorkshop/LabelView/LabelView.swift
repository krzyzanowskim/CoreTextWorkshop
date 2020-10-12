import UIKit
import CoreText

/// Custom label view
@IBDesignable
final public class LabelView: UIView {

    @IBInspectable
    public var text: String?

    private var textFont: UIFont = .preferredFont(forTextStyle: .body)

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override class func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }

    // MARK: - Draw

    public override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)

        // Get CGContext to draw on
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        // Check for string to draw
        guard let text = self.text else {
            return
        }

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)

        let attributedString = NSAttributedString(string: text, attributes: [.font : textFont])
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: bounds, transform: nil), nil)

        let ctLines = CTFrameGetLines(ctFrame) as! [CTLine]

        var ctLinesOrigins = Array<CGPoint>(repeating: .zero, count: ctLines.count)
        // Get origins in CoreGraphics coodrinates
        CTFrameGetLineOrigins(ctFrame, CFRange(), &ctLinesOrigins)

        // Draw lines at origins
        for (ctLine, lineOrigin) in zip(ctLines, ctLinesOrigins) {

            // Tranform coordinates for iOS
            let transformedLineOrigin = lineOrigin.applying(.init(scaleX: 1, y: -1))
                                                  .applying(.init(translationX: 0, y: bounds.height))

            context.textPosition = transformedLineOrigin

            for styleRun in CTLineGetGlyphRuns(ctLine) as! [CTRun] {
                let glyphsCount = CTRunGetGlyphCount(styleRun)

                var glyphs = [CGGlyph](repeating: .zero, count: glyphsCount)
                CTRunGetGlyphs(styleRun, CFRange(), &glyphs)

                var glyphsPositions = [CGPoint](repeating: .zero, count: glyphsCount)
                CTRunGetPositions(styleRun, CFRange(), &glyphsPositions)

                let runAttributes = CTRunGetAttributes(styleRun) as! [String: Any]
                let font = (runAttributes[kCTFontAttributeName as String] as? UIFont) ?? self.textFont

                for (glyph, position) in zip(glyphs, glyphsPositions) {
                    guard let glyphPath = CTFontCreatePathForGlyph(font, glyph, nil) else {
                        // whitespace has no glyph
                        continue
                    }

                    context.saveGState()

                    // Adjust path position, or change local context translateBy, scaleBy
                    var pathTransformation = CGAffineTransform(translationX: position.x, y: transformedLineOrigin.y).scaledBy(x: 1.0, y: -1.0)
                    let tranformedPath = glyphPath.copy(using: &pathTransformation)!

                    context.addPath(tranformedPath)
                    context.fillPath()
                    context.restoreGState()
                }
            }
        }

        context.restoreGState()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        // redraw on re-layout
        setNeedsDisplay()
    }
}

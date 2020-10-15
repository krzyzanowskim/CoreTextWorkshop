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

    public override var bounds: CGRect {
        didSet {
            frame.size.height = intrinsicContentSize.height
        }
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

        let attributedString = NSAttributedString(string: text, attributes: [.font : textFont, .foregroundColor: UIColor.label])
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
            CTLineDraw(ctLine, context)
        }

        context.restoreGState()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        // redraw on re-layout
        setNeedsDisplay()
    }

    public override var intrinsicContentSize: CGSize {
        guard let text = self.text else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return getSizeThatFits(text: text, font: self.textFont, maxWidth: bounds.width)
    }
}


private func getSizeThatFits(text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
    let attributedString = NSAttributedString(string: text, attributes: [.font : font])
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let rectPath = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 50000))
    let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: rectPath, transform: nil), nil)

    let ctLines = CTFrameGetLines(ctFrame) as! [CTLine]

    var ctLinesOrigins = Array<CGPoint>(repeating: .zero, count: ctLines.count)
    // Get origins in CoreGraphics coodrinates
    CTFrameGetLineOrigins(ctFrame, CFRange(), &ctLinesOrigins)

    guard let minOrigin = ctLinesOrigins.min(by: { $0.y < $1.y }),
            let lastCTLine = ctLines.last else {
        return .zero
    }

    // Transform last origin to iOS coordinates
    let transformedMinOrigin = minOrigin
        .applying(.init(scaleX: 1, y: -1))
        .applying(.init(translationX: 0, y: rectPath.height))

    // Get last line metrics and get full height (relative to from origin)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(lastCTLine, &ascent, &descent, &leading)
    let lineSpacing = (ascent + descent + leading) * 0.2 // 20% by default, actual value depends on Paragraph

    // Calculate maximum height of the frame
    let maxHeight = transformedMinOrigin.y + descent + leading + (lineSpacing / 2)
    return CGSize(width: maxWidth, height: maxHeight)
}

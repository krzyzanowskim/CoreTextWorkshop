import UIKit
import CoreText

/// Custom label view
@IBDesignable
final public class LabelView: UIView {

    @IBInspectable
    public var text: String?

    private var attributedString: NSAttributedString? {
        guard let text = self.text else {
            return nil
        }
        return NSAttributedString(string: text, attributes: [.font: textFont, .foregroundColor: UIColor.label])
    }
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
        guard let attributedString = self.attributedString else {
            return
        }

        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)

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
        guard let attributedString = self.attributedString else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return getSizeThatFits(attributedString, maxWidth: bounds.width)
    }
}


private func getSizeThatFits(_ attributedString: NSAttributedString, maxWidth: CGFloat) -> CGSize {
    let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
    let rectPath = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 50000))

    let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(), CGPath(rect: rectPath, transform: nil), nil)

    guard let ctLines = CTFrameGetLines(ctFrame) as? [CTLine], !ctLines.isEmpty else {
        return .zero
    }

    var ctLinesOrigins = Array<CGPoint>(repeating: .zero, count: ctLines.count)
    // Get origins in CoreGraphics coodrinates
    CTFrameGetLineOrigins(ctFrame, CFRange(), &ctLinesOrigins)

    // Transform last origin to iOS coordinates
    let transform: CGAffineTransform
    #if os(macOS)
    transform = CGAffineTransform.identity
    #else
    transform = CGAffineTransform(scaleX: 1, y: -1).concatenating(CGAffineTransform.init(translationX: 0, y: rectPath.height))
    #endif

    guard let lastCTLineOrigin = ctLinesOrigins.last?.applying(transform), let lastCTLine = ctLines.last else {
        return .zero
    }

    // Get last line metrics and get full height (relative to from origin)
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    var leading: CGFloat = 0
    CTLineGetTypographicBounds(lastCTLine, &ascent, &descent, &leading)
    let lineSpacing = (ascent + descent + leading) * 0.2 // 20% by default, actual value depends on Paragraph

    // Calculate maximum height of the frame
    let maxHeight = lastCTLineOrigin.y + descent + leading + (lineSpacing / 2)
    return CGSize(width: maxWidth, height: maxHeight)
}

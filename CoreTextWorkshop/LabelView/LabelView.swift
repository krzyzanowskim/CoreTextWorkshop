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
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), CGPath(rect: bounds, transform: nil), nil)
        let ctLines = CTFrameGetLines(ctFrame) as! [CTLine]

        var currentY: CGFloat = 0.0
        for ctLine in ctLines {
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            var leading: CGFloat = 0.0
            CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)

            let lineHeight = ascent + descent + leading

            context.textPosition = CGPoint(x: 0, y: currentY + ascent)
            CTLineDraw(ctLine, context)

            currentY += lineHeight
        }

        context.restoreGState()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

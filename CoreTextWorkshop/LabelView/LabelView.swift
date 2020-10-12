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
        let typesetter = CTTypesetterCreateWithAttributedString(attributedString)

        // LeftRight/TopBottom
        var startCharacterIndex = 0
        var currentY: CGFloat = 0
        while startCharacterIndex < attributedString.length {
            let breakCharacterIndex = startCharacterIndex + CTTypesetterSuggestLineBreak(typesetter, startCharacterIndex, Double(bounds.width))
            let ctLine = CTTypesetterCreateLine(typesetter, CFRange(location: startCharacterIndex, length: breakCharacterIndex - startCharacterIndex))

            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            CTLineGetTypographicBounds(ctLine, &ascent, &descent, &leading)

            let lineHeight = ascent + descent + leading

            context.textPosition = CGPoint(x: 0, y: currentY + ascent)
            CTLineDraw(ctLine, context)

            startCharacterIndex = breakCharacterIndex
            currentY += lineHeight
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

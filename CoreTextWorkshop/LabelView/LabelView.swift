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

        let attributedString = NSAttributedString(string: text, attributes: [.font : textFont])
        let ctLine = CTLineCreateWithAttributedString(attributedString)

        var descent: CGFloat = 0.0
        var leading: CGFloat = 0.0
        CTLineGetTypographicBounds(ctLine, nil, &descent, &leading)

        // Do the drawing here in `bounds` or `dirtyRect`
        // Hello World
        context.saveGState()

        context.textMatrix = CGAffineTransform(scaleX: 1.0, y: -1.0)
        context.textPosition = CGPoint(x: 0, y: bounds.height - descent - leading)
        CTLineDraw(ctLine, context)

        context.restoreGState()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

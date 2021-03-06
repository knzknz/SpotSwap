import UIKit
import MapKit

class CalloutView: UIView {
    // MARK: - Types
    /// Shape of pointer at the bottom of the callout bubble
    ///
    /// - rounded: Circular, rounded pointer.
    /// - straight: Straight lines for pointer. The angle is measured in radians, must be greater than 0 and less than `.pi` / 2. Using `.pi / 4` yields nice 45 degree angles.
    enum BubblePointerType {
        case rounded
        case straight(angle: CGFloat)
    }
    
    // MARK: - Properties
    weak var annotation: MKAnnotation?
    
    // Shape of pointer at bottom of the callout bubble, pointing at annotation view.
    private let bubblePointerType = BubblePointerType.straight(angle: .pi/4 )
    
    // Insets for rounding of callout bubble's corners
    // The "bottom" is amount of rounding for pointer at the bottom of the callout
    private let inset = UIEdgeInsets(top: 5, left: 5, bottom: 10, right: 5)
    
    // Configures apparance of callout bubble. Color/Border attributes etc.
    private let bubbleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = Stylesheet.Colors.White.cgColor
        layer.lineWidth = 0.5
        return layer
    }()
    
    // Container View for callout
    let contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
    
    // MARK: - Inits
    init(annotation: MKAnnotation) {
        self.annotation = annotation
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    // Configure the view. Height/Width set the size of the callout.
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: inset.top / 2.0),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset.bottom - inset.right / 2.0),
            contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left / 2.0),
            contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right / 2.0),
            contentView.widthAnchor.constraint(equalToConstant: 210),
            contentView.heightAnchor.constraint(equalToConstant: 120)
            // contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: inset.left + inset.right),
            // contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: inset.top + inset.bottom)
            ])
        
        addBackgroundButton(to: contentView)
        layer.insertSublayer(bubbleLayer, at: 0)
    }
    
    // If the view is resized, update the path for the callout bubble
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
    }
    
    // Override hitTest to detect taps within our callout bubble
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let contentViewPoint = convert(point, to: contentView)
        return contentView.hitTest(contentViewPoint, with: event)
    }
    
    /// Update `UIBezierPath` for callout bubble
    ///
    /// The setting of the bubblePointerType dictates whether the pointer at the bottom of the
    /// bubble has straight lines or whether it has rounded corners.
    private func updatePath() {
        let path = UIBezierPath()
        var point: CGPoint
        var controlPoint: CGPoint
        
        point = CGPoint(x: bounds.size.width - inset.right, y: bounds.size.height - inset.bottom)
        path.move(to: point)
        
        switch bubblePointerType {
        case .rounded:
            // lower right
            point = CGPoint(x: bounds.size.width / 2.0 + inset.bottom, y: bounds.size.height - inset.bottom)
            path.addLine(to: point)
            
            // right side of arrow
            controlPoint = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height - inset.bottom)
            point = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height)
            path.addQuadCurve(to: point, controlPoint: controlPoint)
            
            // left of pointer
            controlPoint = CGPoint(x: point.x, y: bounds.size.height - inset.bottom)
            point = CGPoint(x: point.x - inset.bottom, y: controlPoint.y)
            path.addQuadCurve(to: point, controlPoint: controlPoint)
            
        case .straight(let angle):
            // lower right
            point = CGPoint(x: bounds.size.width / 2.0 + tan(angle) * inset.bottom, y: bounds.size.height - inset.bottom)
            path.addLine(to: point)
            
            // right side of arrow
            point = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height)
            path.addLine(to: point)
            
            // left of pointer
            point = CGPoint(x: bounds.size.width / 2.0 - tan(angle) * inset.bottom, y: bounds.size.height - inset.bottom)
            path.addLine(to: point)
        }
        
        // bottom left
        point.x = inset.left
        path.addLine(to: point)
        
        // lower left corner
        controlPoint = CGPoint(x: 0, y: bounds.size.height - inset.bottom)
        point = CGPoint(x: 0, y: controlPoint.y - inset.left)
        path.addQuadCurve(to: point, controlPoint: controlPoint)
        
        // left
        point.y = inset.top
        path.addLine(to: point)
        
        // top left corner
        controlPoint = CGPoint.zero
        point = CGPoint(x: inset.left, y: 0)
        path.addQuadCurve(to: point, controlPoint: controlPoint)
        
        // top
        point = CGPoint(x: bounds.size.width - inset.left, y: 0)
        path.addLine(to: point)
        
        // top right corner
        controlPoint = CGPoint(x: bounds.size.width, y: 0)
        point = CGPoint(x: bounds.size.width, y: inset.top)
        path.addQuadCurve(to: point, controlPoint: controlPoint)
        
        // right
        point = CGPoint(x: bounds.size.width, y: bounds.size.height - inset.bottom - inset.right)
        path.addLine(to: point)
        
        // lower right corner
        controlPoint = CGPoint(x:bounds.size.width, y: bounds.size.height - inset.bottom)
        point = CGPoint(x: bounds.size.width - inset.right, y: bounds.size.height - inset.bottom)
        path.addQuadCurve(to: point, controlPoint: controlPoint)
        
        path.close()
        bubbleLayer.path = path.cgPath
    }
    
    // Add this `CalloutView` to an annotation view (i.e. show the callout on the map above the pin)
    func add(to annotationView: MKAnnotationView) {
        annotationView.addSubview(self)
        // constraints for this callout with respect to its superview.
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: annotationView.topAnchor, constant: annotationView.centerOffset.y * 2.5),
            centerXAnchor.constraint(equalTo: annotationView.centerXAnchor, constant: annotationView.calloutOffset.x)
            ])
    }
}

// MARK: - Background Button related code
extension CalloutView {
    /// Add background button to callout
    ///
    /// This adds a button, the same size as the callout's `contentView`, to the `contentView`.
    /// The purpose of this is two-fold: First, it provides an easy method, `didTouchUpInCallout`,
    /// that you can `override` in order to detect taps on the callout. Second, by adding this
    /// button (rather than just adding a tap gesture or the like), it ensures that when you tap
    /// on the button, that it won't simultaneously register as a deselecting of the annotation,
    /// thereby dismissing the callout.
    ///
    /// This serves a similar functional purpose as `_MKSmallCalloutPassthroughButton` in the
    /// default system callout.
    ///
    /// - Parameter view: The view to which we're adding this button.
    
    fileprivate func addBackgroundButton(to view: UIView) {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        button.addTarget(self, action: #selector(didTouchUpInCallout(_:)), for: .touchUpInside)
    }
    
    /// Callout tapped
    ///
    /// If you want to detect a tap on the callout, override this method. By default, this method does nothing.
    /// - Parameter sender: The actual hidden button that was tapped, not the callout, itself.
    @objc func didTouchUpInCallout(_ sender: Any) {
        // this is intentionally blank. Override in subclass
    }
}

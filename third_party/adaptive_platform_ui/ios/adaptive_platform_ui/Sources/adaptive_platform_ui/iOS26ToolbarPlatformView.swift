import UIKit
import Flutter

// MARK: - Factory
class iOS26ToolbarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return iOS26ToolbarPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Container View with Gradient
class ToolbarContainerView: UIView {
    var gradientLayer: CAGradientLayer?
    var onTraitChange: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        // Extend gradient below the container bounds for smooth fade
        gradientLayer?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + 30)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            onTraitChange?()
        }
    }
}

// MARK: - Platform View
class iOS26ToolbarPlatformView: NSObject, FlutterPlatformView {
    private var containerView: ToolbarContainerView
    private var navigationBar: UINavigationBar
    private var navigationItem: UINavigationItem
    private var channel: FlutterMethodChannel

    private var isDark: Bool = false
    private var perActionTintTags: Set<Int> = []
    private var currentConfiguration: [String: Any] = [:]
    private var nativeBackdrop: UIVisualEffectView?
    private var nativeTitle: NativeToolbarTitleControl?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        containerView = ToolbarContainerView(frame: frame)
        navigationBar = UINavigationBar()
        navigationItem = UINavigationItem()
        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        if let params = args as? [String: Any] {
            isDark = params["isDark"] as? Bool ?? false
        }

        super.init()

        // Apply Flutter's brightness override
        if #available(iOS 13.0, *) {
            containerView.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        // The fixed toolbar host stacks one bar per page and fades them, so it
        // draws a single gradient of its own behind them instead.
        let showsGradient = (args as? [String: Any])?["showsGradient"] as? Bool ?? true
        if showsGradient {
            setupGradient()
        }
        setupNavigationBar()

        if let params = args as? [String: Any] {
            configureItems(params)
            configureNativePresentation(params)
            // Apply global tint color after configuring items
            if let n = params["tint"] as? NSNumber {
                let color = Self.colorFromARGB(n.intValue)
                containerView.tintColor = color
                navigationBar.tintColor = color
                // Apply to items that don't have their own per-action tint
                for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                    if !perActionTintTags.contains(item.tag) {
                        item.tintColor = color
                    }
                }
            }
        }

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return containerView
    }

    private func setupGradient() {
        containerView.clipsToBounds = false

        // Add gradient layer for better text readability
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        containerView.gradientLayer = gradientLayer
        containerView.onTraitChange = { [weak self] in
            self?.updateGradientColors()
        }
        updateGradientColors()
    }

    private func setupNavigationBar() {
        containerView.backgroundColor = .clear
        // Keeps glass buttons from turning blue after a menu closes
        containerView.tintColor = .label

        // Make navigation bar transparent to show gradient behind
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.items = [navigationItem]

        // Configure transparent appearance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            if #available(iOS 15.0, *) {
                navigationBar.compactAppearance = appearance
            }
        }

        containerView.addSubview(navigationBar)

        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    private func updateGradientColors() {
        let isDarkMode = containerView.traitCollection.userInterfaceStyle == .dark
        let baseColor = isDarkMode ? UIColor.black : UIColor.white

        // Subtle gradient for text readability
        containerView.gradientLayer?.colors = [
            baseColor.withAlphaComponent(0.85).cgColor,  // 0% - slightly transparent top
            baseColor.withAlphaComponent(0.6).cgColor,   // 40% - fade
            baseColor.withAlphaComponent(0.2).cgColor,   // 70% - more fade
            baseColor.withAlphaComponent(0.0).cgColor    // 100% - transparent
        ]
        containerView.gradientLayer?.locations = [0.0, 0.4, 0.7, 1.0]
    }

    private func configureItems(_ params: [String: Any]) {
        // Title
        if let title = params["title"] as? String {
            navigationItem.title = title
        }

        // Leading/Back button
        var leadingItems: [UIBarButtonItem] = []

        if let leading = params["leading"] as? String {
            let leadingButton: UIBarButtonItem
            if leading.isEmpty {
                leadingButton = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.left"),
                    style: .plain,
                    target: self,
                    action: #selector(leadingTapped)
                )
            } else {
                leadingButton = UIBarButtonItem(
                    title: leading,
                    style: .plain,
                    target: self,
                    action: #selector(leadingTapped)
                )
            }
            leadingButton.isEnabled = params["backEnabled"] as? Bool != false
            leadingItems.append(leadingButton)
        }

        // Process actions
        var leftGroup: [UIBarButtonItem] = []
        var rightGroup: [UIBarButtonItem] = []

        if let actions = params["actions"] as? [[String: Any]] {
            // First pass: check if any flexible spacer exists
            let hasFlexible = actions.contains { ($0["spacerAfter"] as? Int) == 2 }

            // Second pass: build buttons
            var foundFlexible = false

            for (index, action) in actions.enumerated() {
                var button: UIBarButtonItem?

                if let menuEntries = action["menu"] as? [[String: Any]] {
                    let menu = makeMenu(menuEntries, actionIndex: index)
                    if let icon = action["icon"] as? String {
                        button = UIBarButtonItem(
                            image: UIImage(systemName: icon) ?? UIImage(named: icon),
                            menu: menu
                        )
                    } else {
                        button = UIBarButtonItem(
                            title: action["title"] as? String,
                            menu: menu
                        )
                    }
                } else if let icon = action["icon"] as? String {
                    button = UIBarButtonItem(
                        image: UIImage(systemName: icon) ?? UIImage(named: icon),
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                } else if let title = action["title"] as? String {
                    button = UIBarButtonItem(
                        title: title,
                        style: .plain,
                        target: self,
                        action: #selector(actionTapped(_:))
                    )
                }

                if action["loading"] as? Bool == true {
                    let spinner = UIActivityIndicatorView(style: .medium)
                    spinner.startAnimating()
                    spinner.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
                    button = UIBarButtonItem(customView: spinner)
                }
                if let btn = button {
                    btn.isEnabled = action["enabled"] as? Bool != false && action["loading"] as? Bool != true
                    btn.tag = index
                    if let label = action["label"] as? String {
                        btn.accessibilityLabel = label
                    }

                    // Apply prominent style (iOS 26+)
                    if action["prominent"] as? Bool == true {
                        if #available(iOS 26.0, *) {
                            btn.style = .prominent
                        }
                    }

                    // Apply per-action tint color
                    if let n = action["tint"] as? NSNumber {
                        btn.tintColor = Self.colorFromARGB(n.intValue)
                        perActionTintTags.insert(index)
                    }

                    // If no flexible spacer exists, all go to right
                    // If flexible exists, split by it
                    if !hasFlexible {
                        rightGroup.append(btn)
                    } else if !foundFlexible {
                        leftGroup.append(btn)
                    } else {
                        rightGroup.append(btn)
                    }

                    // Check for spacers
                    if let spacerAfter = action["spacerAfter"] as? Int {
                        if spacerAfter == 1 {
                            // Fixed space
                            if #available(iOS 16.0, *) {
                                if !hasFlexible {
                                    rightGroup.append(.fixedSpace(12))
                                } else if !foundFlexible {
                                    leftGroup.append(.fixedSpace(12))
                                } else {
                                    rightGroup.append(.fixedSpace(12))
                                }
                            }
                        } else if spacerAfter == 2 {
                            // Flexible spacer - mark split point
                            foundFlexible = true
                        }
                    }
                }
            }
        }

        // Assign to navigation item
        navigationItem.leftBarButtonItems = leadingItems + leftGroup
        navigationItem.rightBarButtonItems = rightGroup.reversed()
    }

    private func configureNativePresentation(_ params: [String: Any]) {
        guard params["nativeTitleLayout"] as? Bool == true else { return }
        currentConfiguration = params
        isDark = params["isDark"] as? Bool ?? false
        containerView.overrideUserInterfaceStyle = isDark ? .dark : .light
        let foreground = (params["foreground"] as? NSNumber).map { Self.colorFromARGB($0.intValue) } ?? UIColor.label
        containerView.tintColor = foreground
        navigationBar.tintColor = foreground
        navigationBar.titleTextAttributes = [.foregroundColor: foreground]
        if nativeBackdrop == nil {
            let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            effect.translatesAutoresizingMaskIntoConstraints = false
            effect.isUserInteractionEnabled = false
            containerView.insertSubview(effect, belowSubview: navigationBar)
            NSLayoutConstraint.activate([
                effect.topAnchor.constraint(equalTo: containerView.topAnchor),
                effect.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                effect.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                effect.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            nativeBackdrop = effect
        }
        let offset = (params["scrollOffset"] as? NSNumber)?.doubleValue ?? 0
        nativeBackdrop?.alpha = CGFloat(max(0, min(offset / 20, 1)))
        let title = params["title"] as? String ?? ""
        let subtitle = params["subtitle"] as? String
        let tappable = params["titleTappable"] as? Bool == true
        let leading = params["leadingTitle"] as? Bool == true
        if leading || subtitle != nil || tappable {
            let control = NativeToolbarTitleControl(frame: .zero)
            let scale = (params["fontScale"] as? NSNumber)?.doubleValue ?? 1
            control.configure(title: title, subtitle: subtitle, foreground: foreground,
                scale: CGFloat(scale), leading: leading)
            control.isEnabled = tappable && params["interactive"] as? Bool != false
            control.accessibilityLabel = params["semanticLabel"] as? String ?? [title, subtitle].compactMap { $0 }.joined(separator: ", ")
            control.accessibilityTraits = tappable ? [.button] : [.header]
            control.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)
            nativeTitle = control
            control.frame = CGRect(origin: .zero, size: control.intrinsicContentSize)
            if leading {
                navigationItem.titleView = nil
                navigationItem.title = nil
                let titleItem = UIBarButtonItem(customView: control)
                titleItem.width = control.intrinsicContentSize.width
                if #available(iOS 26.0, *) { titleItem.hidesSharedBackground = true }
                navigationItem.leftBarButtonItems = [titleItem]
            } else {
                navigationItem.titleView = control
            }
        } else {
            nativeTitle = nil
            navigationItem.titleView = nil
            navigationItem.title = title
        }
    }

    @objc private func titleTapped() {
        channel.invokeMethod("onTitleTapped", arguments: nil)
    }

    /// Builds the menu of a bar button; dividers split it into inline groups
    private func makeMenu(_ entries: [[String: Any]], actionIndex: Int) -> UIMenu {
        var groups: [[UIMenuElement]] = []
        var current: [UIMenuElement] = []

        for (itemIndex, entry) in entries.enumerated() {
            if entry["divider"] as? Bool == true {
                if !current.isEmpty { groups.append(current); current = [] }
                continue
            }

            let title = entry["title"] as? String ?? ""
            let image = (entry["icon"] as? String).flatMap {
                UIImage(systemName: $0) ?? UIImage(named: $0)
            }
            var attributes: UIMenuElement.Attributes = []
            if entry["enabled"] as? Bool == false { attributes.insert(.disabled) }
            if entry["destructive"] as? Bool == true { attributes.insert(.destructive) }

            let subtitle = entry["subtitle"] as? String
            let action = UIAction(
                title: title,
                subtitle: subtitle?.isEmpty == false ? subtitle : nil,
                image: image,
                attributes: attributes
            ) { [weak self] _ in
                self?.channel.invokeMethod(
                    "onMenuItemTapped",
                    arguments: ["action": actionIndex, "item": itemIndex]
                )
            }
            current.append(action)
        }
        if !current.isEmpty { groups.append(current) }

        return UIMenu(
            title: "",
            children: groups.map { UIMenu(title: "", options: .displayInline, children: $0) }
        )
    }

    @objc private func leadingTapped() {
        channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func actionTapped(_ sender: UIBarButtonItem) {
        channel.invokeMethod("onActionTapped", arguments: ["index": sender.tag])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateConfiguration":
            guard let params = call.arguments as? [String: Any] else { result(FlutterMethodNotImplemented); return }
            let previousContent = currentConfiguration.filter { $0.key != "scrollOffset" }
            let newContent = params.filter { $0.key != "scrollOffset" }
            if NSDictionary(dictionary: previousContent).isEqual(to: newContent) {
                currentConfiguration = params
                let offset = (params["scrollOffset"] as? NSNumber)?.doubleValue ?? 0
                nativeBackdrop?.alpha = CGFloat(max(0, min(offset / 20, 1)))
            } else {
                perActionTintTags.removeAll()
                configureItems(params)
                configureNativePresentation(params)
            }
            result(nil)
        case "diagnostics":
            result(["renderer": NSStringFromClass(type(of: navigationBar)), "titleRenderer": "UIKit",
                "actionViews": (navigationItem.rightBarButtonItems ?? []).map { item in
                    item.customView.map { NSStringFromClass(type(of: $0)) } ?? "UIBarButtonItem"
                },
                "titleWidth": nativeTitle.map { Double($0.bounds.width) } ?? 0,
                "title": currentConfiguration["title"] ?? "", "configuration": currentConfiguration])
        case "updateTitle":
            if let args = call.arguments as? [String: Any], let title = args["title"] as? String {
                navigationItem.title = title
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        case "setBrightness":
            if let args = call.arguments as? [String: Any],
               let dark = args["isDark"] as? Bool {
                isDark = dark
                if #available(iOS 13.0, *) {
                    containerView.overrideUserInterfaceStyle = dark ? .dark : .light
                }
            }
            result(nil)
        case "updateActions":
            if let args = call.arguments as? [String: Any] {
                perActionTintTags.removeAll()
                configureItems(args)
                // Re-apply global tint to items without per-action tint
                if let globalTint = navigationBar.tintColor {
                    for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                        if !perActionTintTags.contains(item.tag) {
                            item.tintColor = globalTint
                        }
                    }
                }
            }
            result(nil)
        case "setStyle":
            if let args = call.arguments as? [String: Any] {
                if let tintValue = args["tint"] {
                    if let n = tintValue as? NSNumber {
                        let color = Self.colorFromARGB(n.intValue)
                        containerView.tintColor = color
                        navigationBar.tintColor = color
                        for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                            if !perActionTintTags.contains(item.tag) {
                                item.tintColor = color
                            }
                        }
                    } else if tintValue is NSNull {
                        containerView.tintColor = .label
                        navigationBar.tintColor = nil
                        for item in (navigationItem.leftBarButtonItems ?? []) + (navigationItem.rightBarButtonItems ?? []) {
                            if !perActionTintTags.contains(item.tag) {
                                item.tintColor = nil
                            }
                        }
                    }
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func colorFromARGB(_ argb: Int) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

/// UIKit owns both labels, intrinsic size and activation; never a Flutter overlay.
private final class NativeToolbarTitleControl: UIControl {
    private let main = UILabel()
    private let subtitle = UILabel()
    private let stack = UIStackView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 2
        stack.addArrangedSubview(main)
        stack.addArrangedSubview(subtitle)
        addSubview(stack)
        isAccessibilityElement = true
        main.lineBreakMode = .byTruncatingTail
        subtitle.lineBreakMode = .byTruncatingTail
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(title: String, subtitle detail: String?, foreground: UIColor, scale: CGFloat, leading: Bool) {
        main.text = title
        main.font = .systemFont(ofSize: (leading ? 18 : 17) * min(max(scale, 0.8), 2), weight: .semibold)
        main.textColor = foreground
        subtitle.text = detail
        subtitle.font = .systemFont(ofSize: 12 * min(max(scale, 0.8), 1.4), weight: .regular)
        subtitle.textColor = foreground.withAlphaComponent(0.65)
        subtitle.isHidden = detail == nil || detail?.isEmpty == true
        stack.alignment = leading ? .leading : .center
        invalidateIntrinsicContentSize()
    }
    override var intrinsicContentSize: CGSize {
        let title = main.intrinsicContentSize
        let detail = subtitle.isHidden ? CGSize.zero : subtitle.intrinsicContentSize
        return CGSize(width: max(title.width, detail.width), height: title.height + detail.height + (subtitle.isHidden ? 0 : 2))
    }
    override func layoutSubviews() { super.layoutSubviews(); stack.frame = bounds }
}

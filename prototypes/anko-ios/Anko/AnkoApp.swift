import SwiftUI
import WebKit

private func previewTheme() -> String? {
    #if DEBUG
    if let value = ProcessInfo.processInfo.environment["ANKO_PREVIEW_THEME"], ["light", "dark"].contains(value) { return value }
    #endif
    return nil
}

@main
struct AnkoApp: App {
    @AppStorage("ankoAppearance") private var appearance = "light"
    var body: some Scene {
        WindowGroup {
            NativeAnkoRoot(appearance: $appearance)
                .ignoresSafeArea()
        }
    }
}

struct NativeAnkoRoot: UIViewControllerRepresentable {
    @Binding var appearance: String
    func makeUIViewController(context: Context) -> AnkoTabController {
        AnkoTabController(theme: previewTheme() ?? appearance) { value in
            if previewTheme() == nil { appearance = value }
        }
    }
    func updateUIViewController(_ controller: AnkoTabController, context: Context) {
        controller.applyAppearance(previewTheme() ?? appearance)
    }
}

// The shared web document owns app state. UIKit owns the tab bar, segmented
// selectors and every binary switch, including their material and gestures.
final class AnkoTabController: UITabBarController, UITabBarControllerDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    private let destinations = ["home", "family", "pet", "mine"]
    private var webView: WKWebView!
    private let controlOverlay = PassthroughOverlay()
    private var controls: [String: UIControl] = [:]
    private var currentTheme: String
    private var onTheme: (String) -> Void
    private var ready = false

    init(theme: String, onTheme: @escaping (String) -> Void) {
        currentTheme = theme
        self.onTheme = onTheme
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // No custom UITabBarAppearance/background: allow the OS to render Liquid Glass.
        tabBar.tintColor = .systemBlue
        viewControllers = zip(["家园", "家人", "Anko", "我的"], ["house", "heart", "pawprint", "person.crop.circle"]).enumerated().map { index, item in
            let child = UIViewController()
            child.edgesForExtendedLayout = .all
            child.extendedLayoutIncludesOpaqueBars = true
            child.tabBarItem = UITabBarItem(title: item.0, image: UIImage(systemName: item.1), tag: index)
            child.tabBarItem.selectedImage = UIImage(systemName: item.1 + ".fill") ?? UIImage(systemName: item.1)
            return child
        }
        let configuration = WKWebViewConfiguration()
        let bridge = WeakScriptHandler(self)
        configuration.userContentController.add(bridge, name: "theme")
        configuration.userContentController.add(bridge, name: "controls")
        if previewTheme() != nil { configuration.websiteDataStore = .nonPersistent() }
        configuration.userContentController.addUserScript(WKUserScript(
            source: "window.ankoNative=true;window.nativeTheme='\(currentTheme)';",
            injectionTime: .atDocumentStart, forMainFrameOnly: true))
        #if DEBUG
        if previewTheme() != nil {
            let candidate = ProcessInfo.processInfo.environment["ANKO_PREVIEW_PAGE"] ?? "home"
            let page = ["home", "mine", "fog", "share", "pet"].contains(candidate) ? candidate : "home"
            configuration.userContentController.addUserScript(WKUserScript(
                source: "window.ankoReview?.go('\(page)');",
                injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        #endif
        webView = GeometryAwareWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        #if DEBUG
        webView.isInspectable = true
        #endif
        controlOverlay.clipsToBounds = true
        webView.addSubview(controlOverlay)
        mountDocument()
        applyAppearance(currentTheme)
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyAppearance(currentTheme)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mountDocument()
        if ready { webView.evaluateJavaScript("window.ankoNativeBridge?.refresh()", completionHandler: nil) }
    }

    private func mountDocument() {
        guard let host = selectedViewController?.view, let webView else { return }
        if webView.superview !== host { webView.removeFromSuperview(); host.addSubview(webView) }
        if webView.frame != host.bounds { webView.frame = host.bounds }
    }

    func applyAppearance(_ theme: String) {
        currentTheme = theme
        let dark = theme == "dark"
        overrideUserInterfaceStyle = dark ? .dark : .light
        view.window?.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        tabBar.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        webView?.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        controlOverlay.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        let background = dark ? UIColor(red: 17/255, green: 20/255, blue: 25/255, alpha: 1) : UIColor(red: 246/255, green: 248/255, blue: 251/255, alpha: 1)
        view.backgroundColor = background
        webView?.backgroundColor = background
        webView?.scrollView.backgroundColor = background
        viewControllers?.forEach { $0.overrideUserInterfaceStyle = overrideUserInterfaceStyle; $0.view.backgroundColor = background }
        setNeedsStatusBarAppearanceUpdate()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle { currentTheme == "dark" ? .lightContent : .darkContent }
    override var childForStatusBarStyle: UIViewController? { nil }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        mountDocument()
        controlOverlay.isHidden = true
        command("navigate", arguments: [destinations[selectedIndex]])
    }

    private func command(_ method: String, arguments: [Any]) {
        guard ready,
              let data = try? JSONSerialization.data(withJSONObject: arguments),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript("window.ankoNativeBridge.\(method)(...\(json))", completionHandler: nil)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ready = true
        webView.evaluateJavaScript("window.ankoNativeBridge?.refresh()", completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame else { return }
        if message.name == "theme", let value = message.body as? String, ["light", "dark"].contains(value) {
            if currentTheme != value { applyAppearance(value); onTheme(value) }
            return
        }
        guard message.name == "controls", let state = message.body as? [String: Any] else { return }
        ready = true
        if let group = state["group"] as? String, let index = destinations.firstIndex(of: group), index != selectedIndex {
            selectedIndex = index
            mountDocument()
        }
        let modal = state["modal"] as? Bool ?? false
        tabBar.alpha = modal ? 0 : 1
        tabBar.isUserInteractionEnabled = !modal
        tabBar.accessibilityElementsHidden = modal
        guard let clip = state["clip"] as? [String: Any] else { return }
        let pageRect = rectangle(clip)
        controlOverlay.frame = pageRect
        controlOverlay.isHidden = false
        let items = state["controls"] as? [[String: Any]] ?? []
        let activeIDs = Set(items.compactMap { $0["id"] as? String })
        for id in Array(controls.keys) where !activeIDs.contains(id) { controls.removeValue(forKey: id)?.removeFromSuperview() }
        for item in items {
            guard let id = item["id"] as? String, let kind = item["kind"] as? String else { continue }
            let control: UIControl
            if let existing = controls[id] { control = existing }
            else if kind == "switch" {
                let toggle = IdentifiedSwitch()
                toggle.identifier = id
                toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
                control = toggle
                controls[id] = control
                controlOverlay.addSubview(control)
            } else {
                let segment = IdentifiedSegment(items: item["options"] as? [String] ?? [])
                segment.identifier = id
                segment.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
                control = segment
                controls[id] = control
                controlOverlay.addSubview(control)
            }
            control.accessibilityIdentifier = id
            control.accessibilityLabel = item["label"] as? String
            let rect = rectangle(item).offsetBy(dx: -pageRect.minX, dy: -pageRect.minY)
            if let toggle = control as? UISwitch {
                toggle.setOn(item["value"] as? Bool ?? false, animated: false)
                toggle.sizeToFit()
                toggle.center = CGPoint(x: rect.midX, y: rect.midY)
            } else if let segment = control as? UISegmentedControl {
                segment.selectedSegmentIndex = (item["value"] as? NSNumber)?.intValue ?? 0
                segment.frame = rect
            }
            control.isHidden = !rect.intersects(controlOverlay.bounds)
        }
        webView.bringSubviewToFront(controlOverlay)
    }
    private func rectangle(_ data: [String: Any]) -> CGRect {
        func number(_ key: String) -> CGFloat { CGFloat((data[key] as? NSNumber)?.doubleValue ?? 0) }
        return CGRect(x: number("x"), y: number("y"), width: number("width"), height: number("height"))
    }
    @objc private func toggleChanged(_ sender: IdentifiedSwitch) { command("setControl", arguments: [sender.identifier, sender.isOn]) }
    @objc private func segmentChanged(_ sender: IdentifiedSegment) { command("setControl", arguments: [sender.identifier, sender.selectedSegmentIndex]) }
}

private final class IdentifiedSwitch: UISwitch { var identifier = "" }
private final class IdentifiedSegment: UISegmentedControl { var identifier = "" }
private final class PassthroughOverlay: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

private final class GeometryAwareWebView: WKWebView {
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        // Safe-area CSS can settle after UIKit changes the selected host.
        DispatchQueue.main.async { [weak self] in
            self?.evaluateJavaScript("requestAnimationFrame(()=>requestAnimationFrame(()=>window.ankoNativeBridge?.refresh()))", completionHandler: nil)
        }
    }
}

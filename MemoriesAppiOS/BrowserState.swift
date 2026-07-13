import Foundation
import WebKit

final class BrowserState: ObservableObject {
    @Published var currentURL: URL?
    @Published var estimatedProgress: Double = 0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    weak var webView: WKWebView?

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func stopLoading() {
        webView?.stopLoading()
    }

    func update(from webView: WKWebView) {
        // Only publish values that actually changed, so redundant delegate/KVO
        // callbacks don't trigger needless SwiftUI view updates.
        if currentURL != webView.url { currentURL = webView.url }
        if estimatedProgress != webView.estimatedProgress { estimatedProgress = webView.estimatedProgress }
        if isLoading != webView.isLoading { isLoading = webView.isLoading }
        if canGoBack != webView.canGoBack { canGoBack = webView.canGoBack }
        if canGoForward != webView.canGoForward { canGoForward = webView.canGoForward }
    }
}

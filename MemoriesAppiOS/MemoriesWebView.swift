import SwiftUI
import UIKit
import WebKit

struct MemoriesWebView: UIViewRepresentable {
    let targetURL: URL
    @ObservedObject var state: BrowserState
    let credential: ServerCredential?

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state, credential: credential)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.applicationNameForUserAgent = "MemoriesAppiOS/1.0"

        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: Coordinator.messageHandlerName)
        userContentController.addUserScript(WKUserScript(source: Coordinator.uploadFeedbackScript, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        state.webView = webView
        webView.load(URLRequest(url: targetURL))
        context.coordinator.loadedURL = targetURL
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        state.webView = webView
        context.coordinator.credential = credential
        // Do not call state.update(from:) here — publishing BrowserState changes
        // during a SwiftUI view update causes an infinite update loop.
        guard context.coordinator.loadedURL != targetURL else { return }
        context.coordinator.loadedURL = targetURL
        webView.load(URLRequest(url: targetURL))
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.messageHandlerName)
        webView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.isLoading))
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        static let messageHandlerName = "memoriesApp"
        static let uploadFeedbackScript = """
        (function() {
            if (window.__memoriesAppUploadFeedbackInstalled) { return; }
            window.__memoriesAppUploadFeedbackInstalled = true;

            var handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.memoriesApp;
            if (!handler) { return; }

            function preview(text) {
                if (!text) { return ""; }
                return String(text).replace(/\\s+/g, " ").trim().slice(0, 1200);
            }

            function notify(payload) {
                try { handler.postMessage(payload); } catch (error) { }
            }

            function reportResponse(status, statusText, url, body) {
                if (status >= 400) {
                    notify({
                        kind: "httpError",
                        status: status,
                        statusText: statusText || "",
                        url: url || "",
                        body: preview(body)
                    });
                }
            }

            var originalFetch = window.fetch;
            if (originalFetch) {
                window.fetch = function() {
                    return originalFetch.apply(this, arguments).then(function(response) {
                        if (response && response.status >= 400) {
                            try {
                                response.clone().text().then(function(body) {
                                    reportResponse(response.status, response.statusText, response.url, body);
                                }).catch(function() {
                                    reportResponse(response.status, response.statusText, response.url, "");
                                });
                            } catch (error) {
                                reportResponse(response.status, response.statusText, response.url, "");
                            }
                        }
                        return response;
                    }).catch(function(error) {
                        notify({ kind: "networkError", message: error && error.message ? error.message : String(error) });
                        throw error;
                    });
                };
            }

            var OriginalXMLHttpRequest = window.XMLHttpRequest;
            if (OriginalXMLHttpRequest) {
                window.XMLHttpRequest = function() {
                    var xhr = new OriginalXMLHttpRequest();
                    xhr.addEventListener("loadend", function() {
                        var body = "";
                        try { body = typeof xhr.responseText === "string" ? xhr.responseText : ""; } catch (error) { }
                        reportResponse(xhr.status, xhr.statusText, xhr.responseURL, body);
                    });
                    return xhr;
                };
                window.XMLHttpRequest.prototype = OriginalXMLHttpRequest.prototype;
            }
        })();
        """

        @ObservedObject var state: BrowserState
        var loadedURL: URL?
        var credential: ServerCredential?

        init(state: BrowserState, credential: ServerCredential?) {
            self.state = state
            self.credential = credential
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            DispatchQueue.main.async {
                self.state.update(from: webView)
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.update(from: webView)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            state.update(from: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.update(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.update(from: webView)
            presentLoadErrorIfNeeded(error, in: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state.update(from: webView)
            presentLoadErrorIfNeeded(error, in: webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame,
               let response = navigationResponse.response as? HTTPURLResponse,
               response.statusCode >= 400 {
                presentServerError(statusCode: response.statusCode, statusText: HTTPURLResponse.localizedString(forStatusCode: response.statusCode), body: nil, in: webView)
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let method = challenge.protectionSpace.authenticationMethod
            guard challenge.previousFailureCount == 0,
                  method == NSURLAuthenticationMethodHTTPBasic || method == NSURLAuthenticationMethodHTTPDigest,
                  let credential,
                  !credential.username.isEmpty else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let urlCredential = URLCredential(user: credential.username, password: credential.password, persistence: .permanent)
            completionHandler(.useCredential, urlCredential)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard let viewController = presentingViewController(for: webView) else {
                completionHandler()
                return
            }

            let alert = UIAlertController(title: hostTitle(for: frame), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })
            viewController.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            guard let viewController = presentingViewController(for: webView) else {
                completionHandler(false)
                return
            }

            let alert = UIAlertController(title: hostTitle(for: frame), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })
            viewController.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            guard let viewController = presentingViewController(for: webView) else {
                completionHandler(nil)
                return
            }

            let alert = UIAlertController(title: hostTitle(for: frame), message: prompt, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(nil)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            viewController.present(alert, animated: true)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.messageHandlerName,
                  let webView = message.webView,
                  let body = message.body as? [String: Any],
                  let kind = body["kind"] as? String else { return }

            switch kind {
            case "httpError":
                let statusCode = body["status"] as? Int ?? 0
                let statusText = body["statusText"] as? String ?? ""
                let responseBody = body["body"] as? String
                presentServerError(statusCode: statusCode, statusText: statusText, body: responseBody, in: webView)
            case "networkError":
                let message = body["message"] as? String ?? "The request could not be completed."
                presentAlert(title: "Upload Failed", message: message, in: webView)
            default:
                break
            }
        }

        private func presentServerError(statusCode: Int, statusText: String, body: String?, in webView: WKWebView) {
            let fallback = statusCode > 0 ? "The server returned \(statusCode) \(statusText)." : "The server rejected the request."
            let message = readableServerMessage(from: body) ?? fallback
            presentAlert(title: "Upload Failed", message: message, in: webView)
        }

        private func presentLoadErrorIfNeeded(_ error: Error, in webView: WKWebView) {
            let nsError = error as NSError
            guard nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled else { return }
            presentAlert(title: "Page Load Failed", message: error.localizedDescription, in: webView)
        }

        private func readableServerMessage(from body: String?) -> String? {
            guard let body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

            if let data = body.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                for key in ["error", "message", "detail"] {
                    if let value = object[key] as? String, !value.isEmpty {
                        return value
                    }
                }
            }

            let withoutTags = body.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            let collapsed = withoutTags.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return collapsed.isEmpty ? nil : collapsed
        }

        private func presentAlert(title: String, message: String, in webView: WKWebView) {
            guard let viewController = presentingViewController(for: webView), viewController.presentedViewController == nil else { return }

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }

        private func hostTitle(for frame: WKFrameInfo) -> String {
            frame.request.url?.host ?? "Website"
        }

        private func presentingViewController(for webView: WKWebView) -> UIViewController? {
            var viewController = webView.window?.rootViewController
            while let presentedViewController = viewController?.presentedViewController {
                viewController = presentedViewController
            }
            return viewController
        }
    }
}

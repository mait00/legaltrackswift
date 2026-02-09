//
//  WebPDFViewer.swift
//  LegalTrack
//
//  Temporary: kad.arbitr.ru PDF links are protected by ddos/captcha and often cannot be fetched via URLSession.
//  Rendering via WKWebView allows the challenge to run and the document to open.
//

import SwiftUI
import WebKit

struct WebPDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op: we only load once per presentation.
    }
}

struct WebPDFScreen: View {
    let url: URL
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebPDFViewer(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") { dismiss() }
                    }
                }
        }
    }
}


//
//  URLImage.swift
//  ImageCache
//
//  Created by Juan Jose Arreola Simon on 03/01/21.
//

#if canImport(SwiftUI)

import Foundation
import SwiftUI
import AllCache
import ShallowPromises

@available(iOS 13.0.0, *)
public final class URLImage<Content: View>: View {
    let url: URL
    @State var uiImage: UIImage?
    @State var error: Error?
    
    private var promise: Promise<UIImage>?
    
    private var placeholder: Content?
    private var onSuccess: (SwiftUI.Image) -> SwiftUI.Image?
    private var onError: (Error) -> Content?
    
    public var body: some View {
        content
    }
    
    private var content: some View {
        Group {
            if let error = error, let result = onError(error) {
                result
            } else if let uiImage = uiImage {
                let image = SwiftUI.Image(uiImage: uiImage)
                onSuccess(image) ?? image
            } else if let placeholder = placeholder {
                placeholder
            } else {
                EmptyView()
            }
        }
    }
    
    public init(_ url: URL,
         @ViewBuilder onSuccess: @escaping (_ image: SwiftUI.Image) -> SwiftUI.Image? = { _ in nil },
         @ViewBuilder onError: @escaping (_ error: Error) -> Content? = { _ in nil },
         @ViewBuilder placeholder: () -> Content? = { nil }) {
        self.url = url
        self.onSuccess = onSuccess
        self.placeholder = placeholder()
        self.onError = onError
    }
    
    public func load() {
        let descriptor = ElementDescriptor(key: url.absoluteString, fetcher: ImageFetcher(url: url), processor: nil)
        promise = ImageCache.shared.instance(for: descriptor).onSuccess({ image in
            self.uiImage = image
        }).onError({ error in
            self.error = error
        })
    }
    
    public func cancel() {
        promise?.cancel()
    }
    
    deinit {
        cancel()
    }
}

#endif

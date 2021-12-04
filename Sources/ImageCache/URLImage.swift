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

@available(iOS 14.0.0, *)
public struct URLImage<Placeholder: View, ErrorView: View>: View {
    @StateObject public var loader: ImageLoader
    
    private var placeholder: Placeholder?
    private var onSuccess: (SwiftUI.Image) -> SwiftUI.Image?
    private var onError: (Error) -> ErrorView?
    
    public var body: some View {
        content
            .onAppear(perform: { loader.load() })
    }
    
    private var content: some View {
        Group {
            if let error = loader.error, let result = onError(error) {
                result
            } else if let uiImage = loader.uiImage {
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
                @ViewBuilder onError: @escaping (_ error: Error) -> ErrorView? = { _ in nil },
                @ViewBuilder placeholder: () -> Placeholder? = { nil },
                @ViewBuilder onSuccess: @escaping (_ image: SwiftUI.Image) -> SwiftUI.Image? = { _ in nil }) {
        _loader = StateObject(wrappedValue: ImageLoader(url: url))
        self.onSuccess = onSuccess
        self.placeholder = placeholder()
        self.onError = onError
    }
}

@available(iOS 13.0, *)
public class ImageLoader: ObservableObject {
    let url: URL
    @Published var uiImage: UIImage?
    @Published var error: Error?
    
    private var promise: Promise<UIImage>?
    
    init(url: URL) {
        self.url = url
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
}

#endif

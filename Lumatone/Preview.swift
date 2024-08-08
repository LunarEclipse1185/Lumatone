//
//  Preview.swift
//  Lumatone
//
//  Created by SH BU on 2024/7/14.
//

import SwiftUI
import AVFoundation

struct Preview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        //
    }
}

struct testPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        Key(note: 10, color: .green)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        //
    }
}

#Preview {
    Preview()
}

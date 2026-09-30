//
//  CameraView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 29/9/2026.
//
import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable{
    class CameraPreview: UIView{
        override class var layerClass: AnyClass{
            AVCaptureVideoPreviewLayer.self
        }
        var previewLayer: AVCaptureVideoPreviewLayer{
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreview {
        let view = CameraPreview()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: CameraPreview, context: Context) {}
    
}

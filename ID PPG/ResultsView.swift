//
//  ResultsView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 10/10/2026.
//
import SwiftUI

struct ResultsView: View {
    @StateObject private var camera = CameraManager()
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Reading Completed")
                    .font(.largeTitle)
                    .bold()
            }
            CameraView(session: camera.session)
                .frame(width: 260, height: 260)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 4)
                )
                .onAppear {
                    camera.turnFlashlightOn()
                }
                .onDisappear {
                    camera.turnFlashlightOff()
                }
        }
    }
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ResultsView()
        }
    }

}


    

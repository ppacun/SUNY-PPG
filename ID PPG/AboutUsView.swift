//
//  AboutUsView.swift
//  ID PPG
//
//  Developed by Yaren Celebi in 4/10/2026.
import SwiftUI

struct AboutUsView: View {
    var body: some View {
        ScrollView{
            VStack(spacing:28) {
                VStack(spacing:12){
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    Text("About Us")
                        .font(.system(size:42, weight: .bold))
                    Text("Camera-based heart rate detection")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                VStack(alignment: .leading, spacing:22){
                    Text("""
                        This is a SUNY Albany CSI 499 Capstone Project in collaboration with vablet that focuses on developing a camera-based photoplethysmography application for iPhone. 
                        """)
                    Text("""
                        The application uses the iPhone camera to estimate heart rate by detecting small changes in light caused by blood flow.
                        """)
                }
                .font(.title3)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                VStack(spacing:12) {
                    Image(systemName: "target")
                        .font(.system(size: 34))
                    Text("Our Aim")
                        .font(.title2)
                        .bold()
                    Text("""
                        Our aim is to offer a simple and accessible way for users to  check their heart rate using only their smartphones, without needing additional equipment or specialized devices. 
                        """)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                }

                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 24)
                
                VStack(spacing: 8) {

                    Text("Capstone Project")
                        .font(.headline)

                    Text("SUNY Albany • CSI 499 • vablet")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 10)
                Text("This application is not intended for medical diagnosis.")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 35)
                    .padding(.bottom, 30)
            }
        }
    }
    
}

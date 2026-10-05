//
//  HowItWorksView.swift
//  ID PPG
//
//  Developed by Yaren Celebi in 4/10/2026.
//
import SwiftUI

struct HowItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Image(systemName:"waveform.path.ecg")
                        .font(.system(size:50))
                        .foregroundStyle(.red)
                    Text("How It Works")
                        .font(.system(size:42, weight: .bold))
                    Text("Your heart rate in four simple steps")
                        .font(.title3)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                VStack(spacing: 20) {
                    StepCard(
                        icon:"hand.point.up.left.fill",
                        title:"1. Cover the camera",
                        description:"Place your fingertip gently over the iPhone's rear camera and flash."
                    )
                    StepCard(
                        icon:"camera.fill",
                        title:"2. Capture the signal",
                        description:"The camera records small changes in light as blood flows through your fingertip with each heartbeat."
                    )
                    StepCard(
                        icon: "waveform",
                        title: "3. Analyze the Changes",
                        description: "The application analyzes the repeating changes in light to identify your pulse signal."
                    )
                    StepCard(
                        icon: "heart.fill",
                        title: "4. Estimate Your Heart Rate",
                        description: "The detected pulse is converted into an estimated heart rate in beats per minute, or BPM."
                    )
                }
                Text("For best results, keep your finger still and fully cover the camera and flash during the measurement.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
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
struct StepCard: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(alignment: .top, spacing:16) {
            Image(systemName: icon)
                .font(.system(size:28))
                .frame(width: 40)
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title3)
                .bold()
        
            Text(description)
                .foregroundStyle(.gray)
                .lineSpacing(3)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        
    }
}

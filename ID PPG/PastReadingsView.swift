//
//  PastReadingsView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 30/9/2026.
//
import SwiftUI



struct PastReadingsView: View {
    @AppStorage("neverShowWarning") private var neverShowWarning = false
    var body: some View {
        HStack {
            Spacer()
            Text("Past Readings \nto be implemented")
                .multilineTextAlignment(.center)
                .onTapGesture {
                    neverShowWarning = false
                }

            Spacer()
        }
    }

}

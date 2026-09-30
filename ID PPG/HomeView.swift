//
//  HomeView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 29/9/2026.
//
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack{
            VStack(spacing: 30){
                Spacer()
                Text("vablet cPPG")
                    .font(.system(size: 50))
                    .bold()
                Spacer()
                NavigationLink{
                    ReadingView()
                }label: {
                    Text("Take Heart Rate")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal,40)
                NavigationLink{
                    PastReadingsView()
                }label: {
                    Text("My Past Readings")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 250, height:80)
                        .background(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal,40)
                NavigationLink {
                    HealthRecommendationsView()
                } label: {
                    Text("Health\nRecommendations")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 250, height: 80)
                        .background(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.horizontal,40)
                Spacer()
                HStack(spacing: 20) {
                    NavigationLink {
                        AboutUsView()
                    } label: {
                        Text("About us")
                    }
                    Text("•")
                    Link("vablet", destination: URL(string: "https://vablet.com")!)
                    Text("•")
                    NavigationLink {
                        HowItWorksView()
                    } label: {
                        Text("How it works")
                    }
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


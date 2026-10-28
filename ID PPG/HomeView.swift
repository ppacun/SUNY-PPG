//
//  HomeView.swift
//  ID PPG
//
//  Created by Dylan Gonzalez on 29/9/2026.
//

import SwiftUI

struct HomeView: View {

    @State private var path = NavigationPath()
    @State private var showSettings = false

    @AppStorage("patientAge") private var patientAge = 18.0
    @AppStorage("activityLevel") private var activityLevel = "None"

    var body: some View {

        NavigationStack(path: $path) {

            ZStack(alignment: .topTrailing) {

                // MAIN HOME PAGE
                VStack(spacing: 30) {

                    Spacer()

                    Text("vablet cPPG")
                        .font(.system(size: 50))
                        .bold()

                    Spacer()

                    NavigationLink {
                        ReadingView()
                    } label: {
                        Text("Take Heart Rate")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.horizontal, 40)

                    NavigationLink {
                        PastReadingsView()
                    } label: {

                        Text("My Past Readings")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width: 250, height: 80)
                            .background(.gray)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 25)
                            )
                    }
                    .padding(.horizontal, 40)

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
                    .padding(.horizontal, 40)
                
                    Spacer()

                    HStack(spacing: 20) {

                        NavigationLink {
                            AboutUsView()
                        } label: {
                            Text("About us")
                        }

                        Text("•")

                        Link(
                            "vablet",
                            destination: URL(string: "https://vablet.com")!
                        )

                        Text("•")

                        NavigationLink {
                            HowItWorksView()
                        } label: {
                            Text("How it works")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

             
                if showSettings {

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {

                            Text("Settings")
                                .font(.headline)
                                .bold()

                            Spacer()

                            Button {
                                showSettings = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.primary)
                            }
                        }

                        Divider()

                            Text("Age: \(Int(patientAge))")
                                .font(.subheadline)

                            Slider(
                                value: $patientAge,
                                in: 0...100,
                                step: 1
                            )
                        Text("What is your activity level?")
                              .font(.subheadline)

                          Picker("Activity Level", selection: $activityLevel) {
                              Text("None").tag("None")
                              Text("Light").tag("Light")
                              Text("Atheltic").tag("Atheltic")
                          }
                          .pickerStyle(.segmented)

                        Text(
                            "Information stays on the device and is only used compare results to population"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    }
                    .padding()
                    .frame(width: 220)
                    .background(.thinMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 15)
                    )
                    .shadow(radius: 8)
                    .padding(.top, 5)
                    .padding(.trailing, 10)
                }
            }

            

            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }
}

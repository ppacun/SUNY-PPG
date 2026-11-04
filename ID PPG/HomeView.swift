import SwiftUI

struct HomeView: View {
    
    @State private var showSettings = false
    
    @AppStorage("patientAge")
    private var patientAge = 18.0
    
    @AppStorage("activityLevel")
    private var activityLevel = "None"
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .topTrailing) {
                
                VStack(spacing: 28) {
                    
                    // MARK: - Header
                    
                    VStack(spacing: 6) {
                        
                        Text("Heart Rate")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Measure your pulse using your iPhone camera.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    
                    // MARK: - Take Heart Rate
                    
                    NavigationLink {
                        ReadingView()
                    } label: {
                        
                        HStack(spacing: 10) {
                            
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Take Heart Rate")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .fill(Color.red)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    
                    // MARK: - Main Options
                    
                    VStack(spacing: 14) {
                        
                        NavigationLink {
                            PastReadingsView()
                        } label: {
                            
                            MainGrayButton(
                                icon: "chart.xyaxis.line",
                                title: "Past Readings",
                                subtitle: "View your previous measurements"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        
                        NavigationLink {
                            HealthRecommendationsView()
                        } label: {
                            
                            MainGrayButton(
                                icon: "heart.text.clipboard",
                                title: "Health Recommendations",
                                subtitle: "Learn about your results"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    
                    // MARK: - Information
                    
                    VStack(spacing: 0) {
                        
                        NavigationLink {
                            AboutUsView()
                        } label: {
                            
                            SimpleRow(
                                icon: "info.circle",
                                title: "About"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        
                        Divider()
                        
                        
                        NavigationLink {
                            HowItWorksView()
                        } label: {
                            
                            SimpleRow(
                                icon: "questionmark.circle",
                                title: "How It Works"
                            )
                        }
                        .buttonStyle(.plain)
                        
                        
                        Divider()
                        
                        
                        Link(
                            destination: URL(
                                string: "https://vablet.com"
                            )!
                        ) {
                            
                            SimpleRow(
                                icon: "safari",
                                title: "Visit Vablet",
                                external: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .background(
                        Color.secondary.opacity(0.12)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    
                    
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                
                
                // MARK: - Settings Overlay
                
                if showSettings {
                    
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            
                            withAnimation(
                                .spring(
                                    response: 0.35,
                                    dampingFraction: 0.82
                                )
                            ) {
                                showSettings = false
                            }
                        }
                    
                    
                    settingsPanel
                        .transition(
                            .scale(
                                scale: 0.95,
                                anchor: .topTrailing
                            )
                            .combined(with: .opacity)
                        )
                        .padding(.trailing, 12)
                        .padding(.top, 6)
                }
            }
            
            .navigationTitle("vablet cPPG")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                

                ToolbarItem(placement: .navigationBarTrailing) {


                    Button {
                        
                        withAnimation(
                            .spring(
                                response: 0.35,
                                dampingFraction: 0.82
                            )
                        ) {
                            showSettings.toggle()
                        }
                        
                    } label: {
                        
                        Image(systemName: "gearshape")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
    
    
    // MARK: - Settings
    
    private var settingsPanel: some View {
        
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            
            // MARK: - Header
            
            HStack {
                
                HStack(spacing: 6) {
                    
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.red)
                    
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Button {
                    
                    withAnimation(
                        .spring(
                            response: 0.3,
                            dampingFraction: 0.8
                        )
                    ) {
                        showSettings = false
                    }
                    
                } label: {
                    
                    Image(systemName: "xmark")
                        .font(
                            .system(
                                size: 11,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.primary)
                        .frame(
                            width: 26,
                            height: 26
                        )
                        .background(
                            Color.secondary.opacity(0.12)
                        )
                        .clipShape(Circle())
                }
            }
            
            
            Divider()
                .opacity(0.35)
            
            
            // MARK: - Age
            
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                
                HStack {
                    
                    Text("Age")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(patientAge))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                
                Slider(
                    value: $patientAge,
                    in: 0...100,
                    step: 1
                )
                .tint(.red)
            }
            
            
            // MARK: - Activity Level
            
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                
                Text("Activity Level")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Picker(
                    "Activity Level",
                    selection: $activityLevel
                ) {
                    
                    Text("None")
                        .tag("None")
                    
                    Text("Light")
                        .tag("Light")
                    
                    Text("Athletic")
                        .tag("Athletic")
                }
                .pickerStyle(.segmented)
            }
            
            
            Divider()
                .opacity(0.35)
            
            
            // MARK: - Privacy
            
            HStack(
                alignment: .top,
                spacing: 6
            ) {
                
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                
                Text(
                    "Your information stays on this device."
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        
        .padding(14)
        
        // Smaller popup
        .frame(width: 250)
        
        // Works in Light + Dark Mode
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(Color(uiColor: .secondarySystemBackground))
        )
        
        // Subtle glass-like border
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.08),
                lineWidth: 1
            )
        )
        
        // Floating effect
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Main Gray Button

private struct MainGrayButton: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.red)


            VStack(
                alignment: .center,
                spacing: 3
            ) {

                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }


            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }

        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .frame(minHeight: 74)

        .background(
            Color.secondary.opacity(0.12)
        )

        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )

        .contentShape(Rectangle())
    }
}


// MARK: - Information Row

private struct SimpleRow: View {

    let icon: String
    let title: String

    var external = false

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(.red)


            Text(title)
                .foregroundStyle(.primary)


            Spacer()


            Image(
                systemName:
                    external
                    ? "arrow.up.right"
                    : "chevron.right"
            )
            .font(.caption.bold())
            .foregroundStyle(.secondary)
        }

        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

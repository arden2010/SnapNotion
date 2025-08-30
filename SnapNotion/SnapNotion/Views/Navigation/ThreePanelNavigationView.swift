//
//  ThreePanelNavigationView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct ThreePanelNavigationView: View {
    @StateObject private var navigationController = NavigationController()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Simple single panel for now - just show main panel
                MainPanelView()
                    .environmentObject(navigationController)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Debug overlay to ensure something is visible
                VStack {
                    HStack {
                        Text("SnapNotion")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Panel: \(navigationController.currentPanel == .main ? "Main" : "Other")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    Spacer()
                }
            }
        }
        .environmentObject(navigationController)
    }
    
    // MARK: - Overlay View
    @ViewBuilder
    private func overlayView(geometry: GeometryProxy) -> some View {
        if navigationController.currentPanel != .main {
            Color.black
                .opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    navigationController.returnToMainPanel()
                }
                .animation(.easeInOut(duration: 0.3), value: navigationController.currentPanel)
        }
    }
    
    // MARK: - Pan Gesture
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                navigationController.handlePanGesture(
                    translation: value.translation,
                    velocity: CGSize(width: 0, height: 0)
                )
            }
            .onEnded { value in
                navigationController.handlePanEnded(
                    translation: value.translation,
                    velocity: value.predictedEndTranslation
                )
            }
    }
}

// MARK: - Main Panel View
struct MainPanelView: View {
    @EnvironmentObject var navigationController: NavigationController
    
    var body: some View {
        VStack(spacing: 0) {
            // Simplified Header
            HStack {
                Text("SnapNotion")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Simple content for testing
            VStack(spacing: 20) {
                Text("Welcome to SnapNotion")
                    .font(.title)
                    .padding()
                
                Text("Intelligent Content Management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Button("Dashboard") {
                        print("Dashboard tapped")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Library") {
                        print("Library tapped")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Favorites") {
                        print("Favorites tapped")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Main Panel Header
struct MainPanelHeader: View {
    @EnvironmentObject var navigationController: NavigationController
    
    var body: some View {
        HStack {
            // Left hamburger menu
            Button(action: navigationController.showLeftPanelAction) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(.leading)
            }
            
            Spacer()
            
            // Phoenix branding
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(Color.phoenixOrange)
                
                Text("SnapNotion")
                    .claudeCodeStyle(.header3, color: .primary)
            }
            
            Spacer()
            
            // Right menu for advanced features
            Button(action: navigationController.showRightPanelAction) {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(.trailing)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
    }
}

// MARK: - Color Extension for Phoenix Orange
extension Color {
    static let phoenixOrange = Color(red: 1.0, green: 0.6, blue: 0.2) // #FF9933
}

#Preview {
    ThreePanelNavigationView()
}
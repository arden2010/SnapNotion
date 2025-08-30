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
                
                // Panel Container
                HStack(spacing: 0) {
                    // Left Panel
                    LeftPanelView()
                        .frame(width: geometry.size.width)
                        .opacity(navigationController.currentPanel == .left ? 1 : 0)
                    
                    // Main Panel
                    MainPanelView()
                        .frame(width: geometry.size.width)
                        .environmentObject(navigationController)
                    
                    // Right Panel
                    RightPanelView()
                        .frame(width: geometry.size.width)
                        .opacity(navigationController.currentPanel == .right ? 1 : 0)
                }
                .offset(x: -navigationController.panelOffset * geometry.size.width)
                .animation(.easeInOut(duration: navigationController.isDragging ? 0 : 0.3), value: navigationController.panelOffset)
                
                // Overlay for iPhone/iPad (if needed)
                if navigationController.deviceType.usesOverlay {
                    overlayView(geometry: geometry)
                }
            }
            .gesture(panGesture)
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
            // Header with hamburger menu and profile
            MainPanelHeader()
                .environmentObject(navigationController)
            
            // Tab Navigation (5 tabs)
            TabNavigationView()
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
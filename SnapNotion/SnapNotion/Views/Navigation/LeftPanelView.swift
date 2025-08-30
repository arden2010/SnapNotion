//
//  LeftPanelView.swift
//  SnapNotion
//
//  Created by A. C. on 8/30/25.
//

import SwiftUI

struct LeftPanelView: View {
    @EnvironmentObject var navigationController: NavigationController
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            leftPanelHeader
            
            // Menu Items
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    profileSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Settings Menu
                    settingsMenu
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var leftPanelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .claudeCodeStyle(.header2, color: .primary)
                
                Text("Configure SnapNotion")
                    .claudeCodeStyle(.caption, color: .secondary)
            }
            
            Spacer()
            
            Button("Done") {
                navigationController.returnToMainPanel()
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.phoenixOrange.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.phoenixOrange)
            }
            
            // User Info
            VStack(spacing: 4) {
                Text("Local User")
                    .claudeCodeStyle(.header3, color: .primary)
                
                Text("SnapNotion Personal")
                    .claudeCodeStyle(.body, color: .secondary)
            }
            
            // Storage Info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Storage")
                        .claudeCodeStyle(.caption, color: .secondary)
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green)
                            .frame(width: 40, height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 60, height: 4)
                    }
                }
                
                Spacer()
                
                Text("2.1 GB")
                    .claudeCodeStyle(.caption, color: .secondary)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Settings Menu
    private var settingsMenu: some View {
        LazyVStack(spacing: 0) {
            SettingMenuItem(
                icon: "person.circle",
                title: "Profile",
                subtitle: "Personal information",
                action: { /* TODO: Navigate to profile */ }
            )
            
            SettingMenuItem(
                icon: "icloud.and.arrow.up",
                title: "Sync",
                subtitle: "CloudKit synchronization",
                action: { /* TODO: Navigate to sync settings */ }
            )
            
            SettingMenuItem(
                icon: "brain.head.profile",
                title: "AI Config",
                subtitle: "AI processing settings",
                action: { /* TODO: Navigate to AI config */ }
            )
            
            SettingMenuItem(
                icon: "square.and.arrow.up",
                title: "Export",
                subtitle: "Data export options",
                action: { /* TODO: Navigate to export */ }
            )
            
            SettingMenuItem(
                icon: "info.circle",
                title: "About",
                subtitle: "App info and credits",
                action: { /* TODO: Navigate to about */ }
            )
            
            // Developer Section
            Divider()
                .padding(.horizontal)
            
            Text("Developer Options")
                .claudeCodeStyle(.caption, color: .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            SettingMenuItem(
                icon: "hammer",
                title: "Debug Mode",
                subtitle: "Development tools",
                action: { /* TODO: Toggle debug mode */ }
            )
            
            SettingMenuItem(
                icon: "trash",
                title: "Reset Data",
                subtitle: "Clear all content",
                destructive: true,
                action: { /* TODO: Reset data */ }
            )
        }
    }
}

// MARK: - Setting Menu Item
struct SettingMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    var destructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(destructive ? .red : .phoenixOrange)
                    .frame(width: 24, height: 24)
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .claudeCodeStyle(.body, color: destructive ? .error : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .claudeCodeStyle(.caption, color: .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LeftPanelView()
        .environmentObject(NavigationController())
}
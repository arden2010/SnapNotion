//
//  ScreenshotProcessingBanner.swift
//  SnapNotion
//
//  Created by A. C. on 8/31/25.
//

import SwiftUI

struct ScreenshotProcessingBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isVisible {
                HStack(spacing: 12) {
                    // Animated processing indicator
                    ZStack {
                        Circle()
                            .stroke(Color.phoenixOrange.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.phoenixOrange, lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                            .rotationEffect(.degrees(360))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isVisible)
                    }
                    
                    // Message text
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.phoenixOrange, Color.phoenixOrange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screenshot Processing View Modifier
extension View {
    func screenshotProcessingBanner(
        isShowing: Binding<Bool>,
        message: String
    ) -> some View {
        self.overlay(
            Group {
                if isShowing.wrappedValue {
                    VStack {
                        ScreenshotProcessingBanner(message: message) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing.wrappedValue = false
                            }
                        }
                        Spacer()
                    }
                    .zIndex(999)
                }
            }
        )
    }
}
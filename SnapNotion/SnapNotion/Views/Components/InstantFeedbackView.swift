//
//  InstantFeedbackView.swift
//  SnapNotion
//
//  Instant feedback system for screenshot processing with floating overlays
//  Created by A. C. on 8/31/25.
//

import SwiftUI
import Combine

// MARK: - Instant Feedback View
struct InstantFeedbackView: View {
    @StateObject private var feedbackManager = InstantFeedbackManager.shared
    
    var body: some View {
        ZStack {
            Color.clear
            
            // Processing Banner
            if feedbackManager.isShowingProcessingBanner {
                VStack {
                    ProcessingBannerView(
                        progress: feedbackManager.processingProgress,
                        message: feedbackManager.processingMessage,
                        onDismiss: {
                            feedbackManager.hideProcessingBanner()
                        }
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: feedbackManager.isShowingProcessingBanner)
                    
                    Spacer()
                }
                .zIndex(1000)
            }
            
            // Quick Preview Overlay
            if feedbackManager.isShowingQuickPreview, let previewData = feedbackManager.previewData {
                QuickPreviewOverlay(
                    previewData: previewData,
                    onAction: { action in
                        feedbackManager.handleQuickAction(action)
                    },
                    onDismiss: {
                        feedbackManager.hideQuickPreview()
                    }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: feedbackManager.isShowingQuickPreview)
                .zIndex(999)
            }
            
            // Success Toast
            if feedbackManager.isShowingSuccessToast {
                VStack {
                    Spacer()
                    
                    SuccessToastView(
                        message: feedbackManager.successMessage,
                        details: feedbackManager.successDetails
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: feedbackManager.isShowingSuccessToast)
                    
                    Spacer().frame(height: 100)
                }
                .zIndex(998)
            }
            
            // Magic Moment Animation
            if feedbackManager.isShowingMagicMoment, let magicMomentData = feedbackManager.magicMomentData {
                MagicMomentView(
                    data: magicMomentData,
                    onComplete: {
                        feedbackManager.hideMagicMoment()
                    }
                )
                .animation(.easeInOut(duration: 0.6), value: feedbackManager.isShowingMagicMoment)
                .zIndex(997)
            }
        }
        .allowsHitTesting(feedbackManager.isShowingInteractiveOverlay)
    }
}

// MARK: - Processing Banner
struct ProcessingBannerView: View {
    let progress: Double
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    ProcessingIndicator(progress: progress)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("\(Int(progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                LinearGradient(
                    colors: [Color.phoenixOrange, Color.phoenixOrange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.phoenixOrange.opacity(0.3))
                    .frame(height: 3)
                    .overlay(
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * progress, height: 3)
                            .animation(.easeInOut(duration: 0.3), value: progress),
                        alignment: .leading
                    )
            }
            .frame(height: 3)
        }
        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Processing Indicator
struct ProcessingIndicator: View {
    let progress: Double
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 32, height: 32)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Center icon
            Image(systemName: progress < 1.0 ? "brain.head.profile" : "checkmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            if progress < 1.0 {
                isAnimating = true
            }
        }
        .onChange(of: progress) { newProgress in
            if newProgress >= 1.0 {
                isAnimating = false
            }
        }
    }
}

// MARK: - Quick Preview Overlay
struct QuickPreviewOverlay: View {
    let previewData: PreviewData
    let onAction: (QuickAction) -> Void
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var timeRemaining = 8.0
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                // Preview content
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: previewData.contentType.icon)
                            .font(.title2)
                            .foregroundColor(previewData.contentType.color)
                        
                        Text(previewData.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(previewData.preview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Extracted insights
                    if !previewData.extractedInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Insights:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.phoenixOrange)
                            
                            ForEach(previewData.extractedInsights.prefix(3), id: \.self) { insight in
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                        .foregroundColor(.phoenixOrange)
                                    
                                    Text(insight)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Quick actions
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "heart",
                        title: "Save",
                        color: .red
                    ) {
                        onAction(.save)
                    }
                    
                    QuickActionButton(
                        icon: "list.bullet",
                        title: "Tasks",
                        color: .blue,
                        badge: previewData.suggestedTasksCount > 0 ? "\(previewData.suggestedTasksCount)" : nil
                    ) {
                        onAction(.createTasks)
                    }
                    
                    QuickActionButton(
                        icon: "square.and.arrow.up",
                        title: "Share",
                        color: .green
                    ) {
                        onAction(.share)
                    }
                    
                    QuickActionButton(
                        icon: "eye",
                        title: "View",
                        color: .purple
                    ) {
                        onAction(.viewDetails)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .background(
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Start countdown timer
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                timeRemaining -= 1.0
                if timeRemaining <= 0 {
                    timer.invalidate()
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 16, y: -16)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Success Toast
struct SuccessToastView: View {
    let message: String
    let details: String?
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let details = details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Magic Moment View
struct MagicMomentView: View {
    let data: MagicMomentData
    let onComplete: () -> Void
    
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            // Sparkle animation
            ForEach(0..<12, id: \.self) { index in
                SparkleView(index: index, phase: animationPhase)
            }
            
            // Center content
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.phoenixOrange)
                    .scaleEffect(animationPhase == 0 ? 0.5 : 1.2)
                    .animation(.easeInOut(duration: 0.6), value: animationPhase)
                
                Text(data.message)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(data.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .scaleEffect(animationPhase == 0 ? 0.5 : 1.0)
            .opacity(animationPhase == 0 ? 0.0 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animationPhase = 1
            }
            
            // Complete animation after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    animationPhase = 2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Sparkle View
struct SparkleView: View {
    let index: Int
    let phase: Int
    
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat(8 + index % 4), weight: .light))
            .foregroundColor(.phoenixOrange.opacity(0.7))
            .offset(
                x: cos(Double(index) * .pi / 6) * (isAnimating ? 80 : 40),
                y: sin(Double(index) * .pi / 6) * (isAnimating ? 80 : 40)
            )
            .scaleEffect(isAnimating ? 1.2 : 0.5)
            .opacity(isAnimating ? 0.8 : 0.3)
            .animation(
                .easeInOut(duration: 0.8)
                .delay(Double(index) * 0.1)
                .repeatCount(3, autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                if phase > 0 {
                    isAnimating = true
                }
            }
            .onChange(of: phase) { newPhase in
                if newPhase > 0 {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
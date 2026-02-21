//
//  LiquidGlass.swift
//  LegalTrack
//
//  Liquid Glass модификаторы для iOS 26 дизайна
//

import SwiftUI

// MARK: - Liquid Glass View Modifier

/// Модификатор для создания эффекта "жидкого стекла" (Liquid Glass)
struct LiquidGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    
    let material: Material
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content
                    .background(colorScheme == .dark ? Color.black.opacity(0.12) : Color.white.opacity(0.08))
            } else {
                content
                    .background(material)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: shadowRadius, x: 0, y: 4)
    }
}

// MARK: - View Extension

extension View {
    /// Применяет эффект Liquid Glass к view
    func liquidGlass(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 10
    ) -> some View {
        modifier(LiquidGlassModifier(
            material: material,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        ))
    }
    
    /// Карточка в стиле Liquid Glass
    func liquidGlassCard(
        padding: CGFloat = 16,
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8
    ) -> some View {
        self
            .padding(padding)
            .background(material)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: shadowRadius, y: 4)
    }
}

// MARK: - Liquid Glass Background

struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Базовый градиентный фон
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color(hex: "#0a0a0a"),
                            Color(hex: "#1a1a1a"),
                            Color(hex: "#0f0f0f")
                        ]
                        : [
                            Color(hex: "#f5f5f7"),
                            Color(hex: "#ffffff"),
                            Color(hex: "#f8f8fa")
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Декоративные световые эффекты
                if colorScheme == .dark {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.primary.opacity(0.15),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: min(400, geometry.size.width * 0.8),
                               height: min(400, geometry.size.width * 0.8))
                        .position(
                            x: geometry.size.width * 0.2,
                            y: geometry.size.height * 0.15
                        )
                        .blur(radius: 60)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.secondary.opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: min(350, geometry.size.width * 0.7),
                               height: min(350, geometry.size.width * 0.7))
                        .position(
                            x: geometry.size.width * 0.8,
                            y: geometry.size.height * 0.7
                        )
                        .blur(radius: 50)
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass Tab Picker Style

struct LiquidGlassSegmentedPickerStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .background(
                Material.ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                        lineWidth: 0.5
                    )
            )
    }
}

extension View {
    func liquidGlassSegmentedStyle() -> some View {
        modifier(LiquidGlassSegmentedPickerStyle())
    }
}

// MARK: - Left Accent Border Helper
struct LeftAccentBorder: ViewModifier {
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(color)
                    .frame(width: width)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
    }
}

extension View {
    func liquidGlassLeftAccent(color: Color, width: CGFloat = 3, cornerRadius: CGFloat = 16) -> some View {
        modifier(LeftAccentBorder(color: color, width: width, cornerRadius: cornerRadius))
    }
}

// MARK: - Unified Screen Styles

extension View {
    /// Unified list backdrop and behavior across tabs/screens.
    func appListScreenStyle() -> some View {
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColors.groupedBackground.ignoresSafeArea())
    }

    /// Unified card surface to avoid mixed materials/radius.
    /// Uses a solid system background for better readability in lists.
    func appCardSurface(cornerRadius: CGFloat = 16, material: Material = .thinMaterial) -> some View {
        self
            .background(
                AppColors.surface,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.border.opacity(0.22), lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    /// Unified list row spacing for card-like layout.
    func appListCardRow(top: CGFloat = 6, bottom: CGFloat = 6, horizontal: CGFloat = 16) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: horizontal, bottom: bottom, trailing: horizontal))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

// MARK: - Animated Background (Orbs)
struct LiquidGlassAnimatedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "#0a0a0a"), Color(hex: "#1a1a1a")]
                    : [Color(hex: "#f5f5f7"), Color(hex: "#ffffff")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if !reduceMotion {
                orb(color: .blue.opacity(0.25), size: 280, x: 0.2, y: 0.25, dx: 0.15, dy: 0.1)
                orb(color: .orange.opacity(0.18), size: 320, x: 0.8, y: 0.7, dx: -0.12, dy: -0.08)
                orb(color: .purple.opacity(0.12), size: 240, x: 0.6, y: 0.2, dx: 0.08, dy: 0.12)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 25).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }

    @ViewBuilder
    private func orb(color: Color, size: CGFloat, x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat) -> some View {
        GeometryReader { geo in
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .blur(radius: 60)
                .position(
                    x: geo.size.width * (animate ? x + dx : x - dx),
                    y: geo.size.height * (animate ? y + dy : y - dy)
                )
        }
        .ignoresSafeArea()
    }
}

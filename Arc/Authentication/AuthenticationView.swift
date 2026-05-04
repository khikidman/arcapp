//
//  AuthenticationView.swift
//  Productivity
//
//  Created by Khi Kidman on 5/31/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

private let providerSignInButtonHeight: CGFloat = 40
private let providerSignInButtonCornerRadius: CGFloat = 8

struct AuthenticationView: View {
    
    @State private var authVM = AuthenticationViewModel()
    @StateObject private var emailViewModel = SignInEmailViewModel()
    @State private var showsEmailFields = false
    @Binding var showSignInView: Bool
    
    var body: some View {
        ZStack {
            AuroraCloudBackground()
                .ignoresSafeArea()

            ArcStardustForeground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                Spacer()
                AuthenticationLogoHeader()

                VStack(spacing: 14) {
                    if showsEmailFields {
                        TextField("", text: $emailViewModel.email, prompt: Text("Email"))
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )

                        SecureField("Password", text: $emailViewModel.password)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Button {
                        if showsEmailFields {
                            Task {
                                await signInWithEmail()
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                showsEmailFields = true
                            }
                        }
                    } label: {
                        Text("Sign In With Email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [.cyan, .blue.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                HStack {
                    VStack {
                        Divider().background(Color.white.opacity(0.65))
                    }
                    Text("or")
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.horizontal)
                    VStack {
                        Divider().background(Color.white.opacity(0.65))
                    }
                }
                .padding(.vertical, 20)
                VStack(spacing: 12) {
                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: .normal)) {
                        Task {
                            do {
                                try await authVM.signInGoogle()
                                showSignInView = false
                            } catch {
                                
                            }
                        }
                    }
                    .frame(height: providerSignInButtonHeight)
                    .background(.white, in: RoundedRectangle(cornerRadius: providerSignInButtonCornerRadius))
                    .clipShape(RoundedRectangle(cornerRadius: providerSignInButtonCornerRadius))

                    Button {
                        Task {
                            do {
                                try await authVM.signInApple()
                                showSignInView = false
                            } catch {

                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 22)

                            Text("Sign in with Apple")
                                .font(.system(size: 14, weight: .medium))

                            Spacer()
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: providerSignInButtonHeight)
                        .background(.white, in: RoundedRectangle(cornerRadius: providerSignInButtonCornerRadius))
                    }
                    .buttonStyle(.plain)
                    .clipShape(RoundedRectangle(cornerRadius: providerSignInButtonCornerRadius))
                }
                .shadow(color: .cyan.opacity(0.2), radius: 18, y: 8)

                Spacer()
            }
            .padding(35)
        }
    }

    private func signInWithEmail() async {
        do {
            try await emailViewModel.signUp()
            showSignInView = false
            return
        } catch {
            print(error)
        }

        do {
            try await emailViewModel.signIn()
            showSignInView = false
        } catch {
            print(error)
        }
    }
}

private struct AuthenticationLogoHeader: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("A")
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .cyan.opacity(0.38), radius: 14, y: 8)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                .offset(x: 0, y: 10)

            CurvedRMark()
                .stroke(
                    LinearGradient(
                        colors: [.white, .cyan.opacity(0.98), .blue.opacity(0.9), .white.opacity(0.92)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 124, height: 84)
                .blur(radius: 0.15)
                .shadow(color: .cyan.opacity(0.72), radius: 12, y: 6)
                .shadow(color: .blue.opacity(0.34), radius: 22, y: 12)
                .offset(x: 53, y: 6)

            Text("c")
                .font(.system(size: 78, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .cyan.opacity(0.34), radius: 14, y: 8)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                .offset(x: 78, y: 10)
        }
        .frame(width: 176, height: 106)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 36)
    }
}

private struct CurvedRMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let stemX = rect.minX + rect.width * 0.08
        path.move(to: CGPoint(x: stemX, y: rect.maxY * 0.89))
        path.addLine(to: CGPoint(x: stemX, y: rect.maxY * 0.48))

        path.move(to: CGPoint(x: stemX, y: rect.maxY * 0.75))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.maxY * 0.28),
            control1: CGPoint(x: rect.minX + rect.width * 0.11, y: rect.minY + rect.height * 0.34),
            control2: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.28)
        )
//        path.addCurve(
//            to: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.maxY * 0.28),
//            control1: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.maxY * 0.28),
//            control2: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.maxY * 0.28)
//        )

        let samples = 16
        for step in 1...samples {
            let progress = CGFloat(step) / CGFloat(samples)
            let x = rect.minX + rect.width * (0.35 + progress * 0.2)
            let y = rect.maxY * 0.28 - pow(progress, 2.8) * rect.height * 0.25
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

private struct ArcStardustForeground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsedTime = timeline.date.timeIntervalSinceReferenceDate
                let start = CGPoint(x: -28, y: size.height * 0.4)
                let end = CGPoint(x: size.width + 30, y: 42)
                let control1 = CGPoint(x: size.width * 0.22, y: size.height * 0.24)
                let control2 = CGPoint(x: size.width * 0.7, y: -18)

                let arcPath = Path { path in
                    path.move(to: start)
                    path.addCurve(to: end, control1: control1, control2: control2)
                }

                var outerGlow = context
                outerGlow.addFilter(.blur(radius: 18))
                outerGlow.stroke(
                    arcPath,
                    with: .color(.cyan.opacity(0.42)),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )

                var innerGlow = context
                innerGlow.addFilter(.blur(radius: 6))
                innerGlow.stroke(
                    arcPath,
                    with: .color(.blue.opacity(0.72)),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )

                for layer in 0..<5 {
                    let layerOffset = CGFloat(layer + 1) * 9
                    let shiftedPath = Path { path in
                        path.move(to: CGPoint(x: start.x, y: start.y + layerOffset))
                        path.addCurve(
                            to: CGPoint(x: end.x, y: end.y + layerOffset),
                            control1: CGPoint(x: control1.x, y: control1.y + layerOffset),
                            control2: CGPoint(x: control2.x, y: control2.y + layerOffset)
                        )
                    }
                    var downwardGlow = context
                    downwardGlow.addFilter(.blur(radius: 10 + CGFloat(layer) * 6))
                    downwardGlow.stroke(
                        shiftedPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                .clear,
                                .cyan.opacity(0.06 + Double(layer) * 0.015),
                                .blue.opacity(0.12 + Double(layer) * 0.035)
                            ]),
                            startPoint: start,
                            endPoint: end
                        ),
                        style: StrokeStyle(lineWidth: 12 + CGFloat(layer) * 8, lineCap: .round)
                    )
                }

                context.stroke(
                    arcPath,
                    with: .linearGradient(
                        Gradient(colors: [.cyan.opacity(0.95), .blue, .cyan.opacity(0.7)]),
                        startPoint: start,
                        endPoint: end
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )

                for index in 0..<18 {
                    let t = 0.06 + seededValue(index: index, salt: 0.13) * 0.88
                    let anchor = cubicPoint(
                        t: t,
                        start: start,
                        control1: control1,
                        control2: control2,
                        end: end
                    )
                    let progress = generatedProgress(
                        index: index,
                        elapsedTime: elapsedTime,
                        duration: 4.8 + Double(seededValue(index: index, salt: 0.41)) * 2.6,
                        delay: Double(seededValue(index: index, salt: 0.77)) * 4.2
                    )
                    let rightWeight = Double(t)
                    let baseDrop = size.height * (0.03 + seededValue(index: index, salt: 1.7) * 0.11)
                    let fallDistance = size.height * (0.24 + seededValue(index: index, salt: 2.3) * 0.18)
                    let drift = sin((progress * .pi * 2) + t * 11) * (18 + 10 * t)
                    let point = CGPoint(
                        x: anchor.x + drift + (seededValue(index: index, salt: 3.1) - 0.5) * 58,
                        y: anchor.y + baseDrop + progress * fallDistance
                    )
                    let opacity = (0.05 + rightWeight * 0.08)
                        * fadeOpacity(for: point.y, in: size.height)
                        * cycleOpacity(for: progress)

                    guard opacity > 0.006 else { continue }

                    let width = 44 + seededValue(index: index, salt: 4.4) * 56
                    let height = 12 + seededValue(index: index, salt: 5.2) * 20
                    let rect = CGRect(
                        x: point.x - width / 2,
                        y: point.y - height / 2,
                        width: width,
                        height: height
                    )

                    var fog = context
                    fog.addFilter(.blur(radius: 16 + seededValue(index: index, salt: 6.5) * 14))
                    fog.fill(
                        Path(ellipseIn: rect),
                        with: .color(fogColor(for: index).opacity(opacity))
                    )
                }

                for index in 0..<72 {
                    let t = 0.04 + seededValue(index: index, salt: 7.2) * 0.92
                    let anchor = cubicPoint(
                        t: t,
                        start: start,
                        control1: control1,
                        control2: control2,
                        end: end
                    )
                    let progress = generatedProgress(
                        index: index,
                        elapsedTime: elapsedTime,
                        duration: 2.2 + Double(seededValue(index: index, salt: 8.8)) * 2.8,
                        delay: Double(seededValue(index: index, salt: 9.6)) * 5.5
                    )
                    let fallDistance = size.height * (0.18 + seededValue(index: index, salt: 10.4) * 0.22)
                    let drift = sin((progress * .pi * 2) + t * 13) * (5 + seededValue(index: index, salt: 11.1) * 12)
                    let point = CGPoint(
                        x: anchor.x + (seededValue(index: index, salt: 12.9) - 0.5) * 70 + drift,
                        y: anchor.y + 10 + seededValue(index: index, salt: 13.5) * 90 + progress * fallDistance
                    )
                    let opacity = (0.38 + Double(t) * 0.42)
                        * fadeOpacity(for: point.y, in: size.height)
                        * cycleOpacity(for: progress)

                    guard opacity > 0.01 else { continue }

                    let particleSize = 0.9 + seededValue(index: index, salt: 14.8) * 2.4
                    let rect = CGRect(
                        x: point.x - particleSize / 2,
                        y: point.y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )

                    if index % 3 == 0 {
                        var glow = context
                        glow.addFilter(.blur(radius: particleSize * 1.4))
                        glow.fill(
                            Path(ellipseIn: rect.insetBy(dx: -particleSize * 1.4, dy: -particleSize * 1.4)),
                            with: .color(dustColor(for: index).opacity(opacity * 0.36))
                        )
                    }

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(dustColor(for: index).opacity(opacity))
                    )
                }

                for particle in dustParticles {
                    let anchor = cubicPoint(
                        t: particle.t,
                        start: start,
                        control1: control1,
                        control2: control2,
                        end: end
                    )
                    let progress = fallProgress(for: particle, elapsedTime: elapsedTime)
                    let fallDistance = size.height * 0.28 + abs(particle.xOffset) * 1.8
                    let drift = sin((progress * .pi * 2) + particle.t * 9) * 8
                    let point = CGPoint(
                        x: anchor.x + particle.xOffset + drift,
                        y: anchor.y + particle.drop + progress * fallDistance
                    )
                    let opacity = particle.opacity
                        * fadeOpacity(for: point.y, in: size.height)
                        * cycleOpacity(for: progress)

                    guard opacity > 0.01 else { continue }

                    let rect = CGRect(
                        x: point.x - particle.size / 2,
                        y: point.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    var glow = context
                    glow.addFilter(.blur(radius: particle.size * 1.2))
                    glow.fill(
                        Path(ellipseIn: rect.insetBy(dx: -particle.size, dy: -particle.size)),
                        with: .color(particle.color.opacity(opacity * 0.5))
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(opacity))
                    )
                }
            }
            .blendMode(.screen)
        }
    }

    private func cubicPoint(
        t: CGFloat,
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint
    ) -> CGPoint {
        let inverse = 1 - t
        let inverseSquared = inverse * inverse
        let inverseCubed = inverseSquared * inverse
        let tSquared = t * t
        let tCubed = tSquared * t

        return CGPoint(
            x: inverseCubed * start.x
                + 3 * inverseSquared * t * control1.x
                + 3 * inverse * tSquared * control2.x
                + tCubed * end.x,
            y: inverseCubed * start.y
                + 3 * inverseSquared * t * control1.y
                + 3 * inverse * tSquared * control2.y
                + tCubed * end.y
        )
    }

    private func fallProgress(for particle: DustParticle, elapsedTime: TimeInterval) -> CGFloat {
        let duration = 3.2 + Double(particle.t) * 2.2
        let delay = Double(abs(particle.xOffset) + particle.drop) * 0.013
        let cyclePosition = (elapsedTime + delay).truncatingRemainder(dividingBy: duration) / duration

        return CGFloat(cyclePosition)
    }

    private func fadeOpacity(for yPosition: CGFloat, in height: CGFloat) -> Double {
        let fadeStart = height * 0.5
        let fadeEnd = height * 0.67

        guard yPosition > fadeStart else { return 1 }
        guard yPosition < fadeEnd else { return 0 }

        return Double(1 - ((yPosition - fadeStart) / (fadeEnd - fadeStart)))
    }

    private func cycleOpacity(for progress: CGFloat) -> Double {
        if progress < 0.12 {
            return Double(progress / 0.12)
        }

        if progress > 0.86 {
            return Double((1 - progress) / 0.14)
        }

        return 1
    }

    private func generatedProgress(
        index: Int,
        elapsedTime: TimeInterval,
        duration: Double,
        delay: Double
    ) -> CGFloat {
        let cyclePosition = (elapsedTime + delay + Double(index) * 0.17)
            .truncatingRemainder(dividingBy: duration) / duration

        return CGFloat(cyclePosition)
    }

    private func seededValue(index: Int, salt: CGFloat) -> CGFloat {
        let value = abs(sin((CGFloat(index) + 1) * 12.9898 + salt * 78.233) * 43758.5453)

        return value - CGFloat(Int(value))
    }

    private func dustColor(for index: Int) -> Color {
        switch index % 5 {
        case 0:
            .white
        case 1, 3:
            .cyan
        default:
            .green
        }
    }

    private func fogColor(for index: Int) -> Color {
        switch index % 4 {
        case 0:
            .cyan
        case 1:
            .blue
        default:
            .green
        }
    }

    private struct DustParticle {
        let t: CGFloat
        let xOffset: CGFloat
        let drop: CGFloat
        let size: CGFloat
        let opacity: Double
        let color: Color
    }

    private let dustParticles: [DustParticle] = [
        DustParticle(t: 0.05, xOffset: 8, drop: 28, size: 2.2, opacity: 0.88, color: .white),
        DustParticle(t: 0.08, xOffset: -10, drop: 48, size: 3.6, opacity: 0.54, color: .cyan),
        DustParticle(t: 0.12, xOffset: 18, drop: 74, size: 1.7, opacity: 0.82, color: .green),
        DustParticle(t: 0.16, xOffset: -4, drop: 112, size: 2.4, opacity: 0.56, color: .cyan),
        DustParticle(t: 0.19, xOffset: 24, drop: 144, size: 1.5, opacity: 0.72, color: .white),
        DustParticle(t: 0.23, xOffset: -28, drop: 62, size: 3.0, opacity: 0.64, color: .green),
        DustParticle(t: 0.27, xOffset: 6, drop: 96, size: 1.8, opacity: 0.92, color: .white),
        DustParticle(t: 0.3, xOffset: 32, drop: 132, size: 2.9, opacity: 0.52, color: .cyan),
        DustParticle(t: 0.34, xOffset: -18, drop: 176, size: 1.6, opacity: 0.68, color: .white),
        DustParticle(t: 0.38, xOffset: 14, drop: 54, size: 3.4, opacity: 0.58, color: .cyan),
        DustParticle(t: 0.41, xOffset: -34, drop: 118, size: 2.0, opacity: 0.76, color: .green),
        DustParticle(t: 0.45, xOffset: 38, drop: 166, size: 1.4, opacity: 0.84, color: .white),
        DustParticle(t: 0.49, xOffset: -8, drop: 212, size: 3.0, opacity: 0.44, color: .cyan),
        DustParticle(t: 0.52, xOffset: 22, drop: 78, size: 2.0, opacity: 0.82, color: .white),
        DustParticle(t: 0.56, xOffset: -30, drop: 138, size: 3.8, opacity: 0.5, color: .green),
        DustParticle(t: 0.59, xOffset: 10, drop: 188, size: 1.5, opacity: 0.9, color: .white),
        DustParticle(t: 0.63, xOffset: 44, drop: 112, size: 2.7, opacity: 0.58, color: .cyan),
        DustParticle(t: 0.66, xOffset: -12, drop: 244, size: 1.8, opacity: 0.66, color: .green),
        DustParticle(t: 0.7, xOffset: 26, drop: 164, size: 1.4, opacity: 0.86, color: .white),
        DustParticle(t: 0.74, xOffset: -24, drop: 96, size: 2.8, opacity: 0.54, color: .cyan),
        DustParticle(t: 0.78, xOffset: 16, drop: 208, size: 3.2, opacity: 0.42, color: .green),
        DustParticle(t: 0.82, xOffset: -36, drop: 148, size: 1.5, opacity: 0.82, color: .white),
        DustParticle(t: 0.86, xOffset: 10, drop: 72, size: 2.4, opacity: 0.72, color: .cyan),
        DustParticle(t: 0.9, xOffset: -18, drop: 118, size: 1.6, opacity: 0.84, color: .white),
        DustParticle(t: 0.94, xOffset: -42, drop: 184, size: 2.7, opacity: 0.5, color: .green)
    ]
}

private struct AuroraCloudBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.015, green: 0.025, blue: 0.07),
                    Color(red: 0.02, green: 0.07, blue: 0.14),
                    Color(red: 0.0, green: 0.12, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: -40) {
                auroraBand(colors: [.cyan.opacity(0.72), .blue.opacity(0.44), .clear])
                    .frame(height: 210)
                    .rotationEffect(.degrees(-13))
                    .offset(x: -52, y: -88)

                auroraBand(colors: [.blue.opacity(0.58), .cyan.opacity(0.42), .clear])
                    .frame(height: 250)
                    .rotationEffect(.degrees(16))
                    .offset(x: 46, y: -24)

                auroraBand(colors: [.cyan.opacity(0.3), .blue.opacity(0.36), .clear])
                    .frame(height: 260)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -26, y: 20)
            }
            .blur(radius: 44)
            .saturation(1.35)
            .blendMode(.screen)

            LinearGradient(
                colors: [.clear, .black.opacity(0.22), .black.opacity(0.52)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func auroraBand(colors: [Color]) -> some View {
        RoundedRectangle(cornerRadius: 120, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .scaleEffect(x: 1.42, y: 0.72)
    }
}

#Preview {
    NavigationStack {
        AuthenticationView(showSignInView: .constant(true))
    }
}

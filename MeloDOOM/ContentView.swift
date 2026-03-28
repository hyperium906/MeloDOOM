//
//  ContentView.swift
//  MeloDOOM
//
//  Created by Joshua Dupati on 3/28/26.
//

import AudioToolbox
import SwiftUI
import UIKit

struct ContentView: View {
    private let defaultGeminiPromptText = "Generate a Gemini update to see Drake react to today’s scores."

    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSection: DashboardSection = .home
    @State private var geminiAPIKey = ""
    @State private var notionToken = ""
    @State private var notionDatabaseID = ""
    @State private var integrationStatus = "Gemini and Notion are scaffolded, but not configured yet."
    @State private var isCallingGemini = false
    @State private var isCallingNotion = false
    @State private var geminiMoodText = "Generate a Gemini update to see Drake react to today’s scores."
    @State private var wallpaperPhase = false
    @State private var homeNotificationPending = false
    @State private var spinnerRotation = 0.0
    @State private var foodSpend = 45.0
    @State private var clothesSpend = 0.0
    @State private var extracurricularSpend = 25.0
    @State private var screenHours = 5.0
    @State private var socialHours = 2.0
    @State private var aiPrompts = 6
    @State private var carMiles = 12.0
    @State private var transitMiles = 6.0
    @State private var streamingHours = 3.0
    @State private var meatMeals = 1
    @State private var flightsThisMonth = 0
    @State private var notionLastSavedAt = Date.now

    private let geminiService = GeminiService()
    private let notionService = NotionService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                animatedWallpaper

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        mainContent
                            .padding(.bottom, 96)
                    }
                    .padding(20)
                    .foregroundStyle(primaryText)
                }

                bottomIslandBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }
            .navigationTitle("MeloDOOM")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    wallpaperPhase.toggle()
                }
            }
            .onChange(of: selectedMood) { oldMood, newMood in
                guard oldMood != newMood else { return }
                AudioServicesPlaySystemSound(1113)
                if selectedSection != .home {
                    homeNotificationPending = true
                }
            }
            .onChange(of: selectedSection) { _, newSection in
                if newSection == .home {
                    homeNotificationPending = false
                }
            }
        }
    }

    @MainActor
    private func generateGeminiPreview() async {
        isCallingGemini = true
        defer { isCallingGemini = false }

        do {
            geminiMoodText = try await geminiService.generateText(
                prompt: geminiMoodPrompt,
                apiKey: geminiAPIKey
            )
            integrationStatus = "Gemini update ready."
        } catch {
            integrationStatus = error.localizedDescription
        }
    }

    @MainActor
    private func sendNotionPreview() async {
        isCallingNotion = true
        defer { isCallingNotion = false }

        do {
            let savedAt = Date.now
            notionLastSavedAt = savedAt
            try await notionService.createDatabaseEntry(
                log: notionDailyLog(savedAt: savedAt),
                databaseID: notionDatabaseID,
                token: notionToken
            )
            integrationStatus = "Daily MeloDOOM log saved to your Notion database."
        } catch {
            integrationStatus = error.localizedDescription
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedSection {
        case .home:
            VStack(alignment: .leading, spacing: 12) {
                healthBarsCard
                characterCard
                moodDialogueCard
                fidgetSpinnerCard
                geminiReactionCard
                notionLogCard
                overallScoreCard
                dailyPulseCard
            }
        case .profile:
            VStack(alignment: .leading, spacing: 12) {
                profileCard
                integrationCard
            }
        case .carbon:
            VStack(alignment: .leading, spacing: 12) {
                heroCard
                carbonOverviewCard
                carbonTrackingCard
            }
        case .finance:
            VStack(alignment: .leading, spacing: 12) {
                heroCard
                financeTrackingCard
            }
        case .digital:
            VStack(alignment: .leading, spacing: 12) {
                digitalTrackingCard
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedSection.title)
                .font(.title.bold())

            Text(selectedSection.description)
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            HStack(spacing: 12) {
                Label("Avatar", systemImage: "person.crop.square")
                Label("Signals", systemImage: "waveform.path.ecg")
                Label("Tracking", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var overallScoreCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overall Score")
                .font(.title3.bold())

            Text("Drake's mood comes from your finance, carbon, and digital scores combined.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            HStack(spacing: 12) {
                summaryPill(title: "Finance", value: "\(financeScore)", tint: .orange)
                summaryPill(title: "Carbon", value: "\(carbonScore)", tint: .green)
                summaryPill(title: "Digital", value: "\(digitalScore)", tint: .blue)
            }

            dashboardRow(title: "Mood logic", detail: overallGuidance, tint: selectedMood.tint)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var geminiReactionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gemini Reaction")
                    .font(.title3.bold())
                Spacer()
                if isCallingGemini {
                    ProgressView()
                        .tint(.white)
                }
            }

            Text(geminiMoodText)
                .font(.body)
                .foregroundStyle(secondaryText)

            Button(isCallingGemini ? "Generating..." : "Generate Drake Update") {
                Task {
                    await generateGeminiPreview()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(geminiAPIKey.isEmpty || isCallingGemini)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var notionLogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notion Log")
                    .font(.title3.bold())
                Spacer()
                if isCallingNotion {
                    ProgressView()
                        .tint(.white)
                }
            }

            Text("Save today's mood, scores, and tracked inputs as a new entry in your connected Notion database.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            Text(notionLogPreview)
                .font(.footnote)
                .foregroundStyle(secondaryText)
                .lineLimit(7)

            Button(isCallingNotion ? "Saving..." : "Save Daily Log to Notion") {
                Task {
                    await sendNotionPreview()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(notionToken.isEmpty || notionDatabaseID.isEmpty || isCallingNotion)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var healthBarsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Health Bars")
                .font(.title3.bold())

            healthBar(title: "Overall", value: overallScore, tint: selectedMood.tint)
            healthBar(title: "Finance", value: financeScore, tint: .orange)
            healthBar(title: "Carbon", value: carbonScore, tint: .green)
            healthBar(title: "Digital", value: digitalScore, tint: .blue)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var fidgetSpinnerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fidget Spinner")
                .font(.title3.bold())

            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 118, height: 118)

                    Circle()
                        .fill(Color.cyan.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .offset(y: -40)

                    Circle()
                        .fill(Color.pink.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .offset(x: -34, y: 22)

                    Circle()
                        .fill(Color.orange.opacity(0.75))
                        .frame(width: 34, height: 34)
                        .offset(x: 34, y: 22)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                }
                .rotationEffect(.degrees(spinnerRotation))
                Spacer()
            }

            Button("Spin") {
                withAnimation(.interpolatingSpring(stiffness: 38, damping: 7)) {
                    spinnerRotation += Double.random(in: 540 ... 1440)
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var carbonOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Carbon Snapshot")
                .font(.title3.bold())

            Text("Estimated daily footprint: \(carbonFootprintKg.formatted(.number.precision(.fractionLength(1)))) kg CO2e")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            dashboardRow(title: "Biggest source", detail: largestCarbonSource, tint: .green)
            dashboardRow(title: "Carbon mood", detail: carbonGuidance, tint: .mint)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var dailyPulseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Pulse")
                .font(.title3.bold())

            dashboardRow(title: "Financial pressure", detail: "Food, clothes, and extracurricular costs are shaping today's budget.", tint: .orange)
            dashboardRow(title: "Carbon load", detail: carbonGuidance, tint: .green)
            dashboardRow(title: "Digital load", detail: "High engagement but still stable", tint: .blue)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile")
                .font(.title3.bold())

            Text("Set up your account, connect services, and manage the app configuration here.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var carbonTrackingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Track Carbon Footprint")
                .font(.title3.bold())

            Text("This estimate combines travel, streaming, food, and flights into a daily carbon score.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            metricSlider(title: "Car miles", value: $carMiles, range: 0 ... 80, step: 1, tint: .green)
            metricSlider(title: "Transit miles", value: $transitMiles, range: 0 ... 60, step: 1, tint: .mint)
            metricSlider(title: "Streaming hours", value: $streamingHours, range: 0 ... 12, step: 0.5, tint: .blue)

            Stepper("Meat-based meals: \(meatMeals)", value: $meatMeals, in: 0 ... 6)
            Stepper("Flights this month: \(flightsThisMonth)", value: $flightsThisMonth, in: 0 ... 8)

            Divider()

            carbonBreakdownRow(title: "Car travel", value: carCarbonKg)
            carbonBreakdownRow(title: "Transit", value: transitCarbonKg)
            carbonBreakdownRow(title: "Streaming", value: streamingCarbonKg)
            carbonBreakdownRow(title: "Meals", value: mealsCarbonKg)
            carbonBreakdownRow(title: "Flights", value: flightCarbonKg)

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("\(carbonFootprintKg.formatted(.number.precision(.fractionLength(1)))) kg CO2e")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var financeTrackingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Track Finances")
                .font(.title3.bold())

            Text("Finance score tracks spending on food, clothes, and extracurriculars.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            metricSlider(title: "Food", value: $foodSpend, range: 0 ... 200, step: 5, tint: .orange, prefix: "$")
            metricSlider(title: "Clothes", value: $clothesSpend, range: 0 ... 400, step: 10, tint: .pink, prefix: "$")
            metricSlider(title: "Extracurriculars", value: $extracurricularSpend, range: 0 ... 300, step: 5, tint: .purple, prefix: "$")

            Divider()

            scoreBreakdownRow(title: "Food pressure", value: foodSpend * 0.18)
            scoreBreakdownRow(title: "Clothes pressure", value: clothesSpend * 0.12)
            scoreBreakdownRow(title: "Extracurricular pressure", value: extracurricularSpend * 0.15)

            Divider()

            HStack {
                Text("Finance score")
                    .font(.headline)
                Spacer()
                Text("\(financeScore)")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var digitalTrackingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Track Digital Load")
                .font(.title3.bold())

            Text("Digital score tracks screen time, social media, AI prompts, and streaming load.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            metricSlider(title: "Screen hours", value: $screenHours, range: 0 ... 16, step: 0.5, tint: .blue)
            metricSlider(title: "Social hours", value: $socialHours, range: 0 ... 10, step: 0.5, tint: .cyan)
            Stepper("AI prompts: \(aiPrompts)", value: $aiPrompts, in: 0 ... 60)

            Divider()

            scoreBreakdownRow(title: "Screen load", value: screenHours * 2.8)
            scoreBreakdownRow(title: "Social load", value: socialHours * 4.0)
            scoreBreakdownRow(title: "AI load", value: Double(aiPrompts) * 0.9)
            scoreBreakdownRow(title: "Streaming load", value: streamingHours * 1.4)

            Divider()

            HStack {
                Text("Digital score")
                    .font(.headline)
                Spacer()
                Text("\(digitalScore)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var integrationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Required Integrations")
                .font(.title3.bold())

            Text("Gemini and Notion are included in the app architecture now. Notion saves each daily log as a new page inside a database.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)

            SecureField("Gemini API Key", text: $geminiAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .profileFieldStyle()

            SecureField("Notion Token", text: $notionToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .profileFieldStyle()

            TextField("Notion Database ID", text: $notionDatabaseID)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .profileFieldStyle()

            HStack(spacing: 12) {
                Button(isCallingGemini ? "Connecting..." : "Test Gemini") {
                    Task {
                        await generateGeminiPreview()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(geminiAPIKey.isEmpty || isCallingGemini)

                Button(isCallingNotion ? "Connecting..." : "Test Notion") {
                    Task {
                        await sendNotionPreview()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(notionToken.isEmpty || notionDatabaseID.isEmpty || isCallingNotion)
            }

            Label(integrationStatus, systemImage: "link.badge.plus")
                .font(.footnote)
                .foregroundStyle(secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var characterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CharacterPixelCard(mood: selectedMood)
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var moodDialogueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How Drake's Feeling")
                .font(.title3.bold())

            Text(selectedMoodDialogue)
                .font(.body)
                .foregroundStyle(secondaryText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var bottomIslandBar: some View {
        HStack(spacing: 10) {
            ForEach(DashboardSection.islandItems) { section in
                Button {
                    selectedSection = section
                } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: section.systemImage)
                                .font(.system(size: 16, weight: .semibold))

                            if section == .home && homeNotificationPending {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -2)
                            }
                        }
                        Text(section.title)
                            .font(.caption2.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(section == selectedSection ? Color.white : Color.white.opacity(0.72))
                    .background(
                        Group {
                            if section == selectedSection {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.18))
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(islandFill, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private var animatedWallpaper: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.10),
                    Color(red: 0.02, green: 0.06, blue: 0.18),
                    Color(red: 0.07, green: 0.13, blue: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.18, green: 0.32, blue: 0.96).opacity(0.42))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(x: wallpaperPhase ? 120 : 40, y: wallpaperPhase ? -160 : -60)

            Circle()
                .fill(Color(red: 0.52, green: 0.90, blue: 1.00).opacity(0.34))
                .frame(width: 280, height: 280)
                .blur(radius: 42)
                .offset(x: wallpaperPhase ? 170 : 240, y: wallpaperPhase ? 10 : -80)

            RoundedRectangle(cornerRadius: 140, style: .continuous)
                .fill(Color(red: 0.10, green: 0.18, blue: 0.76).opacity(0.30))
                .frame(width: 280, height: 420)
                .blur(radius: 56)
                .rotationEffect(.degrees(wallpaperPhase ? -32 : -18))
                .offset(x: wallpaperPhase ? -120 : -170, y: wallpaperPhase ? 0 : 80)

            RoundedRectangle(cornerRadius: 140, style: .continuous)
                .fill(Color(red: 0.46, green: 0.86, blue: 1.00).opacity(0.26))
                .frame(width: 220, height: 360)
                .blur(radius: 54)
                .rotationEffect(.degrees(wallpaperPhase ? 18 : 30))
                .offset(x: wallpaperPhase ? 150 : 100, y: wallpaperPhase ? -120 : -10)
        }
        .overlay(Color.black.opacity(0.18))
        .ignoresSafeArea()
    }

    private var carCarbonKg: Double {
        carMiles * 0.40
    }

    private var transitCarbonKg: Double {
        transitMiles * 0.14
    }

    private var streamingCarbonKg: Double {
        streamingHours * 0.06
    }

    private var mealsCarbonKg: Double {
        Double(meatMeals) * 1.9
    }

    private var flightCarbonKg: Double {
        Double(flightsThisMonth) * 3.5
    }

    private var carbonFootprintKg: Double {
        carCarbonKg + transitCarbonKg + streamingCarbonKg + mealsCarbonKg + flightCarbonKg
    }

    private var carbonScore: Int {
        let rawScore = 100 - (carbonFootprintKg * 4.5)
        return max(0, min(100, Int(rawScore.rounded())))
    }

    private var financeScore: Int {
        let spendingPressure = (foodSpend * 0.18) + (clothesSpend * 0.12) + (extracurricularSpend * 0.15)
        let rawScore = 100 - spendingPressure
        return max(0, min(100, Int(rawScore.rounded())))
    }

    private var digitalScore: Int {
        let usagePressure = (screenHours * 2.8) + (socialHours * 4.0) + (Double(aiPrompts) * 0.9) + (streamingHours * 1.4)
        let rawScore = 100 - usagePressure
        return max(0, min(100, Int(rawScore.rounded())))
    }

    private var overallScore: Int {
        Int(((Double(financeScore) * 0.3) + (Double(carbonScore) * 0.4) + (Double(digitalScore) * 0.3)).rounded())
    }

    private var selectedMood: CharacterMood {
        switch overallScore {
        case 75...:
            return .thriving
        case 45...:
            return .struggling
        default:
            return .critical
        }
    }

    private var largestCarbonSource: String {
        let sources: [(String, Double)] = [
            ("Car travel is leading today’s footprint.", carCarbonKg),
            ("Public transit is a noticeable contributor.", transitCarbonKg),
            ("Flights are dominating the footprint.", flightCarbonKg),
            ("Food choices are adding the most carbon.", mealsCarbonKg),
            ("Streaming is the smallest but still measurable load.", streamingCarbonKg)
        ]

        return sources.max(by: { $0.1 < $1.1 })?.0 ?? "No carbon sources tracked yet."
    }

    private var carbonGuidance: String {
        switch carbonScore {
        case 80...:
            return "Low-impact day. You’re keeping emissions under control."
        case 55...:
            return "Moderate-impact day. One or two habits are pushing the footprint up."
        default:
            return "High-impact day. Travel or food choices are putting pressure on the score."
        }
    }

    private var overallGuidance: String {
        switch selectedMood {
        case .thriving:
            return "Strong combined habits keep Drake energized and performance-ready."
        case .struggling:
            return "Mixed signals are pulling Drake into a more strained state."
        case .critical:
            return "Finance, carbon, or digital overload is pushing Drake into recovery mode."
        }
    }

    private var selectedMoodDialogue: String {
        switch selectedMood {
        case .thriving:
            return "Drake feels locked in, light on his feet, and ready to own the day. The numbers are working in his favor, so his energy is high and the pressure feels manageable."
        case .struggling:
            return "Drake is holding it together, but he can feel the strain building. A few habits are dragging on his momentum, and he's trying not to let the pressure show too much."
        case .critical:
            return "Drake feels drained and overloaded. The combined weight of finance, carbon, and digital stress is catching up, and he needs a reset before he burns out."
        }
    }

    private var notionLogEntry: String {
        """
        MeloDOOM Daily Log

        Date: \(formattedLogDate)
        Mood: \(selectedMood.title)
        Overall Score: \(overallScore)
        Finance Score: \(financeScore)
        Carbon Score: \(carbonScore)
        Digital Score: \(digitalScore)

        Finance Inputs
        Food: $\(Int(foodSpend.rounded()))
        Clothes: $\(Int(clothesSpend.rounded()))
        Extracurriculars: $\(Int(extracurricularSpend.rounded()))

        Carbon Inputs
        Car Miles: \(Int(carMiles.rounded()))
        Transit Miles: \(Int(transitMiles.rounded()))
        Streaming Hours: \(streamingHours.formatted(.number.precision(.fractionLength(1))))
        Meat-Based Meals: \(meatMeals)
        Flights This Month: \(flightsThisMonth)

        Digital Inputs
        Screen Hours: \(screenHours.formatted(.number.precision(.fractionLength(1))))
        Social Hours: \(socialHours.formatted(.number.precision(.fractionLength(1))))
        AI Prompts: \(aiPrompts)

        Mood Summary
        \(selectedMoodDialogue)

        Gemini Summary
        \(geminiSummaryForNotion)
        """
    }

    private var notionLogTitle: String {
        "MeloDOOM \(formattedLogDate) • \(selectedMood.title)"
    }

    private var notionLogPreview: String {
        """
        \(formattedLogDate) • \(selectedMood.title) • Overall \(overallScore)
        Finance \(financeScore) • Carbon \(carbonScore) • Digital \(digitalScore)
        """
    }

    private var geminiSummaryForNotion: String {
        let trimmedText = geminiMoodText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty || trimmedText == defaultGeminiPromptText {
            return "No Gemini summary generated yet."
        }
        return trimmedText
    }

    private var formattedLogDate: String {
        notionLastSavedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func notionDailyLog(savedAt: Date) -> NotionDailyLog {
        NotionDailyLog(
            title: "MeloDOOM \(savedAt.formatted(date: .abbreviated, time: .shortened)) • \(selectedMood.title)",
            loggedAt: savedAt,
            mood: selectedMood.title,
            overallScore: overallScore,
            financeScore: financeScore,
            carbonScore: carbonScore,
            digitalScore: digitalScore,
            foodSpend: foodSpend,
            clothesSpend: clothesSpend,
            extracurricularSpend: extracurricularSpend,
            carMiles: carMiles,
            transitMiles: transitMiles,
            streamingHours: streamingHours,
            meatMeals: meatMeals,
            flightsThisMonth: flightsThisMonth,
            screenHours: screenHours,
            socialHours: socialHours,
            aiPrompts: aiPrompts,
            moodSummary: selectedMoodDialogue,
            geminiSummary: geminiSummaryForNotion,
            content: """
            MeloDOOM Daily Log

            Date: \(savedAt.formatted(date: .abbreviated, time: .shortened))
            Mood: \(selectedMood.title)
            Overall Score: \(overallScore)
            Finance Score: \(financeScore)
            Carbon Score: \(carbonScore)
            Digital Score: \(digitalScore)

            Finance Inputs
            Food: $\(Int(foodSpend.rounded()))
            Clothes: $\(Int(clothesSpend.rounded()))
            Extracurriculars: $\(Int(extracurricularSpend.rounded()))

            Carbon Inputs
            Car Miles: \(Int(carMiles.rounded()))
            Transit Miles: \(Int(transitMiles.rounded()))
            Streaming Hours: \(streamingHours.formatted(.number.precision(.fractionLength(1))))
            Meat-Based Meals: \(meatMeals)
            Flights This Month: \(flightsThisMonth)

            Digital Inputs
            Screen Hours: \(screenHours.formatted(.number.precision(.fractionLength(1))))
            Social Hours: \(socialHours.formatted(.number.precision(.fractionLength(1))))
            AI Prompts: \(aiPrompts)

            Mood Summary
            \(selectedMoodDialogue)

            Gemini Summary
            \(geminiSummaryForNotion)
            """
        )
    }

    private var geminiMoodPrompt: String {
        """
        You are writing a short fictional update for a Drake-inspired tamagotchi app character.

        Current mood: \(selectedMood.title)
        Overall score: \(overallScore)
        Finance score: \(financeScore)
        Carbon score: \(carbonScore)
        Digital score: \(digitalScore)

        Write 2 short sentences in first person that match the mood. Keep it playful, reflective, and clearly fictional. Do not claim to be the real Drake.
        """
    }

    private func metricSlider(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, tint: Color, prefix: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(prefix)\(value.wrappedValue.formatted(.number.precision(.fractionLength(step < 1 ? 1 : 0))))")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
            }

            Slider(value: value, in: range, step: step)
            .tint(tint)
        }
    }

    private func carbonBreakdownRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text("\(value.formatted(.number.precision(.fractionLength(1)))) kg")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
        }
    }

    private func scoreBreakdownRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value.formatted(.number.precision(.fractionLength(1))))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(secondaryText)
        }
    }

    private func healthBar(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))

            HStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.12))

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tint)
                            .frame(width: geometry.size.width * CGFloat(value) / 100)
                    }
                }
                .frame(height: 10)

                Text("\(value)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(secondaryText)

                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
            }
            .frame(height: 12)
        }
    }

    private func summaryPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(secondaryText)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func dashboardRow(title: String, detail: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var primaryText: Color {
        .white
    }

    private var secondaryText: Color {
        Color.white.opacity(0.78)
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.28)
    }

    private var islandFill: Color {
        colorScheme == .dark ? Color.black.opacity(0.92) : Color.black.opacity(0.88)
    }
}

#Preview {
    ContentView()
}

private extension View {
    func profileFieldStyle() -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.38))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .foregroundStyle(Color.white)
            .tint(.white)
    }
}

private enum CharacterMood: String, CaseIterable, Identifiable {
    case thriving
    case struggling
    case critical

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var assetName: String {
        switch self {
        case .thriving:
            return "happy"
        case .struggling:
            return "Sad"
        case .critical:
            return "Really Sad"
        }
    }

    var title: String {
        switch self {
        case .thriving:
            return "Thriving"
        case .struggling:
            return "Sad"
        case .critical:
            return "Critical"
        }
    }

    var description: String {
        switch self {
        case .thriving:
            return "The character looks energized, clean, and ready to perform."
        case .struggling:
            return "The character is still holding it together, but the pressure is showing."
        case .critical:
            return "The character is depleted and needs a reset from high-impact choices."
        }
    }

    var tint: Color {
        switch self {
        case .thriving:
            return .green
        case .struggling:
            return .orange
        case .critical:
            return .red
        }
    }

    var backdrop: [Color] {
        switch self {
        case .thriving:
            return [Color(red: 0.89, green: 0.98, blue: 0.86), Color(red: 0.76, green: 0.92, blue: 0.78)]
        case .struggling:
            return [Color(red: 0.99, green: 0.93, blue: 0.74), Color(red: 0.95, green: 0.77, blue: 0.51)]
        case .critical:
            return [Color(red: 0.99, green: 0.84, blue: 0.84), Color(red: 0.92, green: 0.58, blue: 0.55)]
        }
    }

    var shadow: Color {
        switch self {
        case .thriving:
            return Color.green.opacity(0.28)
        case .struggling:
            return Color.orange.opacity(0.24)
        case .critical:
            return Color.red.opacity(0.24)
        }
    }
}

private enum DashboardSection: String, CaseIterable, Identifiable {
    case profile
    case finance
    case home
    case carbon
    case digital

    var id: String { rawValue }

    static let islandItems: [DashboardSection] = [.profile, .finance, .home, .carbon, .digital]

    var title: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .profile:
            return "Use this area for account setup, persona selection, preferences, and personal stats."
        case .home:
            return "Use this area for the combined summary across finance, carbon, digital, and character mood."
        case .finance:
            return "Use this area for purchases, ticket spending, merch, subscriptions, and budget signals."
        case .carbon:
            return "Use this area to log daily carbon-related activity and watch your footprint score change."
        case .digital:
            return "Use this area for social use, AI usage, content creation, and attention metrics."
        }
    }

    var tint: Color {
        switch self {
        case .profile:
            return .gray
        case .home:
            return .indigo
        case .finance:
            return .orange
        case .carbon:
            return .green
        case .digital:
            return .blue
        }
    }

    var systemImage: String {
        switch self {
        case .profile:
            return "person.crop.circle.fill"
        case .home:
            return "house.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .carbon:
            return "leaf.fill"
        case .digital:
            return "iphone.gen3"
        }
    }
}

private struct CharacterPixelCard: View {
    let mood: CharacterMood

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: mood.backdrop,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if mood == .thriving {
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: 72, height: 14)
                    .offset(y: 44)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 6)
                avatarContent
                    .padding(.horizontal, 4)
                    .offset(y: mood == .thriving ? -12 : 0)
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    Circle()
                        .fill(mood.tint)
                        .frame(width: 10, height: 10)
                    Text(mood.label.uppercased())
                        .font(.caption2.weight(.black))
                        .tracking(1)
                        .foregroundStyle(Color.black.opacity(0.72))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.55), in: Capsule())
                .padding(.bottom, 10)
            }
        }
        .shadow(color: mood.shadow, radius: 14, y: 8)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let image = UIImage(named: mood.assetName) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            PixelSpriteView(rows: spriteRows)
        }
    }

    private var spriteRows: [[SpriteCell]] {
        switch mood {
        case .thriving:
            return [
                [.clear, .clear, .clear, .outline, .outline, .outline, .outline, .outline, .outline, .clear, .clear, .clear],
                [.clear, .clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear, .clear],
                [.clear, .clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear, .clear],
                [.clear, .clear, .outline, .skin, .eyeWhite, .eyeWhite, .skin, .eyeWhite, .eyeWhite, .outline, .clear, .clear],
                [.clear, .clear, .outline, .skin, .eyeWhite, .pupil, .skin, .eyeWhite, .pupil, .outline, .clear, .clear],
                [.clear, .clear, .outline, .skin, .skin, .smile, .smile, .skin, .skin, .outline, .clear, .clear],
                [.clear, .outline, .skin, .skin, .beard, .beard, .beard, .beard, .skin, .skin, .outline, .clear],
                [.outline, .jacket, .jacket, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .jacket, .jacket, .outline],
                [.clear, .outline, .jacket, .jacket, .shirt, .mark, .mark, .shirt, .jacket, .jacket, .outline, .clear],
                [.clear, .clear, .outline, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .outline, .clear, .clear],
                [.clear, .outline, .skin, .jacketDark, .skin, .shirt, .shirt, .skin, .jacketDark, .skin, .outline, .clear],
                [.outline, .jacket, .clear, .clear, .pants, .clear, .clear, .pants, .clear, .clear, .jacket, .outline],
                [.clear, .outline, .clear, .pants, .pants, .clear, .clear, .pants, .pants, .clear, .outline, .clear],
                [.clear, .clear, .outline, .pants, .clear, .clear, .clear, .clear, .pants, .outline, .clear, .clear],
                [.clear, .outline, .boot, .boot, .clear, .clear, .clear, .clear, .boot, .boot, .outline, .clear],
                [.clear, .clear, .outline, .clear, .boot, .boot, .boot, .boot, .clear, .outline, .clear, .clear]
            ]
        case .struggling:
            return [
                [.clear, .clear, .outline, .outline, .outline, .outline, .outline, .outline, .outline, .outline, .clear, .clear],
                [.clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear],
                [.clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear],
                [.clear, .outline, .skin, .skin, .eyeWhite, .eyeWhite, .skin, .eyeWhite, .eyeWhite, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .eyeWhite, .pupil, .skin, .eyeWhite, .pupil, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .frown, .skin, .skin, .frown, .skin, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .beard, .beard, .beard, .beard, .skin, .skin, .outline, .clear],
                [.clear, .outline, .jacket, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .jacket, .outline, .clear],
                [.clear, .outline, .jacket, .jacket, .shirt, .mark, .mark, .shirt, .jacket, .jacket, .outline, .clear],
                [.clear, .outline, .jacket, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .jacket, .outline, .clear],
                [.clear, .outline, .jacketDark, .skin, .skin, .shirt, .shirt, .skin, .skin, .jacketDark, .outline, .clear],
                [.clear, .clear, .outline, .jacket, .clear, .clear, .clear, .clear, .jacket, .outline, .clear, .clear],
                [.clear, .clear, .outline, .pants, .pants, .clear, .clear, .pants, .pants, .outline, .clear, .clear],
                [.clear, .clear, .outline, .pants, .pants, .clear, .clear, .pants, .pants, .outline, .clear, .clear],
                [.clear, .clear, .clear, .outline, .pants, .outline, .outline, .pants, .outline, .clear, .clear, .clear],
                [.clear, .clear, .outline, .boot, .boot, .clear, .clear, .boot, .boot, .outline, .clear, .clear]
            ]
        case .critical:
            return [
                [.clear, .clear, .outline, .outline, .outline, .outline, .outline, .outline, .outline, .outline, .clear, .clear],
                [.clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear],
                [.clear, .outline, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .hair, .outline, .clear],
                [.clear, .outline, .skin, .skin, .eyeWhite, .eyeWhite, .skin, .eyeWhite, .eyeWhite, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .pupil, .eyeWhite, .skin, .eyeWhite, .pupil, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .frown, .frown, .frown, .frown, .skin, .skin, .outline, .clear],
                [.clear, .outline, .skin, .skin, .beard, .beard, .beard, .beard, .skin, .skin, .outline, .clear],
                [.clear, .outline, .jacketDark, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .jacketDark, .outline, .clear],
                [.clear, .outline, .jacketDark, .jacket, .shirt, .mark, .mark, .shirt, .jacket, .jacketDark, .outline, .clear],
                [.clear, .outline, .jacketDark, .jacket, .shirt, .shirt, .shirt, .shirt, .jacket, .jacketDark, .outline, .clear],
                [.clear, .clear, .outline, .skin, .skin, .shirt, .shirt, .skin, .skin, .outline, .clear, .clear],
                [.clear, .clear, .outline, .jacketDark, .clear, .clear, .clear, .clear, .jacketDark, .outline, .clear, .clear],
                [.clear, .clear, .outline, .pants, .pants, .clear, .clear, .pants, .pants, .outline, .clear, .clear],
                [.clear, .clear, .outline, .pants, .pants, .clear, .clear, .pants, .pants, .outline, .clear, .clear],
                [.clear, .clear, .clear, .outline, .pants, .clear, .clear, .pants, .outline, .clear, .clear, .clear],
                [.clear, .clear, .outline, .boot, .clear, .clear, .clear, .clear, .boot, .outline, .clear, .clear]
            ]
        }
    }
}

private struct PixelSpriteView: View {
    let rows: [[SpriteCell]]

    var body: some View {
        GeometryReader { geometry in
            let pixel = min(geometry.size.width / 12, geometry.size.height / 16)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Rectangle()
                                .fill(cell.color)
                                .frame(width: pixel, height: pixel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(12.0 / 16.0, contentMode: .fit)
        .drawingGroup()
    }
}

private enum SpriteCell {
    case clear
    case outline
    case hair
    case skin
    case eyeWhite
    case pupil
    case beard
    case jacket
    case jacketDark
    case shirt
    case mark
    case smile
    case frown
    case pants
    case boot

    var color: Color {
        switch self {
        case .clear:
            return .clear
        case .outline:
            return Color.black.opacity(0.9)
        case .hair:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        case .skin:
            return Color(red: 0.74, green: 0.55, blue: 0.43)
        case .eyeWhite:
            return Color.white
        case .pupil:
            return Color.black
        case .beard:
            return Color(red: 0.32, green: 0.22, blue: 0.17)
        case .jacket:
            return Color(red: 0.86, green: 0.12, blue: 0.14)
        case .jacketDark:
            return Color(red: 0.63, green: 0.08, blue: 0.10)
        case .shirt:
            return Color(red: 0.98, green: 0.97, blue: 0.93)
        case .mark:
            return Color.black
        case .smile:
            return Color(red: 0.55, green: 0.19, blue: 0.22)
        case .frown:
            return Color(red: 0.36, green: 0.16, blue: 0.18)
        case .pants:
            return Color(red: 0.67, green: 0.82, blue: 0.95)
        case .boot:
            return Color(red: 0.78, green: 0.62, blue: 0.37)
        }
    }
}

# Melodoom 🎵

> An AI-powered virtual companion app where your favorite music icon reacts to your daily carbon, financial, and digital footprint — built in 10 hours at Hacklanta 2026.

---

## What is Melodoom?

Melodoom is a single-screen iOS app inspired by the nostalgia of Tamagotchi and the cultural pull of music icons. Each user adopts a digital artist character — Drake, Beyoncé, or SZA — whose health, mood, and reactions are tied directly to the choices they make every day.

The better your footprint, the more your artist thrives. The worse your choices, the more they suffer — and they'll let you know about it, in their own voice.

---

## Screens

| Screen | Purpose |
|---|---|
| **Home** | Battle-style character display — shows artist mood, HP bar, vibe bar, and Gemini's dialogue response |
| **Carbon** | Log daily transport, energy use, and food choices |
| **Finance** | Log spending category, daily amount, and impulse purchases |
| **Digital** | Log screen time, streaming hours, and device charging habits |
| **Profile** | User info and selected artist character |

---

## How It Works

1. User opens the app and sees their music icon character on the Home screen
2. User taps one of the three input buttons — Carbon, Finance, or Digital
3. User answers simple tap and slider questions about their day
4. Inputs are scored LOW / MEDIUM / HIGH per category
5. Scores are sent to the Gemini API with a custom system prompt
6. Gemini determines a mood state and generates a short response in the artist's voice
7. The character's visual state updates — color, animation, HP bar — to reflect the mood
8. The response appears in the dialogue box on the Home screen

---

## Mood States

| Mood | Trigger | Visual |
|---|---|---|
| **THRIVING** | Majority of scores LOW | Full color saturation, scale pulse animation, gold particles |
| **STRUGGLING** | Mixed scores or one HIGH | 50% saturation, slow opacity breathe, amber tint |
| **CRITICAL** | Two or more scores HIGH | Near-full desaturation, red tint, screen shake on appear |

---

## Tech Stack

| Layer | Tool |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Target OS | iOS 26 |
| Dependencies | Swift Package Manager |
| AI | Google Gemini API (gemini-1.5-flash) |
| Backend | Notion API *(post-hackathon)* |
| Local Cache | UserDefaults |
| Character Art | Transparent PNG sprite |

---

## Gemini Prompt Structure

The Gemini integration uses a two-part prompt:

**System instruction** — defines the artist's personality, tone, and mood logic. Never changes between calls.

**User message** — built dynamically from the user's scored inputs:

```
Today's footprint check-in:
- Carbon impact: LOW | MEDIUM | HIGH
- Financial impact: LOW | MEDIUM | HIGH
- Digital impact: LOW | MEDIUM | HIGH
```

**Required output — always JSON:**

```json
{
  "mood": "THRIVING" | "STRUGGLING" | "CRITICAL",
  "message": "string — max 20 words in the artist's voice"
}
```

---

## Input Scoring

```swift
// Carbon
// 0 = walked/biked → LOW
// 1 = transit      → LOW
// 2 = drove alone  → MEDIUM
// 3 = flew         → HIGH

// Financial
// 0-1 = no spend / essentials → LOW
// 2   = some discretionary    → MEDIUM
// 3   = heavy spend           → HIGH

// Digital (hours)
// 0-2 = LOW
// 3-5 = MEDIUM
// 6+  = HIGH
```

---

## Project Structure

```
Melodoom/
├── MelodoomApp.swift
├── ContentView.swift
├── Models/
│   ├── Artist.swift
│   └── LyraResponse.swift
├── Services/
│   ├── GeminiService.swift
│   └── NotionService.swift
├── ViewModels/
│   └── MelodoomViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── CarbonView.swift
│   ├── FinanceView.swift
│   ├── DigitalView.swift
│   ├── ProfileView.swift
│   ├── CharacterView.swift
│   └── LyraMessageView.swift
└── Utilities/
    └── ScoreMapper.swift
```

---

## API Key Setup

Never hardcode API keys. Store them in `Config.xcconfig` and add it to `.gitignore` immediately.

```
// Config.xcconfig
GEMINI_API_KEY = your_key_here
NOTION_API_KEY = your_key_here
NOTION_DATABASE_ID = your_database_id_here
```

Access in code:

```swift
let geminiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
```

---

## Artists

| Artist | Personality | Accent Color |
|---|---|---|
| **Drake** | Warm but honest, OVO confidence, music metaphors | Gold `#c8a951` |
| **Beyoncé** | Regal, direct, holds you accountable | Amber `#f5c842` |
| **SZA** | Reflective, poetic, emotionally intelligent | Purple `#b07aff` |

---

## Current Status

| Feature | Status |
|---|---|
| Home screen — character + mood display | ✅ Built |
| Carbon input screen | ✅ Built |
| Finance input screen | ✅ Built |
| Digital input screen | ✅ Built |
| Profile screen | ✅ Built |
| Gemini API integration | ✅ Built |
| SwiftUI mood animations | ✅ Built |
| Notion backend logging | 🔜 Post-hackathon |
| User authentication | 🔜 Post-hackathon |
| Additional artist characters | 🔜 Post-hackathon |
| Community dashboard | 🔜 Post-hackathon |
| Push notifications | 🔜 Post-hackathon |

---

## Fallback Responses

Hardcoded for demo reliability — used when Gemini call fails or WiFi drops:

```swift
let fallbackResponses: [MoodState: LyraResponse] = [
    .thriving:   LyraResponse(mood: "THRIVING",
                   message: "Today you moved like the opening note. Clean, intentional, alive."),
    .struggling: LyraResponse(mood: "STRUGGLING",
                   message: "Even great sets have an off night. Tomorrow we tune back up."),
    .critical:   LyraResponse(mood: "CRITICAL",
                   message: "The signal is breaking up. I need you to make some changes.")
]
```

---

## Built At

**Hacklanta 2026** — Social Good · Startup · Most Creative

---

## License

MIT

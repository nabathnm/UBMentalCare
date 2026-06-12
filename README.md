# UBMentalCare

Noresah (UBMentalCare) is a Flutter-based mobile application designed as a comprehensive digital platform to support student mental health at Universitas Brawijaya (UB). The application connects students with psychological experts from LKM UB (Layanan Konseling Mahasiswa) and provides initial mitigation and coping strategies for psychological distress through an AI-powered chatbot called **ResahAI**.

Built using a clean, modular feature-first architecture, Noresah leverages **Supabase** for secure authentication and backend database management, and **Google Generative AI (Gemini)** to drive its empathetic conversational agent.

---

## 📱 Core Features

### 🔐 Authentication & Role-Based Access
*   **UB Student Login:** Students log in using their official UB credential email format (`*@student.ub.ac.id`).
*   **LKM UB Psychologist Login:** Psychologists access their portal using their verified UB staff email format (`*@psychologist.ub.ac.id`).
*   **Session Security:** Handled seamlessly and securely through Supabase Auth.
*   **Onboarding Flow:** Dynamic onboarding questionnaires for students to set up their profile preferences and mental health baseline.

### 🤖 ResahAI (Empathetic AI Chatbot)
*   **Initial Mitigation:** Conversational support acts as the first line of defense for students experiencing anxiety, stress, or panic.
*   **Distress Level Detection:** The AI automatically analyzes the tone and sentiment of the conversation to categorize the user's distress level into four tiers: **Aman (Safe)**, **Waspada (Alert)**, **Khawatir (Anxious)**, and **Kritis (Critical)**.
*   **Conversation History:** Easily access, view, and continue past interactions with ResahAI.
*   **Rich Text Support:** Seamless rendering of markdown responses from Gemini.

### 🚨 Emergency Call (Call Darurat)
*   **Automatic Activation:** An emergency banner and quick-access emergency call button automatically trigger on the UI if the student's distress level escalates to **Kritis (Critical)** or if emergency keywords are detected in the conversation.
*   **Location Integration:** Automatically retrieves and sends the user's current coordinates to emergency services when initiating the call.
*   **Direct Hotline:** Instant connection to university security/medical clinics and emergency hotlines.

### 💬 Anonymous Community Q&A Forum
*   **Privacy-First Posting:** Students can post their mental health questions completely anonymously to protect their Personally Identifiable Information (PII).
*   **Verified Replies:** Only licensed LKM UB psychologists can write replies and answer posts, ensuring professional advice.
*   **Public Read Feed:** Other students can browse the questions and answers to find comfort in shared experiences.

### 📅 Consultation Booking System
*   **Psychologist Schedule Browser:** Students can view real-time availability and weekly slots of LKM UB psychologists.
*   **Appointment Booking:** Students can schedule 1-on-1 counseling sessions. Bookings are automatically capped when a slot is full.
*   **Psychologist Workflow:** Psychologists can view incoming appointment requests on their dashboard and confirm or manage their schedule.

### 📊 Mood Tracker & Journaling
*   **Daily Mood Logger:** Students track their daily emotional state using intuitive emojis: *Sedih* (Sad), *Biasa* (Neutral), *Senang* (Happy), *Gembira* (Joyful), and *Bahagia* (Excited).
*   **Mood Status Display:** The user's current mental status is prominently displayed on the dashboard.
*   **Chronological Journaling:** A private space for students to write down their thoughts. Features full Create, Read, Update, and Delete (CRUD) capability, with list entries grouped by date.

---

## 🛠️ Tech Stack & Key Libraries

*   **Frontend Framework:** Flutter (Dart SDK `^3.11.5`)
*   **Backend-as-a-Service:** [Supabase Flutter](https://pub.dev/packages/supabase_flutter) (Database, Authentication, Storage)
*   **AI Engine (Hybrid & Fallback):**
    *   **Primary:** Groq API (using `llama-3.3-70b-versatile`)
    *   **Fallback:** Google Generative AI (Gemini API via `google_generative_ai`)
*   **State Management:** [Provider](https://pub.dev/packages/provider) (Clean separation of state and UI components)
*   **Content Renderer:** [Flutter Markdown](https://pub.dev/packages/flutter_markdown)
*   **Hardware / Device Utilities:**
    *   [url_launcher](https://pub.dev/packages/url_launcher) (Handling emergency dialing and scheduling calls)
    *   [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) (Loading local configuration keys securely)
    *   [intl](https://pub.dev/packages/intl) (Date and currency formatting)

---

## 🎨 Theme & Brand System

Noresah follows a clean, modern design system optimized for emotional comfort and readability.

*   **Primary Color:** `#273383` (Deep Indigo Blue - represents stability, trust, and professional support)
*   **Secondary Color:** `#FA6400` (Warm Coral Orange - represents warmth, safety, and responsiveness)
*   **Neutral Colors:**
    *   Dark Neutral: `#1B263B` (For text and headings)
    *   Light Neutral: `#F5F5F5` (Background scaffold color)
    *   Card/Base Neutral: `#FFFFFF` (White)
*   **Typography:** Roboto (Primary font family)

---

## 🗃️ Project Structure

Noresah implements a modular, feature-oriented project layout to maintain readability and scalability as features grow:

```bash
lib/
├── core/
│   ├── models/                # Global data models (booking, distress, forum, journal, mood, profile)
│   ├── providers/             # ChangeNotifier providers for state management (booking, chat, classification, forum, journal, mood, profile)
│   ├── services/              # Core business services (problem preference, profile)
│   └── utils/
│       ├── constant/          # Global application styling & color constants (app_colors)
│       └── widgets/           # Global shared widgets (auth_gate, chat_bubble)
├── features/
│   ├── auth/                  # Authentication features
│   │   ├── login/             # Login flow and views (login_page)
│   │   ├── onboarding/        # Student onboarding flow (onboarding_page, onboarding_provider)
│   │   └── register/          # Register flow and views (register_page)
│   ├── psikolog/              # Psychologist-specific features
│   │   ├── booking/           # Consultation booking management (psikolog_booking_page)
│   │   ├── dashboard/         # Psychologist home dashboard (psikolog_dashboard_page)
│   │   ├── forum/             # Q&A community response page (psikolog_forum_page)
│   │   ├── profile/           # Psychologist profile (psikolog_profile_page)
│   │   └── widgets/           # Psychologist-specific widgets (psikolog_navigation)
│   └── user/                  # Student/User-specific features
│       ├── chat/              # ResahAI chatbot flow (chat_page, chat_history_page, emergency_page)
│       │   └── pages/widgets/ # Chat elements (chat_bubble, quick_action_chip, typing_indicator)
│       ├── consultation/      # Psychologist browsing & booking (consultation_page, booking_detail_page)
│       ├── forum/             # Anonymous community forum Q&A (forum_page, forum_detail_page)
│       ├── home/              # User homepage and mood view (home_page)
│       ├── journal/           # Student journaling editor & history (journal_editor_page, journal_list_page)
│       ├── profile/           # User profile screen (profile_page)
│       └── widgets/           # User interface layouts (navigation)
├── app.dart                   # MultiProvider setup & material app theme configuration
└── main.dart                  # App entrance, dotenv configuration, & Supabase initialization
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:
1.  [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (matching environment sdk `^3.11.5`).
2.  A [Supabase](https://supabase.com) project set up with the corresponding database schemas.
3.  A [Google AI Studio](https://aistudio.google.com/) Gemini API key.

### Configuration

1.  Clone this repository:
    ```bash
    git clone https://github.com/nabathnm/noresah.git
    cd noresah
    ```

2.  Create a `.env` file in the root directory of the project:
    ```env
    SUPABASE_URL=your_supabase_project_url
    SUPABASE_KEY=your_supabase_anon_key
    GEMINI_API_KEY=your_google_gemini_api_key
    ```

3.  Ensure `.env` is loaded in your `pubspec.yaml` assets section:
    ```yaml
    assets:
      - .env
      - assets/navbar/
    ```

### Run the App

1.  Fetch project dependencies:
    ```bash
    flutter pub get
    ```

2.  Run the application in debug mode:
    ```bash
    flutter run
    ```

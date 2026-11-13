# AI-Powered-Resume-Builder

**Author:** Sohaib Ahmad

**Last updated:** November 13, 2026

A Flutter app for creating, editing, importing, previewing, and exporting professional resumes.

## Features

- Email/password authentication with Firebase Authentication
- Resume editor for personal information, summary, experience, education, skills, projects, languages, and certifications
- AI summary generation, achievement rewriting, and skill suggestions with Google Gemini
- LinkedIn profile import from a PDF or pasted text
- Classic, Modern, Minimal, and CV templates with live preview
- PDF export, sharing, and printing
- Multiple resumes per user, stored in Cloud Firestore
- Duplicate and delete resumes

## Tech Stack

Flutter, Firebase Authentication, Cloud Firestore, Cloud Functions, Google Gemini, `pdf`, and `printing`.

## Setup

1. Install Flutter and Firebase CLI.
2. Clone this repository and install Flutter dependencies:

   ```sh
   git clone https://github.com/gamingdanger0811/AI-Powered-Resume-Builder.git
   cd AI-Powered-Resume-Builder
   flutter pub get
   ```

3. Configure your Firebase project with FlutterFire (`flutterfire configure`).
4. In `functions/`, install the Cloud Functions dependencies with `npm install`.
5. Set the Gemini key as a Firebase Functions secret:

   ```sh
   firebase functions:secrets:set GEMINI_API_KEY
   ```

6. Deploy the function:

   ```sh
   firebase deploy --only functions
   ```

7. Start the app with `flutter run -d chrome` or select a connected device.

## Notes

- The Gemini API key is kept in a Firebase Functions secret and is not embedded in the Flutter app.
- AI generation and profile import use the authenticated `generateContent` callable in `us-central1`, which enforces a per-user request limit.
- LinkedIn does not provide public API access to full profiles. Import works through a LinkedIn PDF upload or pasted profile text.
- Imported information should be reviewed and corrected before saving.

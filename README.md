Sound Track EDU

Sound Track EDU is an iOS app that helps Deaf and Hard-of-Hearing (DHH) students—and anyone who benefits from visual access to speech—participate fully in mainstream classrooms.

What it does

Live: Real-time on-device transcription of classroom speech.

Chat: Peer-to-peer, push-to-talk group discussion capture with correct speaker attribution.

Alerts: Quick teacher-to-student notifications (e.g., “important now” or “you were called”).

Review: Saved sessions with optional AI-generated summaries for fast study.

Who it’s for

Students with hearing loss (including mild), classroom support staff, and teachers in mainstream K-12 environments.

How it works (tech)

Language: Swift, SwiftUI

Speech: Apple Speech framework (on-device where available)

Peer-to-peer: MultipeerConnectivity (Bluetooth/Wi-Fi, no server)

AI summaries: OpenAI API (configurable; summaries stored locally)

Setup

Requirements

Xcode 15+

iOS 16+ target

An Apple Developer account for device testing

Clone and open

git clone https://github.com/anikam23/sound-track-edu.git
cd sound-track-edu
open "Sound Track EDU.xcodeproj"


Add API key (optional, for AI summaries)

Create Secrets.plist at the project root with a string key OPENAI_API_KEY.

Build & run

Select your device or simulator in Xcode and press Run.

Permissions

Microphone — recording for transcription and chat

Local Network / Bluetooth — peer discovery and messaging for Chat/Alerts

Notifications — optional student alerts

Privacy

Transcription and peer chat are processed locally on device; AI summaries use your OpenAI key if enabled. No classrooms servers are required.

Folder guide (high-level)

Sound Track EDU/ — app sources (SwiftUI views, services, models)

Sound Track EDU/UI/Chat/ — Chat UI

Sound Track EDU/Services/ — Transcription, Multipeer chat, alerts

Sound Track EDU/Models/ — Data models

Sound Track EDU/Assets.xcassets/ — App assets (icons, splash)

Public Domain

This project is released into the public domain.
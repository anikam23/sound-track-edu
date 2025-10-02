import Foundation
import Combine

/// Manages local student profile persistence using UserDefaults
@MainActor
class ProfileStore: ObservableObject {
    @Published var profile: StudentProfile
    
    private let userDefaultsKey = "StudentProfile"
    
    init() {
        self.profile = Self.loadOrCreateDefault()
    }
    
    /// Loads existing profile from UserDefaults or creates a default one
    static func loadOrCreateDefault() -> StudentProfile {
        guard let data = UserDefaults.standard.data(forKey: "StudentProfile"),
              let profile = try? JSONDecoder().decode(StudentProfile.self, from: data) else {
            // Create default profile if none exists
            return StudentProfile.createDefault()
        }
        return profile
    }
    
    /// Saves the current profile to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(profile) else {
            print("Failed to encode student profile")
            return
        }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    /// Updates profile and saves automatically
    func updateProfile(_ newProfile: StudentProfile) {
        profile = newProfile
        save()
    }
    
    /// Convenience method to update specific fields
    func updateDisplayName(_ name: String) {
        profile.displayName = name
        save()
    }
    
    func updateReceiveAlerts(_ enabled: Bool) {
        profile.receiveAlerts = enabled
        save()
    }
    
    func updateAutoStartOnImportant(_ enabled: Bool) {
        profile.autoStartOnImportant = enabled
        save()
    }
}


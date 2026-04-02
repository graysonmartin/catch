import Foundation

public enum SupabaseConfig {
    public enum Environment {
        case development
        case production
    }

    public static var current: Environment = .production

    public static var url: URL {
        if let bundleURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !bundleURL.isEmpty,
           let url = URL(string: bundleURL) {
            return url
        }
        // Fallback when xcconfig is not yet wired up
        switch current {
        case .development:
            return URL(string: "https://tqmjfpevabhfaxotfvge.supabase.co")!
        case .production:
            return URL(string: "https://jxvuloqmmvuvrnnqgddf.supabase.co")!
        }
    }

    public static var anonKey: String {
        if let bundleKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !bundleKey.isEmpty {
            return bundleKey
        }
        // Fallback when xcconfig is not yet wired up
        switch current {
        case .development:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxbWpmcGV2YWJoZmF4b3RmdmdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2ODYwODMsImV4cCI6MjA4OTI2MjA4M30.w_LpZwt9dOGhkgkogVFwAF9sjI-DzDs-oEUntQ1VLkw"
        case .production:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4dnVsb3FtbXZ1dnJubnFnZGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTE3ODEsImV4cCI6MjA4ODM4Nzc4MX0.VSLMp6rhgPJczLlRYyetQz7ku2ouBAs2fasl4WwkRbE"
        }
    }
}

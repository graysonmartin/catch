import Foundation

public enum SupabaseConfig {
    public enum Environment {
        case development
        case production
    }

    public static var current: Environment = .development

    public static var url: URL {
        switch current {
        case .development:
            URL(string: "https://jxvuloqmmvuvrnnqgddf.supabase.co")!
        case .production:
            // TODO: Replace with production URL when available
            URL(string: "https://jxvuloqmmvuvrnnqgddf.supabase.co")!
        }
    }

    public static var anonKey: String {
        switch current {
        case .development:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4dnVsb3FtbXZ1dnJubnFnZGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTE3ODEsImV4cCI6MjA4ODM4Nzc4MX0.VSLMp6rhgPJczLlRYyetQz7ku2ouBAs2fasl4WwkRbE"
        case .production:
            // TODO: Replace with production anon key when available
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4dnVsb3FtbXZ1dnJubnFnZGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTE3ODEsImV4cCI6MjA4ODM4Nzc4MX0.VSLMp6rhgPJczLlRYyetQz7ku2ouBAs2fasl4WwkRbE"
        }
    }
}

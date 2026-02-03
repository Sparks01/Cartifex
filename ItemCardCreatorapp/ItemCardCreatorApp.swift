import SwiftUI
import SwiftData

@main
struct ItemCardCreatorApp: App {
    var sharedModelContainer: ModelContainer = {
        // REGISTER ALL NEW MODELS HERE
        let schema = Schema([
            Card.self,
            CardCollection.self,
            SpellDetails.self,
            WeaponDetails.self,
            ArmorDetails.self,
            MagicItemDetails.self,
            NPCDetails.self,
            LocationDetails.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    CatalogDataStore.shared.loadFromDisk()
                     await CatalogDataStore.shared.loadAllDataFromAPI()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

import Foundation

// Search result with match context
struct SupplementSearchResult: Identifiable {
    let supplement: SupplementReference
    let matchedTerms: [String]
    let matchType: MatchType

    var id: String { supplement.id }

    enum MatchType: Int, Comparable {
        case exactName = 0
        case partialName = 1
        case keyword = 2
        case goal = 3

        static func < (lhs: MatchType, rhs: MatchType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

class SupplementDatabaseService {
    static let shared = SupplementDatabaseService()

    private var database: SupplementDatabase?
    private var supplementsByName: [String: SupplementReference] = [:]

    private init() {
        loadDatabase()
    }

    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "supplement_database", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load supplement database")
            return
        }

        do {
            let decoder = JSONDecoder()
            database = try decoder.decode(SupplementDatabase.self, from: data)
            indexSupplements()
        } catch {
            print("Failed to decode supplement database: \(error)")
        }
    }

    private func indexSupplements() {
        guard let supplements = database?.supplements else { return }

        for supplement in supplements {
            for name in supplement.names {
                supplementsByName[name.lowercased()] = supplement
            }
        }
    }

    func getAllSupplements() -> [SupplementReference] {
        return database?.supplements ?? []
    }

    func searchSupplements(query: String) -> [SupplementReference] {
        guard !query.isEmpty else { return getAllSupplements() }
        return searchSupplementsWithContext(query: query).map { $0.supplement }
    }

    func searchSupplementsWithContext(query: String) -> [SupplementSearchResult] {
        guard !query.isEmpty else {
            return getAllSupplements().map {
                SupplementSearchResult(supplement: $0, matchedTerms: [], matchType: .exactName)
            }
        }

        let lowercasedQuery = query.lowercased()
        var results: [SupplementSearchResult] = []

        for supplement in getAllSupplements() {
            // Check exact name match
            if supplement.names.contains(where: { $0.lowercased() == lowercasedQuery }) {
                let matchedName = supplement.names.first { $0.lowercased() == lowercasedQuery } ?? supplement.primaryName
                results.append(SupplementSearchResult(
                    supplement: supplement,
                    matchedTerms: [matchedName],
                    matchType: .exactName
                ))
                continue
            }

            // Check partial name match
            let matchedNames = supplement.names.filter { $0.lowercased().contains(lowercasedQuery) }
            if !matchedNames.isEmpty {
                results.append(SupplementSearchResult(
                    supplement: supplement,
                    matchedTerms: matchedNames,
                    matchType: .partialName
                ))
                continue
            }

            // Check keyword match
            let matchedKeywords = supplement.keywords.filter { $0.lowercased().contains(lowercasedQuery) }
            if !matchedKeywords.isEmpty {
                results.append(SupplementSearchResult(
                    supplement: supplement,
                    matchedTerms: matchedKeywords,
                    matchType: .keyword
                ))
                continue
            }

            // Check goal match
            let matchedGoals = supplement.goalRelevance.filter { $0.lowercased().contains(lowercasedQuery) }
            if !matchedGoals.isEmpty {
                results.append(SupplementSearchResult(
                    supplement: supplement,
                    matchedTerms: matchedGoals,
                    matchType: .goal
                ))
            }
        }

        // Sort by match priority (exact name first, then partial name, keyword, goal)
        return results.sorted { $0.matchType < $1.matchType }
    }

    func getSupplement(byId id: String) -> SupplementReference? {
        return database?.supplements.first { $0.id == id }
    }

    func getSupplement(byName name: String) -> SupplementReference? {
        return supplementsByName[name.lowercased()]
    }

    func getInteractions(for supplementId: String) -> [SupplementInteraction] {
        return database?.interactions.filter {
            $0.supplementA == supplementId || $0.supplementB == supplementId
        } ?? []
    }

    func getInteractionsBetween(supplements: [String]) -> [SupplementInteraction] {
        guard let interactions = database?.interactions else { return [] }

        return interactions.filter { interaction in
            supplements.contains(interaction.supplementA) &&
            supplements.contains(interaction.supplementB)
        }
    }

    func getSynergies(for supplementId: String) -> [SupplementSynergy] {
        return database?.synergies.filter {
            $0.supplementA == supplementId || $0.supplementB == supplementId
        } ?? []
    }

    func getSynergiesBetween(supplements: [String]) -> [SupplementSynergy] {
        guard let synergies = database?.synergies else { return [] }

        return synergies.filter { synergy in
            supplements.contains(synergy.supplementA) &&
            supplements.contains(synergy.supplementB)
        }
    }

    func getSupplementsForGoal(_ goal: Goal) -> [SupplementReference] {
        return getAllSupplements().filter { $0.goalRelevance.contains(goal.rawValue) }
    }
}

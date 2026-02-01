import SwiftUI
import SwiftData

struct AddSupplementSheet: View {
    @Bindable var viewModel: SupplementsViewModel
    let user: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var showingManualEntry = false
    @State private var showingBarcodeScanner = false
    @State private var showDuplicateAlert = false
    @State private var selectedReference: SupplementReference?

    var searchResults: [SupplementSearchResult] {
        SupplementDatabaseService.shared.searchSupplementsWithContext(query: searchQuery)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingMD) {
                    searchView
                }
            }
            .navigationTitle("Add to Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntrySheet(viewModel: viewModel, user: user)
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView(
                    onProductFound: { product in
                        // Try to find a matching supplement in the database
                        if let reference = SupplementDatabaseService.shared.getSupplement(byName: product.name) {
                            let added = viewModel.addSupplement(
                                from: reference,
                                dosage: reference.defaultDosageMin,
                                dosageUnit: reference.defaultDosageUnit,
                                to: user,
                                modelContext: modelContext
                            )
                            if added {
                                dismiss()
                            } else {
                                showDuplicateAlert = true
                            }
                        } else {
                            // Pre-fill search with scanned product name
                            searchQuery = product.displayTitle
                        }
                    },
                    onManualEntry: { _ in
                        showingManualEntry = true
                    }
                )
            }
            .alert("Already added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This supplement is already in your routine.")
            }
            .sheet(item: $selectedReference) { reference in
                SupplementReferenceDetailSheet(
                    reference: reference,
                    viewModel: viewModel,
                    user: user,
                    onAdd: { dismiss() }
                )
            }
        }
    }

    // MARK: - Search View

    @FocusState private var isSearchFocused: Bool

    private var searchView: some View {
        VStack(spacing: Theme.spacingMD) {
            // Search Bar with Barcode Button
            HStack(spacing: Theme.spacingSM) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.textSecondary)

                    TextField("Search supplements", text: $searchQuery)
                        .foregroundColor(Theme.textPrimary)
                        .focused($isSearchFocused)

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                .padding(Theme.spacingMD)
                .background(Theme.surface)
                .cornerRadius(Theme.cornerRadiusSM)

                // Barcode Scanner Button
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusSM)
                }
            }
            .padding(.horizontal, Theme.spacingLG)

            // Results
            ScrollView {
                LazyVStack(spacing: Theme.spacingSM) {
                    if searchQuery.isEmpty {
                        // Empty state - prompt to search
                        VStack(spacing: Theme.spacingMD) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.textSecondary.opacity(0.5))

                            Text("Search for your supplements")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)

                            Text("Add as many as you need")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.spacingXXL)
                    } else if searchResults.isEmpty {
                        // No results state
                        VStack(spacing: Theme.spacingMD) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.textSecondary.opacity(0.5))

                            Text("No matches found")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            Text("Not here?")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, Theme.spacingSM)

                            Button(action: {
                                showingManualEntry = true
                            }) {
                                Text("Add it")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.spacingXXL)
                    } else {
                        ForEach(searchResults) { result in
                            HStack {
                                // Main content - tap to open detail sheet
                                Button(action: {
                                    selectedReference = result.supplement
                                }) {
                                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                        Text(result.supplement.primaryName)
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textPrimary)

                                        Text(result.supplement.supplementCategory.displayName)
                                            .font(Theme.captionFont)
                                            .foregroundColor(Theme.textSecondary)

                                        // Show match context for keyword/goal matches
                                        if !searchQuery.isEmpty && !result.matchedTerms.isEmpty && result.matchType != .exactName && result.matchType != .partialName {
                                            Text("matches: \(result.matchedTerms.joined(separator: ", "))")
                                                .font(Theme.captionFont)
                                                .foregroundColor(Theme.accent)
                                                .italic()
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Text(result.supplement.displayDosageRange)
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)

                                // Quick add button - separate tap target
                                Button(action: {
                                    let added = viewModel.addSupplement(
                                        from: result.supplement,
                                        dosage: result.supplement.defaultDosageMin,
                                        dosageUnit: result.supplement.defaultDosageUnit,
                                        to: user,
                                        modelContext: modelContext
                                    )
                                    if added {
                                        dismiss()
                                    } else {
                                        showDuplicateAlert = true
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.accent)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(Theme.spacingMD)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusSM)
                        }

                        // Manual Entry Option at bottom of search results
                        Button(action: {
                            showingManualEntry = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(Theme.textSecondary)

                                Text("Not here? Add it")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textSecondary)

                                Spacer()
                            }
                            .padding(Theme.spacingMD)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusSM)
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingLG)
            }
        }
        .padding(.top, Theme.spacingLG)
        .onAppear {
            // Auto-focus search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
}

struct ManualEntrySheet: View {
    @Bindable var viewModel: SupplementsViewModel
    let user: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: SupplementCategory = .other
    @State private var dosageString = ""
    @State private var dosageUnit = "mg"
    @State private var showDuplicateAlert = false
    @State private var customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    // Frequency state
    @State private var frequencyType: FrequencyType = .daily
    @State private var selectedWeekdays: Set<ScheduleFrequency.Weekday> = [.monday, .wednesday, .friday]
    @State private var everyNDays: Int = 2
    @State private var weeklyDay: ScheduleFrequency.Weekday = .monday

    let dosageUnits = ["mg", "mcg", "g", "IU", "ml", "serving", "capsule", "tablet", "softgel", "gummy", "billion CFU"]

    enum FrequencyType: String, CaseIterable {
        case daily = "Daily"
        case specificDays = "Specific days"
        case everyNDays = "Every X days"
        case weekly = "Weekly"
    }

    private var customTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: customTime)
    }

    private var customFrequency: ScheduleFrequency {
        switch frequencyType {
        case .daily:
            return .daily
        case .specificDays:
            return .specificDays(selectedWeekdays)
        case .everyNDays:
            return .everyNDays(interval: everyNDays, startDate: Date())
        case .weekly:
            return .weekly(weeklyDay)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: Theme.spacingLG) {
                            // Name
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("NAME")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                TextField("Supplement name", text: $name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(Theme.spacingMD)
                                    .background(Theme.surface)
                                    .cornerRadius(Theme.cornerRadiusSM)
                            }

                            // Category
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("CATEGORY")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                Picker("Category", selection: $category) {
                                    ForEach(SupplementCategory.allCases, id: \.self) { cat in
                                        Text(cat.displayName).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.spacingMD)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusSM)
                            }

                            // Dosage
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("DOSAGE")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                HStack(spacing: Theme.spacingMD) {
                                    TextField("Amount", text: $dosageString)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textPrimary)
                                        .keyboardType(.decimalPad)
                                        .padding(Theme.spacingMD)
                                        .background(Theme.surface)
                                        .cornerRadius(Theme.cornerRadiusSM)

                                    Picker("Unit", selection: $dosageUnit) {
                                        ForEach(dosageUnits, id: \.self) { unit in
                                            Text(unit).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Theme.spacingMD)
                                    .background(Theme.surface)
                                    .cornerRadius(Theme.cornerRadiusSM)
                                }
                            }

                            // Time
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("TIME")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                DatePicker(
                                    "Time",
                                    selection: $customTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(Theme.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.spacingMD)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusSM)
                            }

                            // Frequency
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("FREQUENCY")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                Picker("Frequency", selection: $frequencyType) {
                                    ForEach(FrequencyType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.spacingMD)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusSM)

                                // Conditional sub-pickers based on frequency type
                                switch frequencyType {
                                case .daily:
                                    EmptyView()

                                case .specificDays:
                                    // Weekday selector
                                    HStack(spacing: Theme.spacingXS) {
                                        ForEach(ScheduleFrequency.Weekday.allCases, id: \.self) { day in
                                            Button(action: {
                                                if selectedWeekdays.contains(day) {
                                                    selectedWeekdays.remove(day)
                                                } else {
                                                    selectedWeekdays.insert(day)
                                                }
                                            }) {
                                                Text(day.initial)
                                                    .font(Theme.captionFont)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(selectedWeekdays.contains(day) ? Theme.background : Theme.textSecondary)
                                                    .frame(width: 36, height: 36)
                                                    .background(selectedWeekdays.contains(day) ? Theme.accent : Theme.surface)
                                                    .cornerRadius(18)
                                            }
                                        }
                                    }

                                case .everyNDays:
                                    // Interval picker
                                    HStack(spacing: Theme.spacingSM) {
                                        Text("Every")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textSecondary)

                                        Picker("Days", selection: $everyNDays) {
                                            ForEach(2...14, id: \.self) { n in
                                                Text("\(n)").tag(n)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(Theme.textPrimary)
                                        .padding(.horizontal, Theme.spacingSM)
                                        .padding(.vertical, Theme.spacingXS)
                                        .background(Theme.surface)
                                        .cornerRadius(Theme.cornerRadiusSM)

                                        Text("days")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textSecondary)
                                    }

                                case .weekly:
                                    // Day of week picker
                                    Picker("Day", selection: $weeklyDay) {
                                        ForEach(ScheduleFrequency.Weekday.allCases, id: \.self) { day in
                                            Text(day.fullName).tag(day)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.textPrimary)
                                    .padding(Theme.spacingMD)
                                    .background(Theme.surface)
                                    .cornerRadius(Theme.cornerRadiusSM)
                                }
                            }
                        }
                        .padding(Theme.spacingLG)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Fixed button at bottom
                    Button(action: {
                        let dosage = Double(dosageString)
                        let added = viewModel.addManualSupplement(
                            name: name,
                            category: category,
                            dosage: dosage,
                            dosageUnit: dosage != nil ? dosageUnit : nil,
                            customTime: customTimeString,
                            customFrequency: customFrequency,
                            to: user,
                            modelContext: modelContext
                        )
                        if added {
                            dismiss()
                        } else {
                            showDuplicateAlert = true
                        }
                    }) {
                        Text("Add supplement")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)
                    .padding(Theme.spacingLG)
                }
            }
            .navigationTitle("Add Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .alert("Already Added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A supplement with this name is already in your routine.")
            }
        }
        .presentationDetents([.large])
    }
}

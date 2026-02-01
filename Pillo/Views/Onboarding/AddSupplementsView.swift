import SwiftUI

struct AddSupplementsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingManualEntry = false
    @State private var selectedReference: SupplementReference?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Theme.spacingSM) {
                Text(Constants.Copy.addSupplementsTitle)
                    .font(Theme.headerFont)
                    .tracking(2)
                    .foregroundColor(Theme.textPrimary)

                Text(Constants.Copy.addSupplementsSubtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.top, Theme.spacingXL)
            .padding(.bottom, Theme.spacingLG)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textSecondary)

                TextField("Search supplements", text: $viewModel.searchQuery)
                    .foregroundColor(Theme.textPrimary)
                    .focused($isSearchFocused)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.spacingMD)
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadiusSM)
            .padding(.horizontal, Theme.spacingLG)

            // Content
            if !viewModel.searchQuery.isEmpty {
                // Search Results
                SearchResultsList(
                    viewModel: viewModel,
                    selectedReference: $selectedReference,
                    showingManualEntry: $showingManualEntry
                )
            } else {
                // Selected Supplements
                SelectedSupplementsList(viewModel: viewModel)
            }

            Spacer()

            // Bottom Buttons - Progressive visibility based on state
            VStack(spacing: Theme.spacingMD) {
                if viewModel.canContinueFromSupplements {
                    let count = viewModel.selectedSupplements.count
                    Button(action: {
                        viewModel.nextStep()
                    }) {
                        Text("Continue with \(count) \(count == 1 ? "supplement" : "supplements")")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                // Note: When searching with no results, the "Add it" button is shown inline in SearchResultsList
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingXL)
        }
        .onAppear {
            // Auto-focus search field to signal "start typing"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSearchFocused = true
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualSupplementEntrySheet(viewModel: viewModel)
        }
        .sheet(item: $selectedReference) { reference in
            OnboardingSupplementDetailSheet(
                reference: reference,
                viewModel: viewModel
            )
        }
    }
}

struct SearchResultsList: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var selectedReference: SupplementReference?
    @Binding var showingManualEntry: Bool

    private var results: [SupplementSearchResult] {
        viewModel.searchResults
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingSM) {
                if results.isEmpty {
                    // No results state
                    VStack(spacing: Theme.spacingMD) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))

                        Text("No matches found")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)

                        Text("Can't find yours?")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)

                        Button(action: {
                            showingManualEntry = true
                        }) {
                            HStack(spacing: Theme.spacingSM) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create new")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Theme.spacingXXL)
                } else {
                    ForEach(results, id: \.id) { (result: SupplementSearchResult) in
                        HStack {
                            // Name/text area — tap to open detail sheet
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
                                    if !viewModel.searchQuery.isEmpty && !result.matchedTerms.isEmpty && result.matchType != .exactName && result.matchType != .partialName {
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

                            // Quick add button — separate tap target
                            Button(action: {
                                viewModel.addSupplement(from: result.supplement)
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
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingMD)
        }
    }
}

struct SelectedSupplementsList: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingSM) {
                if viewModel.selectedSupplements.isEmpty {
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
                    .padding(.top, Theme.spacingXXL)
                } else {
                    ForEach(viewModel.selectedSupplements, id: \.id) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                                Text(entry.name)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)

                                HStack(spacing: Theme.spacingSM) {
                                    Text(entry.category.displayName)
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)

                                    if let dosage = entry.dosage, let unit = entry.dosageUnit {
                                        Text("•")
                                            .foregroundColor(Theme.textSecondary)
                                        Text("\(Int(dosage))\(unit)")
                                            .font(Theme.captionFont)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }
                            }

                            Spacer()

                            Button(action: {
                                withAnimation {
                                    viewModel.removeSupplement(entry)
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(Theme.spacingSM)
                            }
                        }
                        .padding(Theme.spacingMD)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusSM)
                    }
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingMD)
        }
    }
}

struct ManualSupplementEntrySheet: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: SupplementCategory = .other
    @State private var dosageString: String = ""
    @State private var dosageUnit: String = "mg"
    @State private var customTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    let dosageUnits = ["mg", "mcg", "g", "IU", "ml", "serving", "capsule", "tablet", "softgel", "gummy", "billion CFU"]

    private var customTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: customTime)
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
                                Text("DOSAGE (OPTIONAL)")
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
                        }
                        .padding(Theme.spacingLG)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Fixed button at bottom
                    Button(action: {
                        let dosage = Double(dosageString)
                        viewModel.addManualSupplement(
                            name: name,
                            category: category,
                            dosage: dosage,
                            dosageUnit: dosage != nil ? dosageUnit : nil,
                            customTime: customTimeString
                        )
                        dismiss()
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
        }
        .presentationDetents([.large])
    }
}

// MARK: - Onboarding Supplement Detail Sheet

struct OnboardingSupplementDetailSheet: View {
    let reference: SupplementReference
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingLG) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.spacingSM) {
                            Text(reference.primaryName.uppercased())
                                .font(Theme.titleFont)
                                .tracking(1)
                                .foregroundColor(Theme.textPrimary)

                            Text(reference.supplementCategory.displayName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            Text("Typical dose: \(reference.displayDosageRange)")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }

                        Divider()
                            .background(Theme.border)

                        if !reference.benefits.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("WHY IT MATTERS")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                Text(reference.benefits)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .lineSpacing(4)
                            }
                        }

                        if !reference.absorptionNotes.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("BEST TIME TO TAKE")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                Text(reference.absorptionNotes)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                    .lineSpacing(4)
                            }
                        }

                        if !reference.avoidWith.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("WHAT TO AVOID")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                ForEach(reference.avoidWith, id: \.self) { avoid in
                                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                                        Text("\u{2022}")
                                            .foregroundColor(Theme.warning)
                                        Text("Don't take with \(avoid.replacingOccurrences(of: "_", with: " ").capitalized)")
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                        }

                        if !reference.pairsWith.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                Text("PAIRS WELL WITH")
                                    .font(Theme.headerFont)
                                    .tracking(1)
                                    .foregroundColor(Theme.textSecondary)

                                ForEach(reference.pairsWith, id: \.self) { pair in
                                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                                        Text("\u{2022}")
                                            .foregroundColor(Theme.success)
                                        Text(pair.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: Theme.spacingXL)

                        // Add button
                        Button(action: {
                            viewModel.addSupplement(from: reference)
                            dismiss()
                        }) {
                            Text("Add to routine")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(Theme.spacingLG)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AddSupplementsView(viewModel: OnboardingViewModel())
    }
}

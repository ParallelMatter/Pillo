import SwiftUI

struct AddSupplementsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showingManualEntry = false
    @State private var showingBarcodeScanner = false
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

            // Search Bar with Barcode Button
            HStack(spacing: Theme.spacingSM) {
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

            // Content
            if !viewModel.searchQuery.isEmpty {
                // Search Results
                SearchResultsList(viewModel: viewModel)
            } else {
                // Selected Supplements
                SelectedSupplementsList(viewModel: viewModel, showingManualEntry: $showingManualEntry)
            }

            Spacer()

            // Bottom Buttons
            VStack(spacing: Theme.spacingMD) {
                if viewModel.canContinueFromSupplements {
                    Button(action: {
                        viewModel.nextStep()
                    }) {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Button(action: {
                    showingManualEntry = true
                }) {
                    Text("Add manually")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, Theme.spacingXL)
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualSupplementEntrySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(
                onProductFound: { product in
                    // Try to find a matching supplement in the database
                    if let reference = SupplementDatabaseService.shared.getSupplement(byName: product.name) {
                        viewModel.addSupplement(from: reference)
                    } else {
                        // Pre-fill search with scanned product name
                        viewModel.searchQuery = product.displayTitle
                    }
                },
                onManualEntry: { _ in
                    showingManualEntry = true
                }
            )
        }
    }
}

struct SearchResultsList: View {
    @Bindable var viewModel: OnboardingViewModel

    private var results: [SupplementSearchResult] {
        viewModel.searchResults
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingSM) {
                ForEach(results, id: \.id) { (result: SupplementSearchResult) in
                    Button(action: {
                        viewModel.addSupplement(from: result.supplement)
                    }) {
                        HStack {
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

                            Spacer()

                            Text(result.supplement.displayDosageRange)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)

                            Image(systemName: "plus.circle")
                                .foregroundColor(Theme.textSecondary)
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
    @Binding var showingManualEntry: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingSM) {
                if viewModel.selectedSupplements.isEmpty {
                    VStack(spacing: Theme.spacingMD) {
                        Image(systemName: "pill.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))

                        Text("No supplements added yet")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)

                        Text("Search above or add manually")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
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

    let dosageUnits = ["mg", "mcg", "g", "IU", "ml"]

    private var customTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: customTime)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

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

                    Spacer()

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
                }
                .padding(Theme.spacingLG)
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
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AddSupplementsView(viewModel: OnboardingViewModel())
    }
}

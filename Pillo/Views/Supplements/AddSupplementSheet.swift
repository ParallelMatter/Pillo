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
    @State private var scannedProductName: String?
    @State private var showDuplicateAlert = false

    var searchResults: [SupplementSearchResult] {
        SupplementDatabaseService.shared.searchSupplementsWithContext(query: searchQuery)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: Theme.spacingMD) {
                    // Search Bar with Barcode Button
                    HStack(spacing: Theme.spacingSM) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textSecondary)

                            TextField("Search supplements", text: $searchQuery)
                                .foregroundColor(Theme.textPrimary)

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
                            ForEach(searchResults) { result in
                                Button(action: {
                                    let added = viewModel.addSupplement(
                                        from: result.supplement,
                                        dosage: result.supplement.defaultDosageMin,
                                        dosageUnit: result.supplement.defaultDosageUnit,
                                        form: nil,
                                        to: user,
                                        modelContext: modelContext
                                    )
                                    if added {
                                        dismiss()
                                    } else {
                                        showDuplicateAlert = true
                                    }
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
                                            if !searchQuery.isEmpty && !result.matchedTerms.isEmpty && result.matchType != .exactName && result.matchType != .partialName {
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
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    .padding(Theme.spacingMD)
                                    .background(Theme.surface)
                                    .cornerRadius(Theme.cornerRadiusSM)
                                }
                            }

                            // Manual Entry Option
                            Button(action: {
                                showingManualEntry = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(Theme.textSecondary)

                                    Text("Add manually")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textSecondary)

                                    Spacer()
                                }
                                .padding(Theme.spacingMD)
                                .background(Theme.surface)
                                .cornerRadius(Theme.cornerRadiusSM)
                            }
                        }
                        .padding(.horizontal, Theme.spacingLG)
                    }
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
                                form: nil,
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
            .alert("Already Added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This supplement is already in your routine.")
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
    @State private var form: SupplementForm = .capsule
    @State private var showDuplicateAlert = false
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
                            .padding(Theme.spacingMD)
                            .background(Theme.surface)
                            .cornerRadius(Theme.cornerRadiusSM)
                        }
                    }

                    // Form
                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Text("FORM")
                            .font(Theme.headerFont)
                            .tracking(1)
                            .foregroundColor(Theme.textSecondary)

                        Picker("Form", selection: $form) {
                            ForEach(SupplementForm.allCases, id: \.self) { f in
                                Text(f.displayName).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.spacingMD)
                        .background(Theme.surface)
                        .cornerRadius(Theme.cornerRadiusSM)
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
                        let added = viewModel.addManualSupplement(
                            name: name,
                            category: category,
                            dosage: dosage,
                            dosageUnit: dosage != nil ? dosageUnit : nil,
                            form: form,
                            customTime: customTimeString,
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
            .alert("Already Added", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A supplement with this name is already in your routine.")
            }
        }
    }
}

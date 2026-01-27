import SwiftUI
import SwiftData

struct SupplementDetailSheet: View {
    let supplement: Supplement
    @Bindable var viewModel: SupplementsViewModel
    let user: User
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editedDosage: String = ""
    @State private var editedUnit: String = "mg"
    @State private var editedForm: SupplementForm = .capsule

    private var reference: SupplementReference? {
        viewModel.getReferenceInfo(for: supplement)
    }

    private var scheduleSlot: ScheduleSlot? {
        user.scheduleSlots?.first { $0.supplementIds.contains(supplement.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.spacingLG) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.spacingSM) {
                            Text(supplement.name.uppercased())
                                .font(Theme.titleFont)
                                .tracking(1)
                                .foregroundColor(Theme.textPrimary)

                            Text(supplement.category.displayName)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            if !supplement.displayDosage.isEmpty {
                                Text("Your dose: \(supplement.displayDosage)")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }

                        Divider()
                            .background(Theme.border)

                        // Reference Info
                        if let ref = reference {
                            // Benefits - Hero Section
                            if !ref.benefits.isEmpty {
                                InfoSection(
                                    title: "WHY IT MATTERS",
                                    content: ref.benefits
                                )
                            }

                            // Demographics
                            if !ref.demographics.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                    Text("ESPECIALLY HELPFUL FOR")
                                        .font(Theme.headerFont)
                                        .tracking(1)
                                        .foregroundColor(Theme.textSecondary)

                                    ForEach(ref.demographics, id: \.self) { demographic in
                                        HStack(alignment: .top, spacing: Theme.spacingSM) {
                                            Text("•")
                                                .foregroundColor(Theme.accent)
                                            Text(demographic)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                    }
                                }
                            }

                            // Deficiency Signs - Expandable
                            if !ref.deficiencySigns.isEmpty {
                                DeficiencySignsSection(signs: ref.deficiencySigns)
                            }

                            // Why This Time
                            if let slot = scheduleSlot {
                                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                    Text("WHY THIS TIME?")
                                        .font(Theme.headerFont)
                                        .tracking(1)
                                        .foregroundColor(Theme.textSecondary)

                                    Text(slot.displayTime)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.accent)

                                    if !ref.absorptionNotes.isEmpty {
                                        Text(ref.absorptionNotes)
                                            .font(Theme.bodyFont)
                                            .foregroundColor(Theme.textPrimary)
                                            .lineSpacing(4)
                                    }
                                }
                            } else if !ref.absorptionNotes.isEmpty {
                                InfoSection(
                                    title: "WHY THIS TIME?",
                                    content: ref.absorptionNotes
                                )
                            }

                            // What to Avoid
                            if !ref.avoidWith.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                    Text("WHAT TO AVOID")
                                        .font(Theme.headerFont)
                                        .tracking(1)
                                        .foregroundColor(Theme.textSecondary)

                                    ForEach(ref.avoidWith, id: \.self) { avoid in
                                        HStack(alignment: .top, spacing: Theme.spacingSM) {
                                            Text("•")
                                                .foregroundColor(Theme.warning)
                                            Text("Don't take with \(avoid.replacingOccurrences(of: "_", with: " ").capitalized)")
                                                .font(Theme.bodyFont)
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                    }
                                }
                            }

                            // Pairs Well With
                            if !ref.pairsWith.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                    Text("PAIRS WELL WITH")
                                        .font(Theme.headerFont)
                                        .tracking(1)
                                        .foregroundColor(Theme.textSecondary)

                                    ForEach(ref.pairsWith, id: \.self) { pair in
                                        HStack(alignment: .top, spacing: Theme.spacingSM) {
                                            Text("•")
                                                .foregroundColor(Theme.success)
                                            Text(pair.replacingOccurrences(of: "_", with: " ").capitalized)
                                                .font(Theme.bodyFont)
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                    }

                                    // Show synergies
                                    let synergies = SupplementDatabaseService.shared.getSynergies(for: ref.id)
                                    ForEach(synergies, id: \.supplementA) { synergy in
                                        Text(synergy.effect)
                                            .font(Theme.captionFont)
                                            .foregroundColor(Theme.textSecondary)
                                            .italic()
                                            .padding(.leading, Theme.spacingMD)
                                    }
                                }
                            }

                            // Goals
                            if !ref.goalRelevance.isEmpty {
                                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                                    Text("SUPPORTS")
                                        .font(Theme.headerFont)
                                        .tracking(1)
                                        .foregroundColor(Theme.textSecondary)

                                    FlowLayout(spacing: Theme.spacingSM) {
                                        ForEach(ref.goalRelevance, id: \.self) { goalString in
                                            if let goal = Goal(rawValue: goalString) {
                                                GoalTag(goal: goal)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: Theme.spacingXL)

                        // Action Buttons
                        HStack(spacing: Theme.spacingMD) {
                            Button(action: {
                                isEditing = true
                            }) {
                                Text("Edit")
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button(action: {
                                viewModel.deleteSupplement(supplement, user: user, modelContext: modelContext)
                                dismiss()
                            }) {
                                Text("Remove")
                                    .foregroundColor(Theme.warning)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
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
            .sheet(isPresented: $isEditing) {
                EditSupplementSheet(
                    supplement: supplement,
                    viewModel: viewModel,
                    modelContext: modelContext,
                    user: user
                )
            }
            .onAppear {
                editedDosage = supplement.dosage.map { String($0) } ?? ""
                editedUnit = supplement.dosageUnit ?? "mg"
                editedForm = supplement.form ?? .capsule
            }
        }
    }
}

struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text(title)
                .font(Theme.headerFont)
                .tracking(1)
                .foregroundColor(Theme.textSecondary)

            Text(content)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(4)
        }
    }
}

struct DeficiencySignsSection: View {
    let signs: [String]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("SIGNS OF LOW LEVELS")
                        .font(Theme.headerFont)
                        .tracking(1)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    Text(isExpanded ? "Hide" : "Learn more")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.accent)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.accent)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    ForEach(signs, id: \.self) { sign in
                        HStack(alignment: .top, spacing: Theme.spacingSM) {
                            Text("•")
                                .foregroundColor(Theme.textSecondary)
                            Text(sign)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct GoalTag: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: goal.icon)
                .font(.system(size: 12))
            Text(goal.displayName)
                .font(Theme.captionFont)
        }
        .foregroundColor(Theme.textPrimary)
        .padding(.horizontal, Theme.spacingSM)
        .padding(.vertical, Theme.spacingXS)
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadiusSM)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}

struct EditSupplementSheet: View {
    let supplement: Supplement
    @Bindable var viewModel: SupplementsViewModel
    let modelContext: ModelContext
    let user: User?
    @Environment(\.dismiss) private var dismiss

    @State private var dosageString: String = ""
    @State private var dosageUnit: String = "mg"
    @State private var form: SupplementForm = .capsule
    @State private var customTime: Date = Date()

    let dosageUnits = ["mg", "mcg", "g", "IU", "ml"]

    private var isManualEntry: Bool {
        supplement.referenceId == nil
    }

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

                    // Time - only for manual entries
                    if isManualEntry {
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

                    Spacer()

                    Button(action: {
                        let dosage = Double(dosageString)
                        viewModel.updateSupplement(
                            supplement,
                            dosage: dosage,
                            dosageUnit: dosage != nil ? dosageUnit : nil,
                            form: form,
                            customTime: isManualEntry ? customTimeString : nil,
                            user: user,
                            modelContext: modelContext
                        )
                        dismiss()
                    }) {
                        Text("Save changes")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Theme.spacingLG)
            }
            .navigationTitle("Edit \(supplement.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .onAppear {
                dosageString = supplement.dosage.map { String($0) } ?? ""
                dosageUnit = supplement.dosageUnit ?? "mg"
                form = supplement.form ?? .capsule
                // Initialize custom time from supplement or default to 9:00 AM
                if let timeString = supplement.customTime {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    customTime = formatter.date(from: timeString) ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
                } else {
                    customTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                }
            }
        }
    }
}

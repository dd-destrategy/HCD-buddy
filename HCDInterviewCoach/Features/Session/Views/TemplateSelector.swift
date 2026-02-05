import SwiftUI

/// Allows users to select an interview template for session setup
struct TemplateSelector: View {
    @Binding var selectedTemplate: InterviewTemplate?
    @ObservedObject var templateManager: TemplateManager

    @State private var showCreateCustom = false
    @State private var searchText = ""

    var filteredTemplates: [InterviewTemplate] {
        if searchText.isEmpty {
            return templateManager.templates
        }
        return templateManager.templates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var builtInTemplates: [InterviewTemplate] {
        filteredTemplates.filter { $0.isBuiltIn }
    }

    var customTemplates: [InterviewTemplate] {
        filteredTemplates.filter { !$0.isBuiltIn }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Interview Templates")
                    .font(Typography.heading2)

                Spacer()

                Button(action: { showCreateCustom = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle")
                        Text("Create")
                    }
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                }
                .buttonStyle(.plain)
                .glassButton(isActive: false, style: .secondary)
                .accessibilityLabel("Create custom template")
                .accessibilityHint("Opens a form to create a new custom interview template")
            }

            // Search field with glass styling
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(Typography.body)

                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Typography.body)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .liquidGlass(
                material: .ultraThin,
                cornerRadius: CornerRadius.medium,
                borderStyle: .subtle,
                enableHover: false
            )

            // Templates list
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Built-in templates section
                    if !builtInTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Built-In Templates")
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.sm)

                            ForEach(builtInTemplates, id: \.id) { template in
                                TemplateRow(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id,
                                    action: {
                                        selectedTemplate = template
                                    }
                                )
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, Spacing.sm)

                    // Custom templates section
                    if !customTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Custom Templates")
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.sm)

                            ForEach(customTemplates, id: \.id) { template in
                                TemplateRow(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id,
                                    action: {
                                        selectedTemplate = template
                                    }
                                )
                            }
                        }
                    } else if !builtInTemplates.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus")
                                .foregroundColor(.secondary)
                            Text("Create a custom template")
                                .foregroundColor(.secondary)
                        }
                        .font(Typography.caption)
                        .padding(Spacing.md)
                    }
                }
            }

            // Selection summary
            if let template = selectedTemplate {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(template.name)
                                .font(Typography.heading3)
                            Text("\(template.duration) min - \(template.topics.count) topics")
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)

                            Text("Selected")
                                .font(Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(Spacing.sm)
                .liquidGlass(
                    material: .ultraThin,
                    cornerRadius: CornerRadius.medium,
                    borderStyle: .accent(.green),
                    enableHover: false
                )
            }
        }
        .padding(Spacing.lg)
        .sheet(isPresented: $showCreateCustom) {
            CreateCustomTemplateView(
                templateManager: templateManager,
                isPresented: $showCreateCustom
            )
            .glassSheet()
        }
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: InterviewTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                // Template details
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Text(template.name)
                            .font(Typography.bodyMedium)
                            .foregroundColor(.primary)

                        if template.isBuiltIn {
                            Text("Built-in")
                                .font(Typography.small)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                        }
                    }

                    Text(template.description)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.md) {
                        Label("\(template.duration) min", systemImage: "clock")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Label("\(template.topics.count) topics", systemImage: "list.bullet")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(Spacing.md)
            .glassCard(isSelected: isSelected, accentColor: .accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.name), \(template.duration) minutes, \(template.topics.count) topics")
        .accessibilityHint(isSelected ? "Currently selected" : "Double-tap to select this template")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Create Custom Template View

private struct CreateCustomTemplateView: View {
    @ObservedObject var templateManager: TemplateManager
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var description = ""
    @State private var duration = 45
    @State private var topicsText = ""
    @State private var selectedConsentVariant: ConsentVariant = .standard

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Form {
                    Section("Template Details") {
                        TextField("Template Name", text: $name)
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)

                        HStack {
                            Text("Duration (minutes)")
                            Spacer()
                            Stepper(value: $duration, in: 15...120, step: 5) {
                                Text("\(duration)")
                            }
                        }
                    }

                    Section("Topics") {
                        TextField("Enter topics (one per line)", text: $topicsText, axis: .vertical)
                            .lineLimit(5, reservesSpace: true)
                    }

                    Section("Consent Variant") {
                        Picker("Consent Type", selection: $selectedConsentVariant) {
                            ForEach([ConsentVariant.standard, .minimal, .research], id: \.self) { variant in
                                Text(variant.rawValue).tag(variant)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Create") {
                        createTemplate()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(16)
            }
            .navigationTitle("Create Template")
        }
    }

    private func createTemplate() {
        let topics = topicsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let template = InterviewTemplate(
            name: name,
            description: description,
            duration: duration,
            topics: topics,
            consentVariant: selectedConsentVariant,
            isBuiltIn: false
        )

        templateManager.saveCustomTemplate(template)
        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedTemplate: InterviewTemplate?

    ZStack {
        // Background to show glass effects
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        TemplateSelector(
            selectedTemplate: $selectedTemplate,
            templateManager: TemplateManager()
        )
        .glassCard()
        .padding()
    }
}

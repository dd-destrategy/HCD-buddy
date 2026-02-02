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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Interview Templates")
                    .font(.headline)

                Spacer()

                Button(action: { showCreateCustom = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Templates list
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Built-in templates section
                    if !builtInTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Built-In Templates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)

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
                        .padding(.vertical, 8)

                    // Custom templates section
                    if !customTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Custom Templates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)

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
                        HStack {
                            Image(systemName: "plus")
                                .foregroundColor(.secondary)
                            Text("Create a custom template")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                        .padding(12)
                    }
                }
            }

            // Selection summary
            if let template = selectedTemplate {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(template.duration) min • \(template.topics.count) topics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)

                            Text("Selected")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(8)
                .background(Color.green.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showCreateCustom) {
            CreateCustomTemplateView(
                templateManager: templateManager,
                isPresented: $showCreateCustom
            )
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
            HStack(alignment: .top, spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .blue : .secondary)

                // Template details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.name)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if template.isBuiltIn {
                            Text("Built-in")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(3)
                        }
                    }

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(template.duration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Label("\(template.topics.count) topics", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.blue : Color.secondary.opacity(0.2),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
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
    @State var selectedTemplate: InterviewTemplate?

    return TemplateSelector(
        selectedTemplate: $selectedTemplate,
        templateManager: TemplateManager()
    )
}

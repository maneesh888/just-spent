//
//  FilterStripView.swift
//  JustSpent
//
//  Created by Claude Code on 2025.
//

import SwiftUI

/// A horizontal strip of filter buttons for filtering expenses by date
struct FilterStripView: View {
    /// The currently selected filter
    @Binding var selectedFilter: DateFilter

    /// Whether to show the custom date range picker
    @State private var showCustomPicker = false

    /// The start date for custom range
    @State private var customStartDate = Date()

    /// The end date for custom range
    @State private var customEndDate = Date()

    /// Validation error message
    @State private var validationError: String?

    /// Available preset filters
    private let presetFilters: [DateFilter] = [.all, .today, .week, .month]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Preset filter buttons
                ForEach(presetFilters, id: \.self) { filter in
                    FilterChipButton(
                        title: filter.displayName,
                        isSelected: isFilterSelected(filter),
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        }
                    )
                    .accessibilityIdentifier("filter_chip_\(filter.displayName.lowercased())")
                }

                // Custom filter button
                FilterChipButton(
                    title: customButtonTitle,
                    isSelected: isCustomSelected,
                    action: {
                        // Initialize dates if switching to custom
                        if case .custom(let start, let end) = selectedFilter {
                            customStartDate = start
                            customEndDate = end
                        } else {
                            // Default to last 7 days
                            customEndDate = Date()
                            customStartDate = Calendar.current.date(byAdding: .day, value: -6, to: customEndDate)!
                        }
                        showCustomPicker = true
                    }
                )
                .accessibilityIdentifier("filter_chip_custom")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .accessibilityIdentifier("filter_strip")
        .sheet(isPresented: $showCustomPicker) {
            CustomDateRangePickerView(
                startDate: $customStartDate,
                endDate: $customEndDate,
                validationError: $validationError,
                onApply: {
                    let validation = DateFilterUtils.shared.validateCustomRange(
                        startDate: customStartDate,
                        endDate: customEndDate
                    )
                    if validation.isValid {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .custom(start: customStartDate, end: customEndDate)
                        }
                        showCustomPicker = false
                        validationError = nil
                    } else {
                        validationError = validation.firstError
                    }
                },
                onCancel: {
                    showCustomPicker = false
                    validationError = nil
                }
            )
            .presentationDetents([.medium])
        }
    }

    /// Whether a preset filter is selected (handles .all special case)
    private func isFilterSelected(_ filter: DateFilter) -> Bool {
        selectedFilter == filter
    }

    /// Whether custom filter is selected
    private var isCustomSelected: Bool {
        if case .custom = selectedFilter {
            return true
        }
        return false
    }

    /// Title for custom button (shows date range when selected)
    private var customButtonTitle: String {
        if let rangeString = selectedFilter.customRangeDisplayString {
            return rangeString
        }
        return "Custom"
    }
}

/// A chip-style button for filter selection
struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) filter")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Date range picker view for custom filter
struct CustomDateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var validationError: String?
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Start Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accessibilityIdentifier("custom_start_date_picker")
                }
                .padding(.horizontal)

                // End Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accessibilityIdentifier("custom_end_date_picker")
                }
                .padding(.horizontal)

                // Validation error
                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .accessibilityIdentifier("validation_error")
                }

                Spacer()

                // Apply button
                Button(action: onApply) {
                    Text("Apply Filter")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityIdentifier("apply_custom_filter_button")
            }
            .padding(.vertical)
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .accessibilityIdentifier("cancel_custom_filter_button")
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FilterStripView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state
            FilterStripViewPreview(initialFilter: .all)
                .previewDisplayName("All Selected")

            // Today selected
            FilterStripViewPreview(initialFilter: .today)
                .previewDisplayName("Today Selected")

            // Custom selected
            FilterStripViewPreview(
                initialFilter: .custom(
                    start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                    end: Date()
                )
            )
            .previewDisplayName("Custom Selected")
        }
    }
}

struct FilterStripViewPreview: View {
    @State var selectedFilter: DateFilter

    init(initialFilter: DateFilter) {
        _selectedFilter = State(initialValue: initialFilter)
    }

    var body: some View {
        VStack {
            FilterStripView(selectedFilter: $selectedFilter)
            Spacer()
            Text("Selected: \(selectedFilter.displayName)")
        }
    }
}
#endif

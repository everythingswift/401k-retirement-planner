import SwiftUI

struct SavedPlansView: View {
    let store: RetirementStore
    @Environment(PlanStore.self) private var planStore
    @Environment(\.dismiss) private var dismiss

    @State private var renameTarget: SavedPlan?
    @State private var renameDraft: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.05, blue: 0.08).ignoresSafeArea()

                if planStore.plans.isEmpty {
                    emptyState
                } else {
                    planList
                }
            }
            .navigationTitle("Saved Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.gold)
                }
            }
            .alert("Rename Plan", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("Name", text: $renameDraft)
                Button("Save") {
                    if let target = renameTarget {
                        let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            planStore.rename(target, to: trimmed)
                        }
                    }
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 44))
                .foregroundStyle(Color.gold.opacity(0.6))
            Text("No saved plans yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Tap Save on the Results screen to keep a configuration.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - List

    @ViewBuilder
    private var planList: some View {
        List {
            ForEach(planStore.plans) { plan in
                Button {
                    store.apply(plan)
                    dismiss()
                } label: {
                    row(plan)
                }
                .listRowBackground(Color.white.opacity(0.04))
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        renameDraft = plan.name
                        renameTarget = plan
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        planStore.delete(plan)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func row(_ plan: SavedPlan) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
            Text(plan.createdAt, style: .relative)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(plan.summary)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.gold.opacity(0.8))
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

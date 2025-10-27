//
//  SettingsView.swift
//  ClipboardManager
//
//  Settings view for configuring application preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Settings content
            Form {
                Section {
                    // Retention Period
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Retention Period")
                                    .font(.headline)
                                Text("How long to keep clipboard history")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Stepper(value: $settings.retentionDays, in: 1...365) {
                                HStack {
                                    TextField("Days", value: $settings.retentionDays, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(settings.retentionDays == 1 ? "day" : "days")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 32)
                        
                        // Quick presets
                        HStack(spacing: 8) {
                            Text("Quick:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach([7, 30, 90, 365], id: \.self) { days in
                                Button(action: {
                                    settings.retentionDays = days
                                }) {
                                    Text("\(days)d")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(settings.retentionDays == days ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                        .foregroundColor(settings.retentionDays == days ? .white : .primary)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 32)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Max Items
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Maximum Items")
                                    .font(.headline)
                                Text("How many items to keep in history")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Stepper(value: $settings.maxItems, in: 10...100) {
                                HStack {
                                    TextField("Items", value: $settings.maxItems, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(settings.maxItems == 1 ? "item" : "items")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.leading, 32)
                        
                        // Quick presets
                        HStack(spacing: 8) {
                            Text("Quick:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach([10, 30, 50, 100], id: \.self) { items in
                                Button(action: {
                                    settings.maxItems = items
                                }) {
                                    Text("\(items)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(settings.maxItems == items ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                        .foregroundColor(settings.maxItems == items ? .white : .primary)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 32)
                        
                        Text("📌 Pinned and sticky items don't count towards this limit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 32)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Storage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("About Clipboard Manager")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Database: ~/Library/Application Support/ClipboardManager/")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.leading, 28)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            
            // Footer with buttons
            Divider()
            
            HStack {
                Button("Reset to Defaults") {
                    settings.reset()
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 500, height: 500)
    }
}

#Preview {
    SettingsView()
}


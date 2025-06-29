//
//  _SidebarListView.swift
//  Stitch
//
//  Created by Christian J Clampitt on 3/8/24.
//

import SwiftUI

// Entire Figma sidebar is 320 pixels wide
let SIDEBAR_WIDTH: CGFloat = 320

let SIDEBAR_LIST_ITEM_ICON_AND_TEXT_SPACING: CGFloat = 4.0

#if targetEnvironment(macCatalyst)
let SIDEBAR_LIST_ITEM_ICON_AND_TEXT_AREA_HEIGHT: CGFloat = 20.0
let SIDEBAR_LIST_ITEM_ROW_COLORED_AREA_HEIGHT: CGFloat = 28.0
let SIDEBAR_LIST_ITEM_FONT: Font = STITCH_FONT // 14.53
#else
let SIDEBAR_LIST_ITEM_ICON_AND_TEXT_AREA_HEIGHT: CGFloat = 24.0
let SIDEBAR_LIST_ITEM_ROW_COLORED_AREA_HEIGHT: CGFloat = 32.0
let SIDEBAR_LIST_ITEM_FONT: Font = stitchFont(18)
#endif

struct SidebarListView: View {
    static let tabs = ["Layers", "Assets"]
    @State private var currentTab = ProjectSidebarTab.layers.rawValue
    
    @Bindable var graph: GraphState
    @Bindable var document: StitchDocumentViewModel
    let syncStatus: iCloudSyncStatus
    
    var body: some View {
        VStack {
            // TODO: re-enable tabs for asset manager
//            Picker("Sidebar Tabs", selection: self.$currentTab) {
//                ForEach(Self.tabs, id: \.self) { tab in
////                    HStack {
//                        //                        Image(systemName: tab.iconName)
//                        Text(tab)
//                        .width(200)
////                    }
//                }
//            }
//            .pickerStyle(.segmented)
            
            switch ProjectSidebarTab(rawValue: self.currentTab) {
            case .none:
                FatalErrorIfDebugView()
            case .some(let tab):
                switch tab {
                case .layers:
                    SidebarListScrollView(graph: graph,
                                          document: document,
                                          sidebarViewModel: graph.layersSidebarViewModel,
                                          tab: tab,
                                          syncStatus: syncStatus)
                case .assets:
                    FatalErrorIfDebugView()
                }
            }
        }
    }
}

struct SidebarListScrollView<SidebarObservable>: View where SidebarObservable: ProjectSidebarObservable {
    @State private var isBeingEditedAnimated = false
    
    @Bindable var graph: GraphState
    @Bindable var document: StitchDocumentViewModel
    @Bindable var sidebarViewModel: SidebarObservable
    let tab: ProjectSidebarTab
    let syncStatus: iCloudSyncStatus
    
    var isBeingEdited: Bool {
        self.sidebarViewModel.isEditing
    }
    
    var sectionHeader: some View {
        HStack {
            Text("Layer List")
            Spacer()
            SidebarEditButtonView(sidebarViewModel: self.sidebarViewModel)
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.WHITE_IN_LIGHT_MODE_BLACK_IN_DARK_MODE.opacity(0.85))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                listView
                Spacer()
                SidebarFooterView(sidebarViewModel: sidebarViewModel,
                                  syncStatus: syncStatus)
            }
            
#if !targetEnvironment(macCatalyst)
            sectionHeader
#endif
        }
    }
    
    // Note: sidebar-list-items is a flat list;
    // indentation is handled by calculated indentations.
    @MainActor @ViewBuilder
    var listView: some View {
        let allFlattenedItems = self.sidebarViewModel.getVisualFlattenedList()
        
        // Empty state
        if allFlattenedItems.isEmpty,
           !(document.storeDelegate?.navPath.first == .graphGenerationTableView) {
            ProjectSidebarEmptyView(document: document)
                .frame(width: NodeEmptyStateAboutButtonsView.defaultWidth)
        }
        
        // Normal layers sidebar view
        else {
            ScrollView(.vertical) {
#if !targetEnvironment(macCatalyst)
                // Empty view for sticky header space
                HStack { }
                    .height(30)
#endif
                
                ZStack(alignment: .topLeading) {
                    ForEach(allFlattenedItems) { item in
                        SidebarListItemSwipeView(
                            graph: graph,
                            document: document,
                            sidebarViewModel: sidebarViewModel,
                            gestureViewModel: item)
                    } // ForEach
                } // ZStack
                .frame(height: Double(CUSTOM_LIST_ITEM_VIEW_HEIGHT * allFlattenedItems.count),
                       alignment: .top)
            } // ScrollView // added
            .scrollContentBackground(.hidden)
            // TODO: remove some of these animations ?
            .animation(.spring(), value: isBeingEdited)
            .onChange(of: isBeingEdited) { _, newValue in
                // This handler enables all animations
                isBeingEditedAnimated = newValue
            }
        }
    }
}

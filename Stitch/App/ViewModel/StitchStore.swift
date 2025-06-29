//
//  StitchStore.swift
//  Stitch
//
//  Created by Elliot Boschwitz on 5/24/22.
//

import AudioKit
import SwiftUI
import StitchSchemaKit


@Observable
final class StitchStore: Sendable {
    
    @MainActor var graphTableLoadedRow: StitchDocumentViewModel? 
    
    // For now, just for debug purposes
    @MainActor var homescreenProjectSelectionState = HomescreenProjectSelectionState()
        
    @MainActor var allProjectUrls: [ProjectLoader]?
    let documentLoader = DocumentLoader()
    let clipboardEncoder = ClipboardEncoder()
    
    @MainActor var alertState: ProjectAlertState
    
    @MainActor
    var systems: [StitchSystemType: StitchSystemViewModel] = [:]
    
    // Components are unqiue to a user, not to a project,
    // and loaded when app loads.
    //    var defaultComponents = ComponentsDict()
    
    // Navigation path for viewing documents
    @MainActor var navPath: [StitchAppRouter] = []
    
    @MainActor var isShowingDrawer = false
    
    // MARK: must be stored here to prevent inspector retain cycle
    @MainActor var showsLayerInspector = false
    
    @MainActor var showsSampleProjectModal = false
    
    // Tracks ID of project which has a title that's currently getting modified
    @MainActor var projectIdForTitleEdit: GraphId?
    
    let environment: StitchEnvironment
    
    @MainActor
    init() {
        self.environment = StitchEnvironment()
        self.alertState = .init()
        
        // Remove cached data from previous session
        try? FileManager.default.removeItem(at: StitchFileManager.tempDir)
        
        // Sets up action dispatching
        GlobalDispatch.shared.delegate = self
        
        self.environment.dirObserver.delegate = self
        self.environment.store = self
    }
}

extension StitchStore {
    // Gets the Redux-style state for legacy purposes
    @MainActor
    func getState() -> AppState {
        AppState(
            isShowingDrawer: self.isShowingDrawer,
            projectIdForTitleEdit: self.projectIdForTitleEdit
        )
    }
    
    @MainActor
    var isShowingAIPreviewer: Bool {
        self.navPath.contains {
            switch $0 {
            case .graphGenerationTableView:
                return true
            default:
                return false
            }
        }
    }
}

final class ClipboardEncoderDelegate: DocumentEncodableDelegate {
    var lastEncodedDocument: StitchClipboardContent
    
    init() {
        self.lastEncodedDocument = .init()
    }
    
    func createSchema(from graph: GraphState) -> StitchClipboardContent {
        fatalError()
    }
    
    func willEncodeProject(schema: StitchClipboardContent) {}
    
    func update(from schema: StitchClipboardContent, rootUrl: URL?) { }
    
    func updateAsync(from schema: StitchClipboardContent) async { }
}

extension StitchStore {
    @MainActor
    func displayError(error: StitchFileError) {
        self.alertState.stitchFileError = error
    }
}

extension StitchStore: GlobalDispatchDelegate {
    @MainActor
    func reswiftDispatch(_ legacyAction: Action) {
        _handleAction(store: self, action: legacyAction)
    }
}

extension StitchStore {
    @MainActor
    var isCurrentProjectSelected: Bool {
        self.currentGraphId.isDefined
    }

    @MainActor
    var currentGraphId: GraphId? {
        currentDocument?.id
    }

    @MainActor
    var currentDocument: StitchDocumentViewModel? {
        if self.navPath.first == .graphGenerationTableView {
            return self.graphTableLoadedRow
        }
        return self.navPath.first?.document
    }
    
    var undoManager: StitchUndoManager {
        self.environment.undoManager
    }
}

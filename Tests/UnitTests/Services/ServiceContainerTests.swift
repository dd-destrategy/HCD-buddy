//
//  ServiceContainerTests.swift
//  HCD Interview Coach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for ServiceContainer dependency injection and service access
//

import XCTest
import SwiftData
@testable import HCDInterviewCoach

@MainActor
final class ServiceContainerTests: XCTestCase {

    var serviceContainer: ServiceContainer!

    override func setUp() {
        super.setUp()
        serviceContainer = ServiceContainer()
    }

    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }

    // MARK: - Test: Container Initialization

    func testContainerInitialization() {
        // Given/When: Container is initialized in setUp

        // Then: Container should be properly initialized
        XCTAssertNotNil(serviceContainer)
    }

    func testContainerInitialization_conformsToProtocol() {
        // Given: The service container

        // Then: Should conform to ServiceContaining protocol
        XCTAssertTrue(serviceContainer is ServiceContaining)
    }

    func testContainerInitialization_isObservableObject() {
        // Given: The service container

        // Then: Should be an ObservableObject for SwiftUI integration
        // This is verified by the fact that ServiceContainer conforms to ObservableObject
        let container: any ObservableObject = serviceContainer
        XCTAssertNotNil(container)
    }

    func testContainerInitialization_withDefaultDataManager() {
        // Given/When: Creating container with default data manager
        let container = ServiceContainer()

        // Then: Should have data manager access
        XCTAssertNotNil(container.dataManager)
    }

    func testContainerInitialization_withCustomDataManager() {
        // Given: The shared data manager
        let sharedDataManager = DataManager.shared

        // When: Creating container with specific data manager
        let container = ServiceContainer(dataManager: sharedDataManager)

        // Then: Should use the provided data manager
        XCTAssertTrue(container.dataManager === sharedDataManager)
    }

    // MARK: - Test: DataManager Access

    func testDataManagerAccess() {
        // Given: An initialized container

        // When: Accessing data manager
        let dataManager = serviceContainer.dataManager

        // Then: Should return a valid DataManager
        XCTAssertNotNil(dataManager)
    }

    func testDataManagerAccess_hasContainer() {
        // Given: The service container

        // When: Accessing data manager's container
        let container = serviceContainer.dataManager.container

        // Then: Should have a valid model container
        XCTAssertNotNil(container)
    }

    func testDataManagerAccess_hasMainContext() {
        // Given: The service container

        // When: Accessing data manager's main context
        let context = serviceContainer.dataManager.mainContext

        // Then: Should have a valid main context
        XCTAssertNotNil(context)
    }

    func testDataManagerAccess_canCreateBackgroundContext() {
        // Given: The service container

        // When: Creating a background context
        let backgroundContext = serviceContainer.dataManager.newBackgroundContext()

        // Then: Should return a new context
        XCTAssertNotNil(backgroundContext)
    }

    // MARK: - Test: TemplateManager Access

    func testTemplateManagerAccess() {
        // Given: An initialized container

        // When: Accessing template manager
        let templateManager = serviceContainer.templateManager

        // Then: Should return a valid TemplateManager
        XCTAssertNotNil(templateManager)
    }

    func testTemplateManagerAccess_hasTemplates() {
        // Given: The service container

        // When: Accessing templates
        let templates = serviceContainer.templateManager.templates

        // Then: Should have built-in templates loaded
        XCTAssertFalse(templates.isEmpty)
    }

    func testTemplateManagerAccess_hasBuiltInTemplates() {
        // Given: The service container

        // When: Getting built-in templates
        let builtInTemplates = serviceContainer.templateManager.getBuiltInTemplates()

        // Then: Should have built-in templates
        XCTAssertGreaterThanOrEqual(builtInTemplates.count, 4)
    }

    func testTemplateManagerAccess_canSaveCustomTemplate() {
        // Given: The service container
        let initialCount = serviceContainer.templateManager.getCustomTemplates().count

        // When: Saving a custom template
        let template = InterviewTemplate(
            name: "Test Custom",
            description: "Test",
            duration: 30,
            topics: ["Topic"],
            consentVariant: .standard,
            isBuiltIn: false
        )
        serviceContainer.templateManager.saveCustomTemplate(template)

        // Then: Custom template should be saved
        let newCount = serviceContainer.templateManager.getCustomTemplates().count
        XCTAssertEqual(newCount, initialCount + 1)
    }

    // MARK: - Test: Singleton Behavior

    func testSingletonBehavior_dataManager() {
        // Given: Multiple containers
        let container1 = ServiceContainer()
        let container2 = ServiceContainer()

        // When: Comparing data managers
        // Both should reference DataManager.shared

        // Then: Should be the same instance (singleton)
        XCTAssertTrue(container1.dataManager === container2.dataManager)
    }

    func testSingletonBehavior_dataManagerIsShared() {
        // Given: The service container

        // When: Comparing with DataManager.shared
        let dataManager = serviceContainer.dataManager

        // Then: Should be the shared instance
        XCTAssertTrue(dataManager === DataManager.shared)
    }

    func testSingletonBehavior_templateManagerNotShared() {
        // Given: Multiple containers
        let container1 = ServiceContainer()
        let container2 = ServiceContainer()

        // When: Comparing template managers

        // Then: Should be different instances (not singleton)
        XCTAssertFalse(container1.templateManager === container2.templateManager)
    }

    func testSingletonBehavior_containerNotSingleton() {
        // Given: Multiple containers
        let container1 = ServiceContainer()
        let container2 = ServiceContainer()

        // Then: Containers should be different instances
        XCTAssertFalse(container1 === container2)
    }

    // MARK: - Test: Thread Safety

    func testThreadSafety_dataManagerAccess() async {
        // Given: Multiple concurrent accesses
        let container = serviceContainer!

        // When: Accessing data manager from multiple tasks
        await withTaskGroup(of: DataManager.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    return container.dataManager
                }
            }

            // Then: All accesses should return the same instance
            var managers: [DataManager] = []
            for await manager in group {
                managers.append(manager)
            }

            XCTAssertEqual(managers.count, 10)
            XCTAssertTrue(managers.allSatisfy { $0 === managers[0] })
        }
    }

    func testThreadSafety_templateManagerOperations() async {
        // Given: The service container
        let container = serviceContainer!

        // When: Performing concurrent template operations
        await withTaskGroup(of: Void.self) { group in
            // Multiple reads
            for _ in 0..<5 {
                group.addTask { @MainActor in
                    _ = container.templateManager.templates
                    _ = container.templateManager.getBuiltInTemplates()
                }
            }

            // Multiple writes
            for i in 0..<5 {
                group.addTask { @MainActor in
                    let template = InterviewTemplate(
                        name: "Concurrent \(i)",
                        description: "Test",
                        duration: 30,
                        topics: ["Topic"],
                        consentVariant: .standard,
                        isBuiltIn: false
                    )
                    container.templateManager.saveCustomTemplate(template)
                }
            }
        }

        // Then: Operations should complete without crash
        XCTAssertGreaterThanOrEqual(serviceContainer.templateManager.getCustomTemplates().count, 5)
    }

    func testThreadSafety_contextOperations() async throws {
        // Given: The service container's data manager
        let dataManager = serviceContainer.dataManager

        // When: Performing concurrent context operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    let session = Session(
                        participantName: "Concurrent User \(i)",
                        projectName: "Concurrent Project",
                        sessionMode: .full
                    )
                    dataManager.mainContext.insert(session)
                    try? dataManager.save()
                }
            }
        }

        // Then: Should complete without crash
        // Clean up
        try dataManager.deleteAllData()
    }

    // MARK: - Test: Protocol Conformance

    func testProtocolConformance_serviceContaining() {
        // Given: A ServiceContainer instance

        // When: Casting to protocol type
        let containing: ServiceContaining = serviceContainer

        // Then: Should provide access to both managers
        XCTAssertNotNil(containing.templateManager)
        XCTAssertNotNil(containing.dataManager)
    }

    func testProtocolConformance_templateManagerType() {
        // Given: The protocol reference
        let containing: ServiceContaining = serviceContainer

        // When: Accessing template manager
        let templateManager = containing.templateManager

        // Then: Should be a TemplateManager instance
        XCTAssertTrue(templateManager is TemplateManager)
    }

    func testProtocolConformance_dataManagerType() {
        // Given: The protocol reference
        let containing: ServiceContaining = serviceContainer

        // When: Accessing data manager
        let dataManager = containing.dataManager

        // Then: Should be a DataManager instance
        XCTAssertTrue(dataManager is DataManager)
    }

    // MARK: - Test: Service Dependencies

    func testServiceDependencies_templateManagerIndependent() {
        // Given: The service container

        // When: Template manager operates
        let templates = serviceContainer.templateManager.templates

        // Then: Should work without requiring data manager operations
        XCTAssertFalse(templates.isEmpty)
    }

    func testServiceDependencies_dataManagerIndependent() throws {
        // Given: The service container

        // When: Data manager operates
        let context = serviceContainer.dataManager.mainContext
        let descriptor = FetchDescriptor<Session>()
        let sessions = try context.fetch(descriptor)

        // Then: Should work independently
        XCTAssertNotNil(sessions)
    }

    // MARK: - Test: Container State

    func testContainerState_templateManagerPublished() {
        // Given: The service container
        let initialTemplateCount = serviceContainer.templateManager.templates.count

        // When: Modifying template manager
        let template = InterviewTemplate(
            name: "State Test",
            description: "Test",
            duration: 30,
            topics: ["Topic"],
            consentVariant: .standard,
            isBuiltIn: false
        )
        serviceContainer.templateManager.saveCustomTemplate(template)

        // Then: Changes should be reflected
        let newCount = serviceContainer.templateManager.templates.count
        XCTAssertEqual(newCount, initialTemplateCount + 1)
    }

    func testContainerState_multipleModifications() {
        // Given: The service container
        let initialCount = serviceContainer.templateManager.getCustomTemplates().count

        // When: Multiple modifications
        for i in 0..<3 {
            let template = InterviewTemplate(
                name: "Batch \(i)",
                description: "Test",
                duration: 30,
                topics: ["Topic"],
                consentVariant: .standard,
                isBuiltIn: false
            )
            serviceContainer.templateManager.saveCustomTemplate(template)
        }

        // Then: All modifications should be applied
        let finalCount = serviceContainer.templateManager.getCustomTemplates().count
        XCTAssertEqual(finalCount, initialCount + 3)
    }
}

// MARK: - Mock ServiceContainer for Testing

/// A mock service container for dependency injection testing
final class MockServiceContainer: ServiceContaining {
    let templateManager: TemplateManager
    let dataManager: DataManager

    @MainActor
    init() {
        self.dataManager = DataManager.shared
        self.templateManager = TemplateManager()
    }
}

// MARK: - MockServiceContainer Tests

extension ServiceContainerTests {

    func testMockServiceContainer_conformsToProtocol() {
        // Given: A mock container
        let mockContainer = MockServiceContainer()

        // Then: Should conform to ServiceContaining
        XCTAssertTrue(mockContainer is ServiceContaining)
    }

    func testMockServiceContainer_providesServices() {
        // Given: A mock container
        let mockContainer = MockServiceContainer()

        // Then: Should provide all required services
        XCTAssertNotNil(mockContainer.templateManager)
        XCTAssertNotNil(mockContainer.dataManager)
    }

    func testServiceContaining_polymorphism() {
        // Given: Both real and mock containers
        let realContainer: ServiceContaining = serviceContainer
        let mockContainer: ServiceContaining = MockServiceContainer()

        // When: Accessing services through protocol
        let realTemplates = realContainer.templateManager.templates
        let mockTemplates = mockContainer.templateManager.templates

        // Then: Both should work through the protocol interface
        XCTAssertFalse(realTemplates.isEmpty)
        XCTAssertFalse(mockTemplates.isEmpty)
    }
}

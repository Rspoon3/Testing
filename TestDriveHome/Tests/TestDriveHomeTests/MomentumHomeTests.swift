import Testing
@testable import MomentumHome

@Suite("MomentumHome Tests")
struct MomentumHomeTests {

    @Test("WorkoutListViewModel initializes with empty state")
    func viewModelInitializes() {
        let viewModel = WorkoutListViewModel()
        #expect(viewModel.healthEvents.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }
}

import Testing
@testable import OsaifuModel

@Suite("The step the crown takes")
struct AmountStepTests {

    @Test("The step follows the amount", arguments: [
        (0, 10), (10, 10), (999, 10),
        (1_000, 100), (1_280, 100), (9_999, 100),
        (10_000, 1_000), (250_000, 1_000)
    ])
    func stepFollowsAmount(amount: Int, step: Int) {
        #expect(AmountStep.of(amount) == step)
    }

    @Test("A press up lands on a multiple of the step")
    func upSnaps() {
        #expect(AmountStep.up(from: 0) == 10)
        #expect(AmountStep.up(from: 1_280) == 1_300)
        #expect(AmountStep.up(from: 12_345) == 13_000)
    }

    @Test("A press down lands on a multiple of the step")
    func downSnaps() {
        #expect(AmountStep.down(from: 1_280) == 1_200)
        #expect(AmountStep.down(from: 12_345) == 12_000)
    }

    @Test("Up and down across a boundary give back the amount")
    func boundaryIsSymmetric() {
        #expect(AmountStep.down(from: 1_000) == 990)
        #expect(AmountStep.up(from: 990) == 1_000)
        #expect(AmountStep.down(from: 10_000) == 9_900)
        #expect(AmountStep.up(from: 9_900) == 10_000)
    }

    @Test("The amount never goes below zero")
    func zeroHolds() {
        #expect(AmountStep.down(from: 0) == 0)
        #expect(AmountStep.down(from: 5) == 0)
    }

    @Test("The amount never goes above the maximum")
    func maximumHolds() {
        #expect(AmountStep.up(from: AmountStep.maximum) == AmountStep.maximum)
    }
}

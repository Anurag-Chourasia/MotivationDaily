import Foundation

struct AdviceSlipResponseDTO: Decodable {
    let slip: AdviceSlipDTO
}

struct AdviceSlipDTO: Decodable {
    let id: Int
    let advice: String
}

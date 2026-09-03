//
//  Array+Extension.swift
//  tetris
//
//  Created by Rishi Jansari on 03/09/2026.
//

import Foundation

extension Array where Element == [Bool] {
    func rotatedClockwise() -> [[Bool]] {
        guard !self.isEmpty, self.count == self[0].count else { return self }
        let n = self.count
        
        var rotated = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        
        for r in 0..<n {
            for c in 0..<n {
                rotated[c][n - 1 - r] = self[r][c]
            }
        }
        return rotated
    }
    
    func rotatedCounterClockwise() -> [[Bool]] {
        guard !self.isEmpty, self.count == self[0].count else { return self }
        let n = self.count
        
        var rotated = [[Bool]](repeating: [Bool](repeating: false, count: n), count: n)
        
        for r in 0..<n {
            for c in 0..<n {
                rotated[n - 1 - c][r] = self[r][c]
            }
        }
        return rotated
    }
}

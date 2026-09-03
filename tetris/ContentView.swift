//
//  ContentView.swift
//  tetris
//
//  Created by Rishi Jansari on 01/09/2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var gameBoard: [[Tile]]
    @State private var currentPiece: [[Bool]] = Shape.t
    @State private var nextPiece: [[Bool]] = Shape.z
    @State private var nextPieces: [[[Bool]]] = Shape.allShapes
    @State private var pieceColor = Color.red
    @State private var nextColor = Color.orange
    @State private var nextColors = ContentView.colors
    @State private var pieceRow = 0
    @State private var pieceCol = 3
    @State private var isGameOver = false
    @State private var isFreshStart = true
    @State private var linesCleared = 0
    @State private var score = 0
    @AppStorage("highScore") private var highScore = 0
    @State private var gamepad = GamepadManager()
    
    private var level: Int {
        (linesCleared / 10) + 1
    }
    
    private var projectedRow: Int {
        var testRow = pieceRow
        while canMove(toRow: testRow + 1, toCol: pieceCol, piece: currentPiece) {
            testRow += 1
        }
        return testRow
    }

    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    static let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
    
    init() {
        var tempGameBoard: [[Tile]] = []
        for _ in 0..<20 {
            var tempRow: [Tile] = []
            for _ in 0..<10 {
                tempRow.append(Tile(color: .clear))
            }
            tempGameBoard.append(tempRow)
        }
        _gameBoard = State(initialValue: tempGameBoard)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                        GridRow {
                            ScrollView(.horizontal) {
                                Text("Score: \(score)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollIndicators(.hidden)
                            ScrollView(.horizontal) {
                                Text("High Score: \(highScore)")
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .scrollIndicators(.hidden)
                        }
                        GridRow {
                            Text("Level: \(level)")
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Lines Cleared: \(linesCleared)")
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .foregroundStyle(.white)
                    .font(.system(.headline, design: .monospaced, weight: .regular))
                    .monospacedDigit()
                    .padding()
                    
                    Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
                        ForEach(0..<22) { row in
                            GridRow(alignment: .center) {
                                ForEach(0..<12) { col in
                                    if row == 0 || col == 0 || row == 21 || col == 11 {
                                        ZStack {
                                            Rectangle()
                                                .fill(.black)
                                                .frame(width: 30, height: 30)
                                            
                                            Rectangle()
                                                .fill(.gray.opacity(0.5))
                                                .frame(width: 30, height: 30)
                                            
                                            Rectangle()
                                                .fill(.white)
                                                .frame(width: 25, height: 25)
                                                .offset(x:1, y:1)
                                            
                                            Rectangle()
                                                .fill(.gray)
                                                .frame(width: 25, height: 25)
                                        }
                                    } else {
                                        let isFallingPiece = isPieceBlock(boardRow: row-1, boardCol: col-1)
                                        let isGhost = isGhostBlock(boardRow: row-1, boardCol: col-1)
                                        let tileColor: Color = isFallingPiece ? pieceColor : gameBoard[row-1][col-1].color
                                        
                                        ZStack {
                                            Rectangle()
                                                .fill(.black)
                                                .frame(width: 30, height: 30)
                                            
                                            if !isFreshStart {
                                                if isGhost {
                                                    Rectangle()
                                                        .strokeBorder(
                                                            Color.white.opacity(0.8),
                                                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 2])
                                                        )
                                                        .background(Rectangle().fill(pieceColor.opacity(0.15)))
                                                        .frame(width: 25, height: 25)
                                                }
                                                
                                                if tileColor != .clear {
                                                    Rectangle()
                                                        .fill(tileColor.opacity(0.5))
                                                        .frame(width: 30, height: 30)
                                                    
                                                    Rectangle()
                                                        .fill(tileColor)
                                                        .frame(width: 25, height: 25)
                                                }
                                            }
                                        }
                                        .onTapGesture {
                                            // tap gesture to rotate piece
                                            if isFallingPiece || isGhost {
                                                let rotated = currentPiece.rotatedClockwise()
                                                if canMove(toRow: pieceRow, toCol: pieceCol, piece: rotated) {
                                                    currentPiece = rotated
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .gesture(
                    // swipe gestures for left, right and down
                    DragGesture(minimumDistance: 50)
                        .onEnded { new in
                            if new.translation.width > 50 && abs(new.translation.height) < 60 && canMove(toRow: pieceRow, toCol: pieceCol + 1, piece: currentPiece) {
                                pieceCol += 1
                            } else if new.translation.width < -50 && abs(new.translation.height) < 60 && canMove(toRow: pieceRow, toCol: pieceCol - 1, piece: currentPiece) {
                                pieceCol -= 1
                            } else if new.translation.height > 140 && abs(new.translation.width) < 80 {
                                var droppedRows = 0
                                while canMove(toRow: pieceRow + 1, toCol: pieceCol, piece: currentPiece) {
                                    pieceRow += 1
                                    droppedRows += 1
                                }
                                score += droppedRows * 2
                                lockPiece()
                            } else if new.translation.height > 50 && abs(new.translation.width) < 40 && canMove(toRow: pieceRow + 1, toCol: pieceCol, piece:currentPiece) {
                                pieceRow += 1
                                score += 1
                            }
                        }
                )
                if isFreshStart {
                    Button {
                        isFreshStart = false
                        restart()
                    } label: {
                        Text("Play")
                            .padding()
                            .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    }
                    .tint(ContentView.colors.randomElement()!)
                    .buttonStyle(.glassProminent)
                    .foregroundStyle(.white)
                }
            }
            .onReceive(timer) { _ in
                guard !isGameOver, !isFreshStart else { return }
                // check if can go down
                if canMove(toRow: pieceRow + 1, toCol: pieceCol, piece: currentPiece) {
                    pieceRow += 1
                } else {
                    // lock in place
                    lockPiece()
                }
            }
            .alert("Game Over", isPresented: $isGameOver) {
                Button("New Game") {
                    restart()
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text("Tetris")
                        .font(.system(.title, design: .monospaced, weight: .black))
                        .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if !isFreshStart && !nextPiece.isEmpty {
                        Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
                            ForEach(nextPiece.indices, id: \.self) { row in
                                GridRow(alignment: .center) {
                                    ForEach(nextPiece[row].indices, id: \.self) { col in
                                        if !nextPiece[row].allSatisfy({ $0 == false }) {
                                            if nextPiece[row][col] {
                                                ZStack {
                                                    Rectangle()
                                                        .fill(.black)
                                                        .frame(width: 14, height: 14)
                                                    
                                                    Rectangle()
                                                        .fill(nextColor.opacity(0.5))
                                                        .frame(width: 14, height: 14)
                                                    
                                                    Rectangle()
                                                        .fill(nextColor)
                                                        .frame(width: 12, height: 12)
                                                }
                                            } else {
                                                Color.clear
                                                    .frame(width: 14, height: 14)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restart", systemImage: "arrow.trianglehead.clockwise") {
                        restart()
                    }
                    .disabled(isFreshStart)
                }
            }
            .onAppear {
                setupGamepadBindings()
            }
        }
    }
    
    private func setupGamepadBindings() {
        // Left
        gamepad.onMoveLeft = {
            guard !isGameOver, !isFreshStart else { return }
            if canMove(toRow: pieceRow, toCol: pieceCol - 1, piece: currentPiece) {
                pieceCol -= 1
            }
        }
        
        // Right
        gamepad.onMoveRight = {
            guard !isGameOver, !isFreshStart else { return }
            if canMove(toRow: pieceRow, toCol: pieceCol + 1, piece: currentPiece) {
                pieceCol += 1
            }
        }
        
        // Soft Drop
        gamepad.onSoftDrop = {
            guard !isGameOver, !isFreshStart else { return }
            if canMove(toRow: pieceRow + 1, toCol: pieceCol, piece: currentPiece) {
                pieceRow += 1
            }
        }
        
        // Rotate
        gamepad.onRotate = {
            guard !isGameOver, !isFreshStart else { return }
            let rotated = currentPiece.rotatedClockwise()
            if canMove(toRow: pieceRow, toCol: pieceCol, piece: rotated) {
                currentPiece = rotated
            }
        }
        
        // Hard Drop (also dismisses game over if active)
        gamepad.onHardDrop = {
            if isGameOver || isFreshStart {
                isFreshStart = false
                restart()
                return
            }
            
            while canMove(toRow: pieceRow + 1, toCol: pieceCol, piece: currentPiece) {
                pieceRow += 1
            }
            lockPiece()
        }
        
        // Restart (+ / - buttons)
        gamepad.onRestart = {
            if isFreshStart {
                isFreshStart = false
            }
            restart()
        }
    }
    
    private func isPieceBlock(boardRow: Int, boardCol: Int) -> Bool {
        let r = boardRow - pieceRow
        let c = boardCol - pieceCol
        
        if r >= 0 && r < currentPiece.count && c >= 0 && c < currentPiece[r].count {
            return currentPiece[r][c]
        }
        return false
    }
    
    private func isGhostBlock(boardRow: Int, boardCol: Int) -> Bool {
        guard projectedRow != pieceRow else { return false }
        
        let r = boardRow - projectedRow
        let c = boardCol - pieceCol
        
        if r >= 0 && r < currentPiece.count && c >= 0 && c < currentPiece[r].count {
            return currentPiece[r][c]
        }
        return false
    }
    
    private func canMove(toRow: Int, toCol: Int, piece: [[Bool]]) -> Bool {
        for r in 0..<piece.count {
            for c in 0..<piece[r].count {
                if piece[r][c] {
                    let targetR = toRow + r
                    let targetC = toCol + c
                    
                    if targetC < 0 || targetC >= 10 || targetR >= 20 {
                        return false
                    }
                    
                    if targetR >= 0 && gameBoard[targetR][targetC].color != .clear {
                        return false
                    }
                }
            }
        }
        return true
    }

    private func lockPiece() {
        for r in 0..<currentPiece.count {
            for c in 0..<currentPiece[r].count {
                if currentPiece[r][c] {
                    let targetR = pieceRow + r
                    let targetC = pieceCol + c
                    
                    if targetR >= 0 && targetR < 20 && targetC >= 0 && targetC < 10 {
                        gameBoard[targetR][targetC].color = pieceColor
                    }
                }
            }
        }
        
        clearLines()
        spawnPiece()
    }
    
    private func clearLines() {
        let initialRowCount = gameBoard.count
        
        gameBoard.removeAll(where: { row in
            row.allSatisfy { $0.color != .clear }
        })
        
        let clearedCount = initialRowCount - gameBoard.count
        
        while gameBoard.count < 20 {
            var emptyRow: [Tile] = []
            for _ in 0..<10 {
                emptyRow.append(Tile(color: .clear))
            }
            gameBoard.insert(emptyRow, at: 0)
        }
        
        if clearedCount > 0 {
            linesCleared += clearedCount
            
            let basePoints: Int
            switch clearedCount {
                case 1: basePoints = 100
                case 2: basePoints = 300
                case 3: basePoints = 500
                case 4: basePoints = 800
                default: basePoints = 0
            }
            
            score += basePoints * level
        }
    }
    
    private func spawnPiece() {
        let candidatePiece = nextPiece
        let candidateColor = nextColor
        
        if !canMove(toRow: 0, toCol: 3, piece: candidatePiece) {
            highScore = max(score, highScore)
            isGameOver = true
            return
        }
        
        currentPiece = candidatePiece
        if nextPieces.count == 1 {
            nextPieces = Shape.allShapes.shuffled()
        } else {
            nextPieces.removeFirst()
        }
        nextPiece = nextPieces[0]
        
        pieceColor = candidateColor
        if nextColors.count == 1 {
            nextColors = ContentView.colors.shuffled()
        } else {
            nextColors.removeFirst()
        }
        nextColor = nextColors[0]
        
        pieceRow = 0
        pieceCol = 3
    }
    
    private func restart() {
        for i in gameBoard.indices {
            for j in gameBoard[i].indices {
                gameBoard[i][j].color = .clear
            }
        }
        
        nextPieces = Shape.allShapes.shuffled()
        currentPiece = nextPieces[0]
        nextPieces.removeFirst()
        nextPiece = nextPieces[0]
        
        nextColors = ContentView.colors.shuffled()
        pieceColor = nextColors[0]
        nextColors.removeFirst()
        nextColor = nextColors[0]
        
        pieceRow = 0
        pieceCol = 3
        isGameOver = false
        
        score = 0
        linesCleared = 0
    }
}

#Preview {
    ContentView()
}

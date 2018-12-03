import Foundation
import UIKit
import PlaygroundSupport


// https://nghiatran.me/longest-common-subsequence-diff-part-1/
// https://nghiatran.me/diff-in-real-world-ios-part-2/
extension String {
    func char(at i: Int) -> String {
        return String((self as NSString).character(at: i))
    }
}

///////////////////////
//  NAIVE APPROACH
// Time complexity is O(2^n)
//////////////////////
// Recursive func to leng of LCS
func LCS(_ a: String, _ b: String) -> Int {
    if a.isEmpty || b.isEmpty {
        return 0
    }
    
    // Preperation
    let lengthA = a.count
    let lengthB = b.count
    
    let aIndex = a.index(a.endIndex, offsetBy: -1)
    let bIndex = b.index(b.endIndex, offsetBy: -1)
    
    // Sub-Problem
    if a.char(at: lengthA - 1) == b.char(at: lengthB - 1) {
        // MATCH
        return 1 + LCS(a.substring(to: aIndex), b.substring(to: bIndex))
    } else {
        // NOT MATCH
        return max(LCS(a.substring(to: aIndex), b), LCS(a, b.substring(to: bIndex)))
    }
}
// Test
let a = "acbaed"
let b = "abcadf"
print(LCS(a, b)) // 4

// Unicode
let x = "😇🙌😉💰🎹"
let y = "🙌🍒💰✈️🎹😎🔴"
print(LCS(x, y)) // 3



////////////////////
// Memoryzation table
////////////////////

// It costs O(n²).

// A = “ADFGT” and B = “AFOXT
struct MemorizationTable<T: Equatable> {
    static func buildTable(x: [T], y: [T]) -> [[Int]] {
        // Create a 2D table, and fill it with 0s
        let n = x.count
        let m = y.count
        
        var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        
        // Iterate from top-left corner --> bottom-right corner
        for i in 0...n {
            for j in 0...m {
                if i == 0 || j == 0 {
                    table[i][j] = 0
                }
                else if x[i-1] == y[j-1] {
                    // MATCH
                    table[i][j] = table[i-1][j-1] + 1
                }
                else { // NOT MATCH
                    table[i][j] = max(table[i-1][j], table[i][j-1])
                }
            }
        }
        return table
    }
}


extension Array where Element: Equatable {
    func LCS(_ other: [Element]) -> [Element] {
        
        let table = MemorizationTable.buildTable(x: self, y: other)
        return self.lcsFromMemorizationTable(table, self, other, self.count, j: other.count)
    }
    
    fileprivate func lcsFromMemorizationTable(_ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, j: Int) -> [Element] {
        
        // Exit
        if i == 0 || j == 0 {
            return []
        }
        // MATCH -> Get the Element
        else if x[i-1] == y[j-1] {
            return lcsFromMemorizationTable(table, x, y, i - 1, j: j - 1) + [x[i-1]]
        }
        // TOP
        else if table[i-1][j] > table[i][j-1] {
            return lcsFromMemorizationTable(table, x, y, i - 1, j: j)
        }
        // LEFT
        // table[i][j-1] > table[i-1][j]
        else {
            return lcsFromMemorizationTable(table, x, y, i, j: j - 1)
        }
    }
}

// Test with string
// Convert [CharacterView] -> [String]
let aStringArray = "acbaed".map {String($0)}
let bStringArray = "abcadfa".map {String($0)}

let lcs = aStringArray.LCS(bStringArray) //
print(lcs) //  ["a", "b", "a", "d"]

// Test with array of Custom model
struct UserObj {
    let name: String
}

extension UserObj: Equatable {
    public static func ==(lhs: UserObj, rhs: UserObj) -> Bool {
        return lhs.name == rhs.name
    }
}

let localUsers = [UserObj(name: "Nghia Tran"),
                  UserObj(name: "nghiatran.me"),
                  UserObj(name: "SaiGon"),
                  UserObj(name: "Algorithm")]
let remoteUsers = [UserObj(name: "Kamakura"),
                   UserObj(name: "Nghia Tran"),
                   UserObj(name: "Algorithm"),
                   UserObj(name: "SaiGon"),
                   UserObj(name: "Somewhere")]
let lcsUser = localUsers.LCS(remoteUsers)
lcsUser.forEach { (user) in
    print(user.name)
}

// Solving of TV and CV Index Diffing
// We need more than LCS, need "how" A can transform into B. This can be extracted from the Mermorization table too///

// Transform Representation
enum DiffTransform<T> {
    // represent for reload/insert/delete in TV/CV
    // Int: index that needs to be transformed
    // T: Generic Data
    case reload(Int, T)
    case insert(Int, T)
    case delete(Int, T)
}

extension DiffTransform: CustomStringConvertible, CustomDebugStringConvertible {
    
    // Value - quick access
    var value: T {
        switch self {
        case .reload(_, let value):
            return value
        case .insert(_, let value):
            return value
        case .delete(_, let value):
            return value
        }
    }
    
    var index: Int {
        switch self {
        case .reload(let index, _):
            return index
        case .insert(let index, _):
            return index
        case .delete(let index, _):
            return index
        }
    }
    
    var description: String {
        return self.stringValue
    }
    var debugDescription: String {
        return self.stringValue
    }
    
    // Is insertion
    var isInsertion: Bool {
        switch self {
        case .insert:
            return true
        default:
            return false
        }
    }
    
    // Is Deletion
    var isDeletion: Bool {
        switch self {
        case .delete:
            return true
        default:
            return false
        }
    }
    
    // Is insertion
    var isReload: Bool {
        switch self {
        case .reload:
            return true
        default:
            return false
        }
    }
    
    private var stringValue: String {
        switch self {
        case .reload(let index, let value):
            return "Reload((\(index))[\(value)])"
        case .insert(let index, let value):
            return "Insert((\(index))[\(value)])"
        case .delete(let index, let value):
            return "Delete((\(index))[\(value)])"
        }
    }
    
}

struct Diff<T> {
    typealias Element = DiffTransform<T>
    
    // Result
    private var _result: [Element] = []
    var result: [Element] {
        return self._result
    }
    
    // Insertion
    var insertions: [Element] {
        return self.result.filter { $0.isInsertion }
    }
    
    // Deleteions
    var deletions: [Element] {
        return self.result.filter { $0.isDeletion }
    }
    
    // Reload
    var reloads: [Element] {
        return self.result.filter { $0.isReload }
    }
    
    mutating func append(item: Element) {
        self._result.append(item)
    }
}


// Override + : Diff + DiffTransform
func +<T> (left: Diff<T>, right: DiffTransform<T>) -> Diff<T> {
    var left = left
    left.append(item: right)
    return left
}

extension Array where Element: Equatable {
    func diff(_ other: [Element]) -> Diff<Element> {
        // Build memorization table
        let table = MemorizationTable.buildTable(x: self, y: other)
        
        // Get Diff
        return Array.diffFromMemorizationTable(table, self, other, self.count, other.count)
    }
    
    fileprivate static func diffFromMemorizationTable(_ table: [[Index]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {
        // Exit
        if i == 0 && j == 0 {
            return Diff<Element>()
        }
        // Insert
        else if i == 0 {
            return diffFromMemorizationTable(table, x, y, i, j-1) + DiffTransform.insert(j-1, y[j-1])
        }
        // Delete
        else if j == 0 {
            return diffFromMemorizationTable(table, x, y, i-1, j) + DiffTransform.delete(i-1, x[i-1])
        }
        // Delete
        else if table[i][j] == table[i-1][j] {
            return diffFromMemorizationTable(table, x, y, i-1, j) + DiffTransform.delete(i-1, x[i-1])
        }
        // Insert
        else if table[i][j] == table[i][j-1] {
            return diffFromMemorizationTable(table, x, y, i, j-1) + DiffTransform.insert(j-1, y[j-1])
        }
        // Reload
        else {
            return diffFromMemorizationTable(table, x, y, i-1, j-1) + DiffTransform.reload(i-1, x[i-1])
        }
    }
    
    // Apply Diff
    func apply(diff: Diff<Element>) -> [Element] {
        var copy = self
        
        // Delete First
        diff.deletions.forEach { copy.remove(at: $0.index) }
        
        // Insert
        diff.insertions.forEach { copy.insert($0.value, at: $0.index) }
        
        return copy
    }
}


// Test with String
let aArray = ["A", "D", "F", "G", "T"]
let bArray = ["A", "F", "O", "X", "T"]

let diff = aArray.diff(bArray)

let c = aArray.apply(diff: diff)
print(c)

struct DiffCalculator<T: Equatable> {
    weak var tableView: UITableView?
    
    private var _data = [T]()
    var data: [T] {
        get { return self._data }
        set {
            let old = self._data
            let diff = old.diff(newValue)
            
            // Set
            self._data = newValue
            
            // Transform
            print(diff)
            self.applyTransform(with: diff)
        }
    }
    
    init(tableView: UITableView, data: [T]) {
        self.tableView = tableView
        self._data = data
    }
    
    fileprivate func applyTransform<T: Equatable>(with diff: Diff<T>) {
        
        // Update Transform
        guard !(diff.result.isEmpty) else { return }
        guard let tableView = self.tableView else { return }
        
        tableView.beginUpdates()
        
        // Map IndexPath
        let deletions = diff.deletions.map { IndexPath(row: $0.index, section: 0) }
        let insertions = diff.insertions.map { IndexPath(row: $0.index, section: 0) }
        let reloads = diff.reloads.map { IndexPath(row: $0.index, section: 0) }
        
        tableView.deleteRows(at: deletions, with: .automatic)
        tableView.insertRows(at: insertions, with: .automatic)
        tableView.reloadRows(at: reloads, with: .automatic)
        
        tableView.endUpdates()
    }
}


// USAGE
let myTableView = UITableView()
let data = ["Nghia Tran", "nghiatran.me", "Saigon", "Singapore", "Bangkok"]
var diffCalculator = DiffCalculator<String>(tableView: myTableView, data: data)

// Using diffCalculator.data as dataSource for UITableView.

// Pull to refresh with new data
let newData = ["Nghia Tran", "Uni", "nghiatran.me", "Ha Noi", "KL", "Singapore", "Bangkok", "Finland"]

// Update new data
// Table reload with optimized way
diffCalculator.data = newData


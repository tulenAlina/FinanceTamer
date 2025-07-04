import Foundation

struct FuzzySearch {
    static func search(text: String, in categories: [Category]) -> [Category] {
        let searchString = text.lowercased()
        guard !searchString.isEmpty else { return categories }
        
        let transliteratedToCyrillic = transliterate(searchString, reverse: true)
        let transliteratedToLatin = transliterate(searchString)
        
        return categories.filter { category in
            let categoryName = category.name.lowercased()
            
            // Проверка по подстрокам 
            if categoryName.contains(searchString) ||
                categoryName.contains(transliteratedToCyrillic) ||
                categoryName.contains(transliteratedToLatin) {
                return true
            }
            
            // Проверка по подстрокам с учетом опечаток
            if containsWithTypos(categoryName, searchString) ||
                containsWithTypos(categoryName, transliteratedToCyrillic) ||
                containsWithTypos(categoryName, transliteratedToLatin) {
                return true
            }
            
            return false
        }.sorted {
            // Сортировка по релевантности
            relevanceScore($0.name, searchString) > relevanceScore($1.name, searchString)
        }
    }
    
    private static func containsWithTypos(_ string: String, _ substring: String) -> Bool {
        guard substring.count >= 3 else { return false } // Не проверяем для очень коротких подстрок
        
        // Разбиваем на слова и проверяем каждое
        for word in string.components(separatedBy: .whitespacesAndNewlines) {
            if word.count >= substring.count {
                for i in 0...(word.count - substring.count) {
                    let start = word.index(word.startIndex, offsetBy: i)
                    let end = word.index(start, offsetBy: substring.count)
                    let chunk = String(word[start..<end])
                    
                    if levenshteinDistance(chunk, substring) <= 1 { // Допускаем 1 опечатку
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private static func relevanceScore(_ categoryName: String, _ searchText: String) -> Int {
        let name = categoryName.lowercased()
        let search = searchText.lowercased()
        let transliterated = transliterate(search, reverse: true)
        
        var score = 0
        
        // Бонус за точное совпадение
        if name == search || name == transliterated {
            score += 100
        }
        
        // Бонус за начало слова
        if name.hasPrefix(search) || name.hasPrefix(transliterated) {
            score += 50
        }
        
        // Бонус за содержащуюся подстроку
        if name.contains(search) || name.contains(transliterated) {
            score += 30
        }
        
        // Учет расстояния Левенштейна (чем меньше, тем лучше)
        let distance = min(
            levenshteinDistance(name, search),
            levenshteinDistance(name, transliterated)
        )
        score += max(0, 20 - distance * 5) // Максимальный бонус 20 для расстояния 0
        
        return score
    }
    
    private static func transliterate(_ string: String, reverse: Bool = false) -> String {
        let mapping: [String: String] = [
            "а": "a", "б": "b", "в": "v", "г": "g", "д": "d",
            "е": "e", "ё": "e", "ж": "zh", "з": "z", "и": "i",
            "й": "y", "к": "k", "л": "l", "м": "m", "н": "n",
            "о": "o", "п": "p", "р": "r", "с": "s", "т": "t",
            "у": "u", "ф": "f", "х": "h", "ц": "ts", "ч": "ch",
            "ш": "sh", "щ": "sch", "ъ": "", "ы": "y", "ь": "",
            "э": "e", "ю": "yu", "я": "ya",
            // Обратная транслитерация
            "a": "а", "b": "б", "c": "к", "d": "д", "e": "е",
            "f": "ф", "g": "г", "h": "х", "i": "и", "j": "ж",
            "k": "к", "l": "л", "m": "м", "n": "н", "o": "о",
            "p": "п", "q": "к", "r": "р", "s": "с", "t": "т",
            "u": "у", "v": "в", "w": "в", "x": "кс", "y": "й",
            "z": "з"
        ]
        
        var result = ""
        for char in string {
            let charStr = String(char)
            if reverse {
                // Для обратной транслитерации проверяем сначала английские буквы
                if let mapped = mapping.first(where: { $0.value == charStr })?.key {
                    result += mapped
                } else {
                    result += mapping[charStr] ?? charStr
                }
            } else {
                result += mapping[charStr] ?? charStr
            }
        }
        return result
    }
    
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = Array(repeating: 0, count: s2.count)
        var last = [Int](0...s2.count)
        
        for (i, char1) in s1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in s2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last!
    }
}

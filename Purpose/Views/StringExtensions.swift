import Foundation

extension String {
    var formattedDate: String {
        
        let rawDateFormatter = DateFormatter()
        rawDateFormatter.dateFormat = "EEE MMM dd yyyy HH:mm:ss 'GMT'Z (zzzz)"
        
        
        if let date = rawDateFormatter.date(from: self) {
            
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        
        return self
    }
}

import Foundation

enum Messages {
    static let funny: [String] = [
        "שעה מול המסך! הגב שלך מסתכל עלייך בצורה מאשימה.",
        "שעה עברה. העיניים שלך ביקשו לומר לך: תפסיק.",
        "שעה! אתה והכיסא הפכתם לדבר אחד. זה לא בריא.",
        "שעה חלפה. יש לך רגליים, השתמש בהן.",
        "שעה מול המסך. קפה זה לא ארוחת צהריים.",
        "שעה! הגוף שלך שלח בקשה לקום. אנא אשר.",
        "שעה עברה. המסך לא הולך לשום מקום, אבל אתה כן.",
        "שעה! אם אתה קורא את זה, אתה כבר יכול לקום.",
        "שעה מול המסך. הספה שבסלון עצובה.",
        "שעה! תן למוח קצת אויר, הוא הרוויח.",
        "שעה חלפה. יש לך חלון? תסתכל דרכו.",
        "שעה! תזכורת: אתה אנושי, לא תוכנה.",
    ]

    static let stretches: [String] = [
        "מתח את הצוואר: הנח את האוזן לכתף, 10 שניות לכל צד.",
        "גלגל את הכתפיים אחורה 5 פעמים לאט.",
        "עמוד, עשה 10 קפיצות קטנות. כן, ממש עכשיו.",
        "הסתכל על נקודה רחוקה 20 שניות, לא על המסך.",
        "מתח את האצבעות: פתח ידיים גדול, סגור, חזור 5 פעמים.",
        "קום ועשה מעגל קטן בחדר. 30 שניות הליכה.",
        "כווץ את שרירי הבטן 10 שניות, שחרר. חזור 3 פעמים.",
        "מתח את הגב: שב על קצה הכיסא, הישר עמוד שדרה.",
        "שתה כוס מים. הגוף שלך מודה לך.",
        "קח 5 נשימות עמוקות. שאיפה 4 שניות, נשיפה 6 שניות.",
    ]

    private static var lastFunnyIndex = -1
    private static var lastStretchIndex = -1

    static func randomFunny() -> String {
        var idx: Int
        repeat { idx = Int.random(in: 0..<funny.count) } while idx == lastFunnyIndex && funny.count > 1
        lastFunnyIndex = idx
        return funny[idx]
    }

    static func randomStretch() -> String {
        var idx: Int
        repeat { idx = Int.random(in: 0..<stretches.count) } while idx == lastStretchIndex && stretches.count > 1
        lastStretchIndex = idx
        return stretches[idx]
    }
}

import SwiftUI

/// Lightweight localization used by the SwiftUI text surface.
///
/// SwiftUI's `PinchText("...")` only localizes string literals. Pinch also renders
/// a large amount of data-driven copy (food names, meals, nudges, and dynamic
/// status lines), so every visual text call is routed through `PinchText`.
/// English variants intentionally fall back to the source copy; German and
/// Japanese provide the first production markets that need translated copy.
enum PinchLocalization {
    private static var language: String {
        let identifier = Locale.current.identifier.lowercased()
        if identifier.hasPrefix("ja") { return "ja" }
        if identifier.hasPrefix("de") { return "de" }
        return "en"
    }

    static func resolve(_ value: String) -> String {
        resolve(value, language: language)
    }

    static func resolve(_ value: String, language lang: String) -> String {
        guard lang != "en" else { return value }
        if let translated = catalog[lang]?[value] { return translated }
        return dynamic(value, language: lang)
    }

    private static func dynamic(_ value: String, language: String) -> String {
        if value.hasSuffix("-day streak"), let number = value.split(separator: "-").first {
            return language == "ja" ? "\(number)日連続" : "\(number)-Tage-Serie"
        }
        if value.hasSuffix(" day logging streak"), let number = value.split(separator: " ").first {
            return language == "ja" ? "\(number)日間の記録" : "\(number) Tage dokumentiert"
        }
        if value.hasPrefix("of ") && value.hasSuffix(" mg") {
            let amount = value.dropFirst(3).dropLast(3)
            return language == "ja" ? "\(amount) mg中" : "von \(amount) mg"
        }
        if value.hasSuffix(" mg left") {
            let amount = value.dropLast(8)
            return language == "ja" ? "残り \(amount) mg" : "\(amount) mg übrig"
        }
        if value.hasPrefix("No match for “") && value.hasSuffix("”") {
            let query = value.dropFirst("No match for “".count).dropLast()
            return language == "ja" ? "「\(query)」に一致する食品はありません" : "Keine Treffer für „\(query)“"
        }
        if value.hasSuffix(" mg sodium.") {
            let prefix = "That is about "
            let amount = value.dropFirst(min(prefix.count, value.count)).dropLast(" mg sodium.".count)
            if value.hasPrefix(prefix) {
                return language == "ja" ? "ナトリウム約 \(amount) mgです。" : "Das sind etwa \(amount) mg Natrium."
            }
        }
        if value.hasPrefix("Stored as ") && value.hasSuffix(" mg sodium per serving.") {
            let amount = value.dropFirst("Stored as ".count).dropLast(" mg sodium per serving.".count)
            return language == "ja" ? "1食あたりナトリウム \(amount) mgとして保存します。" : "Als \(amount) mg Natrium pro Portion gespeichert."
        }
        if value.hasPrefix("Dinner check-in — ") && value.hasSuffix(" mg still in the budget. You’ve got this.") {
            let amount = value.dropFirst("Dinner check-in — ".count).dropLast(" mg still in the budget. You’ve got this.".count)
            return language == "ja" ? "夕食リマインダー — あと \(amount) mg。まだ大丈夫です。" : "Abendessen-Erinnerung – noch \(amount) mg im Budget. Du schaffst das."
        }
        if value.hasPrefix("vs. ") && value.hasSuffix(" mg left") {
            let amount = value.dropFirst("vs. ".count).dropLast(" mg left".count)
            return language == "ja" ? "残り \(amount) mgとの比較" : "gegenüber \(amount) mg übrig"
        }
        if value.hasSuffix(" mg still in the budget. You’ve got this.") {
            let amount = value.dropLast(" mg still in the budget. You’ve got this.".count)
            return language == "ja" ? "あと \(amount) mg。まだ大丈夫です。" : "Noch \(amount) mg im Budget. Du schaffst das."
        }
        if value.hasPrefix("per ") && value.hasSuffix(" mg") {
            let serving = value.dropFirst(4).dropLast(3)
            return language == "ja" ? "1食あたり \(serving) mg" : "pro \(serving) mg"
        }
        if value.hasPrefix(" is yours — ") && value.hasSuffix(" to ") {
            let body = value.dropFirst(" is yours — ".count).dropLast(4)
            let number = body.split(separator: " ").first.map(String.init) ?? String(body)
            return language == "ja" ? "あなたのもの — あと\(number)日で" : "gehört dir – noch \(number) Tage bis"
        }
        if value.hasSuffix(" mg left — a light bite still fits.") {
            let amount = value.dropLast(" mg left — a light bite still fits.".count)
            return language == "ja" ? "残り\(amount) mg — 軽い食事ならまだ大丈夫です。" : "Noch \(amount) mg – ein leichter Happen passt noch."
        }
        if value.contains(" mg left — under every usual pick.") {
            let amount = value.components(separatedBy: " mg left").first ?? value
            return language == "ja" ? "残り\(amount) mg —いつもの食品ならどれでも収まります。夕食は新鮮に。" : "Noch \(amount) mg – unter jedem üblichen Essen. Wähle zum Abendessen etwas Frisches."
        }
        if value.contains(" of your usual picks fit.") {
            let parts = value.components(separatedBy: " mg left — ")
            let amount = parts.first ?? value
            let fits = parts.dropFirst().first?.replacingOccurrences(of: " of your usual picks fit.", with: "") ?? ""
            return language == "ja" ? "残り\(amount) mg — いつもの食品のうち\(fits)個が収まります。" : "Noch \(amount) mg – \(fits) deiner üblichen Lebensmittel passen."
        }
        if value.hasSuffix(" mg over budget. Ease up tonight — tomorrow resets.") {
            let amount = value.dropLast(" mg over budget. Ease up tonight — tomorrow resets.".count)
            return language == "ja" ? "目標を\(amount) mg超過。今夜は控えめに。明日リセットされます。" : "\(amount) mg über dem Budget. Heute Abend etwas weniger – morgen beginnt neu."
        }
        if value.hasPrefix("Finished ") && value.hasSuffix(" mg over budget.") {
            let amount = value.dropFirst("Finished ".count).dropLast(" mg over budget.".count)
            return language == "ja" ? "\(amount) mg目標超過で終了。" : "Mit \(amount) mg über dem Budget abgeschlossen."
        }
        if value.hasPrefix("Closed at ") && value.hasSuffix(" Nice save.") {
            let body = value.dropFirst("Closed at ".count).dropLast(" Nice save.".count)
            return language == "ja" ? "\(body)で終了 — いい節約です。" : "Bei \(body) abgeschlossen – gut gespart."
        }
        if value.hasSuffix(" days on the books. Quiet consistency counts.") {
            let number = value.dropLast(" days on the books. Quiet consistency counts.".count)
            return language == "ja" ? "\(number)日を記録しました。静かな継続が力になります。" : "\(number) Tage sind geschafft. Ruhige Beständigkeit zählt."
        }
        if value.contains("% of your day") {
            let prefix = value.dropLast("% of your day".count)
            return language == "ja" ? "\(prefix)%の1日分" : "\(prefix)% deines Tages"
        }
        if value.contains(" free shelf spots left. Pinch Plus is unlimited.") {
            let prefix = value.dropLast(" free shelf spots left. Pinch Plus is unlimited.".count)
            return language == "ja" ? "無料の食品棚の残り\(prefix)件。Pinch Plusは無制限です。" : "Noch \(prefix) kostenlose Regalplätze. Pinch Plus ist unbegrenzt."
        }
        return value
    }

    private static let catalog: [String: [String: String]] = [
        "de": [
            "Today": "Heute", "Yesterday": "Gestern", "Breakfast": "Frühstück",
            "Lunch": "Mittagessen", "Dinner": "Abendessen", "Snacks": "Snacks",
            "Awards": "Auszeichnungen", "Trends": "Trends", "Settings": "Einstellungen",
            "Meet Pinch": "Lerne Pinch kennen",
            "The kindest way to watch your sodium. One number a day, a friend who keeps count with you.": "Die freundlichste Art, Natrium im Blick zu behalten. Eine Zahl pro Tag und ein Freund, der mit dir zählt.",
            "Nice to meet you": "Schön, dich kennenzulernen",
            "Skip the tour": "Rundgang überspringen", "Continue": "Weiter", "Back": "Zurück",
            "Why count sodium?": "Warum Natrium zählen?",
            "So Pinch knows how to help — and what to suggest.": "Damit Pinch weiß, wie es helfen und was es vorschlagen kann.",
            "Doctor recommended": "Vom Arzt empfohlen", "A clinician gave me a number": "Eine Ärztin oder ein Arzt hat mir einen Wert genannt",
            "Blood pressure": "Blutdruck", "Keeping BP in a friendly range": "Den Blutdruck in einem guten Bereich halten",
            "Healthy lifestyle": "Gesunder Lebensstil", "Just eating smarter": "Einfach bewusster essen",
            "Curious": "Neugierig", "Exploring what I actually eat": "Herausfinden, was ich wirklich esse",
            "How’s the plate lately?": "Wie sieht dein Teller gerade aus?",
            "No judgment — it just tunes Pinch’s tips.": "Keine Wertung – Pinch passt damit nur seine Tipps an.",
            "Could use some work": "Da geht noch etwas", "Lots of takeout and quick fixes": "Viel Take-away und schnelle Lösungen",
            "Somewhere in the middle": "Irgendwo dazwischen", "Trying, most days": "An den meisten Tagen bemüht",
            "Pretty healthy": "Ziemlich gesund", "Mostly home-cooked": "Meist selbst gekocht",
            "Set your salt budget": "Setze dein Salzbudget",
            "Milligrams of sodium per day. You can change it anytime.": "Milligramm Natrium pro Tag. Du kannst es jederzeit ändern.",
            "Heart & kidney care": "Herz- und Nierenschutz", "AHA strict — doctor-ordered limits": "Streng nach AHA – ärztlich vorgegebene Grenzen",
            "Standard budget": "Standardbudget", "FDA guideline for most adults": "FDA-Richtwert für die meisten Erwachsenen",
            "Custom": "Benutzerdefiniert", "Slide to your prescribed number": "Schiebe auf deinen verordneten Wert",
            "SUGGESTED": "EMPFOHLEN", "Not medical advice. Ask your doctor what’s right for you.": "Keine medizinische Beratung. Frage deine Ärztin oder deinen Arzt, was für dich passt.",
            "Set my budget": "Mein Budget festlegen", "Gentle check-ins?": "Sanfte Erinnerungen?",
            "Pinch can wave at mealtimes. Nothing pushy.": "Pinch kann sich zu den Mahlzeiten melden. Ganz ohne Druck.",
            "Keep these check-ins": "Diese Erinnerungen speichern",
            "You’re all set": "Alles bereit", "Pinch is ready to keep count with you.": "Pinch ist bereit, mit dir mitzuzählen.",
            "Start tracking": "Tracking starten", "Log a food": "Lebensmittel protokollieren",
            "Log again": "Erneut protokollieren", "Nothing logged this day": "An diesem Tag nichts protokolliert",
            "The shaker stayed calm — or the log did.": "Der Streuer blieb ruhig – oder das Protokoll.",
            "USUAL SUSPECTS": "ÜBLICHE VERDÄCHTIGE", "Logged today": "HEUTE PROTOKOLLIERT",
            "THE LONG GAME": "DER LANGE WEG", "Tap any tracked day to revisit its log.": "Tippe auf einen protokollierten Tag, um ihn erneut anzusehen.",
            "Salt calendar": "Salzkalender", "LAST 4 WEEKS": "LETZTE 4 WOCHEN", "before Pinch": "vor Pinch",
            "KEEP SHAKING": "WEITER SCHÜTTELN", "Quiet proof that showing up counts.": "Ein stiller Beweis, dass Dranbleiben zählt.",
            "day logging streak": "Tage dokumentiert", "Every streak badge is yours. Keep shaking.": "Jeder Serienabzeichen gehört dir. Weiter schütteln.",
            "First Pinch": "Erster Pinch", "Logged your very first food": "Dein erstes Lebensmittel protokolliert",
            "Log a food to earn": "Protokolliere ein Lebensmittel zum Verdienen", "Hat Trick": "Hattrick",
            "A 3-day logging streak": "Eine 3-Tage-Serie", "Salt Week": "Salzwoche", "A 7-day logging streak": "Eine 7-Tage-Serie",
            "Steady Shaker": "Ruhiger Schüttler", "A 30-day logging streak": "Eine 30-Tage-Serie",
            "YOUR SETUP": "DEIN SETUP", "Pinch 1.0, made with a pinch of love": "Pinch 1.0, mit einer Prise Liebe gemacht",
            "Nutrition search powered by FatSecret": "Nahrungssuche powered by FatSecret", "Pinch Plus": "Pinch Plus",
            "Manage plan": "Abo verwalten", "See what’s inside": "Mehr erfahren", "mg per day": "mg pro Tag",
            "Theme": "Erscheinungsbild", "Palette": "Farbpalette", "Light": "Hell", "Dark": "Dunkel",
            "Export my data": "Meine Daten exportieren", "Every entry, as a CSV": "Jeden Eintrag als CSV",
            "Replay welcome": "Willkommen erneut ansehen", "User ID": "Benutzer-ID", "Copy": "Kopieren",
            "Close": "Schließen", "Clear": "Löschen", "Search the salt shelf…": "Salzregal durchsuchen …",
            "Searching the big shelf…": "Großes Regal wird durchsucht …", "Nothing salty by that name": "Nichts Salziges mit diesem Namen",
            "Quick log instead": "Stattdessen schnell protokollieren", "QUICK ADD": "SCHNELL HINZUFÜGEN",
            "Powered by FatSecret": "Powered by FatSecret", "Know the number? Skip the search.": "Kennst du die Zahl? Überspringe die Suche.",
            "Pin to favorites too": "Auch zu Favoriten hinzufügen", "Goes on your shelf — searchable forever.": "Kommt in dein Regal – dauerhaft durchsuchbar.",
            "Add calories & macros (optional)": "Kalorien und Makros hinzufügen (optional)", "Hide calories & macros": "Kalorien und Makros ausblenden",
            "Add to my shelf": "Zu meinem Regal hinzufügen", "Log it": "Protokollieren", "Restore purchases": "Käufe wiederherstellen", "Undo": "Rückgängig",
            "Tracking is free forever. Plus adds the extras.": "Tracking bleibt kostenlos. Plus ergänzt die Extras.",
            "One wave per meal, quiet hours respected. Never guilt.": "Eine Welle pro Mahlzeit, Ruhezeiten werden respektiert. Nie Schuldgefühle.",
            "Nudges are off": "Erinnerungen sind aus", "Turn on nudges": "Erinnerungen einschalten",
            "Meal check-ins are off": "Mahlzeit-Erinnerungen sind aus", "Turn on check-ins": "Erinnerungen einschalten",
            "BEST VALUE": "BESTES ANGEBOT", "Yearly": "Jährlich", "Monthly": "Monatlich",
            "Four-week trends and the salt calendar": "Vier-Wochen-Trends und Salzkalender", "FatSecret food search and logging": "FatSecret-Lebensmittelsuche und Protokollierung",
            "Unlimited custom shelf foods": "Unbegrenzt eigene Lebensmittel speichern", "CSV export for every logged entry": "CSV-Export für jeden protokollierten Eintrag",
            "Sodium widget for your Home Screen": "Natrium-Widget für deinen Home-Bildschirm", "Manage subscription": "Abo verwalten",
            "Sodium Tracker": "Natrium-Tracker", "Bacon": "Speck", "Greek yogurt": "Griechischer Joghurt",
            "Plain bagel": "Bagel natur", "Instant ramen": "Instant-Ramen", "Chicken salad wrap": "Hähnchen-Salat-Wrap",
            "Miso soup": "Misosuppe", "Soy sauce": "Sojasauce", "Dill pickle": "Gewürzgurke", "Potato chips": "Kartoffelchips",
            "French fries": "Pommes frites", "Cottage cheese": "Hüttenkäse", "Cheeseburger": "Cheeseburger",
            "Last two weeks: the dot shows sodium level": "Letzte zwei Wochen: Der Punkt zeigt den Natriumwert",
            "Pinch stays quiet. Flip them on for gentle mealtime waves.": "Pinch bleibt ruhig. Schalte sie für sanfte Wellen zu den Mahlzeiten ein.",
            "MEAL CHECK-INS": "MAHLZEIT-ERINNERUNGEN", "RECENT": "ZULETZT", "PINCH": "PINCH", "ON": "AN",
            "Quiet hours respected, always. Tune times later in Settings.": "Ruhezeiten werden immer respektiert. Passe die Zeiten später in den Einstellungen an.",
            "1,500 mg is the AHA limit for heart & kidney care. Ask your doctor what fits you — Pinch just keeps the count.": "1.500 mg ist der AHA-Grenzwert für Herz- und Nierenschutz. Frage deine Ärztin oder deinen Arzt, was passt – Pinch zählt nur mit.",
            "DAILY SALT BUDGET": "TÄGLICHES SALZBUDGET", "APPEARANCE": "ERSCHEINUNGSBILD", "PINCH & NUDGES": "PINCH & ERINNERUNGEN", "DATA & EXTRAS": "DATEN & EXTRAS", "ACCOUNT": "KONTO",
            "Jump to a day": "Zu einem Tag springen", "Pinch keeps the most recent 14 days close at hand.": "Pinch hält die letzten 14 Tage griffbereit.", "Pinch & nudges": "Pinch & Erinnerungen", "Gentle reminders. Never guilt.": "Sanfte Erinnerungen. Niemals Schuldgefühle.",
            "Turn them on for quiet reminders at breakfast, lunch, and dinner.": "Schalte sie für ruhige Erinnerungen zu Frühstück, Mittag- und Abendessen ein.", "TODAY’S CHECK-INS": "HEUTIGE ERINNERUNGEN", "Dinner check-in": "Abendessen-Erinnerung", "Streak check": "Serien-Check",
            "Google Play handles payment and renewal. Cancel anytime in Play subscriptions.": "Google Play übernimmt Zahlung und Verlängerung. Kündige jederzeit in den Play-Abos.", "Google Play terms": "Google-Play-Bedingungen", "Manage plans": "Pläne verwalten",
            "NUTRITION DATABASE": "NAHRUNGSDATENBANK", "Searching verified servings…": "Geprüfte Portionen werden gesucht …", "Online search is taking a break. Local results still work.": "Die Online-Suche macht eine Pause. Lokale Ergebnisse funktionieren weiterhin.", "Try soup, pizza or ramen — or enter the mg yourself.": "Versuche Suppe, Pizza oder Ramen – oder gib die mg selbst ein.", "Open": "Öffnen", "Quick log": "Schnellprotokoll", "New food": "Neues Lebensmittel",
            "Nothing logged yet": "Noch nichts protokolliert", "Every day starts clean. Add a food when you’re ready.": "Jeder Tag beginnt neu. Füge ein Lebensmittel hinzu, wenn du bereit bist.", "YOUR PATTERN": "DEIN MUSTER", "The numbers, with the edges softened.": "Die Zahlen, mit sanften Kanten.", "RECENT DAYS": "LETZTE TAGE", "SMALL WINS": "KLEINE ERFOLGE", "YOUR BADGES": "DEINE ABZEICHEN", "Thirty steady days — Pinch is impressed.": "Dreißig konstante Tage – Pinch ist beeindruckt.",
            "A gentle wave at the times below": "Eine sanfte Welle zu den unten angegebenen Zeiten", "Meal check-ins": "Mahlzeit-Erinnerungen", "1 g salt ≈ 393 mg sodium": "1 g Salz ≈ 393 mg Natrium", "Choose Sodium mg or Salt g in Quick log and New food. Pinch does the conversion before saving.": "Wähle in Schnellprotokoll und Neuem Lebensmittel Natrium-mg oder Salz-g. Pinch rechnet vor dem Speichern um.", "A clean page, a clear number, and Pinch beside you.": "Eine klare Seite, eine klare Zahl und Pinch an deiner Seite.",
            "Previous day": "Vorheriger Tag", "Next day": "Nächster Tag", "Nudges": "Erinnerungen", "Remove": "Entfernen", "Previous week": "Vorherige Woche", "Next week": "Nächste Woche", "Favorite": "Favorit",
            "FROM FATSECRET": "VON FATSECRET", "MG": "MG", "PLUS": "PLUS", "6:30 PM": "18:30 Uhr", "Try \"soup,\" \"pizza,\" or \"ramen\" — or use Quick log to enter the milligrams yourself.": "Versuche Suppe, Pizza oder Ramen – oder gib die Milligramm über das Schnellprotokoll selbst ein.",
            "Fresh page — plenty of room today.": "Frische Seite – heute ist viel Platz.", "Nice pace. Steady shakes.": "Gutes Tempo. Ruhig weiterschütteln.", "Careful — the shaker is getting warm.": "Vorsicht – der Streuer wird warm.", "Over budget. Tomorrow is a clean slate — I kept notes.": "Über dem Budget. Morgen ist ein neuer Anfang – ich habe Notizen gemacht.",
            "A quiet page in the log book.": "Eine ruhige Seite im Protokoll.", "That day ran salty — all data, no judgment.": "Dieser Tag war salzig – nur Daten, keine Wertung.", "A good day on the books.": "Ein guter Tag im Protokoll.", "Whew — a salty one. Pace the rest.": "Puh – ein salziger Eintrag. Lass es für den Rest ruhiger angehen.", "Noted. Keeping count together.": "Notiert. Wir zählen gemeinsam weiter.", "Light touch. Nice pick.": "Leichte Hand. Gute Wahl.",
            "Active — thanks for keeping Pinch fed.": "Aktiv – danke, dass du Pinch fütterst.", "4-week trends, unlimited shelf foods, and export.": "Vier-Wochen-Trends, unbegrenzte Regal-Lebensmittel und Export.", "Pinch Plus is active": "Pinch Plus ist aktiv", "Your premium tools are unlocked.": "Deine Premium-Werkzeuge sind freigeschaltet.", "A little more Pinch": "Ein bisschen mehr Pinch", "Your four-week view, unlimited shelf, and export are ready.": "Deine Vier-Wochen-Ansicht, das unbegrenzte Regal und der Export sind bereit.", "See the longer pattern, save every regular, and take your data with you.": "Sieh das längere Muster, speichere deine Favoriten und nimm deine Daten mit.", "Working…": "Wird bearbeitet …", "Loading plans…": "Pläne werden geladen …", "Continue with Plus": "Mit Plus fortfahren", "Cancel anytime": "Jederzeit kündbar",
        ],
        "ja": [
            "Today": "今日", "Yesterday": "昨日", "Breakfast": "朝食", "Lunch": "昼食", "Dinner": "夕食", "Snacks": "間食",
            "Awards": "アワード", "Trends": "傾向", "Settings": "設定", "Meet Pinch": "Pinchに会おう",
            "The kindest way to watch your sodium. One number a day, a friend who keeps count with you.": "ナトリウムをやさしく見守る方法。1日1つの数字を、そばで数えてくれる友だちと一緒に。",
            "Nice to meet you": "はじめまして", "Skip the tour": "ツアーをスキップ", "Continue": "続ける", "Back": "戻る",
            "Why count sodium?": "なぜナトリウムを数えるの？", "So Pinch knows how to help — and what to suggest.": "Pinchがあなたに合う助け方や提案を知るためです。",
            "Doctor recommended": "医師のすすめ", "Blood pressure": "血圧", "Healthy lifestyle": "健康的な生活",
            "Curious": "気になっている", "How’s the plate lately?": "最近の食事はどう？", "Could use some work": "少し見直したい",
            "Somewhere in the middle": "まあまあ", "Pretty healthy": "かなり健康的", "Set your salt budget": "塩分の目標を設定",
            "Milligrams of sodium per day. You can change it anytime.": "1日のナトリウム量（mg）。いつでも変更できます。",
            "Heart & kidney care": "心臓と腎臓のケア", "Standard budget": "標準目標", "Custom": "カスタム",
            "SUGGESTED": "おすすめ", "Not medical advice. Ask your doctor what’s right for you.": "医療アドバイスではありません。あなたに合う方法を医師に相談してください。",
            "Gentle check-ins?": "やさしいリマインダー？", "Keep these check-ins": "このリマインダーを保存",
            "You’re all set": "準備完了", "Pinch is ready to keep count with you.": "Pinchが一緒に数える準備ができました。",
            "Start tracking": "記録を始める", "Log a food": "食品を記録", "Log again": "もう一度記録",
            "Nothing logged this day": "この日の記録はありません", "USUAL SUSPECTS": "いつもの食品",
            "THE LONG GAME": "長期の傾向", "Tap any tracked day to revisit its log.": "記録した日をタップしてログを見直せます。",
            "Salt calendar": "塩分カレンダー", "LAST 4 WEEKS": "過去4週間", "KEEP SHAKING": "続けよう",
            "Quiet proof that showing up counts.": "続けた証は、静かに積み重なります。", "day logging streak": "日間の記録連続",
            "First Pinch": "最初のPinch", "Hat Trick": "ハットトリック", "Salt Week": "塩分ウィーク", "Steady Shaker": "安定した記録",
            "YOUR SETUP": "設定", "Pinch 1.0, made with a pinch of love": "Pinch 1.0、愛をひとつまみ込めて", "Pinch Plus": "Pinch Plus", "Manage plan": "プランを管理", "See what’s inside": "内容を見る",
            "mg per day": "mg / 日", "Theme": "テーマ", "Palette": "カラー", "Light": "ライト", "Dark": "ダーク",
            "Export my data": "データをエクスポート", "Every entry, as a CSV": "すべての記録をCSVで", "Replay welcome": "ウェルカムを再表示",
            "User ID": "ユーザーID", "Copy": "コピー", "Close": "閉じる", "Clear": "クリア",
            "Search the salt shelf…": "食品を検索…", "Searching the big shelf…": "食品を検索中…", "Nothing salty by that name": "その名前の食品はありません",
            "Quick log instead": "代わりにクイック記録", "QUICK ADD": "クイック追加", "Powered by FatSecret": "FatSecretを利用",
            "Know the number? Skip the search.": "数値がわかる？検索をスキップ。", "Pin to favorites too": "お気に入りにも追加",
            "Goes on your shelf — searchable forever.": "食品棚に保存。いつでも検索できます。", "Add calories & macros (optional)": "カロリーと栄養素を追加（任意）",
            "Hide calories & macros": "カロリーと栄養素を隠す", "Add to my shelf": "食品棚に追加", "Log it": "記録する",
            "Restore purchases": "購入を復元", "Tracking is free forever. Plus adds the extras.": "記録は無料で使い続けられます。Plusで追加機能を利用できます。",
            "Nudges are off": "リマインダーはオフ", "Turn on nudges": "リマインダーをオン", "BEST VALUE": "おすすめ", "Undo": "元に戻す",
            "Yearly": "年額", "Monthly": "月額", "Four-week trends and the salt calendar": "4週間の傾向と塩分カレンダー",
            "FatSecret food search and logging": "FatSecret食品検索と記録", "Unlimited custom shelf foods": "カスタム食品を無制限に保存",
            "CSV export for every logged entry": "全記録をCSVでエクスポート", "Sodium widget for your Home Screen": "ホーム画面のナトリウムウィジェット",
            "Sodium Tracker": "ナトリウムトラッカー", "Bacon": "ベーコン", "Greek yogurt": "ギリシャヨーグルト", "Plain bagel": "プレーンベーグル",
            "Instant ramen": "インスタントラーメン", "Chicken salad wrap": "チキンサラダラップ", "Miso soup": "味噌汁", "Soy sauce": "しょうゆ",
            "Dill pickle": "ディルピクルス", "Potato chips": "ポテトチップス", "French fries": "フライドポテト", "Cottage cheese": "カッテージチーズ",
            "Cheeseburger": "チーズバーガー",
            "Last two weeks: the dot shows sodium level": "直近2週間：点がナトリウム量を示します",
            "Pinch stays quiet. Flip them on for gentle mealtime waves.": "Pinchは静かに待機します。食事のやさしいお知らせをオンにできます。",
            "MEAL CHECK-INS": "食事リマインダー", "RECENT": "最近", "PINCH": "PINCH", "ON": "オン",
            "Quiet hours respected, always. Tune times later in Settings.": "静かな時間はいつも尊重します。時間は設定で後から変更できます。",
            "1,500 mg is the AHA limit for heart & kidney care. Ask your doctor what fits you — Pinch just keeps the count.": "1,500 mgは心臓と腎臓のケアにおけるAHAの目安です。医師に相談し、Pinchは記録をお手伝いします。",
            "DAILY SALT BUDGET": "1日の塩分目標", "APPEARANCE": "表示", "PINCH & NUDGES": "Pinchとリマインダー", "DATA & EXTRAS": "データと追加機能", "ACCOUNT": "アカウント",
            "Jump to a day": "日に移動", "Pinch keeps the most recent 14 days close at hand.": "Pinchは直近14日分をすぐ確認できるようにします。", "Pinch & nudges": "Pinchとリマインダー", "Gentle reminders. Never guilt.": "やさしいリマインダー。責めません。",
            "Meal check-ins are off": "食事リマインダーはオフ", "Turn them on for quiet reminders at breakfast, lunch, and dinner.": "朝食・昼食・夕食に静かなリマインダーを設定できます。", "Turn on check-ins": "リマインダーをオン", "TODAY’S CHECK-INS": "今日のリマインダー", "Dinner check-in": "夕食リマインダー", "Streak check": "連続記録チェック",
            "Google Play handles payment and renewal. Cancel anytime in Play subscriptions.": "支払いと更新はGoogle Playが処理します。Playの定期購入からいつでも解約できます。", "Google Play terms": "Google Play利用規約", "Manage plans": "プランを管理",
            "NUTRITION DATABASE": "栄養データベース", "Searching verified servings…": "確認済みの量を検索中…", "Online search is taking a break. Local results still work.": "オンライン検索はお休み中です。ローカルの結果は利用できます。", "Try soup, pizza or ramen — or enter the mg yourself.": "スープ、ピザ、ラーメンなどを試すか、mgを入力してください。", "Open": "開く", "Quick log": "クイック記録", "New food": "新しい食品",
            "Nothing logged yet": "まだ記録がありません", "Every day starts clean. Add a food when you’re ready.": "毎日が新しく始まります。準備ができたら食品を追加しましょう。", "YOUR PATTERN": "あなたの傾向", "The numbers, with the edges softened.": "数字を、やさしく見つめる。", "RECENT DAYS": "最近の日々", "SMALL WINS": "小さな達成", "YOUR BADGES": "あなたのバッジ", "Thirty steady days — Pinch is impressed.": "30日間の継続。Pinchも感心しています。",
            "A gentle wave at the times below": "下記の時間にやさしくお知らせします", "Meal check-ins": "食事リマインダー", "1 g salt ≈ 393 mg sodium": "塩1 g ≈ ナトリウム393 mg", "Choose Sodium mg or Salt g in Quick log and New food. Pinch does the conversion before saving.": "クイック記録と新しい食品でナトリウムmgまたは塩gを選べます。保存前にPinchが換算します。", "A clean page, a clear number, and Pinch beside you.": "すっきりした画面、わかりやすい数字、そしてそばにいるPinch。",
            "Previous day": "前の日", "Next day": "次の日", "Nudges": "リマインダー", "Remove": "削除", "Previous week": "前の週", "Next week": "次の週", "Favorite": "お気に入り",
            "FROM FATSECRET": "FatSecretから", "MG": "MG", "PLUS": "PLUS", "6:30 PM": "18:30", "Try \"soup,\" \"pizza,\" or \"ramen\" — or use Quick log to enter the milligrams yourself.": "スープ、ピザ、ラーメンなどを試すか、クイック記録でmgを入力してください。",
            "Fresh page — plenty of room today.": "すっきりしたページ。今日は余裕があります。", "Nice pace. Steady shakes.": "いいペース。ゆっくり続けよう。", "Careful — the shaker is getting warm.": "少し注意。塩分が増えています。", "Over budget. Tomorrow is a clean slate — I kept notes.": "目標を超えました。明日は新しいスタートです。記録は残っています。",
            "A quiet page in the log book.": "記録帳の静かな1ページ。", "That day ran salty — all data, no judgment.": "塩分が多かった日。データだけ、責めません。", "A good day on the books.": "記録に残る良い1日。", "Whew — a salty one. Pace the rest.": "ふう、塩分が多め。残りはゆっくりいきましょう。", "Noted. Keeping count together.": "記録しました。一緒に数えていきましょう。", "Light touch. Nice pick.": "軽やかな選択。いいですね。",
            "Active — thanks for keeping Pinch fed.": "利用中です。Pinchを使ってくれてありがとう。", "4-week trends, unlimited shelf foods, and export.": "4週間の傾向、食品の無制限保存、エクスポート。", "Pinch Plus is active": "Pinch Plusは有効です", "Your premium tools are unlocked.": "プレミアム機能が利用できます。", "A little more Pinch": "もう少しPinchを", "Your four-week view, unlimited shelf, and export are ready.": "4週間の表示、無制限の食品棚、エクスポートが利用できます。", "See the longer pattern, save every regular, and take your data with you.": "長期の傾向を見て、いつもの食品を保存し、データを持ち出せます。", "Working…": "処理中…", "Loading plans…": "プランを読み込み中…", "Continue with Plus": "Plusで続ける", "Cancel anytime": "いつでも解約できます",
        ],
    ]
}

/// Routes every display string through the locale catalog while retaining the
/// native SwiftUI.Text type so modifiers and Text concatenation keep working.
func PinchText(_ value: String) -> SwiftUI.Text {
    SwiftUI.Text(verbatim: PinchLocalization.resolve(value))
}

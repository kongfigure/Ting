import Foundation
import FirebaseCore
import FirebaseFirestore

final class FirebaseService {
    static var isConfigured: Bool { FirebaseApp.app() != nil }

    private let db = Firestore.firestore()
    private var lessonListener: ListenerRegistration?
    private var wordListener: ListenerRegistration?

    func saveLesson(_ lesson: Lesson) {
        do {
            try db.collection("lessons").document(lesson.id.uuidString).setData(from: lesson)
        } catch {
            print("❌ Firestore saveLesson failed: \(error)")
        }
    }

    func saveWord(_ word: Word) {
        do {
            try db.collection("words").document(word.id.uuidString).setData(from: word)
        } catch {
            print("❌ Firestore saveWord failed: \(error)")
        }
    }

    // Firestore delivers snapshot callbacks on the main queue by default.
    func startListening(
        onLessons: @escaping ([Lesson]) -> Void,
        onWords: @escaping ([Word]) -> Void
    ) {
        lessonListener = db.collection("lessons").addSnapshotListener { snapshot, error in
            guard let snapshot else {
                print("❌ Firestore lessons listener failed: \(error?.localizedDescription ?? "unknown")")
                return
            }
            onLessons(snapshot.documents.compactMap { try? $0.data(as: Lesson.self) })
        }
        wordListener = db.collection("words").addSnapshotListener { snapshot, error in
            guard let snapshot else {
                print("❌ Firestore words listener failed: \(error?.localizedDescription ?? "unknown")")
                return
            }
            onWords(snapshot.documents.compactMap { try? $0.data(as: Word.self) })
        }
    }

    func stopListening() {
        lessonListener?.remove()
        wordListener?.remove()
        lessonListener = nil
        wordListener = nil
    }
}

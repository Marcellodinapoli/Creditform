import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<QuizQuestion>> fetchQuiz(String courseId) async {
    try {
      final snapshot = await _db
          .collection('quizzes')
          .doc(courseId)
          .collection('questions')
          .get();

      return snapshot.docs.map((doc) {
        return QuizQuestion.fromMap(doc.data());
      }).toList();
    } catch (e) {
      print('Errore durante il fetch del quiz: $e');
      return [];
    }
  }
}

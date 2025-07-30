import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/page_wrapper.dart';

class CourseDetailsPage extends StatefulWidget {
  final String courseTitle;

  const CourseDetailsPage({Key? key, required this.courseTitle}) : super(key: key);

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

// Classe per rappresentare i dettagli delle risposte di un quiz
class QuizAnswerDetail {
  final String question;
  final List<String> answers;
  final int correctIndex;
  final int? userAnswerIndex;

  QuizAnswerDetail({
    required this.question,
    required this.answers,
    required this.correctIndex,
    this.userAnswerIndex,
  });
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  late Future<Map<String, dynamic>> _progressFuture;
  late Future<List<QuizAttempt>> _quizAttemptsFuture;
  late Future<int> _downloadedFilesCountFuture;

  // Esempio dati quiz svolto: sostituisci con dati reali caricati da DB
  final List<QuizAnswerDetail> quizDetails = [
    QuizAnswerDetail(
      question: 'Qual è la capitale d\'Italia?',
      answers: ['Roma', 'Napoli', 'Milano'],
      correctIndex: 0,
      userAnswerIndex: 1,
    ),
    QuizAnswerDetail(
      question: '2 + 2 fa?',
      answers: ['3', '4', '5'],
      correctIndex: 1,
      userAnswerIndex: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress(widget.courseTitle);
    _quizAttemptsFuture = _loadQuizAttempts(widget.courseTitle);
    _downloadedFilesCountFuture = _loadDownloadedFilesCount(widget.courseTitle);
  }

  Future<Map<String, dynamic>> _loadProgress(String courseTitle) async {
    final prefs = await SharedPreferences.getInstance();

    String quizStatus = prefs.getString('quiz_status_$courseTitle') ?? 'non iniziato';
    if (quizStatus == 'incompleto') {
      quizStatus = 'non iniziato';
    }

    return {
      'videoStatus': prefs.getString('video_status_$courseTitle') ?? 'non iniziato',
      'videoLastView': prefs.getString('video_last_view_$courseTitle') ?? '-',
      'quizStatus': quizStatus,
      'quizAvgScore': prefs.getString('quiz_avg_score_$courseTitle') ?? '-',
      'quizLastAttempt': prefs.getString('quiz_last_attempt_$courseTitle') ?? '-',
      'quizAttemptCount': prefs.getInt('quiz_attempt_count_$courseTitle') ?? 0,
      'quizAvgTime': prefs.getString('quiz_avg_time_$courseTitle') ?? '-',
      'quizCorrectAnswers': prefs.getInt('quiz_correct_answers_$courseTitle') ?? 0,
      'quizWrongAnswers': prefs.getInt('quiz_wrong_answers_$courseTitle') ?? 0,
    };
  }

  Future<List<QuizAttempt>> _loadQuizAttempts(String courseTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawAttempts = prefs.getStringList('quizAttempts_$courseTitle') ?? [];
    return rawAttempts.map((entry) {
      final parts = entry.split(' ');
      String scorePart = parts.isNotEmpty ? parts[0] : '';
      String timestamp = parts.length > 1 ? parts.sublist(1).join(' ') : '-';
      return QuizAttempt(score: scorePart, timestamp: timestamp);
    }).toList();
  }

  Future<int> _loadDownloadedFilesCount(String courseTitle) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('downloadedFilesCount_$courseTitle') ?? 0;
  }

  void _showQuizDetailsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dettagli Quiz'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: quizDetails.map((detail) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.question,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...detail.answers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final answer = entry.value;
                      Color color = Colors.black;
                      if (idx == detail.correctIndex) {
                        color = Colors.green;
                      }
                      if (detail.userAnswerIndex != null &&
                          idx == detail.userAnswerIndex &&
                          idx != detail.correctIndex) {
                        color = Colors.red;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${idx + 1}. $answer',
                          style: TextStyle(color: color),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold);

    return PageWrapper(
      title: widget.courseTitle,
      showBackButton: true,
      backButtonText: '',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Impossibile caricare i dettagli'));
          }
          final progress = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Video', style: titleStyle),
              const SizedBox(height: 8),
              Text('Stato: ${progress['videoStatus']}'),
              Text('Ultima visualizzazione: ${progress['videoLastView']}'),

              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 16),

              Text('File scaricati', style: titleStyle),
              const SizedBox(height: 8),

              FutureBuilder<int>(
                future: _downloadedFilesCountFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final count = snapshot.data ?? 0;
                  return Text(
                    count > 0 ? 'Totale file scaricati: $count' : 'Nessun file scaricato',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),

              const Divider(height: 32),

              Text('Quiz', style: titleStyle),
              const SizedBox(height: 8),
              Text('Stato: ${progress['quizStatus']}'),
              Text('Punteggio medio: ${progress['quizAvgScore']}'),
              Text('Ultimo tentativo: ${progress['quizLastAttempt']}'),
              Text('Tentativi fatti: ${progress['quizAttemptCount']}'),
              Text('Tempo medio: ${progress['quizAvgTime']}'),
              Text('Risposte corrette: ${progress['quizCorrectAnswers']}'),
              Text('Risposte sbagliate: ${progress['quizWrongAnswers']}'),

              const Divider(height: 32),

              Text('Dettaglio tentativi quiz', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              FutureBuilder<List<QuizAttempt>>(
                future: _quizAttemptsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      children: const [
                        Divider(color: Colors.purple, thickness: 2),
                        SizedBox(height: 8),
                        Text('Nessun tentativo quiz disponibile.'),
                      ],
                    );
                  }
                  final attempts = snapshot.data!;
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Nome quiz')),
                      DataColumn(label: Text('Inizia')),
                      DataColumn(label: Text('Durata')),
                      DataColumn(label: Text('Punteggio')),
                      DataColumn(label: Text('Dettagli')),
                    ],
                    rows: attempts.map((attempt) {
                      return DataRow(cells: [
                        DataCell(Text(widget.courseTitle)),
                        DataCell(Text(attempt.timestamp)),
                        const DataCell(Text('---')),
                        DataCell(Text(attempt.score)),
                        DataCell(
                          ElevatedButton(
                            child: const Text('Dettagli'),
                            onPressed: _showQuizDetailsPopup,
                          ),
                        ),
                      ]);
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuizAttempt {
  final String score;
  final String timestamp;

  QuizAttempt({
    required this.score,
    required this.timestamp,
  });
}

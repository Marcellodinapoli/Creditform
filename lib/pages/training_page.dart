import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // import auth
import '../widgets/custom_webview_stub.dart'
if (dart.library.io) '../widgets/custom_webview_mobile.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import '../widgets/page_wrapper.dart';

class TrainingPage extends StatefulWidget {
  final List<String> courseList;
  final int currentIndex;

  const TrainingPage({
    Key? key,
    required this.courseList,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with SingleTickerProviderStateMixin {
  late String courseTitle;
  bool isCompleted = false;
  bool isVideoCompleted = true;
  bool wasAlreadyCompleted = false;
  bool canAccess = true;
  int videoViews = 0;
  List<String> quizAttempts = [];
  int downloadedFilesCount = 0; // <-- aggiunto conteggio file scaricati
  late TabController _tabController;
  Timer? quizTimer;
  int remainingSeconds = 200;
  int currentQuestionIndex = -1;
  int correctAnswers = 0;
  bool isQuizCompleted = false;
  List<QuizQuestion> quizQuestions = [];

  User? currentUser; // current user

  final Map<String, String> courseVideos = {
    'Uso del portale':
    'https://iframe.mediadelivery.net/play/469320/3ddfd831-2cf3-4c73-8fac-9d42c9a41798',
    'Tipi di finanziamenti': 'https://esempio.com/playlist1.m3u8',
  };

  @override
  void initState() {
    super.initState();

    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() {
        canAccess = false;
      });
      return;
    }

    courseTitle = widget.courseList[widget.currentIndex];
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPreviousCompletion();
    });
    _loadStatus();
    _loadQuizQuestions();
  }

  Future<void> _loadQuizQuestions() async {
    if (currentUser == null) {
      print("Accesso negato: utente non loggato.");
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quiz')
          .doc(courseTitle)
          .collection('domande')
          .get();

      print(
          "DEBUG - Caricate ${snapshot.docs.length} domande per il corso: $courseTitle");

      final questions =
      snapshot.docs.map((doc) => QuizQuestion.fromFirestore(doc)).toList();

      setState(() {
        quizQuestions = questions;
      });
    } catch (e) {
      print("Errore durante il caricamento delle domande: $e");
    }
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      wasAlreadyCompleted =
          prefs.getString('status_$courseTitle')?.startsWith('completato') ??
              false;
      videoViews = prefs.getInt('videoViews_$courseTitle') ?? 0;
      quizAttempts = prefs.getStringList('quizAttempts_$courseTitle') ?? [];
      downloadedFilesCount =
          prefs.getInt('downloadedFilesCount_$courseTitle') ?? 0; // <-- carico conteggio file
    });
  }

  Future<void> _checkPreviousCompletion() async {
    if (widget.currentIndex > 0) {
      final prefs = await SharedPreferences.getInstance();
      final prevTitle = widget.courseList[widget.currentIndex - 1];
      final prevStatus = prefs.getString('status_$prevTitle') ?? '';
      final isPrevComplete = prevStatus.startsWith('completato');

      if (!isPrevComplete && mounted) {
        setState(() {
          canAccess = false;
        });
      }
    }
  }

  Future<void> _markAsInProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('status_$courseTitle', 'incompleto');
  }

  Future<void> _markAsCompletedWithVote(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    if (isVideoCompleted) {
      await prefs.setString(
          'status_$courseTitle', 'completato ($score/${quizQuestions.length})');
    }
    final newAttempt = '$score/${quizQuestions.length} ($now)';
    quizAttempts.add(newAttempt);
    await prefs.setStringList('quizAttempts_$courseTitle', quizAttempts);
    setState(() {
      isCompleted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
          Text('Stato aggiornato con voto: $score/${quizQuestions.length}')),
    );
  }

  void _startQuizTimer() {
    quizTimer?.cancel();
    remainingSeconds = 200;
    quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          isQuizCompleted = true;
        });
        _markAsCompletedWithVote(correctAnswers);
      }
    });
  }

  void _answerQuestion(int selectedIndex) {
    if (remainingSeconds <= 0) return;
    final correctIndex = quizQuestions[currentQuestionIndex].correctIndex;
    if (selectedIndex == correctIndex) {
      correctAnswers++;
    }
    if (currentQuestionIndex < quizQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      quizTimer?.cancel();
      setState(() {
        isQuizCompleted = true;
      });
      _markAsCompletedWithVote(correctAnswers);
    }
  }

  @override
  void dispose() {
    if (!isCompleted) {
      _markAsInProgress();
    }
    quizTimer?.cancel();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    final videoUrl = courseVideos[courseTitle];
    _trackVideoView();
    return Center(
      child: Container(
        width: 1280, // larghezza fissa container
        height: 720, // altezza fissa container
        decoration: BoxDecoration(
          color: Colors.black, // sfondo nero per la cornice
          borderRadius: BorderRadius.circular(8), // angoli arrotondati
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildPlayer(videoUrl),
        ),
      ),
    );
  }

  Future<void> _trackVideoView() async {
    final prefs = await SharedPreferences.getInstance();
    videoViews++;
    await prefs.setInt('videoViews_$courseTitle', videoViews);
  }

  Widget _buildPlayer(String? videoUrl) {
    if (kIsWeb) {
      final viewID = 'video-${courseTitle.hashCode}';
      try {
        ui_web.platformViewRegistry.registerViewFactory(viewID, (int _) {
          final iframe = html.IFrameElement()
            ..src = videoUrl!
            ..style.border = 'none'
            ..style.width = '1280px' // larghezza fissa 1280 px
            ..style.height = '720px' // altezza fissa 720 px
            ..style.backgroundColor = 'white' // sfondo bianco
            ..allowFullscreen = true;
          iframe.setAttribute('allowfullscreen', '');
          return iframe;
        });
      } catch (_) {}
      return Center(
        child: Container(
          padding: EdgeInsets.zero,
          color: Colors.white,
          width: 1280, // larghezza fissa container
          height: 720, // altezza fissa container
          child: HtmlElementView(viewType: viewID),
        ),
      );
    } else {
      return CustomWebView(url: videoUrl!);
    }
  }

  Widget _buildQuizSection() {
    if (quizQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isQuizCompleted) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            correctAnswers == quizQuestions.length
                ? 'Complimenti! Hai superato il quiz!'
                : (correctAnswers >= 6
                ? 'Complimenti! Hai superato il quiz!'
                : 'Oops! Non hai superato il quiz!\nRipeti il corso!'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Text('Il tuo punteggio è $correctAnswers / ${quizQuestions.length}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentQuestionIndex = -1;
                correctAnswers = 0;
                isQuizCompleted = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Ricomincia quiz'),
              ],
            ),
          )
        ],
      );
    }

    if (currentQuestionIndex == -1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hai 200 secondi di tempo.\n\nQuiz a tempo\n\nInizia quando sei pronto!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentQuestionIndex = 0;
                });
                _startQuizTimer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: const Text('Inizia'),
            ),
          ],
        ),
      );
    }

    final question = quizQuestions[currentQuestionIndex];
    return Center(
      child: Container(
        width: 700,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tempo rimasto: $remainingSeconds secondi'),
            Text('${currentQuestionIndex + 1} / ${quizQuestions.length}'),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ...question.answers.asMap().entries.map(
                  (entry) => Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(entry.key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${entry.key + 1}. ${entry.value}'),
                  ),
                ),
              ),
            ),
            // Nuova sezione per il dettaglio dei file scaricati
            const SizedBox(height: 20),
            const Text(
              'Dettaglio file scaricati',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(downloadedFilesCount > 0
                ? 'Hai scaricato $downloadedFilesCount file.'
                : 'Nessun file scaricato.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previousCourse =
    widget.currentIndex > 0 ? widget.courseList[widget.currentIndex - 1] : null;
    final nextCourse = widget.currentIndex < widget.courseList.length - 1
        ? widget.courseList[widget.currentIndex + 1]
        : null;

    return PageWrapper(
      title: 'Training',
      showBackButton: true,
      backButtonText: '', // <- Togli testo "Ritorna", solo freccia bianca
      child: currentUser == null
          ? const Center(
        child: Text(
          'Devi effettuare il login per accedere a questo corso.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      )
          : canAccess
          ? Column(
        children: [
          const Divider(height: 1),
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                previousCourse != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PRECEDENTE",
                        style: TextStyle(color: Colors.purple)),
                    Text(previousCourse),
                  ],
                )
                    : const SizedBox(),
                Text(
                  courseTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                nextCourse != null
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("SUCCESSIVO",
                        style: TextStyle(color: Colors.purple)),
                    Text(nextCourse,
                        style: const TextStyle(color: Colors.purple)),
                  ],
                )
                    : const SizedBox(),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: const [
              Tab(icon: Icon(Icons.ondemand_video), text: 'Video corso'),
              Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
              Tab(icon: Icon(Icons.attach_file), text: 'Allegati'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoPlayer(),
                _buildQuizSection(),
                const Center(child: Text('Nessun file disponibile al momento.')),
              ],
            ),
          ),
        ],
      )
          : const Center(
        child: Text(
          'Devi completare il corso precedente per accedere a questo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}

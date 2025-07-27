import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'courses_page.dart';
import 'main_scaffold_with_role.dart';
import 'course_details_page.dart';
import '../widgets/page_wrapper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  User? currentUser;
  late Future<List<CourseProgress>> progressFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    progressFuture = _loadAllProgress();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<List<CourseProgress>> _loadAllProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final allCourses = [...preDecadenzaCourses, ...postDecadenzaCourses];

    List<CourseProgress> list = [];
    for (var course in allCourses) {
      final videoProgress = prefs.getDouble('video_progress_${course.title}') ?? 0.0;
      final quizAvgScoreStr = prefs.getString('quiz_avg_score_${course.title}') ?? '-';
      double quizAvgScore = 0;
      if (quizAvgScoreStr != '-' && quizAvgScoreStr.endsWith('%')) {
        quizAvgScore = double.tryParse(quizAvgScoreStr.replaceAll('%', '')) ?? 0;
      }

      list.add(CourseProgress(
        title: course.title,
        videoStatus: prefs.getString('video_status_${course.title}') ?? 'non iniziato',
        videoLastView: prefs.getString('video_last_view_${course.title}') ?? '-',
        videoViewsCount: prefs.getInt('video_views_count_${course.title}') ?? 0,
        quizStatus: prefs.getString('quiz_status_${course.title}') ?? 'non iniziato',
        quizAvgScore: quizAvgScoreStr,
        quizAvgScoreDouble: quizAvgScore,
        quizAttemptsCount: prefs.getInt('quiz_attempt_count_${course.title}') ?? 0,
        videoProgressDouble: videoProgress,
      ));
    }
    return list;
  }

  Widget _buildProgressBars(double videoProgress, double quizAvgScore, int filesCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progresso video: ${(videoProgress * 100).toStringAsFixed(0)}%'),
        LinearProgressIndicator(
          value: videoProgress,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        Text('Media punteggio quiz: ${quizAvgScore.toStringAsFixed(0)}%'),
        LinearProgressIndicator(
          value: quizAvgScore / 100,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        Text('File scaricati: $filesCount', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14)),
      ],
    );
  }

  Widget _buildCourseList(List<CourseProgress> progressList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: progressList.length,
      itemBuilder: (context, index) {
        final progress = progressList[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(progress.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video: ${progress.videoStatus}'),
                Text('Quiz: ${progress.quizStatus}'),
                const SizedBox(height: 8),
                _buildProgressBars(progress.videoProgressDouble, progress.quizAvgScoreDouble, progress.videoViewsCount),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsPage(courseTitle: progress.title),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = currentUser?.displayName ?? 'Utente';

    return MainScaffoldWithRole(
      role: 'user',
      currentPage: 'dashboard',
      child: PageWrapper(
        title: 'Dashboard',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benvenuto, $userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // TabBar con icone + testo uguali a Training
            TabBar(
              controller: _tabController,
              labelColor: Colors.purple,         // colore fucsia come Training
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              tabs: const [
                Tab(icon: Icon(Icons.ondemand_video), text: 'I miei progressi'),
                Tab(icon: Icon(Icons.quiz), text: 'Il mio account'),
                Tab(icon: Icon(Icons.attach_file), text: 'Altro'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FutureBuilder<List<CourseProgress>>(
                    future: progressFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text('Impossibile caricare i progressi'));
                      }
                      final progressList = snapshot.data!;

                      // Separazione per categorie
                      final preDecadenzaProgress = progressList.where((p) => preDecadenzaCourses.any((c) => c.title == p.title)).toList();
                      final postDecadenzaProgress = progressList.where((p) => postDecadenzaCourses.any((c) => c.title == p.title)).toList();

                      return ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          const Text('Pre decadenza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildCourseList(preDecadenzaProgress),
                          const SizedBox(height: 24),
                          const Text('Post decadenza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildCourseList(postDecadenzaProgress),
                        ],
                      );
                    },
                  ),

                  // Il tuo account
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: currentUser == null
                        ? const Center(child: Text('Utente non loggato', style: TextStyle(fontSize: 18)))
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nome: ${currentUser!.displayName ?? "Non specificato"}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Email: ${currentUser!.email ?? "Non specificata"}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funzione modifica in sviluppo')));
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifica'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Conferma cancellazione'),
                                    content: const Text('Sei sicuro di voler cancellare il tuo account? Questa operazione è irreversibile.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Conferma')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await FirebaseAuth.instance.currentUser!.delete();
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account cancellato con successo')));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante la cancellazione: $e')));
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Cancella account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Altro placeholder
                  Center(
                    child: Text(
                      'Sezione "Altro" in sviluppo...',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseProgress {
  final String title;
  final String videoStatus;
  final String videoLastView;
  final int videoViewsCount;
  final String quizStatus;
  final String quizAvgScore;
  final int quizAttemptsCount;
  final double videoProgressDouble;
  final double quizAvgScoreDouble;

  CourseProgress({
    required this.title,
    required this.videoStatus,
    required this.videoLastView,
    required this.videoViewsCount,
    required this.quizStatus,
    required this.quizAvgScore,
    required this.quizAttemptsCount,
    required this.videoProgressDouble,
    required this.quizAvgScoreDouble,
  });
}

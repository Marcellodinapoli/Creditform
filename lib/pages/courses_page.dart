import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_page.dart';
import 'main_scaffold_with_role.dart'; // gestisce il menù a destra
import '../widgets/page_wrapper.dart';

class CourseInfo {
  final String title;
  final String number;
  const CourseInfo(this.title, this.number);
}

const List<CourseInfo> preDecadenzaCourses = [
  CourseInfo('Uso del portale', 'Corso 1'),
  CourseInfo('Tipi di finanziamenti', 'Corso 2'),
  CourseInfo('Garanzie e assicurazioni', 'Corso 3'),
  CourseInfo('I primi insoluti', 'Corso 4'),
  CourseInfo('Script di una telefonata', 'Corso 5'),
  CourseInfo('Recupero stragiudiziale', 'Corso 6'),
];

const List<CourseInfo> postDecadenzaCourses = [
  CourseInfo('Decadenza', 'Corso 7'),
  CourseInfo('Terzo pagatore', 'Corso 8'),
  CourseInfo('Procedure di incasso', 'Corso 9'),
  CourseInfo('Titoli di credito', 'Corso 10'),
  CourseInfo('Ricapitoliamo', 'Corso 11'),
  CourseInfo('Normativa', 'Corso 12'),
];

class CoursesPage extends StatelessWidget {
  final String role;
  const CoursesPage({super.key, this.role = 'user'});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Numero colonne responsive
    final crossAxis = width >= 900 ? 3 : width >= 600 ? 2 : 1;
    final maxContentWidth = 1300.0;

    final allCourses = [...preDecadenzaCourses, ...postDecadenzaCourses];

    return MainScaffoldWithRole(
      role: role,
      currentPage: 'corsi',
      child: PageWrapper(
        title: 'Corsi',
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: ListView(
                children: [
                  const Text('Pre decadenza',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _CourseGrid(
                      courses: preDecadenzaCourses,
                      crossAxis: crossAxis,
                      allCourses: allCourses),
                  const SizedBox(height: 32),
                  const Text('Post decadenza',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _CourseGrid(
                      courses: postDecadenzaCourses,
                      crossAxis: crossAxis,
                      allCourses: allCourses),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseGrid extends StatelessWidget {
  final List<CourseInfo> courses;
  final int crossAxis;
  final List<CourseInfo> allCourses;
  const _CourseGrid({
    required this.courses,
    required this.crossAxis,
    required this.allCourses,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 3 / 3.3,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _CourseCard(
          info: courses[index],
          allCourses: allCourses,
        );
      },
    );
  }
}

class _CourseCard extends StatefulWidget {
  final CourseInfo info;
  final List<CourseInfo> allCourses;

  const _CourseCard({required this.info, required this.allCourses});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress(widget.info.title);
  }

  Future<Map<String, dynamic>> _loadProgress(String courseTitle) async {
    final prefs = await SharedPreferences.getInstance();

    String quizStatus = prefs.getString('quiz_status_$courseTitle') ?? 'non iniziato';
    if (quizStatus == 'incompleto') quizStatus = 'non iniziato';

    // Nota: videoProgress è recuperato ma non più usato perché tolta la barra progresso
    double videoProgress = prefs.getDouble('video_progress_$courseTitle') ?? 0.0;

    return {
      'videoStatus': prefs.getString('video_status_$courseTitle') ?? 'non iniziato',
      'videoProgress': videoProgress,
      'videoLastView': prefs.getString('video_last_view_$courseTitle') ?? '-',
      'quizStatus': quizStatus,
      'quizAvgScore': prefs.getString('quiz_avg_score_$courseTitle') ?? '-',
      'quizLastAttempt': prefs.getString('quiz_last_attempt_$courseTitle') ?? '-',
      'quizAttemptCount': prefs.getInt('quiz_attempt_count_$courseTitle') ?? 0,
      'quizAvgTime': prefs.getString('quiz_avg_time_$courseTitle') ?? '-',
    };
  }

  @override
  Widget build(BuildContext context) {
    const _headerColor = Color(0xFF1E66FF);
    const _buttonColor = Color(0xFFE91E63);
    final isFirstCourse = widget.info.title == 'Uso del portale';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _headerColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.info.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.info.number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _headerColor,
                  ),
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: _progressFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return _buildStatusBadge('non iniziato');
                    }
                    final data = snapshot.data!;
                    final status = data['quizStatus'] as String? ?? 'non iniziato';

                    return _buildStatusBadge(status);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Cosa contiene:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (isFirstCourse)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Video corso durata: 2m:30s'),
                    Text('• Test competenze informatiche'),
                    Text('• Test competenze sul credito al consumo'),
                  ],
                ),
              )
            else
              const SizedBox(height: 32),
            const SizedBox(height: 10),
            const Text('Cosa vedremo:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (isFirstCourse)
              const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 4),
                child: Text('• Come sfruttare al meglio la nostra piattaforma web'),
              )
            else
              const SizedBox(height: 32),
            const SizedBox(height: 16),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _buttonColor,
                  side: const BorderSide(color: _buttonColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingPage(
                        courseList: widget.allCourses.map((e) => e.title).toList(),
                        currentIndex: widget.allCourses.indexWhere((c) => c.title == widget.info.title),
                      ),
                    ),
                  );
                },
                child: const Text('Accedi', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    if (status.contains('/10')) {
      color = Colors.green.shade700;
      label = "✅ $status";
    } else if (status == "completato") {
      color = Colors.green;
      label = "✅ Completato";
    } else if (status == "incompleto") {
      color = Colors.orange;
      label = "🟡 Incompleto";
    } else {
      color = Colors.red;
      label = "❌ Non iniziato";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'courses_page.dart';
import 'roleplay_page.dart'; // Assicurati che il nome della classe sia corretto (RoleplayPage o RolePlayPage)
import 'training_page.dart';

class MainScaffoldWithRole extends StatefulWidget {
  final String role;
  final String currentPage;
  final Widget child;

  const MainScaffoldWithRole({
    Key? key,
    required this.role,
    required this.currentPage,
    required this.child,
  }) : super(key: key);

  @override
  State<MainScaffoldWithRole> createState() => _MainScaffoldWithRoleState();
}

class _MainScaffoldWithRoleState extends State<MainScaffoldWithRole> {
  late String role;
  late String currentPage;

  static const Color appBarBlue = Color(0xFF1565C0); // blu scuro personalizzato
  static const Color selectedBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    role = widget.role;
    currentPage = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CreditForm',
          style: TextStyle(color: Colors.white), // testo forzato bianco
        ),
        backgroundColor: appBarBlue,
      ),
      body: Row(
        children: [
          // Contenuto principale (espande a sinistra)
          Expanded(
            child: widget.child,
          ),

          // Menu a destra fisso
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Menù',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Titolo menù nero e grassetto
                    ),
                  ),
                ),
                _buildMenuItem('dashboard', 'Dashboard', Icons.dashboard),
                _buildMenuItem('corsi', 'Corsi', Icons.menu_book),
                _buildMenuItem('roleplay', 'Roleplay', Icons.record_voice_over),
                // Se vuoi togliere training dal menu, non aggiungerlo qui
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String pageKey, String label, IconData icon) {
    final isSelected = pageKey == currentPage;
    return ListTile(
      leading: Icon(icon, color: isSelected ? selectedBlue : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? selectedBlue : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        if (pageKey != currentPage) {
          setState(() {
            currentPage = pageKey;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                switch (pageKey) {
                  case 'dashboard':
                    return DashboardPage();
                  case 'corsi':
                    return CoursesPage(role: role);
                  case 'roleplay':
                    return RoleplayPage(role: role);
                  default:
                    return DashboardPage();
                }
              },
            ),
          );
        }
      },
    );
  }
}

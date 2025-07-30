import 'package:flutter/material.dart';
import 'main_scaffold_with_role.dart';
import '../widgets/page_wrapper.dart';
import 'dart:html' as html;

class RoleplayPage extends StatefulWidget {
  final String role;

  const RoleplayPage({Key? key, this.role = 'user'}) : super(key: key);

  @override
  State<RoleplayPage> createState() => _RoleplayPageState();
}

class _RoleplayPageState extends State<RoleplayPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const [
    Tab(icon: Icon(Icons.warning_amber_rounded), text: "Pre decadenza"),
    Tab(icon: Icon(Icons.check_circle_outline), text: "Post decadenza"),
  ];

  final List<Map<String, String>> preDecadenzaSim = [
    {
      'title': 'Simulazione Pre 1',
      'deb': 'Mario Rossi',
      'gar': 'Luca Bianchi',
      'impInit': '10.000€',
      'impTrans': '8.000€',
      'link': 'https://elevenlabs.io/app/talk-to?agent_id=UOhvZcURnSkxxtFirBux',
    },
    {
      'title': 'Simulazione Pre 2',
      'deb': 'Anna Verdi',
      'gar': 'Giulia Neri',
      'impInit': '5.000€',
      'impTrans': '4.500€',
    },
  ];

  final List<Map<String, String>> postDecadenzaSim = [
    {
      'title': 'Simulazione Post 1',
      'deb': 'Carlo Blu',
      'gar': 'Mario Giallo',
      'impInit': '15.000€',
      'impTrans': '10.000€',
    },
    {
      'title': 'Simulazione Post 2',
      'deb': 'Sara Viola',
      'gar': 'Luca Verde',
      'impInit': '20.000€',
      'impTrans': '18.000€',
    },
  ];

  int selectedPreIndex = 0;
  int selectedPostIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  void openPopupWindow(String url) {
    final width = 700; // più stretto
    final height = 600;
    final screenWidth = html.window.screen?.available.width ?? 1920;
    final left = screenWidth - width - 20; // spostato quasi al bordo destro (20px margine)
    final top = 100;
    final windowFeatures =
        'width=$width,height=$height,left=$left,top=$top,resizable=yes,scrollbars=yes,noopener=yes,noreferrer=yes';

    html.window.open(url, 'simulazione_popup', windowFeatures);
    // Rimosso popup?.focus(); perché non esiste in dart:html
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = const Color(0xFF6A1B9A);
    return MainScaffoldWithRole(
      role: widget.role,
      currentPage: 'roleplay',
      child: PageWrapper(
        title: 'Esercitazioni Role Play',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: labelColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: labelColor,
              indicatorWeight: 4,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
              tabs: myTabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final icon = tab.icon as Icon;
                return Tab(
                  icon: Icon(
                    icon.icon,
                    color: _tabController.index == index ? labelColor : Colors.grey,
                  ),
                  text: tab.text,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoleplaySection(
                    simulations: preDecadenzaSim,
                    selectedIndex: selectedPreIndex,
                    onSelect: (idx) {
                      setState(() {
                        selectedPreIndex = idx;
                      });
                    },
                    onOpenLink: openPopupWindow,
                  ),
                  _buildRoleplaySection(
                    simulations: postDecadenzaSim,
                    selectedIndex: selectedPostIndex,
                    onSelect: (idx) {
                      setState(() {
                        selectedPostIndex = idx;
                      });
                    },
                    onOpenLink: openPopupWindow,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleplaySection({
    required List<Map<String, String>> simulations,
    required int selectedIndex,
    required Function(int) onSelect,
    required Function(String) onOpenLink,
  }) {
    final selectedSim = simulations[selectedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debitore: ${selectedSim['deb']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Garante: ${selectedSim['gar']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Importo iniziale: ${selectedSim['impInit']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Importo transatto: ${selectedSim['impTrans']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: simulations.length,
              shrinkWrap: true,
              itemBuilder: (context, idx) {
                final sim = simulations[idx];
                final isSelected = idx == selectedIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Apri simulazione'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue.shade300 : null,
                    ),
                    onPressed: sim.containsKey('link')
                        ? () {
                      onSelect(idx);
                      onOpenLink(sim['link']!);
                    }
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

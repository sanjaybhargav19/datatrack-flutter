
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = UsageProvider();
  await provider.loadData();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const DataTrackApp(),
    ),
  );
}

// ================= THEME =================

class DataTrackApp extends StatelessWidget {
  const DataTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'DataTrack',
          themeMode: provider.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF38BDF8),
              brightness: Brightness.dark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ================= DATA MODEL =================

class UsageRecord {
  final String id;
  final String appName;
  final double amount;
  final String category;
  final DateTime date;

  UsageRecord({
    required this.id,
    required this.appName,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'appName': appName,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
  };

  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    return UsageRecord(
      id: json['id'],
      appName: json['appName'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
    );
  }
}

// ================= PROVIDER =================

class UsageProvider extends ChangeNotifier {
  List<UsageRecord> records = [];

  double dataLimit = 10;
  bool darkMode = true;

  int selectedPage = 0;

  final List<double> weeklyUsage = [
    1.2, 2.1, 1.5, 2.8, 1.7, 3.1, 2.2
  ];

  double get totalUsed =>
      records.fold(0, (sum, item) => sum + item.amount);

  double get remaining =>
      (dataLimit - totalUsed).clamp(0, dataLimit);

  double get percentage =>
      dataLimit <= 0 ? 0 : totalUsed / dataLimit;

  int get alertCount => records
      .where((r) => r.amount >= 1)
      .length;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    darkMode = prefs.getBool('darkMode') ?? true;
    dataLimit = prefs.getDouble('dataLimit') ?? 10;

    final saved = prefs.getString('records');

    if (saved != null) {
      final List decoded = jsonDecode(saved);
      records = decoded
          .map((item) => UsageRecord.fromJson(item))
          .toList();
    } else {
      records = [
        UsageRecord(
          id: '1',
          appName: 'YouTube',
          amount: 1.2,
          category: 'Entertainment',
          date: DateTime.now(),
        ),
        UsageRecord(
          id: '2',
          appName: 'Instagram',
          amount: 0.8,
          category: 'Social Media',
          date: DateTime.now(),
        ),
        UsageRecord(
          id: '3',
          appName: 'Chrome',
          amount: 0.5,
          category: 'Browsing',
          date: DateTime.now(),
        ),
        UsageRecord(
          id: '4',
          appName: 'WhatsApp',
          amount: 0.3,
          category: 'Communication',
          date: DateTime.now(),
        ),
      ];
      await saveData();
    }

    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'records',
      jsonEncode(records.map((e) => e.toJson()).toList()),
    );

    await prefs.setDouble('dataLimit', dataLimit);
    await prefs.setBool('darkMode', darkMode);
  }

  void addRecord(
    String name,
    double amount,
    String category,
  ) {
    records.insert(
      0,
      UsageRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        appName: name,
        amount: amount,
        category: category,
        date: DateTime.now(),
      ),
    );

    saveData();
    notifyListeners();
  }

  void updateRecord(
    String id,
    String name,
    double amount,
    String category,
  ) {
    final index = records.indexWhere((r) => r.id == id);

    if (index != -1) {
      final old = records[index];

      records[index] = UsageRecord(
        id: id,
        appName: name,
        amount: amount,
        category: category,
        date: old.date,
      );

      saveData();
      notifyListeners();
    }
  }

  void deleteRecord(String id) {
    records.removeWhere((r) => r.id == id);
    saveData();
    notifyListeners();
  }

  void setLimit(double value) {
    dataLimit = value;
    saveData();
    notifyListeners();
  }

  void toggleTheme() {
    darkMode = !darkMode;
    saveData();
    notifyListeners();
  }

  void setPage(int index) {
    selectedPage = index;
    notifyListeners();
  }
}

// ================= HOME AND NAVIGATION =================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<String> titles = const [
    'Dashboard',
    'Usage History',
    'Analytics',
    'Data Plan',
    'Notifications',
    'Settings',
  ];

  final List<IconData> icons = const [
    Icons.dashboard_rounded,
    Icons.history_rounded,
    Icons.analytics_rounded,
    Icons.data_usage_rounded,
    Icons.notifications_active_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsageProvider>();
    final width = MediaQuery.of(context).size.width;

    final pages = [
      const DashboardScreen(),
      const HistoryScreen(),
      const AnalyticsScreen(),
      const PlanScreen(),
      const NotificationScreen(),
      const SettingsScreen(),
    ];

    final isDesktop = width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.blue),
            const SizedBox(width: 10),
            const Text(
              'DataTrack',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: provider.toggleTheme,
            icon: Icon(
              provider.darkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Change theme',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: provider.selectedPage,
              onDestinationSelected: provider.setPage,
              labelType: NavigationRailLabelType.all,
              destinations: List.generate(
                titles.length,
                (i) => NavigationRailDestination(
                  icon: Icon(icons[i]),
                  label: Text(titles[i]),
                ),
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(provider.selectedPage),
                child: pages[provider.selectedPage],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: provider.selectedPage,
              onDestinationSelected: provider.setPage,
              destinations: [
                NavigationDestination(
                  icon: Icon(icons[0]),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(icons[1]),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(icons[2]),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(icons[3]),
                  label: 'Plan',
                ),
                NavigationDestination(
                  icon: Icon(icons[4]),
                  label: 'Alerts',
                ),
                NavigationDestination(
                  icon: Icon(icons[5]),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}

// ================= COMMON PAGE =================

class PageContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const PageContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD =================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    return PageContainer(
      title: 'Welcome back 👋',
      subtitle: 'Monitor and manage your internet consumption.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 700 ? 3 : 1;

              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: count == 1 ? 3.0 : 2.1,
                children: [
                  StatCard(
                    title: 'Total Used',
                    value: '${p.totalUsed.toStringAsFixed(2)} GB',
                    icon: Icons.wifi,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'Remaining',
                    value: '${p.remaining.toStringAsFixed(2)} GB',
                    icon: Icons.data_usage,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: 'Monthly Limit',
                    value: '${p.dataLimit.toStringAsFixed(1)} GB',
                    icon: Icons.speed,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Data Consumption',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Circular usage indicator with centered percentage text.
                  Center(
                    child: SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: p.percentage.clamp(0.0, 1.0),
                              ),
                              duration: const Duration(seconds: 1),
                              builder: (context, value, child) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.shade700,
                                  color: Colors.blue,
                                );
                              },
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(p.percentage.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Used',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${p.remaining.toStringAsFixed(2)} GB remaining out of ${p.dataLimit} GB',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => p.setPage(1),
                child: const Text('View All'),
              ),
            ],
          ),

          ...p.records.take(4).map(
            (record) => UsageTile(record: record),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showUsageDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Data Usage'),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= STAT CARD =================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

// ================= USAGE HISTORY =================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    final filtered = p.records.where((r) {
      return r.appName.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return PageContainer(
      title: 'Usage History',
      subtitle: 'Manage your internet consumption records.',
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search applications...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => search = value),
          ),
          const SizedBox(height: 18),

          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text('No usage records found.'),
            ),

          ...filtered.map(
            (record) => UsageTile(
              record: record,
              editable: true,
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () => showUsageDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Record'),
          ),
        ],
      ),
    );
  }
}

// ================= USAGE TILE =================

class UsageTile extends StatelessWidget {
  final UsageRecord record;
  final bool editable;

  const UsageTile({
    super.key,
    required this.record,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.read<UsageProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.data_usage),
        ),
        title: Text(
          record.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${record.category} • ${record.date.day}/${record.date.month}/${record.date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${record.amount.toStringAsFixed(2)} GB',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (editable) ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showUsageDialog(context, record: record);
                  } else if (value == 'delete') {
                    p.deleteRecord(record.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ================= ADD / EDIT FORM =================

void showUsageDialog(
  BuildContext context, {
  UsageRecord? record,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(
    text: record?.appName ?? '',
  );
  final amountController = TextEditingController(
    text: record?.amount.toString() ?? '',
  );

  String category = record?.category ?? 'Entertainment';

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              record == null ? 'Add Data Usage' : 'Edit Data Usage',
            ),
            content: SizedBox(
              width: 380,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Application Name',
                        prefixIcon: Icon(Icons.apps),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter application name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Data Used (GB)',
                        prefixIcon: Icon(Icons.wifi),
                      ),
                      validator: (value) {
                        final number = double.tryParse(value ?? '');

                        if (number == null || number <= 0) {
                          return 'Enter a valid positive number';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: [
                        'Entertainment',
                        'Social Media',
                        'Browsing',
                        'Communication',
                        'Other',
                      ].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final p = dialogContext.read<UsageProvider>();
                    final name = nameController.text.trim();
                    final amount = double.parse(amountController.text);

                    if (record == null) {
                      p.addRecord(name, amount, category);
                    } else {
                      p.updateRecord(
                        record.id,
                        name,
                        amount,
                        category,
                      );
                    }

                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(record == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ================= ANALYTICS =================

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    return PageContainer(
      title: 'Analytics',
      subtitle: 'Understand your data usage patterns.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatCard(
            title: 'Total Consumption',
            value: '${p.totalUsed.toStringAsFixed(2)} GB',
            icon: Icons.analytics,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Usage (GB)',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        maxY: 4,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon', 'Tue', 'Wed', 'Thu',
                                  'Fri', 'Sat', 'Sun'
                                ];

                                final index = value.toInt();

                                if (index < 0 || index >= days.length) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(days[index]),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(7, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: p.weeklyUsage[i],
                                width: 18,
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Application Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          ...p.records.map(
            (record) => ListTile(
              title: Text(record.appName),
              subtitle: Text(record.category),
              trailing: Text(
                '${record.amount.toStringAsFixed(2)} GB',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= DATA PLAN =================

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final formKey = GlobalKey<FormState>();
  final limitController = TextEditingController();

  @override
  void dispose() {
    limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    return PageContainer(
      title: 'Data Plan',
      subtitle: 'Configure your monthly internet allowance.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.data_usage,
                  size: 50,
                  color: Colors.blue,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Monthly Data Limit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Current limit: ${p.dataLimit} GB',
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'New limit in GB',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid data limit';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      p.setLimit(
                        double.parse(limitController.text),
                      );
                      limitController.clear();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data plan updated successfully!'),
                        ),
                      );
                    }
                  },
                  child: const Text('Update Data Plan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= NOTIFICATIONS =================

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    final alerts = [
      if (p.percentage >= 0.8)
        'You have consumed 80% or more of your data plan.',
      if (p.percentage >= 0.9)
        'Warning: You are approaching your data limit.',
      if (p.percentage >= 1)
        'Your monthly data limit has been exceeded.',
      if (p.alertCount > 0)
        '${p.alertCount} usage records have consumption of 1 GB or more.',
    ];

    return PageContainer(
      title: 'Notifications',
      subtitle: 'Stay informed about your data consumption.',
      child: Column(
        children: [
          if (alerts.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('All good!'),
                subtitle: Text('No data limit alerts currently.'),
              ),
            ),
          ...alerts.map(
            (alert) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Data Usage Alert'),
                subtitle: Text(alert),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= SETTINGS =================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UsageProvider>();

    return PageContainer(
      title: 'Settings',
      subtitle: 'Customize your DataTrack experience.',
      child: Card(
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('DataTrack User'),
              subtitle: Text('Application profile'),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Change application appearance'),
              value: p.darkMode,
              onChanged: (_) => p.toggleTheme(),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.storage),
              title: Text('Local Storage'),
              subtitle: Text('Your records are saved in browser storage'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About DataTrack'),
              subtitle: Text('Flutter Internet Usage Tracker • Version 1.0'),
            ),
          ],
        ),
      ),
    );
  }
}

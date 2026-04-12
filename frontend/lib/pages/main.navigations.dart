import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'expense/expense_list_page.dart';
import 'income/income_list_page.dart';
import 'master/master_data_page.dart';
import 'recap/recap_list_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    RecapListPage(),
    ExpenseListPage(),
    IncomeListPage(),
    MasterDataPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Rekap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: 'Pengeluaran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Pemasukan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_outlined),
            label: 'Master',
          ),
        ],
      ),
    );
  }
}

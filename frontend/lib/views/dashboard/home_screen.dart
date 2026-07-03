import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({super.key, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasName = widget.userName != null && widget.userName!.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasName) ...[
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'مرحبا بك،',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              hasName ? widget.userName! : 'مرحبا بك',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.menu, color: Colors.black87),
                    ),
                  ],
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'لا يوجد أدوية للتذكير!\nأضف أدويتك في خانة أدويتي\nلتبدأ تذكيراتك في الحال.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1D9E75),
                        fontSize: 18,
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF1D9E75),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              label: 'اليوم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'أدويتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.bell),
              label: 'التذكيرات',
            ),
          ],
        ),
      ),
    );
  }
}

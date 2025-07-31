import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/ui/pages/home/question_carousel.dart';

import '../../../services/firestore/firestore_service.dart';
import 'gradings_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  late final String userId;
  int currentIndex = 0;

  @override
  void initState() {
    tabController = TabController(length: 3, vsync: this);
    userId = AuthenticationService().currentUser!.uid;
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: [
          _buildHomeWidget(),
          const Center(child: Text('Discover')),
        ][currentIndex],
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            setState(() => currentIndex = index);
          case 1:
            context.pushNamed('create-question');
          case 2:
            setState(() => currentIndex = 1);
        }
      },
      currentIndex: currentIndex,
    );
  }

  Widget _buildHomeWidget() {
    return ListView(
      children: [
        GradingsChart(
          gradings: FirestoreService().streamUserGradings(userId: userId),
        ),
        QuestionCarousel.fromHistory(
          label: "Recent Questions",
          historyStream: FirestoreService().streamHistory(userId: userId),
        ),
        //todo fix carousel for user questions
        QuestionCarousel.fromQuestions(
          label: "Your Questions",
          questionsStream: FirestoreService().getQuestionsStream(
              userId: userId),
        ),
      ],
    );
  }
}

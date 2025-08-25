import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:your_cooked/services/auth/auth_service.dart';
import 'package:your_cooked/ui/pages/home/consitency_chart.dart';
import 'package:your_cooked/ui/pages/home/profile_drawer.dart';
import 'package:your_cooked/ui/pages/home/profile_icon.dart';
import 'package:your_cooked/ui/pages/home/question_carousel.dart';

import '../../../services/firestore/firestore_service.dart';
import 'discover_page.dart';

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
      body: _buildBody(),
      appBar: _buildAppbar(),
      endDrawer: ProfileDrawer(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: ProfileIcon(),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
      title: Text("Your Cooked"),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: [
        _buildHomeWidget(context),
        Container(),
        DiscoverPage(),
      ][currentIndex],
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
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
        if (index == 1) {
          context.pushNamed('create-question');
        } else {
          setState(() => currentIndex = index);
        }
      },
      currentIndex: currentIndex,
    );
  }

  Widget _buildHomeWidget(BuildContext context) {
    return ListView(
      children: [
        ConsistencyChart(
          stream: FirestoreService().streamUserGradings(userId: userId),
        ),
        QuestionCarousel.fromHistory(
          label: "Recent Questions",
          historyStream: FirestoreService().streamHistory(userId: userId),
        ),
        QuestionCarousel.fromQuestions(
          label: "Your Questions",
          questionsStream: FirestoreService().getQuestionsStream(
            userId: userId,
          ),
        ),
      ],
    );
  }
}

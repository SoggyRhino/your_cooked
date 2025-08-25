import 'package:flutter/material.dart';
import 'package:your_cooked/services/auth/auth_service.dart';

import 'profile_icon.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(children: [_buildHeader(context), _buildSignOut(context)]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = AuthenticationService().currentUser!;
    final name = user.displayName ?? user.email ?? "Missing";
    return DrawerHeader(
      child: Row(
        children: [
          ProfileIcon(),
          const SizedBox(width: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Sign Out'),
      onTap: () {
        AuthenticationService().signOut();
        Navigator.pop(context);
      },
    );
  }
}

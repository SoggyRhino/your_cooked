import 'package:flutter/material.dart';

import '../../../services/auth/auth_service.dart';

const _colors = [
  Color(0xFF8B0000), // Dark Red
  Color(0xFFD2691E), // Dark Orange (Chocolate)
  Color(0xFFB8860B), // Dark Yellow (DarkGoldenrod)
  Color(0xFF006400), // Dark Green
  Color(0xFF008B8B), // Dark Blue (DarkCyan)
  Color(0xFF483D8B), // Dark Indigo (DarkSlateBlue)
  Color(0xFF4B0082), // Dark Purple (Indigo)
  Color(0xFFC71585), // Dark Pink (MediumVioletRed)
  Color(0xFF8A2BE2), // Darker Pastel Purple (BlueViolet)
  Color(0xFF551A8B), // Darker Dusky Purple (Purple) - Adjusted
  Color(0xFFDB7093), // Darker Pastel Pink (PaleVioletRed)
  Color(0xFFFF69B4), // Darker Pale Pink (HotPink) - Adjusted
  Color(0xFFE9967A), // Darker Peach (DarkSalmon)
  Color(0xFFDAA520), // Darker Pastel Yellow (Goldenrod)
  Color(0xFF2E8B57), // Darker Mint Green (SeaGreen)
  Color(0xFF6A5ACD), // Darker Periwinkle (SlateBlue)
  Color(0xFF708090), // Darker Alice Blue (SlateGray)
  Color(0xFF4682B4), // Darker Baby Blue (SteelBlue)
  Color(0xFF5F9EA0), // Darker Cadet Blue (CadetBlue)
  Color(0xFF00BFFF), // Darker Light Sky Blue (DeepSkyBlue) - Adjusted
  Color(0xFF800080), // Darker Lavender (Purple) - Adjusted
  Color(0xFFD8BFD8), // Darker Lavender Blush (Thistle)
  Color(0xFFFFB6C1), // Darker Misty Rose (LightPink) - Adjusted
  Color(0xFF2F4F4F), // Darker Mint Cream (DarkSlateGray)
  Color(0xFF00FA9A), // Darker Honeydew (MediumSpringGreen) - Adjusted
  Color(0xFF696969), // Darker Ghost White (DimGray)
];

class ProfileIcon extends StatefulWidget {
  final VoidCallback? onTap;

  const ProfileIcon({super.key, this.onTap});

  @override
  State<ProfileIcon> createState() => _ProfileIconState();
}

class _ProfileIconState extends State<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final url = AuthenticationService().currentUser?.photoURL;
    final str =
        (AuthenticationService().currentUser?.displayName ??
        AuthenticationService().currentUser?.email ??
        "Missing");
    final background = _colors[str.length % _colors.length];

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: background,
          ),
          child: Center(
            child: url == null
                ? Image.network(url!)
                : Text(
                    str[0],
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
          ),
        ),
      ),
    );
  }
}

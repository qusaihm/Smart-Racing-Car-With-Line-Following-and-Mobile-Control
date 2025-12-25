import 'package:flutter/material.dart';
import 'theme.dart';
// تم إزالة استيراد default_speed_settings.dart
import 'theme_settings.dart';
import 'language_settings.dart';
import 'notifications_settings.dart';
import 'privacy_settings.dart';
import 'help_support.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // تم إزالة تعريفات الألوان الثابتة هنا. يجب أن تكون cardColor و primaryColor متاحة من 'theme.dart'.

  Widget _settingsTile(String title,
      {String? subtitle, IconData? icon, VoidCallback? onTap}) {
    // نعتمد على أن cardColor و primaryColor تم استيرادهما من theme.dart
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null)
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            // 💡 تم حذف "Default Speed"
            
            // 💡 تمت المحافظة على التنقل باستخدام Navigator.push و MaterialPageRoute
            _settingsTile('Theme',
                subtitle: 'Light',
                icon: Icons.palette,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ThemeSettingsPage()),
                )),
                
            // 💡 تمت المحافظة على التنقل باستخدام Navigator.push و MaterialPageRoute
            _settingsTile('Language',
                subtitle: 'English',
                icon: Icons.language,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
                )),
                
            const SizedBox(height: 16),
            
            // 💡 تمت المحافظة على التنقل باستخدام Navigator.push و MaterialPageRoute
            _settingsTile('Notifications',
                icon: Icons.notifications,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsSettingsPage()),
                )),
                
            // 💡 تمت المحافظة على التنقل باستخدام Navigator.push و MaterialPageRoute
            _settingsTile('Privacy',
                icon: Icons.security,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacySettingsPage()),
                )),
                
            // 💡 تمت المحافظة على التنقل باستخدام Navigator.push و MaterialPageRoute
            _settingsTile('Help & Support',
                icon: Icons.help_outline,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                )),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';


class AppearanceSettings extends StatefulWidget {
  @override
  _AppearanceSettingsState createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  String _selectedTheme = 'Light'; // Default theme

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              title: Text('Light Theme'),
              leading: Radio<String>(
                value: 'Light',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Dark Theme'),
              leading: Radio<String>(
                value: 'Dark',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save selected theme preferences
                Navigator.pop(context);
              },
              child: Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }
}

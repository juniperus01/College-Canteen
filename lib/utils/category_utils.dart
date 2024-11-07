import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryUtils {
  // This map stores the relation between localized names and Firebase collection names
  static final Map<String, String> _collectionMap = {
    // Hindi to Firebase mappings
    'दोसा': 'dosa',
    'चाट': 'chat',
    'स्नैक्स': 'snacks',
    'फ्रैंकी': 'franky',
    'हॉट आइटम्स': 'hot_items',
    'सैंडविच': 'sandwiches',
    // English to Firebase mappings (as fallback)
    'Dosa': 'dosa',
    'Chat': 'chat',
    'Snacks': 'snacks',
    'Franky': 'franky',
    'Hot Items': 'hot_items',
    'Sandwiches': 'sandwiches'
  };

  // Convert display name (Hindi/English) to Firebase collection name
  static String getFirebaseCollection(String displayName) {
    // First try direct mapping
    String? collectionName = _collectionMap[displayName];
    if (collectionName != null) {
      return collectionName;
    }

    // If no direct mapping found, try normalized comparison
    String normalizedInput = displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return _collectionMap.values.firstWhere(
      (name) => name.toLowerCase() == normalizedInput,
      orElse: () => 'dosa' // Default to 'dosa' if no match found
    );
  }

  // Convert Firebase collection name to display name
  static String getDisplayName(String firebaseCollection, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map Firebase collection names to localized strings
    switch (firebaseCollection) {
      case 'dosa':
        return l10n.dosaCategory;
      case 'chat':
        return l10n.chatCategory;
      case 'snacks':
        return l10n.snacksCategory;
      case 'franky':
        return l10n.frankyCategory;
      case 'hot_items':
        return l10n.hotItemsCategory;
      case 'sandwiches':
        return l10n.sandwichesCategory;
      default:
        return firebaseCollection;
    }
  }

  // Debug method to verify mappings
  static void debugPrintMapping(String displayName) {
    print('Display Name: $displayName');
    print('Firebase Collection: ${getFirebaseCollection(displayName)}');
  }
}
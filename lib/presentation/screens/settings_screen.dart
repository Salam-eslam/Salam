import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/enhanced_theme_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../services/accessibility_service.dart';
import 'simple_cache_management.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final AccessibilityService _accessibilityService = AccessibilityService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _accessibilityService.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accessibilityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<PreferenceSettingsProvider, EnhancedThemeProvider>(
        builder: (context, prefProvider, themeProvider, child) {
          final colorScheme = Theme.of(context).colorScheme;
          final isDarkTheme = themeProvider.isDarkTheme(context);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkTheme
                    ? [colorScheme.surface, colorScheme.surfaceContainerHighest]
                    : [
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest
                      ],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Settings Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Theme & Appearance Section
                        _buildSectionHeader(
                            'Theme & Appearance', Icons.palette, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildSwitchTile(
                              icon: isDarkTheme
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              title: 'Dark Theme',
                              subtitle: 'Toggle between light and dark themes',
                              value:
                                  themeProvider.themeMode == ThemeMode.dark ||
                                      (themeProvider.themeMode ==
                                              ThemeMode.system &&
                                          isDarkTheme),
                              onChanged: (value) {
                                themeProvider.setThemeMode(
                                    value ? ThemeMode.dark : ThemeMode.light);
                              },
                              colorScheme: colorScheme,
                              color: colorScheme.primary,
                            ),
                            _buildDropdownTile(
                              icon: Icons.color_lens,
                              title: 'Theme Style',
                              subtitle: themeProvider.themeStyle.name,
                              onTap: () =>
                                  _showThemeStyleDialog(context, themeProvider),
                              colorScheme: colorScheme,
                              color: colorScheme.secondary,
                            ),
                            _buildDropdownTile(
                              icon: Icons.font_download,
                              title: 'Arabic Font',
                              subtitle: themeProvider.arabicFont.displayName,
                              onTap: () =>
                                  _showArabicFontDialog(context, themeProvider),
                              colorScheme: colorScheme,
                              color: colorScheme.tertiary,
                            ),
                            _buildSliderTile(
                              icon: Icons.format_size,
                              title: 'Font Scale',
                              subtitle:
                                  '${(themeProvider.fontScale * 100).round()}%',
                              value: themeProvider.fontScale,
                              min: 0.7,
                              max: 2.0,
                              divisions: 13,
                              onChanged: (value) =>
                                  themeProvider.setFontScale(value),
                              colorScheme: colorScheme,
                              color: colorScheme.primary,
                            ),
                            _buildSwitchTile(
                              icon: Icons.contrast,
                              title: 'High Contrast',
                              subtitle:
                                  'Improve readability with higher contrast',
                              value: themeProvider.isHighContrast,
                              onChanged: (value) =>
                                  themeProvider.setHighContrast(value),
                              colorScheme: colorScheme,
                              color: colorScheme.error,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Quick Accessibility Actions
                        _buildSectionHeader('Quick Accessibility',
                            Icons.accessibility_new, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildQuickAccessButtons(
                                context, themeProvider, colorScheme),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Text-to-Speech Section
                        _buildSectionHeader('Text-to-Speech Settings',
                            Icons.record_voice_over, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildTtsToggle(context, colorScheme),
                            if (_accessibilityService.isTtsEnabled) ...[
                              _buildTtsSpeedSlider(context, colorScheme),
                              _buildTtsPitchSlider(context, colorScheme),
                              _buildTtsVolumeSlider(context, colorScheme),
                              _buildTtsLanguageSelector(context, colorScheme),
                              _buildTtsOptionsToggles(context, colorScheme),
                            ],
                            _buildTestButtons(context, colorScheme),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Visual Accessibility
                        _buildSectionHeader('Visual Accessibility',
                            Icons.visibility, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildSwitchTile(
                              icon: Icons.contrast,
                              title: 'High Contrast Mode',
                              subtitle:
                                  'Increase contrast for better visibility',
                              value: themeProvider.isHighContrast,
                              onChanged: themeProvider.setHighContrast,
                              colorScheme: colorScheme,
                              color: colorScheme.error,
                            ),
                            _buildSwitchTile(
                              icon: Icons.animation,
                              title: 'Reduce Animations',
                              subtitle: 'Minimize motion for sensitive users',
                              value: themeProvider.reduceAnimations,
                              onChanged: themeProvider.setReduceAnimations,
                              colorScheme: colorScheme,
                              color: colorScheme.secondary,
                            ),
                            _buildSwitchTile(
                              icon: Icons.vibration,
                              title: 'Haptic Feedback',
                              subtitle: 'Vibration feedback for interactions',
                              value: themeProvider.enableHaptics,
                              onChanged: themeProvider.setEnableHaptics,
                              colorScheme: colorScheme,
                              color: colorScheme.tertiary,
                            ),
                            _buildSwitchTile(
                              icon: Icons.auto_awesome,
                              title: 'Dynamic Colors',
                              subtitle: 'Use system colors when available',
                              value: themeProvider.autoTheme,
                              onChanged: themeProvider.setAutoTheme,
                              colorScheme: colorScheme,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Reading Experience Section
                        _buildSectionHeader(
                            'Reading Experience', Icons.menu_book, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            Selector<EnhancedThemeProvider, double>(
                              selector: (_, themeProvider) =>
                                  themeProvider.arabicFontSize,
                              builder: (context, arabicFontSize, child) {
                                final themeProvider =
                                    context.read<EnhancedThemeProvider>();
                                return _buildSliderTile(
                                  icon: Icons.format_size,
                                  title: 'Arabic Text Size',
                                  subtitle: '${arabicFontSize.round()}px',
                                  value: arabicFontSize,
                                  min: 14.0,
                                  max: 32.0,
                                  divisions: 18,
                                  onChanged: (value) =>
                                      themeProvider.setArabicFontSize(value),
                                  colorScheme: colorScheme,
                                  color: colorScheme.primary,
                                );
                              },
                            ),
                            Selector<EnhancedThemeProvider, bool>(
                              selector: (_, themeProvider) =>
                                  themeProvider.isNightReadingMode,
                              builder: (context, isNightReadingMode, child) {
                                final themeProvider =
                                    context.read<EnhancedThemeProvider>();
                                return _buildSwitchTile(
                                  icon: Icons.nightlight_round,
                                  title: 'Night Reading Mode',
                                  subtitle:
                                      'Dim screen for comfortable reading',
                                  value: isNightReadingMode,
                                  onChanged: (value) => themeProvider
                                      .enableNightReadingMode(value),
                                  colorScheme: colorScheme,
                                  color: colorScheme.secondary,
                                );
                              },
                            ),
                            _buildSwitchTile(
                              icon: Icons.translate,
                              title: 'Show Translation',
                              subtitle: 'Display verse translations',
                              value: prefProvider.showTranslation,
                              onChanged: (value) =>
                                  prefProvider.toggleTranslation(value),
                              colorScheme: colorScheme,
                              color: colorScheme.tertiary,
                            ),
                            if (prefProvider.showTranslation)
                              _buildDropdownTile(
                                icon: Icons.language,
                                title: 'Translation Language',
                                subtitle: PreferenceSettingsProvider
                                            .availableTranslations[
                                        prefProvider.selectedTranslation] ??
                                    'Select',
                                onTap: () => _showTranslationDialog(
                                    context, prefProvider),
                                colorScheme: colorScheme,
                                color: colorScheme.tertiary,
                              ),
                            _buildSwitchTile(
                              icon: Icons.book,
                              title: 'Show Tafsir',
                              subtitle: 'Display scholarly commentary',
                              value: prefProvider.showTafsir,
                              onChanged: (value) =>
                                  prefProvider.toggleTafsir(value),
                              colorScheme: colorScheme,
                              color: colorScheme.primary,
                            ),
                            if (prefProvider.showTafsir)
                              _buildDropdownTile(
                                icon: Icons.school,
                                title: 'Tafsir Source',
                                subtitle:
                                    PreferenceSettingsProvider.availableTafsir[
                                            prefProvider.selectedTafsir] ??
                                        'Select',
                                onTap: () =>
                                    _showTafsirDialog(context, prefProvider),
                                colorScheme: colorScheme,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Notifications & Alerts Section
                        _buildSectionHeader('Notifications & Alerts',
                            Icons.notifications, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildNavigationTile(
                              icon: Icons.notification_important,
                              title: 'Prayer Notifications',
                              subtitle: 'Configure prayer time alerts',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationSettingsScreen(),
                                  ),
                                );
                              },
                              colorScheme: colorScheme,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Storage & Cache Section
                        _buildSectionHeader(
                            'Storage & Offline', Icons.storage, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildNavigationTile(
                              icon: Icons.cloud_download,
                              title: 'Cache Management',
                              subtitle: 'Manage offline content and storage',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SimpleCacheManagementScreen(),
                                  ),
                                );
                              },
                              colorScheme: colorScheme,
                              color: colorScheme.secondary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Quick Actions Section
                        _buildSectionHeader(
                            'Theme Presets', Icons.palette, colorScheme),
                        _buildSettingsCard(
                          colorScheme: colorScheme,
                          children: [
                            _buildThemePresets(
                                context, themeProvider, colorScheme),
                            const SizedBox(height: 8),
                            _buildActionTile(
                              icon: Icons.restore,
                              title: 'Reset All Settings',
                              subtitle:
                                  'Restore all settings to default values',
                              onTap: () => _showResetDialog(
                                  context, themeProvider, prefProvider),
                              colorScheme: colorScheme,
                              color: colorScheme.error,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        activeTrackColor: color.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.play_arrow,
        color: color,
      ),
      onTap: onTap,
    );
  }

  // Dialog methods
  void _showThemeStyleDialog(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme Style'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<AppThemeStyle>(
            groupValue: themeProvider.themeStyle,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeStyle(value);
                Navigator.pop(context);
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppThemeStyle.values.length,
              itemBuilder: (context, index) {
                final style = AppThemeStyle.values[index];
                return RadioListTile<AppThemeStyle>(
                  title: Text(style.name),
                  value: style,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showArabicFontDialog(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Arabic Font'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<ArabicFontFamily>(
            groupValue: themeProvider.arabicFont,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setArabicFont(value);
                Navigator.pop(context);
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ArabicFontFamily.values.length,
              itemBuilder: (context, index) {
                final font = ArabicFontFamily.values[index];
                return RadioListTile<ArabicFontFamily>(
                  title: Text(font.displayName),
                  value: font,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTranslationDialog(
      BuildContext context, PreferenceSettingsProvider prefProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Translation'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: prefProvider.selectedTranslation,
            onChanged: (selectedKey) {
              if (selectedKey != null) {
                prefProvider.setSelectedTranslation(selectedKey);
                Navigator.pop(context);
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  PreferenceSettingsProvider.availableTranslations.length,
              itemBuilder: (context, index) {
                final key = PreferenceSettingsProvider
                    .availableTranslations.keys
                    .elementAt(index);
                final value =
                    PreferenceSettingsProvider.availableTranslations[key]!;
                return RadioListTile<String>(
                  title: Text(value),
                  value: key,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTafsirDialog(
      BuildContext context, PreferenceSettingsProvider prefProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Tafsir'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: prefProvider.selectedTafsir,
            onChanged: (selectedKey) {
              if (selectedKey != null) {
                prefProvider.setSelectedTafsir(selectedKey);
                Navigator.pop(context);
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: PreferenceSettingsProvider.availableTafsir.length,
              itemBuilder: (context, index) {
                final key = PreferenceSettingsProvider.availableTafsir.keys
                    .elementAt(index);
                final value = PreferenceSettingsProvider.availableTafsir[key]!;
                return RadioListTile<String>(
                  title: Text(value),
                  value: key,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(
      BuildContext context,
      EnhancedThemeProvider themeProvider,
      PreferenceSettingsProvider prefProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              themeProvider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Accessibility methods
  Widget _buildQuickAccessButtons(BuildContext context,
      EnhancedThemeProvider themeProvider, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildQuickActionButton(
            context,
            'Accessibility Mode',
            Icons.accessibility,
            !themeProvider.isHighContrast,
            () async {
              if (themeProvider.isHighContrast) {
                await themeProvider.disableAccessibilityMode();
                _accessibilityService
                    .announceAction('Accessibility mode disabled');
              } else {
                await themeProvider.enableAccessibilityMode();
                _accessibilityService
                    .announceAction('Accessibility mode enabled');
              }
            },
            colorScheme,
          ),
          _buildQuickActionButton(
            context,
            'High Contrast',
            Icons.contrast,
            themeProvider.isHighContrast,
            () async {
              await themeProvider
                  .setHighContrast(!themeProvider.isHighContrast);
              _accessibilityService.announceAction(themeProvider.isHighContrast
                  ? 'High contrast enabled'
                  : 'High contrast disabled');
            },
            colorScheme,
          ),
          _buildQuickActionButton(
            context,
            'Large Text',
            Icons.format_size,
            themeProvider.fontScale > 1.0,
            () async {
              final newScale = themeProvider.fontScale > 1.0 ? 1.0 : 1.3;
              await themeProvider.setFontScale(newScale);
              _accessibilityService.announceAction(newScale > 1.0
                  ? 'Large text enabled'
                  : 'Large text disabled');
            },
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isEnabled,
    VoidCallback onPressed,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: isEnabled
          ? colorScheme.primary.withValues(alpha: 0.1)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isEnabled
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTtsToggle(BuildContext context, ColorScheme colorScheme) {
    return StreamBuilder<bool>(
      stream: _accessibilityService.speakingStream,
      builder: (context, snapshot) {
        return _buildSwitchTile(
          icon: _accessibilityService.isTtsEnabled
              ? Icons.volume_up
              : Icons.volume_off,
          title: 'Enable Text-to-Speech',
          subtitle: _accessibilityService.isTtsEnabled
              ? 'Voice announcements enabled'
              : 'Voice announcements disabled',
          value: _accessibilityService.isTtsEnabled,
          onChanged: (value) {
            _accessibilityService.setTtsEnabled(value);
            setState(() {});
          },
          colorScheme: colorScheme,
          color: colorScheme.primary,
        );
      },
    );
  }

  Widget _buildTtsSpeedSlider(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.speed, color: colorScheme.secondary, size: 24),
          ),
          title: Text(
            'Speech Speed',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            _accessibilityService.ttsSpeed.displayName,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Slider(
            value: _accessibilityService.ttsSpeed.index.toDouble(),
            min: 0,
            max: TtsSpeed.values.length - 1,
            divisions: TtsSpeed.values.length - 1,
            activeColor: colorScheme.secondary,
            onChanged: (value) {
              _accessibilityService.setTtsSpeed(TtsSpeed.values[value.round()]);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTtsPitchSlider(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.graphic_eq, color: colorScheme.tertiary, size: 24),
          ),
          title: Text(
            'Voice Pitch',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${(_accessibilityService.ttsPitch * 100).round()}%',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Slider(
            value: _accessibilityService.ttsPitch,
            min: 0.5,
            max: 2.0,
            activeColor: colorScheme.tertiary,
            onChanged: (value) {
              _accessibilityService.setTtsPitch(value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTtsVolumeSlider(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.volume_up, color: colorScheme.primary, size: 24),
          ),
          title: Text(
            'Voice Volume',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            '${(_accessibilityService.ttsVolume * 100).round()}%',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Slider(
            value: _accessibilityService.ttsVolume,
            min: 0.0,
            max: 1.0,
            activeColor: colorScheme.primary,
            onChanged: (value) {
              _accessibilityService.setTtsVolume(value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTtsLanguageSelector(
      BuildContext context, ColorScheme colorScheme) {
    return _buildDropdownTile(
      icon: Icons.language,
      title: 'Voice Language',
      subtitle: _accessibilityService.ttsLanguage.displayName,
      onTap: () => _showTtsLanguageDialog(context),
      colorScheme: colorScheme,
      color: colorScheme.secondary,
    );
  }

  Widget _buildTtsOptionsToggles(
      BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.auto_stories,
          title: 'Auto-read Content',
          subtitle: 'Automatically read new content',
          value: _accessibilityService.autoRead,
          onChanged: (value) {
            _accessibilityService.setAutoRead(value);
            setState(() {});
          },
          colorScheme: colorScheme,
          color: colorScheme.tertiary,
        ),
        _buildSwitchTile(
          icon: Icons.announcement,
          title: 'Announce Navigation',
          subtitle: 'Announce screen changes',
          value: _accessibilityService.announceNavigation,
          onChanged: (value) {
            _accessibilityService.setAnnounceNavigation(value);
            setState(() {});
          },
          colorScheme: colorScheme,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildTestButtons(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _accessibilityService.testTts,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test English'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _accessibilityService.testArabicTts,
              icon: const Icon(Icons.language),
              label: const Text('Test Arabic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTtsLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Voice Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<TtsLanguage>(
            groupValue: _accessibilityService.ttsLanguage,
            onChanged: (value) {
              if (value != null) {
                _accessibilityService.setTtsLanguage(value);
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TtsLanguage.values.length,
              itemBuilder: (context, index) {
                final language = TtsLanguage.values[index];
                return RadioListTile<TtsLanguage>(
                  title: Text(language.displayName),
                  value: language,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePresets(BuildContext context,
      EnhancedThemeProvider themeProvider, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: themeProvider.applyIslamicPreset,
              icon: const Icon(Icons.mosque),
              label: const Text('Islamic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: themeProvider.applyModernPreset,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Modern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: themeProvider.applyElegantPreset,
              icon: const Icon(Icons.diamond),
              label: const Text('Elegant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Beautiful Help Screen
// ignore: unused_element

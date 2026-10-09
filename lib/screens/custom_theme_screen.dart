import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/storybook_themes.dart';
import '../theme/storybook_ui.dart';

/// PRO: custom theme creator — pick parchment, wood, ink, accent and pawn
/// colors. Live preview, persisted per color.
class CustomThemeScreen extends StatefulWidget {
  final StoryAudio audio;
  final StorySettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  StoryThemeDef get _t => StoryThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  // Curated storybook-friendly palette choices.
  static const List<Color> palette = [
    Color(0xFFF1E3C3), Color(0xFFE3CFA4), Color(0xFFF7E8C8),
    Color(0xFF6B4A2F), Color(0xFFA4713F), Color(0xFF4A3220),
    Color(0xFF4E331F), Color(0xFF7A5230), Color(0xFF3A2513),
    Color(0xFF1C2438), Color(0xFF2C3A55), Color(0xFF101624),
    Color(0xFF2E1F14), Color(0xFF4A3320), Color(0xFFF1E3C3),
    Color(0xFFB08D3E), Color(0xFFD4A93C), Color(0xFF8A6B2A),
    Color(0xFFB87333), Color(0xFFE09E5A), Color(0xFF7E4F22),
    Color(0xFFC0C6D4), Color(0xFFE8ECF5), Color(0xFF7E8698),
    Color(0xFF4E6B34), Color(0xFF6E8B4A), Color(0xFF3A5226),
    Color(0xFFB3402E), Color(0xFF2E5F8A), Color(0xFF3E7A3E),
    Color(0xFFD9A62E), Color(0xFF7D3C98), Color(0xFF229954),
    Color(0xFF2471A3), Color(0xFFC0392B), Color(0xFFE67E22),
    Color(0xFF5A2A1A), Color(0xFF7C3F24), Color(0xFF8A6A42),
  ];

  static const rows = [
    ('Parchment', 'parchment'),
    ('Parchment deep', 'parchmentDeep'),
    ('Wood dark', 'woodDark'),
    ('Wood mid', 'woodMid'),
    ('Ink', 'ink'),
    ('Ink soft', 'inkSoft'),
    ('Accent metal', 'accent'),
    ('Accent light', 'accentLight'),
    ('Accent dark', 'accentDark'),
    ('Gold leaf', 'goldLeaf'),
    ('Serpent green', 'snakeGreen'),
    ('Player 1', 'pc0'),
    ('Player 2', 'pc1'),
    ('Player 3', 'pc2'),
    ('Player 4', 'pc3'),
  ];

  Future<void> _pick(String key, String label) async {
    final s = widget.settings;
    final current = Color(s.customColors[key]!);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _t.parchment,
            border: Border.all(color: _t.accent, width: 2.5),
            boxShadow: Story.paperShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick $label', style: Story.titleSmall(20, t: _t)),
              const SizedBox(height: 14),
              SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: palette.length,
                  itemBuilder: (_, i) {
                    final c = palette[i];
                    final selected = c.toARGB32() == current.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _t.accentLight
                                : Colors.black.withValues(alpha: 0.4),
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              WoodButton(
                label: 'Cancel',
                width: 160,
                fontSize: 15,
                t: _t,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      widget.audio.click();
      await s.setCustomColor(key, chosen.toARGB32());
      // Selecting a custom color auto-applies the custom theme.
      await s.setTheme('custom');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final preview = s.customTheme;
    return ParchmentBackdrop(
      t: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.ink),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('Theme Creator', style: Story.titleSmall(22, t: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () async {
                widget.audio.click();
                await s.resetCustomColors();
                if (mounted) setState(() {});
              },
              child:
                  Text('Reset', style: Story.label(13, t: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                children: [
                  // Live preview strip.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: preview.parchment,
                      border: Border.all(
                          color: preview.accent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text('Live preview',
                            style: Story.label(13, t: preview)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final c in preview.pawnColors)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c,
                                  border: Border.all(
                                      color: preview.accentLight,
                                      width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 3),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: preview.snakeGreen
                                .withValues(alpha: 0.35),
                            border: Border.all(
                                color: preview.accent
                                    .withValues(alpha: 0.6)),
                          ),
                          alignment: Alignment.center,
                          child: Text('Serpent sample',
                              style: Story.label(11, t: preview)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final r in rows)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 5),
                      child: GestureDetector(
                        onTap: () => _pick(r.$2, r.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color:
                                t.parchmentDeep.withValues(alpha: 0.55),
                            border: Border.all(
                                color: t.accent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(
                                      s.customColors[r.$2]!),
                                  border: Border.all(
                                      color: t.accentLight,
                                      width: 1.5),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(r.$1,
                                    style:
                                        Story.body(15, t: t)),
                              ),
                              Icon(Icons.palette,
                                  color: t.accentLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  WoodButton(
                    label: 'Use This Theme',
                    width: 260,
                    t: t,
                    onTap: () async {
                      widget.audio.click();
                      await s.setTheme('custom');
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

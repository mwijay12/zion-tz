import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/top_notification.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/sermon_note.dart';
import '../services/notes_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = NotesService();
  List<SermonNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final data = await _notesService.getNotes();
    setState(() {
      _notes = data;
      _isLoading = false;
    });
  }

  void _showAddNoteDialog() {
    AppHaptics.lightImpact();
    final titleController = TextEditingController();
    final preacherController = TextEditingController(text: ChurchProfile.headBishop);
    final scriptureController = TextEditingController();
    final contentController = TextEditingController();

    void insertFormatting(String prefix, [String suffix = '']) {
      final text = contentController.text;
      final selection = contentController.selection;
      if (selection.start >= 0 && selection.end >= 0 && selection.start != selection.end) {
        final selectedText = text.substring(selection.start, selection.end);
        final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
        contentController.text = newText;
        contentController.selection = TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length);
      } else {
        final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
        final newText = text.replaceRange(cursorPos, cursorPos, '$prefix$suffix');
        contentController.text = newText;
        contentController.selection = TextSelection.collapsed(offset: cursorPos + prefix.length);
      }
    }

    void loadEldersPrayerTemplate() {
      AppHaptics.mediumImpact();
      titleController.text = 'Sala na Maombi kwa Ajili ya Wazee na Wazazi';
      preacherController.text = ChurchProfile.assistantPastor;
      scriptureController.text = 'Kutoka 20:12, Zaburi 92:14';
      contentController.text =
          '**SALA YA BARAKA NA AFYA KWA WAZEE WA SAYUNI**\n\n'
          'Ee Bwana Mungu wa Sayuni na Mungu wa Baba zetu,\n'
          'Tunawaleta wazee, bibi, mababu na wazazi wetu wote mbele za kiti chako cha neema.\n\n'
          '• **Afya na Nguvu:** Katika uzee wao wazae matunda, wawe wamejaa utomvu na kustawi (Zaburi 92:14).\n'
          '• **Amani na Faraja:** Walinde dhidi ya simanzi, upweke, na maumivu ya uzee.\n'
          '• **Hekima:** Iwe nuru kwa vizazi vijavyo kupitia miongozo yao ya kiroho.\n\n'
          'Tunatamka ulinzi wa damu ya Yesu juu yao. Katika jina la Yesu Kristo, Amina!';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              top: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 14,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Andika Dokezo Jipya',
                              style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                    const SizedBox(height: 12),

                    // Quick Template Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16),
                            label: const Text(
                              'Sala kwa Wazee (Sweetheart)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            backgroundColor: AppColors.primaryContainer,
                            side: BorderSide(color: AppColors.border),
                            onPressed: () {
                              setModalState(() {
                                loadEldersPrayerTemplate();
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.shield_rounded, color: AppColors.gold, size: 16),
                            label: Text(
                              'Maombi ya Vita vya Kiroho',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceLow,
                            side: BorderSide(color: AppColors.border),
                            onPressed: () {
                              setModalState(() {
                                titleController.text = 'Maombi ya Vita vya Kiroho & Ushindi';
                                scriptureController.text = 'Waefeso 6:10-18';
                                contentController.text =
                                    '**SALA YA VITA VYA KIROHO**\n\n'
                                    '1. Kuvaa silaha zote za Mungu.\n'
                                    '2. Ngao ya imani kuzima mishale yote yenye moto.\n'
                                    '3. Upanga wa Roho ambao ni Neno la Mungu.';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Kichwa cha Somo *',
                        hintText: 'Mf. Kusimama Imara Katika Maombi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: preacherController,
                            decoration: const InputDecoration(
                              labelText: 'Mhubiri',
                              hintText: 'Jina la Mtumishi',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: scriptureController,
                            decoration: const InputDecoration(
                              labelText: 'Mstari wa Biblia',
                              hintText: 'Mf. Zaburi 132',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Formatting Toolbar (Bold, Italic, Bullets, Verse)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.format_bold_rounded, size: 20),
                            tooltip: 'Koleza (Bold)',
                            onPressed: () => insertFormatting('**', '**'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_italic_rounded, size: 20),
                            tooltip: 'Mshazari (Italic)',
                            onPressed: () => insertFormatting('*', '*'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                            tooltip: 'Nukta (Bullet)',
                            onPressed: () => insertFormatting('\n• '),
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu_book_rounded, size: 20),
                            tooltip: 'Nukuu ya Mstari',
                            onPressed: () => insertFormatting('📖 '),
                          ),
                          const Spacer(),
                          Text(
                            'Markdown',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Kumbukumbu & Mafundisho *',
                        hintText: 'Andika maneno makuu, unabii, na mafundisho uliyojifunza...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              contentController.text.trim().isEmpty) {
                            return;
                          }
                          AppHaptics.mediumImpact();
                          final newNote = SermonNote(
                            id: 'note-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text.trim(),
                            preacher: preacherController.text.trim().isEmpty
                                ? ChurchProfile.headBishop
                                : preacherController.text.trim(),
                            scripture: scriptureController.text.trim(),
                            content: contentController.text.trim(),
                            date: DateTime.now(),
                          );
                          await _notesService.addNote(newNote);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadNotes();
                        },
                        child: const Text('Hifadhi Dokezo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  },
);
}

  void _shareNote(SermonNote note) {
    AppHaptics.lightImpact();
    final text = '''
*DAFTARI LA MAHUBIRI — ZION JERUSALEM*
Kichwa: ${note.title}
Mhubiri: ${note.preacher}
Mstari: ${note.scripture}
Tarehe: ${AppFormatters.formatSwahiliDate(note.date)}

${note.content}

Sayuni Jerusalem Church — Mbagala Kwa Matope
''';
    Share.share(text);
  }

  Future<void> _exportNoteAsPdf(SermonNote note) async {
    AppHaptics.mediumImpact();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Church Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ZION JERUSALEM CHURCH',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                      pw.Text(
                        'Kwa Matope, Mbagala • Dar es Salaam, Tanzania',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'DAFTARI LA SAYUNI',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.amber900,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: PdfColors.purple800),
              pw.SizedBox(height: 16),

              // Title
              pw.Text(
                note.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 8),

              // Preacher & Scripture
              pw.Row(
                children: [
                  pw.Text('Mhubiri: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(note.preacher, style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(width: 16),
                  if (note.scripture.isNotEmpty) ...[
                    pw.Text('Maandiko: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(note.scripture, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Tarehe: ${AppFormatters.formatSwahiliDate(note.date)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 18),

              // Content Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  note.content,
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
                ),
              ),

              pw.Spacer(),
              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hekalu la Sayuni — Nuru ya Mataifa', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.Text('Simu: ${ChurchProfile.pastoralHelpline}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${note.title.replaceAll(' ', '_')}_Zion.pdf',
    );
  }

  void _showEditNoteDialog(SermonNote note) {
    AppHaptics.lightImpact();
    final titleController = TextEditingController(text: note.title);
    final preacherController = TextEditingController(text: note.preacher);
    final scriptureController = TextEditingController(text: note.scripture);
    final contentController = TextEditingController(text: note.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMutedOf(context).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hariri Dokezo',
                        style: AppTypography.headlineMedium(color: AppColors.textPrimaryOf(context)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Kichwa cha Somo *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: preacherController,
                          decoration: const InputDecoration(
                            labelText: 'Mhubiri',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: scriptureController,
                          decoration: const InputDecoration(
                            labelText: 'Mstari wa Biblia',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Maudhui ya Somo / Maombi *',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty ||
                            contentController.text.trim().isEmpty) {
                          return;
                        }
                        AppHaptics.mediumImpact();
                        final updatedNote = SermonNote(
                          id: note.id,
                          title: titleController.text.trim(),
                          preacher: preacherController.text.trim(),
                          scripture: scriptureController.text.trim(),
                          content: contentController.text.trim(),
                          date: note.date,
                        );
                        await _notesService.updateNote(updatedNote);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadNotes();
                        if (mounted) {
                          AppTopAlert.show(
                            context,
                            title: 'Dokezo Limehaririwa',
                            message: 'Mabadiliko ya dokezo yamehifadhiwa!',
                            type: TopAlertType.success,
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Hifadhi Mabadiliko'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormattedNoteContent(String rawText, Color textColor) {
    final lines = rawText.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('### ') || trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final cleanHeader = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              cleanHeader,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        );
        continue;
      }

      final isBullet = trimmed.startsWith('• ') || trimmed.startsWith('- ') || trimmed.startsWith('* ');
      final contentLine = isBullet ? trimmed.substring(2) : trimmed;
      final spans = _parseMarkdownSpans(contentLine, textColor);

      if (isBullet) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: spans, style: TextStyle(color: textColor, fontSize: 13, height: 1.45)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(children: spans, style: TextStyle(color: textColor, fontSize: 13, height: 1.45)),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<TextSpan> _parseMarkdownSpans(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)');
    int lastMatchEnd = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: baseColor),
        ));
      }

      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: baseColor,
          ),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: baseColor,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: baseColor),
      ));
    }

    return spans;
  }

  void _deleteNote(String id) async {
    AppHaptics.lightImpact();
    await _notesService.deleteNote(id);
    _loadNotes();
    if (mounted) {
      AppTopAlert.show(
        context,
        title: 'Dokezo Limefutwa',
        message: 'Dokezo limetolewa kwenye daftari lako.',
        type: TopAlertType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChurchThemeService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvasOf(context),
          appBar: AppBar(
            title: Text(
              'Daftari la Mahubiri & Sala',
              style: AppTypography.titleMedium(color: AppColors.textPrimaryOf(context)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                onPressed: _showAddNoteDialog,
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloatingActionButton.extended(
              onPressed: _showAddNoteDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Andika Dokezo', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notes.isEmpty
                  ? EmptyStateView(
                      icon: Icons.edit_note_rounded,
                      title: 'Daftari Liko Tupu',
                      description: 'Hujarekodi dokezo lolote la mahubiri. Bofya kitufe cha chini kuanza.',
                      actionLabel: 'Andika Dokezo la Kwanza',
                      onAction: _showAddNoteDialog,
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 120 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: _notes.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerOf(context),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      note.scripture.isNotEmpty ? note.scripture : 'Somo la Ibada',
                                      style: AppTypography.caption(color: AppColors.primary),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.gold),
                                        tooltip: 'Hariri Dokezo',
                                        onPressed: () => _showEditNoteDialog(note),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Color(0xFFDC2626)),
                                        tooltip: 'Pakua PDF',
                                        onPressed: () => _exportNoteAsPdf(note),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primary),
                                        tooltip: 'Shiriki',
                                        onPressed: () => _shareNote(note),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                        tooltip: 'Futa',
                                        onPressed: () => _deleteNote(note.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note.title,
                                style: AppTypography.titleMedium(color: AppColors.textPrimaryOf(context)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mhubiri: ${note.preacher} • ${AppFormatters.formatSwahiliDate(note.date)}',
                                style: AppTypography.caption(color: AppColors.textMutedOf(context)),
                              ),
                              const SizedBox(height: 10),
                              _buildFormattedNoteContent(
                                note.content,
                                AppColors.textSecondaryOf(context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}

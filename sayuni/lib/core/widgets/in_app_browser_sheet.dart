import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';

/// In-app browser bottom sheet for external hymn lyrics (MySongbooks).
///
/// Keeps members inside Sayuni while reading full lyrics/audio on
/// MySongbooks, with a fallback to the external browser if the WebView
/// fails (offline, blocked, etc.).
///
/// ```dart
/// showInAppBrowser(context, url: hymn.externalUrl!, title: hymn.title);
/// ```
void showInAppBrowser(
  BuildContext context, {
  required String url,
  required String title,
}) {
  AppHaptics.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _InAppBrowserSheet(url: url, title: title),
  );
}

class _InAppBrowserSheet extends StatefulWidget {
  final String url;
  final String title;

  const _InAppBrowserSheet({required this.url, required this.title});

  @override
  State<_InAppBrowserSheet> createState() => _InAppBrowserSheetState();
}

class _InAppBrowserSheetState extends State<_InAppBrowserSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _loadFailed = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            // Only treat main-frame failures as fatal; subresource
            // errors (ads, images) should not block the page.
            if (error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _loadFailed = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.titleMedium(
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'MySongbooks — maneno kamili',
                        style: AppTypography.caption(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'Fungua kwenye browser',
                  onPressed: _openExternally,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _loadFailed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Imeshindikana kupakia ukurasa. Angalia internet yako, au fungua kwenye browser.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(
                                color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openExternally,
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Fungua kwenye Browser'),
                          ),
                        ],
                      ),
                    ),
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

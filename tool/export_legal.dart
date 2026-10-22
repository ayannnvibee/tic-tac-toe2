// Writes the Privacy Policy and Terms of Use as standalone web pages, from
// the same text the app shows (lib/legal/legal_content.dart), so the website
// and the app never disagree. Run from the project root:
//
//     dart run tool/export_legal.dart
//
// Output, ready to upload to kodrilla.com:
//     legal_site/tic-tac-toe/privacy-policy/index.html
//     legal_site/tic-tac-toe/terms-of-use/index.html
// They belong at https://kodrilla.com/legal/tic-tac-toe/privacy-policy and
// https://kodrilla.com/legal/tic-tac-toe/terms-of-use.

import 'dart:convert';
import 'dart:io';

import 'package:tic_tac_toe_infinity/legal/legal_content.dart';

const HtmlEscape _escape = HtmlEscape(HtmlEscapeMode.element);

/// Escapes [text] and turns the support email and website into links.
String _paragraph(String text) => _escape
    .convert(text)
    .replaceAll(
      LegalInfo.supportEmail,
      '<a href="mailto:${LegalInfo.supportEmail}">${LegalInfo.supportEmail}</a>',
    )
    .replaceAll(
      '${LegalInfo.website}.',
      '<a href="${LegalInfo.website}">${LegalInfo.website}</a>.',
    );

String _page(LegalDocument document) {
  final body = StringBuffer();
  for (final section in document.sections) {
    body.writeln('    <h2>${_escape.convert(section.heading)}</h2>');
    for (final paragraph in section.paragraphs) {
      body.writeln('    <p>${_paragraph(paragraph)}</p>');
    }
  }
  final title = '${document.title} | ${LegalInfo.appName}';
  return '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escape.convert(title)}</title>
  <style>
    :root { color-scheme: light dark; --accent: #6d3fd1; }
    body {
      margin: 0; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6; background: #faf8f5; color: #1d1b20;
    }
    main { max-width: 720px; margin: 0 auto; padding: 32px 20px 64px; }
    a { color: var(--accent); }
    h1 { margin: 8px 0 4px; font-size: 2rem; }
    h2 { margin-top: 28px; font-size: 1.2rem; }
    .meta { color: #625b71; font-size: .9rem; }
    @media (prefers-color-scheme: dark) {
      body { background: #141218; color: #e6e0e9; }
      .meta { color: #cac4d0; }
      :root { --accent: #cfbcff; }
    }
  </style>
</head>
<body>
  <main>
    <a href="/legal">&larr; Kodrilla legal documents</a>
    <h1>${_escape.convert(document.title)}</h1>
    <p class="meta">${_escape.convert(LegalInfo.appName)} &middot; Last updated: ${_escape.convert(LegalInfo.effectiveDate)}</p>
$body  </main>
</body>
</html>
''';
}

void main() {
  for (final document in LegalDocument.values) {
    final slug = Uri.parse(document.url).pathSegments.last;
    final file = File('legal_site/tic-tac-toe/$slug/index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync(_page(document));
    stdout.writeln('${file.path}  ->  ${document.url}');
  }
}

/// A source the bot used for its answer.
class ChatCitation {
  const ChatCitation({
    required this.title,
    required this.url,
    this.snippet = '',
  });

  /// Page or file name, e.g. "JAKIM 1.pdf".
  final String title;

  /// Link to the source. Empty for uploaded documents.
  final String url;

  /// The passage the bot quoted from the source.
  final String snippet;

  bool get isLinkable => url.isNotEmpty;
  bool get hasSnippet => snippet.isNotEmpty;
}

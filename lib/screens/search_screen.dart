import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:flutube/utils/utils.dart';
import 'package:flutube/widgets/widgets.dart';

class CustomSearchDelegate extends SearchDelegate {
  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      context.backLeading(() => close(context, null));

  @override
  Widget buildResults(BuildContext context) {
    return SearchResult(query: query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SuggestionList(
      query: query,
      showResults: () {
        showResults(context);
        return false;
      },
      onTap: (value) {
        query = value;
        showResults(context);
      },
    );
  }
}

class SearchResult extends HookWidget {
  const SearchResult({
    Key? key,
    required this.query,
  }) : super(key: key);

  final String query;

  @override
  Widget build(BuildContext context) {
    var isMounted = useIsMounted();
    var yt = YoutubeExplode();
    final _currentPage = useState<SearchList?>(null);
    void loadVideos() async =>
        _currentPage.value = await yt.search.getVideos(query);
    final controller = useScrollController();

    void _getMoreData() async {
      if (isMounted() &&
          controller.position.pixels == controller.position.maxScrollExtent &&
          _currentPage.value != null) {
        final page = await (_currentPage.value)!.nextPage();
        if (page == null || page.isEmpty && !isMounted()) return;

        _currentPage.value = page;
      }
    }

    useEffect(() {
      loadVideos();
      controller.addListener(_getMoreData);
      return () => controller.removeListener(_getMoreData);
    }, [controller]);

    return _currentPage.value != null
        ? ListView.builder(
            shrinkWrap: true,
            controller: controller,
            itemCount: _currentPage.value!.length + 1,
            itemBuilder: (ctx, idx) => idx == _currentPage.value!.length
                ? getCircularProgressIndicator()
                : FTVideo(
                    videoData: _currentPage.value![idx],
                    isRow: !context.isMobile,
                    loadData: true,
                  ),
          )
        : getCircularProgressIndicator();
  }
}

class SuggestionList extends HookWidget {
  final Function(String value) onTap;
  final String query;
  final bool Function() showResults;

  const SuggestionList({
    Key? key,
    required this.query,
    required this.onTap,
    required this.showResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final yt = YoutubeExplode();
    Future<List<String>> getSuggestions() =>
        yt.search.getQuerySuggestions(query).whenComplete(() => yt.close());
    return WillPopScope(
      onWillPop: () async => query.isNotEmpty ? showResults() : true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FutureBuilder<List<String>>(
            future: getSuggestions(),
            builder: (ctx, snapshot) => snapshot.data != null
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, idx) => ListTile(
                      onTap: () => onTap(snapshot.data![idx]),
                      title: Text(snapshot.data![idx]),
                    ),
                  )
                : query.isNotEmpty
                    ? getCircularProgressIndicator()
                    : const SizedBox(),
          ),
        ),
      ),
    );
  }
}

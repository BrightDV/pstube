import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'package:flutube/utils/utils.dart';
import 'package:flutube/models/models.dart';
import 'package:flutube/screens/screens.dart';
import 'package:flutube/widgets/widgets.dart';
import 'package:flutube/providers/providers.dart';

class MyHomePage extends HookConsumerWidget {
  MyHomePage({Key? key}) : super(key: key);

  final PageController _controller = PageController();

  @override
  Widget build(context, ref) {
    final _currentIndex = useState<int>(0);
    final _addDownloadController = TextEditingController();

    final mainScreens = [
      const HomeScreen(),
      const LikedScreen(),
      const PlaylistScreen(),
      const DownloadsScreen(),
      const SettingsScreen(),
    ];

    final Map<String, List<IconData>> navItems = {
      "Home": [FontAwesomeIcons.home],
      "Liked": [FontAwesomeIcons.thumbsUp, FontAwesomeIcons.solidThumbsUp],
      "Playlist": [FontAwesomeIcons.list],
      "Downloads": [FontAwesomeIcons.download],
      "Settings": [FontAwesomeIcons.cog],
    };

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(myApp.name),
        actions: [
          buildSearchButton(context),
          if (_currentIndex.value == 3)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trash),
              onPressed: () {
                final deleteFromStorage = ValueNotifier<bool>(false);
                showPopoverWB(
                  context: context,
                  builder: (ctx) => ValueListenableBuilder<bool>(
                      valueListenable: deleteFromStorage,
                      builder: (_, value, ___) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clear all items from download list?', style: context.textTheme.bodyText1),
                            CheckboxListTile(
                              value: value,
                              onChanged: (val) => deleteFromStorage.value = val!,
                              title: const Text("Also delete them from storage"),
                            ),
                          ],
                        );
                      }),
                  onConfirm: () {
                    final downloadListUtils = ref.read(downloadListProvider);
                    for (DownloadItem item in downloadListUtils.downloadList) {
                      if (File(item.queryVideo.path + item.queryVideo.name).existsSync() && deleteFromStorage.value) {
                        File(item.queryVideo.path + item.queryVideo.name).deleteSync();
                      }
                    }
                    downloadListUtils.clearAll();
                    context.back();
                  },
                  confirmText: "Yes",
                  title: "Confirm!",
                );
              },
              tooltip: "Clear all",
            ),
          if (_currentIndex.value == 4)
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    child: const Text('Reset default'),
                    onTap: () => resetDefaults(ref),
                  )
                ];
              },
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          if (!context.isMobile)
            NavigationRail(
              destinations: [
                for (var item in navItems.entries)
                  NavigationRailDestination(
                    label: Text(item.key, style: context.textTheme.bodyText1),
                    icon: FaIcon(item.value[0]),
                    selectedIcon: FaIcon(item.value.length == 2 ? item.value[1] : item.value[0]),
                  ),
              ],
              selectedIndex: _currentIndex.value,
              onDestinationSelected: (index) => _controller.jumpToPage(index),
            ),
          Flexible(
            child: FtBody(
              child: PageView.builder(
                controller: _controller,
                itemCount: mainScreens.length,
                itemBuilder: (context, index) => mainScreens[index],
                onPageChanged: (index) => _currentIndex.value = index,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex.value == 0
          ? FloatingActionButton(
              onPressed: () async {
                if (_addDownloadController.text.isEmpty) {
                  var clipboard = await Clipboard.getData(Clipboard.kTextPlain);
                  var youtubeRegEx = RegExp(
                      r"^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$");
                  if (clipboard != null && clipboard.text != null && youtubeRegEx.hasMatch(clipboard.text!)) {
                    _addDownloadController.text = clipboard.text!;
                  }
                }
                showPopoverWB(
                  context: context,
                  onConfirm: () {
                    context.back();
                    if (_addDownloadController.value.text.isNotEmpty) {
                      showDownloadPopup(context, videoUrl: _addDownloadController.text);
                    }
                  },
                  hint: "https://youtube.com/watch?v=***********",
                  title: "Download from video url",
                  controller: _addDownloadController,
                );
              },
              child: const FaIcon(FontAwesomeIcons.plus),
            )
          : null,
      bottomNavigationBar: Visibility(
        visible: context.isMobile,
        child: Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          padding: const EdgeInsets.all(6),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: context.getAltBackgroundColor,
          ),
          child: SalomonBottomBar(
            selectedItemColor: context.textTheme.bodyText1!.color,
            unselectedItemColor: context.getAlt2BackgroundColor,
            items: [
              for (var item in navItems.entries)
                SalomonBottomBarItem(
                  title: Text(item.key, style: context.textTheme.bodyText1!.copyWith(fontSize: 15)),
                  icon: FaIcon(item.value[0], size: 20),
                  activeIcon: FaIcon(item.value.length == 2 ? item.value[1] : item.value[0], size: 20),
                ),
            ],
            currentIndex: _currentIndex.value,
            onTap: (index) => _controller.jumpToPage(index),
          ),
        ),
      ),
    );
  }
}

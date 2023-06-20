// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/saved.dart';
import '../utils/build_context.dart';

class _StopwatchSavedGroup {
    final DateTime date;
    final List<StopwatchSaved> stopwatches;

    _StopwatchSavedGroup({required this.stopwatches, required this.date});
}

class SavedPage extends StatefulWidget {
    const SavedPage({super.key});

    @override
    State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {

    final _stopwatchesGroups = <_StopwatchSavedGroup>[];
    List<StopwatchSaved> _stopwatches = [];
    bool _isLoading = false;

    bool
    get isBigScreen => MediaQuery.of(context).size.width > 700;

    void _clear() async {
        bool isCancel = (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                icon: const Icon(Icons.bookmark_border_outlined),
                title: const Text("Clear saved"),
                content: const Text("Are you sure want to clear all saved?"),
                actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    FilledButton.tonal(onPressed: () => Navigator.pop(context, false), child: const Text("Clear")),
                ]
            )
        )) ?? true;

        if (isCancel) return;

        await StopwatchSaved.clearDB();
        _update();
    }

    void _update() async {
        _stopwatches = await StopwatchSaved.queryDB();
        _stopwatchesGroups.clear();
        _stopwatches.sort((a, b) => (a.date).compareTo(b.date));

        List<StopwatchSaved> items = List.from(_stopwatches.reversed.toList());
        for (StopwatchSaved item in items){
            if (_stopwatchesGroups.isEmpty){
                _stopwatchesGroups.add(_StopwatchSavedGroup(stopwatches: [item], date: item.date));
            } else if (DateUtils.isSameDay(_stopwatchesGroups.last.date, item.date)) {
                _stopwatchesGroups.last.stopwatches.add(item);
            } else {
                _stopwatchesGroups.add(_StopwatchSavedGroup(stopwatches: [item], date: item.date));
            }
        }
        setState(() {
            _isLoading = false;
        });
    }

    String stopwatchInString(StopwatchSaved stopwatch){
        Duration duration = stopwatch.time;
        String text = 'Time: ${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')}';
        if (stopwatch.laps.isNotEmpty){
            text += '\nLap times:';
            for (int i = 0; i < stopwatch.laps.length; i++){
                duration = stopwatch.laps[i];
                Duration difference = stopwatch.laps.last;
                if (i + 1 < stopwatch.laps.length){
                    difference = stopwatch.laps[i] - stopwatch.laps[i + 1];
                }
                text = '$text\n#${stopwatch.laps.length - i}   [ ${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')} ]   [ ${difference.inMinutes >= 60? '${'${difference.inHours}'}:':''}${'${difference.inMinutes % 60}'.padLeft(2, '0')}:${'${difference.inSeconds % 60}'.padLeft(2, '0')}.${'${difference.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')} ]';
            }
        }
        return text;
    }

    void _copy(StopwatchSaved stopwatch){
        Clipboard.setData(ClipboardData(text: stopwatchInString(stopwatch)));
        context.showSnackBar(const Text("Copied to clipboard"));
    }

    void _share(StopwatchSaved stopwatch){
        Share.share(stopwatchInString(stopwatch));
    }

    void _delete(StopwatchSaved stopwatch) async {
        StopwatchSaved s = StopwatchSaved.copy(stopwatch);
        await stopwatch.deleteDB();
        _update();
        if (mounted) context.showSnackBar(
            const Text("Deleted"),
            action: SnackBarAction(label: 'Undo', onPressed: () async {
                await s.insertDB();
                _update();
            })
        );
    }

    void _showDetail(StopwatchSaved stopwatch) async {
        await showModalBottomSheet(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            builder: (context) => BottomSheet(
                onClosing: (){},
                showDragHandle: true,
                enableDrag: false,
                builder: (context) => StatefulBuilder(builder: (context, setState){
                    final duration = stopwatch.time;
                    final int lapsLength = stopwatch.laps.length;

                    Widget timeText = Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text([ if (duration.inMinutes >= 60) '${duration.inHours}',
                            '${duration.inMinutes % 60}'.padLeft(2, '0'),
                            [ '${duration.inSeconds % 60}'.padLeft(2, '0'),
                                '${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')
                            ].join('.'),
                        ].join(':'), style: context.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                    );

                    Widget laps = Flexible(child: Material(
                        color: Colors.transparent,
                        child: SingleChildScrollView(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(lapsLength, (index){
                                final duration = stopwatch.laps[index];

                                Duration difference = stopwatch.laps.last;
                                if (index + 1 < lapsLength){
                                    difference = stopwatch.laps[index] - stopwatch.laps[index + 1];
                                }
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: ListTile(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(
                                            topLeft    : Radius.circular(index == 0? 12 : 0),
                                            topRight   : Radius.circular(index == 0? 12 : 0),
                                            bottomLeft : Radius.circular(index == lapsLength-1? 12 : 0),
                                            bottomRight: Radius.circular(index == lapsLength-1? 12 : 0),
                                        )),
                                        tileColor: context.colorScheme.secondaryContainer,
                                        leading: Text('#${lapsLength - index}'),
                                        title: Text([ if (duration.inMinutes >= 60) '${duration.inHours}',
                                            '${duration.inMinutes % 60}'.padLeft(2, '0'),
                                            [ '${duration.inSeconds % 60}'.padLeft(2, '0'),
                                                '${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')
                                            ].join('.'),
                                        ].join(':')),
                                        trailing: Text([ if (difference.inMinutes >= 60) '${difference.inHours}',
                                            '${difference.inMinutes % 60}'.padLeft(2, '0'),
                                            [ '${difference.inSeconds % 60}'.padLeft(2, '0'),
                                                '${difference.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')
                                            ].join('.'),
                                        ].join(':')),
                                    ),
                                );
                            })
                        )),
                    ));

                    Widget actions = Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <List<dynamic>>[
                                ["Copy"  , Icons.copy_outlined , _copy  ],
                                ["Share" , Icons.share_outlined, _share ],
                                ["Delete", Icons.delete_outline, _delete],
                            ].map<Widget>((option) => IconButton(
                                tooltip: option[0],
                                icon: Icon(option[1]),
                                onPressed: (){
                                    option[2](stopwatch);
                                    Navigator.pop(context);
                                },
                            )).toList(),
                        ),
                    );

                    return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                timeText,
                                if (lapsLength > 0) laps,
                                actions
                            ],
                        ),
                    );
                })
            )
        );
    }

    @override
    void didChangeDependencies() async {
        super.didChangeDependencies();
        _update();
    }

    dynamic _appBar() {
        Widget leading = IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back)
        );

        List<Widget> actions = [
            AnimatedCrossFade(
                firstChild: Container(),
                secondChild: PopupMenuButton(
                    onSelected: (value){ switch(value){ case "clear": _clear(); } },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem(
                            value: 'clear',
                            child: Text("Clear"),
                        )
                    ]
                ),
                crossFadeState: _stopwatchesGroups.isNotEmpty? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250)
            )
        ];

        if (isBigScreen) return AppBar(
            leading: leading,
            title: const Text('Saved'),
            actions: actions,
        );

        return SliverAppBar.large(
            leadingWidth: 52.0,
            title: const Text(
                'Saved',
                style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans')
            ),
            leading: leading,
            actions: actions,
        );
    }

    List<Widget> stopwatchesWidget(int index){
        return List.generate(_stopwatchesGroups[index].stopwatches.length, (index2) {
            var stopwatchSaved = _stopwatchesGroups[index].stopwatches[index2];
            final duration = stopwatchSaved.time;

            void delete(StopwatchSaved stopwatch, int index, int index2) async {
                StopwatchSaved s = StopwatchSaved.copy(stopwatch);
                await stopwatch.deleteDB();
                _update();
                if (mounted) context.showSnackBar(
                    const Text("Deleted"),
                    action: SnackBarAction(label: 'Undo', onPressed: () async {
                        await s.insertDB();
                        _update();
                    })
                );
            }

            Widget title = Text('${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')}');
            Widget? trailing;
            if (stopwatchSaved.laps.isNotEmpty){
                int length = stopwatchSaved.laps.length;
                trailing = Text('$length lap${length > 1? 's' : ''}');
            }

            return Dismissible(
                key: ValueKey("${stopwatchSaved.id}"),
                onDismissed: (direction) => delete(stopwatchSaved, index, index2),
                background: Container(
                    color: context.colorScheme.error,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                        Icon(Icons.delete_outlined, color: context.colorScheme.onError),
                        const SizedBox(width: 16),
                        Text("Delete", style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onError))
                    ])
                ),
                secondaryBackground: Container(
                    color: context.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.all(16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text("Delete", style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onError)),
                        const SizedBox(width: 16),
                        Icon(Icons.delete_outlined, color: context.colorScheme.onError),
                    ])
                ),
                child: ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: title,
                    trailing: trailing,
                    onTap: () => _showDetail(stopwatchSaved),
                ),
            );
        });
    }

    Widget _body(){
        if (_isLoading){
            if (isBigScreen) return const Center(child: CircularProgressIndicator());
            return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        if (_stopwatchesGroups.isEmpty){
            Widget message = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Icon(Icons.bookmark_border_outlined, size: context.textTheme.displayLarge?.fontSize),
                    const SizedBox(height: 16,),
                    Text("No saved", style: context.textTheme.titleLarge)
                ]
            );

            if (isBigScreen) return SizedBox.expand(child: message);

            return SliverFillRemaining(child: message);
        }

        List<Widget> stopwatches = List.generate(_stopwatchesGroups.length, (index){

            Widget date = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                    DateFormat.yMMMMd().format(_stopwatchesGroups[index].date),
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.colorScheme.onPrimaryContainer)
                ),
            );

            return Card(
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        date,
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...stopwatchesWidget(index),
                        const SizedBox(height: 8),
                    ]
                )
            );
        });

        if (isBigScreen) return SafeArea(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: ListView(
                        padding: EdgeInsets.zero,
                        children: stopwatches,
                    )
                )
            ],
        ));

        return SliverList(delegate: SliverChildListDelegate(stopwatches));
    }

    @override
    Widget build(BuildContext context) {
        context.changeSystemUI();

        if (isBigScreen) return Scaffold(
            appBar: _appBar(),
            body: _body(),
        );

        return Scaffold(body: SafeArea(
            top: false,
            child: CustomScrollView(slivers: [
                _appBar(),
                _body()
            ]),
        ));
    }
}
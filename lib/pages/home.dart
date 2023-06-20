// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stopwatch/data/saved.dart';

import 'settings.dart';
import 'saved.dart';
import '../utils/build_context.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    final _duration = ValueNotifier(const Duration());
    final _laps = ValueNotifier(<Duration>[]);
    Timer? _timer;
    bool _isStart = false;
    bool _isSaved = false;
    bool _firstLap = true;

    bool
    get isBigScreen => MediaQuery.of(context).size.width > 700;

    void _gotoSettingsPage(){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    }

    void _gotoSavedPage(){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedPage()));
    }

    void _startStopwatch(){
        setState((){
            _isStart = true;
            _isSaved = false;
        });
        _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
            _duration.value = _duration.value + const Duration(milliseconds: 10);
        });
    }

    void _pauseStopwatch(){
        setState(() => _isStart = false);
        _timer?.cancel();
    }

    void _resetStopwatch(){
        _timer?.cancel();
        _laps.value.clear();
        _duration.value = const Duration();
        setState((){
            _firstLap = true;
            _isStart = false;
        });
    }

    void _lapStopwatch(){
        if (_firstLap) setState(() => _firstLap = false);
        var laps = _laps.value;
        laps.insert(0, _duration.value);
        _laps.value = List.from(laps);
    }

    String _stopwatchInString(){
        Duration duration = _duration.value;
        String text = 'Time: ${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')}';
        if (_laps.value.isNotEmpty){
            text += '\nLap times:';
            for (int i = 0; i < _laps.value.length; i++){
                duration = _laps.value[i];
                Duration difference = _laps.value.last;
                if (i + 1 < _laps.value.length){
                    difference = _laps.value[i] - _laps.value[i + 1];
                }
                text = '$text\n#${_laps.value.length - i}   [ ${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')} ]   [ ${difference.inMinutes >= 60? '${'${difference.inHours}'}:':''}${'${difference.inMinutes % 60}'.padLeft(2, '0')}:${'${difference.inSeconds % 60}'.padLeft(2, '0')}.${'${difference.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')} ]';
            }
        }
        return text;
    }

    void _copyStopwatch(){
        Clipboard.setData(ClipboardData(text: _stopwatchInString()));
        context.showSnackBar(const Text('Copied'));
    }

    void _shareStopwatch(){
        Share.share(_stopwatchInString());
    }

    void _saveStopwatch(){
        var stopwatch = StopwatchSaved(time: _duration.value, laps: _laps.value);
        stopwatch.insertDB();
        context.showSnackBar(const Text('Saved'));
        setState(() => _isSaved = true);
    }

    @override
    void dispose(){
        _timer?.cancel();
        super.dispose();
    }

    PreferredSizeWidget _appBar(){
        return AppBar(
            title: const Text("Stopwatch"),
            actions: [
                IconButton(
                    onPressed: _gotoSettingsPage,
                    icon: const Icon(Icons.settings_outlined)
                ),
                IconButton(
                    onPressed: _gotoSavedPage,
                    icon: const Icon(Icons.bookmark_border_outlined)
                ),
                if (_duration.value.inMilliseconds > 0) PopupMenuButton(
                    position: PopupMenuPosition.over,
                    itemBuilder: (context) => const <PopupMenuEntry>[
                        PopupMenuItem(value: 'copy', child: Text('Copy')),
                        PopupMenuItem(value: 'share', child: Text('Share')),
                    ],
                    onSelected: (value){ switch (value){
                        case 'copy' : return _copyStopwatch();
                        case 'share': return _shareStopwatch();
                    }},
                ),
                const SizedBox(width: 8),
            ],
        );
    }

    Widget _body(){
        Widget child = ValueListenableBuilder<Duration>(
            valueListenable: _duration,
            builder: (context, duration, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                        '${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}',
                        style: context.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    Text(
                        '${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0'),
                        style: context.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                ]
            ),
        );

        if (_laps.value.isNotEmpty){
            Widget laps = Padding(
                padding: const EdgeInsets.all(16.0),
                child: ValueListenableBuilder<List<Duration>>(
                    valueListenable: _laps,
                    builder: (context, laps, child) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(laps.length, (index){
                            final duration = laps[index];

                            Duration difference = laps.last;
                            if (index + 1 < laps.length){
                                difference = laps[index] - laps[index + 1];
                            }

                            return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: ListTile(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(
                                        topLeft    : Radius.circular(index == 0? 12 : 0),
                                        topRight   : Radius.circular(index == 0? 12 : 0),
                                        bottomLeft : Radius.circular(index == laps.length-1? 12 : 0),
                                        bottomRight: Radius.circular(index == laps.length-1? 12 : 0),
                                    )),
                                    tileColor: context.colorScheme.secondaryContainer,
                                    leading: Text('#${laps.length - index}'),
                                    trailing: Text('${difference.inMinutes >= 60? '${'${difference.inHours}'}:':''}${'${difference.inMinutes % 60}'.padLeft(2, '0')}:${'${difference.inSeconds % 60}'.padLeft(2, '0')}.${'${difference.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')}'),
                                    title: Text('${duration.inMinutes >= 60? '${'${duration.inHours}'}:':''}${'${duration.inMinutes % 60}'.padLeft(2, '0')}:${'${duration.inSeconds % 60}'.padLeft(2, '0')}.${'${duration.inMilliseconds % 1000}'.replaceAll(RegExp(r'0+$'), '').padLeft(2, '0')}'),
                                ),
                            );
                        }),
                    )
                ),
            );

            if (isBigScreen){
                laps = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: laps
                );
            }

            child = Center(child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const SizedBox(height: 16),
                    child,
                    laps,
                    const SizedBox(height: 56 + 32) // 56 = floating-action-button height,
                ],
            )));
        } else {
            child = Center(child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    child,
                    const SizedBox(height: 56 + 32) // 56 = floating-action-button height,
                ],
            )));
        }

        return SafeArea(child: child);
    }

    Widget _floatingActionButton(){
        List<Widget> actions = [
            if (_duration.value.inMilliseconds > 0) ...[
                Tooltip(
                    message: 'Reset',
                    child: InkWell(
                        onTap: _resetStopwatch,
                        child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.restart_alt_outlined),
                        ),
                    ),
                ),
                if (!_isSaved) Tooltip(
                    message: 'Save',
                    child: InkWell(
                        onTap: _saveStopwatch,
                        child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.bookmark_border_outlined),
                        ),
                    ),
                ),
            ]
        ];

        Widget divider = Container(
            width: 1,
            height: 56.0,
            color: context.colorScheme.onPrimaryContainer,
        );

        Widget mainButton = InkWell(
            onTap: _startStopwatch,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                        Icon(Icons.play_arrow_outlined),
                        SizedBox(width: 8),
                        Text('Start'),
                        SizedBox(width: 8),
                    ]
                ),
            ),
        );

        if (_isStart){
            mainButton = InkWell(
                onTap: _pauseStopwatch,
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
                            Icon(Icons.pause_outlined),
                            SizedBox(width: 8),
                            Text('Pause'),
                            SizedBox(width: 8),
                        ]
                    ),
                ),
            );

            actions = <Widget>[
                Tooltip(
                    message: 'Reset',
                    child: InkWell(
                        onTap: _resetStopwatch,
                        child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Icon(Icons.restart_alt_outlined),
                        ),
                    ),
                ),
                InkWell(
                    onTap: _lapStopwatch,
                    child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.motion_photos_pause_outlined),
                    ),
                ),
            ];
        }

        return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            color: context.colorScheme.primaryContainer,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.colorScheme.onPrimaryContainer),
                child: IconTheme(
                    data: Theme.of(context).iconTheme.copyWith(color: context.colorScheme.onPrimaryContainer),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            mainButton,
                            if (actions.isNotEmpty) divider,
                            ...List.generate(actions.length, (index) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    if (index > 0) divider,
                                    actions[index]
                                ],
                            ))
                        ]
                    ),
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        context.changeSystemUI();
        return Scaffold(
            appBar: _appBar(),
            body: _body(),
            floatingActionButton: _floatingActionButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
    }
}
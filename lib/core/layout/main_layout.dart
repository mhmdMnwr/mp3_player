import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mp3_player_v2/core/data/repo/audio_repo.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/core/logic/theme_cubit.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/all_audio_page.dart';
import 'package:mp3_player_v2/features/favorite/presentation/favorite_page.dart';
import 'package:mp3_player_v2/features/player/presentation/player_page.dart';
import 'package:mp3_player_v2/features/player/presentation/widgets/bottom_navagationbar.dart';

class MainLayout extends StatefulWidget {
  final String? initialSongId;
  final bool autoPlay;

  const MainLayout({super.key, this.initialSongId, this.autoPlay = false});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late final PlayerCubit _playerCubit;
  late final StreamSubscription<PlayerState> _playerSubscription;
  PlayerState _playerState = const PlayerState();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _playerCubit = PlayerCubit(audioRepo: AudioRepoImpl());
    _playerState = _playerCubit.state;

    _playerSubscription = _playerCubit.stream.listen((PlayerState state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playerState = state;
      });
    });

    if (_playerCubit.state.songs.isEmpty) {
      _playerCubit.loadSongs(
        selectedSongId: widget.initialSongId,
        autoPlay: widget.autoPlay,
      );
    } else if (widget.initialSongId != null) {
      _playerCubit.selectSongById(
        widget.initialSongId!,
        autoPlay: widget.autoPlay,
      );
    }
  }

  @override
  void dispose() {
    _playerSubscription.cancel();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) {
      return;
    }

    if (index == 0 || index == 1) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }

    if (index == 2) {
      _playerCubit.loadFavoriteSongs();
      setState(() {
        _currentIndex = 2;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final titles = ['Playing', 'All Audios', 'Favorites'];
    final safeTitleIndex = math.min(_currentIndex, titles.length - 1);
    final themeCubit = context.read<ThemeCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[safeTitleIndex],
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                themeCubit.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey<bool>(themeCubit.isDark),
                color: colors.textPrimary,
              ),
            ),
            onPressed: themeCubit.toggleTheme,
            tooltip: themeCubit.isDark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              PlayerPage(
                playerState: _playerState,
                playerCubit: _playerCubit,
                onFavoriteLongPress: () => _onTabChanged(2),
              ),
              AllAudioPage(
                playerState: _playerState,
                playerCubit: _playerCubit,
                onSongPlayed: () {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
              FavoritePage(
                playerState: _playerState,
                playerCubit: _playerCubit,
                onSongPlayed: () {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

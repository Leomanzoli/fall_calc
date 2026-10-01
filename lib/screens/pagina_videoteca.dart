// lib/screens/pagina_videoteca.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:fall_calc_final/widgets/bottom_navigation_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modelo simples para cada vídeo
class VideoItem {
  final String id;
  final String titulo;
  final String? subtitulo;

  const VideoItem({required this.id, required this.titulo, this.subtitulo});

  String get thumbnailUrl => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class PaginaVideoteca extends StatefulWidget {
  const PaginaVideoteca({super.key});

  @override
  State<PaginaVideoteca> createState() => _PaginaVideotecaState();
}

class _PaginaVideotecaState extends State<PaginaVideoteca> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  int _currentVideoIndex = 0;

  // Lista de vídeos
  final List<VideoItem> _videos = const [
    VideoItem(id: 'aE2Do8rJ0tQ', titulo: 'Fator de Queda'),
    VideoItem(id: '6fINgiZKK8U', titulo: 'Zona Livre de Queda (ZLQ)'),
    VideoItem(
      id: 'hGt_R9LAlmI',
      titulo: 'Efeito Pêndulo em Trabalhos em Altura',
    ),
    VideoItem(
      id: '5BjTuXca7go',
      titulo: 'NR 35 - ZLQ + Linha de Vida Horizontal',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    // O player iFrame oficial envia o cabeçalho Referer/origin exigido pelo
    // YouTube, evitando o erro 153 ("Video player configuration error").
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _videos[_currentVideoIndex].id,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: true,
        loop: false,
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        playsInline: true,
        interfaceLanguage: 'pt',
        captionLanguage: 'pt',
      ),
    );

    _playerSubscription = _controller.listen((value) {
      if (value.playerState == PlayerState.ended &&
          _currentVideoIndex < _videos.length - 1) {
        _playVideo(_currentVideoIndex + 1, autoPlay: true);
      }
    });
  }

  void _openInYoutube(String videoId) async {
    final String youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final Uri url = Uri.parse(youtubeUrl);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o YouTube')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o YouTube')),
        );
      }
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _controller.close();
    super.dispose();
  }

  void _playVideo(int index, {bool autoPlay = true}) {
    if (index == _currentVideoIndex) return;

    setState(() {
      _currentVideoIndex = index;
    });

    final videoId = _videos[index].id;
    if (autoPlay) {
      _controller.loadVideoById(videoId: videoId);
    } else {
      _controller.cueVideoById(videoId: videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentVideo = _videos[_currentVideoIndex];

    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      backgroundColor: Colors.black,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Videoteca'),
            elevation: 4,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Player de vídeo
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: player,
                ),

                // Título do vídeo atual
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Text(
                        currentVideo.titulo,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openInYoutube(currentVideo.id),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Assistir no YouTube'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFF0000,
                          ), // YouTube red
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Seção da playlist
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_play,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Playlist de Vídeos',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 24,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),

                // Lista de vídeos
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final isCurrent = index == _currentVideoIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: isCurrent ? 2 : 1,
                          ),
                          color: isCurrent
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.1,
                                )
                              : colorScheme.surface,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    video.thumbnailUrl,
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.video_library,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                  if (!isCurrent)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          title: Text(
                            video.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          subtitle: isCurrent
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      color: colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reproduzindo agora',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          trailing: isCurrent
                              ? Icon(
                                  Icons.equalizer,
                                  color: colorScheme.primary,
                                  size: 24,
                                )
                              : Icon(
                                  Icons.play_circle_outline,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                          onTap: () => _playVideo(index),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
          bottomNavigationBar: const BottomNavigationWidget(currentIndex: 2),
        );
      },
    );
  }
}

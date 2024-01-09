import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:grand_fantasia_launcher/src/widgets/tab_button.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/launcher_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final controller = LauncherController();
  var progress = 0.0;
  var errorWhileUpdating = false;
  var isUpdated = false;
  var updateStatusLabel = 'Atualizando jogo...';

  void _tryUpdate() async {
    controller.isUpdated().then((value) {
      final (_, isUpdated) = value;

      this.isUpdated = isUpdated;

      debugPrint('isUpdated: $isUpdated');

      if (!isUpdated) {
        controller.update((progress) {
          setState(() {
            this.progress = progress;
          });

          debugPrint("Total Progress: ${(progress * 100).toStringAsFixed(2)}%");
        }).then((value) {
          setState(() {
            updateStatusLabel = 'Jogo atualizado';
          });
        }, onError: (error) {
          debugPrint(error.toString());

          setState(() {
            errorWhileUpdating = true;
            updateStatusLabel = 'Falha ao atualizar jogo.. $error';
          });
        });
      } else {
        setState(() {
          progress = 1.0;
          updateStatusLabel = 'Jogo atualizado';
        });
      }
    }, onError: (error) {
      debugPrint(error.toString());

      setState(() {
        errorWhileUpdating = true;
        updateStatusLabel = 'Falha ao atualizar jogo';
      });
    });
  }

  @override
  void initState() {
    _tryUpdate();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (_) {
        windowManager.startDragging();
      },
      child: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerLeft,
                image: AssetImage('assets/images/adventure_time_bg.jpg'),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 15,
                  left: 30,
                  child: Image.asset(
                    'assets/images/logo_adventures.png',
                    scale: 1.1,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TabButton(
                            child: const Icon(
                              Icons.remove_rounded,
                              size: 25,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              windowManager.minimize();
                            },
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          TabButton(
                            child: const Icon(
                              Icons.close_rounded,
                              size: 25,
                              color: Colors.black54,
                            ),
                            onPressed: () {
                              windowManager.close();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(
                      flex: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 15,
                                    //color: const Color(0xFF00FF00),
                                    color: const Color(0xFF9C27B0),
                                    backgroundColor: const Color(0xFF9C27B0)
                                        .withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    color: Colors.black,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9C27B0),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      updateStatusLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: Colors.black,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (errorWhileUpdating) {
                                    setState(() {
                                      errorWhileUpdating = false;
                                      progress = 0.0;
                                      updateStatusLabel = 'Atualizando jogo...';
                                    });

                                    _tryUpdate();
                                  }

                                  if (progress == 1.0) {
                                    await controller.startGame(
                                      updateLauncher: !isUpdated,
                                    );

                                    windowManager.close();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9C27B0),
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  elevation: 5,
                                ),
                                child: Builder(builder: (context) {
                                  var buttonLabel = 'Iniciar Jogo';

                                  if (errorWhileUpdating) {
                                    buttonLabel = 'Tentar novamente';
                                  } else if (progress < 1.0) {
                                    buttonLabel = 'Aguarde';
                                  }

                                  return Text(
                                    buttonLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

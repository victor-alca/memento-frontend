import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test_app/app/router/app_routes.dart';
import 'package:test_app/features/tests/presentation/models/resultado_test_args.dart';
import 'package:test_app/features/auth/service/auth_service.dart';
import 'package:test_app/app/provider/supabase_provider.dart';
import 'package:test_app/features/auth/models/user_model.dart';

class StroopTestPage extends StatefulWidget {
  const StroopTestPage({super.key});

  @override
  State<StroopTestPage> createState() => _StroopTestPageState();
}

class _StroopTestPageState extends State<StroopTestPage> {
  final SpeechToText _speechToText = SpeechToText();
  
  // Lista de palavras e cores
  final List<String> palavras = ['VERMELHO', 'AZUL', 'VERDE', 'AMARELO'];
  final List<Color> cores = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
  final List<String> coresTexto = ['vermelho', 'azul', 'verde', 'amarelo'];
  
  // Estado do teste
  String palavraAtual = '';
  Color corAtual = Colors.black;
  String corCorretaTexto = '';
  int indiceAtual = 0;
  int pontuacao = 0;
  int erros = 0;
  int totalItens = 50;
  
  // Controle de tempo
  List<Duration> temposDeResposta = [];
  late DateTime tempoInicio;
  
  // Controle do reconhecimento de voz
  bool _speechEnabled = false;
  bool _speechListening = false;
  bool _permissionGranted = false;
  String _lastWords = '';
  
  // Controle de feedback visual
  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;
  
  // Controle de tempo
  int _timeRemaining = 15;
  
  late final AuthService authService;
  @override
  void initState() {
    super.initState();
    _initPermissionsAndSpeech();
    authService = AuthService(supabase.client);
  }
  
  void _initPermissionsAndSpeech() async {
    // Primeiro verifica e pede permissão de microfone
    await _requestMicrophonePermission();
    
    if (_permissionGranted) {
      _initSpeech();
      // Aguarda um pouco para garantir que o speech foi inicializado
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _gerarProximoItem();
        }
      });
    } else {
      _showPermissionDialog();
    }
  }
  
  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    _permissionGranted = status == PermissionStatus.granted;
    setState(() {});
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão necessária'),
          content: const Text(
            'Para realizar o Stroop Test, é necessário permitir o acesso ao microfone. '
            'Você gostaria de tentar novamente?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.patientHome);
              },
            ),
            TextButton(
              child: const Text('Tentar novamente'),
              onPressed: () {
                Navigator.of(context).pop();
                _initPermissionsAndSpeech();
              },
            ),
          ],
        );
      },
    );
  }
  
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        setState(() {
          _speechListening = false;
        });
        // Se houve erro e não está mostrando feedback, tenta escutar novamente
        if (!_showingFeedback && indiceAtual < totalItens) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!_speechListening && !_showingFeedback && mounted) {
              _startListening();
            }
          });
        }
      },
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() {
            _speechListening = false;
          });
          // Se parou de escutar e não está mostrando feedback, tenta escutar novamente
          if (!_showingFeedback && indiceAtual < totalItens) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (!_speechListening && !_showingFeedback && mounted) {
                _startListening();
              }
            });
          }
        }
      },
    );
    setState(() {});
  }
  
  void _gerarProximoItem() {
    final random = Random();
    
    // Seleciona uma palavra aleatória
    final indicePalavra = random.nextInt(palavras.length);
    palavraAtual = palavras[indicePalavra];
    
    // Seleciona uma cor aleatória
    final indiceCor = random.nextInt(cores.length);
    corAtual = cores[indiceCor];
    corCorretaTexto = coresTexto[indiceCor];
    
    tempoInicio = DateTime.now();
    _timeRemaining = 15;
    
    setState(() {});
    
    // Aguarda um pouco antes de iniciar o reconhecimento (para dar tempo da UI atualizar)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_showingFeedback) {
        _ensureListening();
      }
    });
    
    // Contador regressivo
    _startCountdown();
  }
  
  void _ensureListening() {
    // Força o início do reconhecimento de voz
    if (_speechEnabled && !_speechListening && !_showingFeedback) {
      _startListening();
    }
    
    // Verifica novamente em 2 segundos se ainda não está escutando
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_speechListening && !_showingFeedback && indiceAtual < totalItens) {
        _startListening();
      }
    });
  }
  
  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_showingFeedback || !mounted) return false;
      
      setState(() {
        _timeRemaining--;
      });
      
      if (_timeRemaining <= 0) {
        if (!_showingFeedback && indiceAtual < totalItens) {
          _processarResposta(''); // Processa como resposta vazia (erro)
        }
        return false;
      }
      
      return true;
    });
  }
  
  void _startListening() async {
    if (!_speechEnabled || _speechListening || _showingFeedback) {
      return;
    }
    
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: "pt_BR",
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
      );
      setState(() {
        _speechListening = true;
      });
    } catch (e) {
      setState(() {
        _speechListening = false;
      });
    }
  }
  
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _speechListening = false;
    });
  }
  
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords.toLowerCase();
    });
    
    // Processa tanto resultados finais quanto parciais se tiver confiança suficiente
    if (result.finalResult || 
        (result.hasConfidenceRating && result.confidence > 0.7) ||
        _verificarVariacoesCor(_lastWords, corCorretaTexto)) {
      
      // Se o resultado contém uma cor válida, processa imediatamente
      if (_lastWords.isNotEmpty && _verificarAlgumaCor(_lastWords)) {
        _processarResposta(_lastWords);
      }
    }
  }
  
  bool _verificarAlgumaCor(String resposta) {
    List<String> todasAsCores = ['vermelho', 'vermelha', 'azul', 'verde', 'amarelo', 'amarela'];
    return todasAsCores.any((cor) => resposta.contains(cor));
  }
  
  void _processarResposta(String resposta) {
    final tempoResposta = DateTime.now().difference(tempoInicio);
    temposDeResposta.add(tempoResposta);
    
    _stopListening();
    
    // Verifica se a resposta está correta
    // A resposta correta é a cor da tinta, não o texto da palavra
    bool acertou = resposta.contains(corCorretaTexto.toLowerCase()) ||
                   _verificarVariacoesCor(resposta, corCorretaTexto);
    
    if (acertou) {
      pontuacao++;
    } else {
      erros++;
    }
    
    // Mostra feedback visual
    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = acertou;
    });
    
    // Espera um pouco mostrando o feedback, depois vai para próximo item
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _showingFeedback = false;
        _lastWords = ''; // Limpa a última resposta
      });
      
      indiceAtual++;
      
      if (indiceAtual >= totalItens) {
        _finalizarTeste();
      } else {
        _gerarProximoItem();
      }
    });
  }
  
  bool _verificarVariacoesCor(String resposta, String corCorreta) {
    Map<String, List<String>> variacoes = {
      'vermelho': ['vermelho', 'vermelha', 'red'],
      'azul': ['azul', 'blue'],
      'verde': ['verde', 'green'],
      'amarelo': ['amarelo', 'amarela', 'yellow'],
    };
    
    List<String> possiveisRespostas = variacoes[corCorreta] ?? [];
    return possiveisRespostas.any((variacao) => resposta.contains(variacao));
  }
  
  void _finalizarTeste() async {
    Duration somaTempos = temposDeResposta.fold(
      Duration.zero,
      (a, b) => a + b,
    );
    double tempoMedio = somaTempos.inMilliseconds / temposDeResposta.length;
    
    // Salvar no Supabase
    final supabase = Supabase.instance.client;

    final User? user = supabase.auth.currentUser;
      debugPrint(user?.id);
      if (user != null) {
      UserModel _role = await authService.getUserData(user.id);
      if(_role.isPatient){
      // Busca o id do paciente associado ao user.id
      final patient = await supabase
      .from('patients')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();
      final patientId = patient?['id'];
        await supabase.from('patient_tests').insert({
          'patient_id': patientId,
          'test_id': 1,
          'score': pontuacao,
          'average_time': tempoMedio,
          'time_spent': somaTempos,
          'test_date': DateTime.now().toIso8601String(),
          'doctor_id': null,
        });
      } else if(_role.isDoctor){
        // Busca o id do medico associado ao user.id
        final doctor = await supabase
        .from('doctors')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
        final doctorId = doctor?['id'];
        await supabase.from('patient_tests').insert({
          // no futuro deve ser colocado o id do paciente associado ao medico
          'patient_id': null,
          'test_id': 1,
          'score': pontuacao,
          'average_time': tempoMedio,
          'time_spent': somaTempos,
          'test_date': DateTime.now().toIso8601String(),
          'doctor_id': doctorId,
        });
      }
      }
    
    // Navegar para tela de resultado
    if (mounted) {
      context.go(
        AppRoutes.resultadoTeste,
        extra: ResultadoTesteArgs(
          pontuacao: pontuacao,
          tempoMedioMs: tempoMedio,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Se não tem permissão, mostra tela de carregamento
    if (!_permissionGranted || !_speechEnabled) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Stroop Test',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Configurando microfone...',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Stroop Test',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Diga em voz alta a cor da tinta usada para escrever a palavra.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            
            // Contador de progresso e estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Item ${indiceAtual + 1}/$totalItens',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Erros | $erros',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Pontos | $pontuacao',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 80),
            
            // Palavra com cor OU feedback
            Center(
              child: _showingFeedback ? _buildFeedbackWidget() : _buildWordWidget(),
            ),
            
            const SizedBox(height: 60),
            
            // Indicador de microfone (só mostra se não está mostrando feedback)
            if (!_showingFeedback) _buildMicrophoneWidget(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWordWidget() {
    return Text(
      palavraAtual,
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: corAtual,
      ),
    );
  }
  
  Widget _buildFeedbackWidget() {
    return Column(
      children: [
        Icon(
          _lastAnswerCorrect ? Icons.check_circle : Icons.cancel,
          size: 80,
          color: _lastAnswerCorrect ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 20),
        Text(
          _lastAnswerCorrect ? 'CORRETO!' : 'INCORRETO!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _lastAnswerCorrect ? Colors.green : Colors.red,
          ),
        ),
        if (_lastWords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Você disse: "$_lastWords"',
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
        if (!_lastAnswerCorrect) ...[
          const SizedBox(height: 16),
          Text(
            'Resposta correta: $corCorretaTexto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildMicrophoneWidget() {
    return Column(
      children: [
        Icon(
          Icons.mic,
          size: 48,
          color: _speechListening ? Colors.red : Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          _speechListening ? 'Escutando...' : 'Diga a cor da tinta',
          style: TextStyle(
            fontSize: 18,
            color: _speechListening ? Colors.red : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tempo restante: ${_timeRemaining}s',
          style: TextStyle(
            fontSize: 16,
            color: _timeRemaining <= 5 ? Colors.red : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        if (_lastWords.isNotEmpty && !_showingFeedback) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Você disse: "$_lastWords"',
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}

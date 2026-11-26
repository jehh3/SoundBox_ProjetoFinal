import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const rosa = Color(0xFFFF00AA);
const azul = Color(0xFF00D9FF);
const fundo = Color(0xFF090B18);
const cinza = Color(0xFF17192D);

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SoundBox',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: fundo,
      colorScheme: const ColorScheme.dark(
        primary: rosa,
        secondary: azul,
        surface: cinza,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: azul,
      ),
    ),
    home: const SoundBox(),
  ));
}

class SoundBox extends StatefulWidget {
  const SoundBox({super.key});

  @override
  State<SoundBox> createState() => _SoundBoxState();
}

class _SoundBoxState extends State<SoundBox> {
  final pesquisa = TextEditingController();

  List musicas = [];
  List favoritos = [];

  bool carregando = true;
  bool erro = false;

  String termo = '';
  int pagina = 0;

  @override
  void initState() {
    super.initState();
    buscarMusicas('');
  }

  Future<void> buscarMusicas(String nome) async {
    setState(() {
      carregando = true;
      erro = false;
      termo = nome;
    });

    try {
      final url = Uri.https('itunes.apple.com', '/search', {
        'term': nome.isEmpty ? 'pop' : nome,
        'entity': 'song',
        'country': 'BR',
        'limit': '30',
      });

      final resposta = await http
          .get(url)
          .timeout(const Duration(seconds: 15));

      if (resposta.statusCode != 200) {
        throw Exception('Erro na API');
      }

      final dados = jsonDecode(resposta.body);

      if (dados is! Map || dados['results'] is! List) {
        throw Exception('Resposta inválida');
      }

      if (!mounted) return;

      setState(() {
        musicas = dados['results'];
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = true;
        carregando = false;
      });
    }
  }

  void pesquisar() {
    if (carregando) return;

    String nome = pesquisa.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome de uma música.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    buscarMusicas(nome);
  }

  bool favorito(dynamic musica) {
    return favoritos.any(
      (item) => item['trackId'] == musica['trackId'],
    );
  }

  void alterarFavorito(dynamic musica) {
    setState(() {
      if (favorito(musica)) {
        favoritos.removeWhere(
          (item) => item['trackId'] == musica['trackId'],
        );
      } else {
        favoritos.add(musica);
      }
    });
  }

  Widget imagem(dynamic musica, double tamanho) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          musica['artworkUrl100'] ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.music_note,
              color: azul,
            );
          },
        ),
      ),
    );
  }

  void detalhes(dynamic musica) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, atualizar) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Detalhes da música'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(child: imagem(musica, 250)),
                  const SizedBox(height: 20),
                  Text(
                    musica['trackName'] ?? 'Sem nome',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    musica['artistName'] ?? 'Desconhecido',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: azul,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: cinza,
                    child: ListTile(
                      leading: const Icon(
                        Icons.album,
                        color: rosa,
                      ),
                      title: const Text('Álbum'),
                      subtitle: Text(
                        musica['collectionName'] ??
                            'Não informado',
                      ),
                    ),
                  ),
                  Card(
                    color: cinza,
                    child: ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: azul,
                      ),
                      title: const Text('Gênero'),
                      subtitle: Text(
                        musica['primaryGenreName'] ??
                            'Não informado',
                      ),
                    ),
                  ),
                  if (musica['trackTimeMillis'] is num)
                    Card(
                      color: cinza,
                      child: ListTile(
                        leading: const Icon(
                          Icons.access_time,
                          color: rosa,
                        ),
                        title: const Text('Duração'),
                        subtitle: Text(
                          '${musica['trackTimeMillis'] ~/ 60000} min '
                          '${musica['trackTimeMillis'] ~/ 1000 % 60} s',
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rosa,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      alterarFavorito(musica);
                      atualizar(() {});
                    },
                    icon: Icon(
                      favorito(musica)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: Text(
                      favorito(musica)
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget listaMusicas(List lista) {
    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final musica = lista[index];

        return Card(
          color: cinza,
          child: ListTile(
            leading: imagem(musica, 55),
            title: Text(
              musica['trackName'] ?? 'Sem nome',
            ),
            subtitle: Text(
              musica['artistName'] ?? 'Desconhecido',
              style: const TextStyle(color: azul),
            ),
            onTap: () => detalhes(musica),
            trailing: IconButton(
              onPressed: () => alterarFavorito(musica),
              icon: Icon(
                favorito(musica)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: rosa,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget resultados() {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(color: rosa),
      );
    }

    if (erro) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Erro ao carregar músicas.'),
            TextButton(
              onPressed: () => buscarMusicas(termo),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (musicas.isEmpty) {
      return const Center(
        child: Text('Nenhuma música encontrada.'),
      );
    }

    return listaMusicas(musicas);
  }

  Widget explorar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.viewInsetsOf(context).bottom == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF390D42),
                  Color(0xFF101D45),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.graphic_eq,
                  color: rosa,
                  size: 40,
                ),
                SizedBox(height: 10),
                Text(
                  'Descubra novas músicas',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Seu som. Seu estilo.',
                  style: TextStyle(color: azul),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        TextField(
          controller: pesquisa,
          enabled: !carregando,
          onSubmitted: (valor) => pesquisar(),
          decoration: const InputDecoration(
            labelText: 'Nome da música',
            prefixIcon: Icon(Icons.search, color: azul),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosa,
                  foregroundColor: Colors.white,
                ),
                onPressed: carregando ? null : pesquisar,
                child: const Text('Pesquisar'),
              ),
            ),
            TextButton(
              onPressed: carregando
                  ? null
                  : () {
                      pesquisa.clear();
                      buscarMusicas('');
                    },
              child: const Text(
                'Limpar',
                style: TextStyle(color: azul),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          termo.isEmpty
              ? 'Músicas para explorar'
              : 'Resultados para "$termo"',
          style: const TextStyle(
            fontSize: 18,
            color: azul,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: resultados()),
      ],
    );
  }

  Widget telaFavoritos() {
    if (favoritos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              color: rosa,
              size: 60,
            ),
            SizedBox(height: 15),
            Text('Nenhuma música favorita.'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minhas músicas favoritas',
          style: TextStyle(
            color: rosa,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('${favoritos.length} músicas salvas'),
        const SizedBox(height: 15),
        Expanded(child: listaMusicas(favoritos)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(
          Icons.headphones,
          color: rosa,
        ),
        title: const Text(
          'SoundBox',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: pagina == 0
              ? explorar()
              : telaFavoritos(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cinza,
        selectedItemColor: rosa,
        unselectedItemColor: azul,
        currentIndex: pagina,
        onTap: (index) {
          FocusScope.of(context).unfocus();
          setState(() {
            pagina = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pesquisa.dispose();
    super.dispose();
  }
}

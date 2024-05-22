import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<List<dynamic>> _csvData = [];
  String _selectedLanguage = 'English';
  String _translation = '';
  String _exampleSentences = '';
  bool _isLoading = false;
  Color _backgroundColor = Colors.white;

  late AnimationController _animationController;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _loadCSV();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _dotCount = IntTween(begin: 1, end: 3).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCSV() async {
    try {
      final data = await rootBundle.loadString('assets/Words.csv');
      final csvConverter = CsvToListConverter();
      setState(() {
        _csvData = csvConverter.convert(data);
      });
    } catch (e) {
      print('Error loading CSV data: $e');
    }
  }

  void _translateWord() async {
    final word = _controller.text.trim().toLowerCase();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a word to translate.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final translations = _csvData.where((row) {
      return _selectedLanguage == 'English'
          ? row[0].toString().toLowerCase().contains(word)
          : row[1].toString().toLowerCase().contains(word);
    }).toList();

    if (translations.isEmpty) {
      setState(() {
        _translation = 'Word not found in the file.';
        _exampleSentences = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _translation = translations
          .map((translation) =>
              _selectedLanguage == 'English' ? translation[1] : translation[0])
          .join('\n');
    });

    await _generateExampleSentence(word);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateExampleSentence(String word) async {
    final prompt = _selectedLanguage == 'English'
        ? 'Create two example sentences using the English word \'$word\' and provide their Hebrew translations.'
        : 'Create two example sentences using the Hebrew word \'$word\' and provide their English translations.';

    final response = await http.post(
      Uri.parse('https://api.cohere.ai/v1/generate'),
      headers: {
        'Authorization': 'Bearer ZUooWKD9I2ym0jyLmdXSjb0cD4sgaMBTnd2G4mHL',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'command-xlarge-nightly',
        'prompt': prompt,
        'max_tokens': 100,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _exampleSentences = data['generations'][0]['text'].trim();
      });
    } else {
      print('Error generating example sentence: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Translation and Example Sentences'),
        actions: [
          IconButton(
            icon: Icon(Icons.color_lens),
            onPressed: () {
              _showColorPicker(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_page),
              title: Text('Contact'),
              onTap: () {
                Navigator.pushNamed(context, '/contact');
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: _backgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
              items: <String>['English', 'Hebrew']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter a word to translate',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _translateWord,
              child: const Text('Translate'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _dotCount,
                          builder: (context, child) {
                            String dots = '.' * _dotCount.value;
                            return Text(
                              'Crafting$dots',
                              style: TextStyle(fontSize: 20, color: Colors.blue),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_translation.isNotEmpty) ...[
                            Text(
                              'Translation:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _translation,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
                          if (_exampleSentences.isNotEmpty) ...[
                            SizedBox(height: 20),
                            Text(
                              'Example Sentences:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _exampleSentences,
                                textDirection: _selectedLanguage == 'Hebrew'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Background Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _backgroundColor,
              onColorChanged: (Color color) {
                setState(() {
                  _backgroundColor = color;
                });
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }
}

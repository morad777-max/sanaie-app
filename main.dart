import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const SanaieInApp());
}

// 3. قاعدة البيانات المحلية (Database Helper باستخدام SQLite)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sanaie_in.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        description TEXT,
        price TEXT
      )
    ''');
  }

  Future<int> insertRequest(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('requests', row);
  }

  Future<List<Map<String, dynamic>>> getRequests() async {
    final db = await instance.database;
    return await db.query('requests');
  }
}

class SanaieInApp extends StatelessWidget {
  const SanaieInApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صنايعي-إن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LoginScreen(),
    );
  }
}

// 1. شاشة تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  String _selectedRole = 'client'; // 'client' أو 'worker'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صنايعي-إن | تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.amber[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.handyman, size: 80, color: Colors.amber),
            const SizedBox(height: 10),
            const Text(
              'وصّلك بالصنايعي المناسب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            const Text('اختر نوع الحساب:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('عميل'),
                    value: 'client',
                    groupValue: _selectedRole,
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('صنايعي'),
                    value: 'worker',
                    groupValue: _selectedRole,
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف المحمول',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_phoneController.text.trim().length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال رقم هاتف صحيح')),
                  );
                  return;
                }
                // توجيه العميل أو الصنايعي حسب اختياره
                if (_selectedRole == 'client') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerOffersScreen()));
                }
              },
              child: const Text('متابعة ودخول', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. شاشة العميل لطلب الخدمة وحفظها محلياً بـ SQLite
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({Key? key}) : super(key: key);

  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String _selectedCategory = 'سباكة';
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _categories = ['سباكة', 'كهرباء', 'تكييف', 'نجارة', 'نقاشة'];

  void _saveAndPublish() async {
    if (_descController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال كافة البيانات')));
      return;
    }

    // حفظ البيانات في قاعدة البيانات المحلية SQLite
    await DatabaseHelper.instance.insertRequest({
      'category': _selectedCategory,
      'description': _descController.text,
      'price': _priceController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ ونشر الطلب محلياً بنجاح!')),
    );

    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerOffersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب خدمة جديدة'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('اختر التخصص:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text('صف المشكلة:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 15),
            const Text('السعر المقترح (ج.م):', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _saveAndPublish,
              child: const Text('نشر الطلب وحفظه', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. شاشة عروض الصنايعي (قائمة الطلبات المتاحة للتقديم عليها)
class WorkerOffersScreen extends StatefulWidget {
  const WorkerOffersScreen({Key? key}) : super(key: key);

  @override
  _WorkerOffersScreenState createState() => _WorkerOffersScreenState();
}

class _WorkerOffersScreenState extends State<WorkerOffersScreen> {
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() async {
    final data = await DatabaseHelper.instance.getRequests();
    setState(() {
      _requests = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض الطلبات المتاحة للصنايعي'),
        backgroundColor: Colors.amber[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          )
        ],
      ),
      body: _requests.isEmpty
          const Center(child: Text('لا توجد طلبات متاحة حالياً، أنشئ طلباً جديداً!', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const Icon(Icons.handyman, color: Colors.amber, size: 40),
                    title: Text('التخصص: ${req['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الوصف: ${req['description']}\nالسعر المقترح: ${req['price']} ج.م'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800]),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                      },
                      child: const Text('تقديم عرض', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// 5. شاشة الملف الشخصي والتقييمات
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي والتقييمات'),
        backgroundColor: Colors.amber[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text('محمد كمال الدين', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('مستخدم معتمد - صنايعي-إن', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 30),
                Icon(Icons.star, color: Colors.amber, size: 30),
                Icon(Icons.star, color: Colors.amber, size: 30),
                Icon(Icons.star, color: Colors.amber, size: 30),
                Icon(Icons.star_half, color: Colors.amber, size: 30),
                SizedBox(width: 10),
                Text('4.8 (تقييم العام)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 40),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('آراء العملاء السابقين:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.comment, color: Colors.green),
                    title: Text('أحمد علي'),
                    subtitle: Text('خدمة ممتازة وسريعة جداً، والأسعار مناسبة.'),
                    trailing: Text('5 نجوم'),
                  ),
                  ListTile(
                    leading: Icon(Icons.comment, color: Colors.green),
                    title: Text('محمود إبراهيم'),
                    subtitle: Text('التزام بالموعد ودقة في إنجاز العمل.'),
                    trailing: Text('5 نجوم'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. شاشة المحادثة المباشرة
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'أهلاً بحضرتك، أنا مستعد لتنفيذ الخدمة بالسعر المطلوب.', 'isMe': false},
    {'text': 'تمام، في انتظار وصولك في الموعد.', 'isMe': true},
  ];
  final _msgController = TextEditingController();

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': _msgController.text.trim(), 'isMe': true});
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة المباشرة'),
        backgroundColor: Colors.amber[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isMe = msg['isMe'];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.amber[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text'], style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.amber[700],
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
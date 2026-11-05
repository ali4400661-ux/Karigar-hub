import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KarachiVIPHubApp());
}

class KarachiVIPHubApp extends StatelessWidget {
  const KarachiVIPHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karachi VIP Service Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF0D9488),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // گوگل لاگ ان (Firebase Auth)
  Future<void> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      setState(() {
        user = userCredential.user;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خوش آمدید! ${user?.displayName ?? ''} کامیاب لاگ ان ہو گیا۔")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("گوگل لاگ ان میں خرابی: $e")),
      );
    }
  }

  // واٹس ایپ انکوائری کھولنے کا فنکشن
  void launchWhatsApp(String workerName, String category, String location, String rate) async {
    String adminPhone = "923161010852";
    String message = "سلام ایڈمن! مجھے اس VIP سروس سے رابطہ کرنا ہے:\n\nنام: $workerName\nشعبہ: $category\nعلاقہ: $location\nریٹ: $rate";
    String url = "https://wa.me/$adminPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کراچی آل ان ون VIP ہب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: Icon(user != null ? Icons.person : Icons.login, color: Colors.white),
            onPressed: signInWithGoogle,
            tooltip: user != null ? user!.displayName : "گوگل لاگ ان",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ویلکم بینر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                user != null 
                  ? "⭐ خوش آمدید، ${user!.displayName}! آپ اب بطور تصدیق شدہ یوزر ایپ استعمال کر رہے ہیں۔"
                  : "⭐ خوش آمدید! کسٹمرز کے لیے تمام رابطے فری ہیں۔ گوگل لاگ ان کے لیے اوپر پروفائل آئیکن پر کلک کریں۔",
                style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // سرچ بار
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "نام یا سروس تلاش کریں...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            const Text("📋 رجسٹرڈ پروفائلز اور خدمات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            // فائر بیس کلاؤڈ ڈیٹا بیس سے لائیو ڈیٹا فیچ کرنے کا سسٹم
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("ڈیٹا لوڈ کرنے میں مسئلہ پیش آیا۔"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularIndicatorBox());
                }

                final docs = snapshot.data!.docs;
                
                // فلٹرنگ
                final filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toLowerCase();
                  String category = (data['category'] ?? '').toLowerCase();
                  return name.contains(searchQuery) || category.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(child: Text("کوئی ریکارڈ موجود نہیں ہے۔", style: TextStyle(color: Colors.grey))),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(6)),
                              child: const Text("Verified ✔️", style: TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(data['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            Text("شعبہ: ${data['category']}", style: const TextStyle(color: Colors.black87)),
                            Text("علاقہ: 📍 ${data['location']}, کراچی", style: const TextStyle(color: Colors.black87)),
                            Text("معاوضہ: ${data['rate']}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => launchWhatsApp(data['name'], data['category'], data['location'], data['rate']),
                              child: const Text("واٹس ایپ پر رابطہ کریں", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CircularIndicatorBox extends StatelessWidget {
  const CircularIndicatorBox({super.key});
import 'package:flutter/material.dart';

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KarachiVIPHubApp());
}

class KarachiVIPHubApp extends StatelessWidget {
  const KarachiVIPHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karachi VIP Service Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF0D9488),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  // گوگل لاگ ان (Firebase Auth)
  Future<void> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      setState(() {
        user = userCredential.user;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خوش آمدید! ${user?.displayName ?? ''} کامیاب لاگ ان ہو گیا۔")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("گوگل لاگ ان میں خرابی: $e")),
      );
    }
  }

  // واٹس ایپ انکوائری کھولنے کا فنکشن
  void launchWhatsApp(String workerName, String category, String location, String rate) async {
    String adminPhone = "923161010852";
    String message = "سلام ایڈمن! مجھے اس VIP سروس سے رابطہ کرنا ہے:\n\nنام: $workerName\nشعبہ: $category\nعلاقہ: $location\nریٹ: $rate";
    String url = "https://wa.me/$adminPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کراچی آل ان ون VIP ہب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: Icon(user != null ? Icons.person : Icons.login, color: Colors.white),
            onPressed: signInWithGoogle,
            tooltip: user != null ? user!.displayName : "گوگل لاگ ان",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ویلکم بینر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                user != null 
                  ? "⭐ خوش آمدید، ${user!.displayName}! آپ اب بطور تصدیق شدہ یوزر ایپ استعمال کر رہے ہیں۔"
                  : "⭐ خوش آمدید! کسٹمرز کے لیے تمام رابطے فری ہیں۔ گوگل لاگ ان کے لیے اوپر پروفائل آئیکن پر کلک کریں۔",
                style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // سرچ بار
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "نام یا سروس تلاش کریں...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            const Text("📋 رجسٹرڈ پروفائلز اور خدمات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            // فائر بیس کلاؤڈ ڈیٹا بیس سے لائیو ڈیٹا فیچ کرنے کا سسٹم
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("ڈیٹا لوڈ کرنے میں مسئلہ پیش آیا۔"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularIndicatorBox());
                }

                final docs = snapshot.data!.docs;
                
                // فلٹرنگ
                final filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toLowerCase();
                  String category = (data['category'] ?? '').toLowerCase();
                  return name.contains(searchQuery) || category.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(child: Text("کوئی ریکارڈ موجود نہیں ہے۔", style: TextStyle(color: Colors.grey))),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(6)),
                              child: const Text("Verified ✔️", style: TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(data['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 6),
                            Text("شعبہ: ${data['category']}", style: const TextStyle(color: Colors.black87)),
                            Text("علاقہ: 📍 ${data['location']}, کراچی", style: const TextStyle(color: Colors.black87)),
                            Text("معاوضہ: ${data['rate']}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => launchWhatsApp(data['name'], data['category'], data['location'], data['rate']),
                              child: const Text("واٹس ایپ پر رابطہ کریں", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CircularIndicatorBox extends StatelessWidget {
  const CircularIndicatorBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

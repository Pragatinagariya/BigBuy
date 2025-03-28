import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];
  bool _isLoading = false;

  final String apiUrl = "https://spk.amisys.in/android/php/v0/get_users.php"; // API endpoint

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ✅ Fetch all customers where au_accid >= 20800001
  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {'action': 'get_users'},
      );

      print("Response Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Parsed JSON: $data");

        if (data["status"] == "success" && data["users"] != null) {
          setState(() {
            users = List<Map<String, dynamic>>.from(data["users"]);
          });
          print("Users List: $users");
        } else {
          showSnackbar(data["message"] ?? "No users found!", Colors.red);
        }
      } else {
        showSnackbar("Error: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      showSnackbar("Error fetching users: $e", Colors.red);
      print("Exception: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Show Snackbar
  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer List"), backgroundColor: Colors.orange),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text("No customers found."))
          : Column(
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(10.0),
          //   child: Text("Total Users: ${users.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          // ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: Text(user["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Username: ${user["username"]}\nMobile: ${user["mobile"]}"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

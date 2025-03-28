import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;

class UserProfilePage extends StatefulWidget {
  final String userid;

  const UserProfilePage({super.key, required this.userid});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  // Track which field is editable
  bool _isEditingName = false;
  bool _isEditingUsername = false;
  bool _isEditingMobile = false;

  final String apiUrl = "https://spk.amisys.in/android/php/v0/user_profile.php";

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  // ✅ Fetch User Data from the Database
  Future<void> fetchUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'action': 'get_user', 'userid': widget.userid},
      );

      print("Response Body: ${response.body}"); // ✅ Debugging line

      final data = jsonDecode(response.body);

      if (data["status"] == "success" && data["user"] != null) {
        setState(() {
          _nameController.text = data["user"]["name"] ?? "";
          _usernameController.text = data["user"]["username"] ?? "";
          _mobileController.text = data["user"]["mobile"] ?? "";
        });
      } else {
        showSnackbar(data["message"] ?? "Failed to load user data!", Colors.red);
      }
    } catch (e) {
      showSnackbar("Error fetching profile: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Update User Data in Database
  Future<void> updateUserProfile() async {
    if (_nameController.text.isEmpty || _usernameController.text.isEmpty || _mobileController.text.isEmpty) {
      showSnackbar("All fields are required!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'action': 'update_user',
          'userid': widget.userid,
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'mobile': _mobileController.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        showSnackbar("Profile updated successfully!", Colors.green);

        // ✅ Update username globally
        globals.username = _usernameController.text.trim();

        // ✅ Disable editing mode after saving
        setState(() {
          _isEditingName = false;
          _isEditingUsername = false;
          _isEditingMobile = false;
        });
      } else {
        showSnackbar(data["message"], Colors.red);
      }
    } catch (e) {
      showSnackbar("Error updating profile: $e", Colors.red);
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
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.orange),
      resizeToAvoidBottomInset: true, // ✅ Prevents bottom overflow
      body: SafeArea( // ✅ Ensures UI does not get cut off
        child: SingleChildScrollView( // ✅ Makes everything scrollable
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Full Name Field with Edit Icon
                _buildEditableField(
                  label: "Full Name",
                  controller: _nameController,
                  isEditing: _isEditingName,
                  onEdit: () => setState(() => _isEditingName = true),
                  onDone: () => setState(() => _isEditingName = false),
                ),
                const SizedBox(height: 12),

                // ✅ Username Field with Edit Icon
                _buildEditableField(
                  label: "Username",
                  controller: _usernameController,
                  isEditing: _isEditingUsername,
                  onEdit: () => setState(() => _isEditingUsername = true),
                  onDone: () => setState(() => _isEditingUsername = false),
                ),
                const SizedBox(height: 12),

                // ✅ Mobile Number Field with Edit Icon
                _buildEditableField(
                  label: "Mobile Number",
                  controller: _mobileController,
                  isEditing: _isEditingMobile,
                  keyboardType: TextInputType.phone,
                  onEdit: () => setState(() => _isEditingMobile = true),
                  onDone: () => setState(() => _isEditingMobile = false),
                ),
                const SizedBox(height: 20),

                // ✅ Ensure button is visible even when keyboard is open
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : updateUserProfile,
                    child: _isLoading ? const CircularProgressIndicator() : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Reusable Editable TextField with Edit Button (OUTSIDE the TextField)
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    bool isEditing = false,
    TextInputType keyboardType = TextInputType.text,
    required VoidCallback onEdit,
    required VoidCallback onDone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit, color: isEditing ? Colors.green : Colors.orange),
              onPressed: isEditing ? onDone : onEdit,
            ),
          ],
        ),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          enabled: isEditing,
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;

class ReturnPolicyPage extends StatefulWidget {
  final String itemName;
  final String userid;
  final String itemPrice; // ✅ "ot_amt"
  final String itemImage; // ✅ "c_images"

  const ReturnPolicyPage({
    Key? key,
    required this.itemName,
    required this.userid,
    required this.itemPrice, // ✅ Pass "ot_amt"
    required this.itemImage, // ✅ Pass "c_images"
  }) : super(key: key);

  @override
  _ReturnPolicyPageState createState() => _ReturnPolicyPageState();
}

class _ReturnPolicyPageState extends State<ReturnPolicyPage> {
  final TextEditingController _otherReasonController = TextEditingController();
  String? selectedReason;
  bool showOtherTextField = false;

  final List<String> reasons = [
    'Defective or damaged item',
    'Wrong item received',
    'Item not as described',
    'Size or fit issue',
    'Other (please specify)',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  // ✅ Submit Return Request
  Future<void> _submitReturnRequest() async {
    print("🔍 User ID in ReturnPolicyPage: ${globals.userid}");
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a return reason!"), backgroundColor: Colors.red),
      );
      return;
    }

    String finalReason = selectedReason!;
    if (selectedReason == "Other (please specify)") {
      finalReason = _otherReasonController.text;
    }

    try {
      var url = Uri.parse("${globals.uriname}submit_return_request.php");
      var response = await http.post(url, body: {
        "user_id": globals.userid,
        "product_name": widget.itemName,
        "price": widget.itemPrice, // ✅ Now uses "ot_amt"
        "reason": finalReason,
        "product_image": widget.itemImage, // ✅ Now uses "c_images"
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "success") {
          // ✅ Store return request status locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool("return_sent_${widget.itemName}", true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Return request submitted successfully!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // ✅ Go back to orders page
        } else {
          throw Exception("Error: ${data["message"]}");
        }
      } else {
        throw Exception("Failed to connect! Status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Return Policy'),
        backgroundColor: Colors.orange,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Product Image
              SizedBox(
                width: 120,
                height: 140,
                child: Image.network(
                  widget.itemImage.isNotEmpty
                      ? widget.itemImage
                      : '${globals.baseImageUrl}0000000.jpg', // ✅ Uses "c_images"
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),
              // ✅ Item Name (Auto-filled)
              TextField(
                decoration: InputDecoration(
                  labelText: 'User Id',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                readOnly: true,
                controller: TextEditingController(text:globals.userid),
              ),
              const SizedBox(height: 20),
              // ✅ Item Name (Auto-filled)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                readOnly: true,
                controller: TextEditingController(text: widget.itemName.toUpperCase()),
              ),

              const SizedBox(height: 20),

              // ✅ Price (Auto-filled, now uses "ot_amt")
              TextField(
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                readOnly: true,
                controller: TextEditingController(text: "₹ ${widget.itemPrice}"),
              ),

              const SizedBox(height: 20),

              // ✅ Reason Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
                value: selectedReason,
                items: reasons.map((reason) {
                  return DropdownMenuItem<String>(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                    showOtherTextField = value == "Other (please specify)";
                  });
                },
              ),

              if (showOtherTextField)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _otherReasonController,
                    decoration: const InputDecoration(labelText: 'Enter your reason', border: OutlineInputBorder()),
                  ),
                ),

              const SizedBox(height: 30),

              // ✅ Submit Button
              ElevatedButton(
                onPressed: _submitReturnRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Return',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

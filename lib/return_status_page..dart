import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReturnStatusPage extends StatefulWidget {
  final String itemName;
  final String userId;

  const ReturnStatusPage({Key? key, required this.itemName, required this.userId}) : super(key: key);

  @override
  _ReturnStatusPageState createState() => _ReturnStatusPageState();
}

class _ReturnStatusPageState extends State<ReturnStatusPage> {
  String statusMessage = "Fetching return request status...";
  String productImage = "";
  String productName = "";
  String productPrice = "0";
  Color statusColor = Colors.black;
  IconData statusIcon = Icons.info_outline;

  @override
  void initState() {
    super.initState();
    fetchReturnStatus();
  }

  Future<void> fetchReturnStatus() async {
    try {
      final response = await http.post(
        Uri.parse('https://spk.amisys.in/android/php/v0/get_return_requests.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'user_id': widget.userId,
          'product_name': widget.itemName,
        },
      );

      print("📢 API Response: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          var returnData = data.firstWhere(
                (element) => element["product_name"].toString().toLowerCase() == widget.itemName.toLowerCase(),
            orElse: () => {},
          );

          if (returnData.isNotEmpty) {
            setState(() {
              productName = returnData["product_name"] ?? "Unknown Product";
              productPrice = returnData["price"] ?? "N/A";
              productImage = returnData["product_image"] ?? "";

              String status = returnData["status"].toString().toLowerCase();
              if (status == "pending") {
                statusMessage = "Your return request is Pending.";
                statusColor = Colors.orange;
                statusIcon = Icons.access_time;
              } else if (status == "accepted") {
                statusMessage = "Your return request has been Accepted.";
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == "rejected") {
                statusMessage = "Your return request has been Rejected.";
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              } else {
                statusMessage = "Unknown status.";
                statusColor = Colors.black;
                statusIcon = Icons.help_outline;
              }
            });
          } else {
            setState(() {
              statusMessage = "You have not sent any return request.";
              productImage = "";
              statusColor = Colors.black;
              statusIcon = Icons.error_outline;
            });
          }
        } else {
          setState(() {
            statusMessage = "You have not sent any return request.";
            productImage = "";
            statusColor = Colors.black;
            statusIcon = Icons.error_outline;
          });
        }
      } else {
        setState(() {
          statusMessage = "⚠ Error fetching return status!";
          productImage = "";
          statusColor = Colors.black;
          statusIcon = Icons.error_outline;
        });
      }
    } catch (e) {
      print("❌ Error fetching return status: $e");
      setState(() {
        statusMessage = "❌ Error fetching return status!";
        productImage = "";
        statusColor = Colors.black;
        statusIcon = Icons.error_outline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Return Request Status"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Product Image (Fix for Cropping Issue)
              if (productImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  child: Image.network(
                    productImage,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain, // Ensure full image is shown
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // ✅ Product Details in a Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 Product Name
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // 🔹 Product Price
                      Text(
                        "Price: ₹$productPrice",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Status Message (With Icon & Color)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                color: statusColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Back Button (New Color & Text Style)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
               // icon: const Icon(Icons.arrow_back, color: Colors.black), // ✅ Black icon
                label: const Text(
                  "   Back  ",
                  style: TextStyle(color: Colors.black), // ✅ Black text
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // ✅ Button background color
                  foregroundColor: Colors.black, // ✅ Ensures text color is black
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'globals.dart';
import 'globals.dart' as globals;

class AdminReturnRequestsPage extends StatefulWidget {
  const AdminReturnRequestsPage({Key? key}) : super(key: key);

  @override
  _AdminReturnRequestsPageState createState() =>
      _AdminReturnRequestsPageState();
}

class _AdminReturnRequestsPageState extends State<AdminReturnRequestsPage> {
  Map<String, List<dynamic>> groupedRequests = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReturnRequests();
  }

  // ✅ Function to set shadow color based on return status
  Color getStatusShadowColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.grey;
      case "accepted":
        return Colors.greenAccent;
      case "rejected":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // ✅ Fetch Return Requests from Database
  Future<void> fetchReturnRequests() async {
    try {
      final response = await http.get(Uri.parse('${globals.uriname}get_return_requests.php'));

      print("📢 API Response Status Code: ${response.statusCode}"); // Debugging
      print("📢 API Response Body: ${response.body}"); // Print API response data

      if (response.statusCode == 200) {
        List<dynamic> returnData = jsonDecode(response.body);

        if (returnData.isEmpty) {
          print("⚠ No return requests found!");
        }

        setState(() {
          groupedRequests.clear();
          for (var request in returnData) {
            String date = request['request_date'].split(' ')[0];
            groupedRequests.putIfAbsent(date, () => []).add(request);
          }
          isLoading = false; // ✅ Stop loading indicator
        });

        print("✅ Return request details updated successfully!");
      } else {
        print("❌ API Error: Failed to fetch return requests!");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching return requests: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ Handle Accept & Reject Actions
  Future<void> updateReturnRequestStatus(int requestId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${globals.uriname}update_return_status.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'request_id': requestId.toString(),
          'status': status,
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        print("✅ Admin Request Updated Successfully!");

        // ✅ Refresh admin return requests
        fetchReturnRequests();  // ✅ Correct function for admin side

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Return request $status successfully!"), backgroundColor: Colors.green),
        );
      } else {
        print("⚠ API Error: ${data["message"]}");
      }
    } catch (e) {
      print("❌ Error updating return request: $e");
    }
  }

  // ✅ Fetch Updated Order Details for User Side
  Future<void> fetchUpdatedOrderDetails() async {
    final response = await http.get(Uri.parse('${globals.uriname}get_order_details.php'));

    if (response.statusCode == 200) {
      print("✅ User order details updated successfully!");
    } else {
      print("⚠ Failed to refresh user orders!");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Admin Return Requests"), backgroundColor: Colors.orange),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(10),
        children: groupedRequests.keys.map((date) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Display Date Header
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Text(
                  DateFormat("dd-MM-yyyy").format(DateTime.parse(date)),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
              ),

              // ✅ List of Requests for this Date
              ...groupedRequests[date]!.map((request) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5, // ✅ Adds shadow
                  shadowColor: getStatusShadowColor(
                      request['status'].toString()), // ✅ Changes shadow color
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ✅ Left Column: Image (Fixed Size)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            request["product_image"] != null &&
                                request["product_image"].isNotEmpty
                                ? request["product_image"]
                                : '${globals.baseImageUrl}0000000.jpg',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ✅ Center Column: Product Name, Price, Reason
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "User: ${request['user_id']}",  // ✅ Display Username
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request['product_name'],
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${request['price']}",
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Reason: ${request['reason']}",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // ✅ Right Column: Accept & Reject Buttons
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                int requestId =
                                    int.tryParse(request['id'].toString()) ?? 0;
                                print(
                                    "Accept Button Pressed - Request ID: $requestId");
                                await updateReturnRequestStatus(
                                    requestId, "accepted");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                              ),
                              child: const Text(
                                "Accept",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () async {
                                int requestId =
                                    int.tryParse(request['id'].toString()) ?? 0;
                                print(
                                    "Reject Button Pressed - Request ID: $requestId");
                                await updateReturnRequestStatus(
                                    requestId, "rejected");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                              ),
                              child: const Text(
                                "Reject",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

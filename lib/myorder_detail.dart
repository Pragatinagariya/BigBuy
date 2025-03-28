import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'globals.dart' as globals;
import 'return_policy.dart';
import 'return_status_page..dart';
import 'shared_pref_helper.dart';
import 'dashboard.dart';
import 'cart.dart';
import 'mycart.dart';
import 'order.dart';
import 'myorders.dart';
import 'company.dart';
import 'category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderTransactionPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String orderDate;
  final String orderNo;
  final String deliverytype;
  final String userid;
  const OrderTransactionPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.orderDate,
    required this.orderNo,
    required this.deliverytype,
    required this.userid,
  });

  @override
  _OrderTransactionPageState createState() => _OrderTransactionPageState();
}

class _OrderTransactionPageState extends State<OrderTransactionPage> {
  List<dynamic>? orderDetails;
  bool isLoading = true;
  double totalAmount = 0.0;
  bool showCart = false;
  bool showOrder = false;
  int cartQty = 0;

  Map<String, List<dynamic>> returnRequests = {};
  List<dynamic> userOrders = [];


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

  String getButtonText(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Return Pending";
      case "accepted":
        return "Return Accepted";
      case "rejected":
        return "Return Rejected";
      default:
        return "Unknown";
    }
  }


  // ✅ Add the function here (Before `fetchUserTypeAndSetVisibility`)
  Future<bool> _checkReturnStatus(String itemName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("return_sent_$itemName") ?? false;
  }

  // ✅ Function to set card color based on return status

  // ✅ Fetch Updated Orders for User Side
  Future<void> fetchUpdatedOrders() async {
    try {
      final response = await http.get(Uri.parse('${globals.uriname}get_order_details.php'));

      if (response.statusCode == 200) {
        List<dynamic> orderData = jsonDecode(response.body); // ✅ Decode JSON
        print("✅ User order details updated successfully!");
        print("Response Body: $orderData"); // ✅ Debug API response

        setState(() {
          userOrders.clear();
          userOrders.addAll(orderData); // ✅ Update the UI with new data
        });

      } else {
        print("⚠ Failed to refresh user orders! Status: ${response.statusCode}");
        print("Error Response: ${response.body}"); // ✅ Debug error response
      }
    } catch (e) {
      print("❌ Error fetching user orders: $e");
    }
  }


  Future<void> fetchReturnRequests() async {
    try {
      final response = await http.get(Uri.parse('${globals.uriname}get_return_requests.php'));

      if (response.statusCode == 200) {
        List<dynamic> returnData = jsonDecode(response.body);
        print("✅ User Return Requests: $returnData");

        setState(() {
          for (var request in returnData) {
            for (var item in userOrders) {  // ✅ Use the global userOrders list
              if (item["IM_ItemName"] == request["product_name"]) {
                item["status"] = request["status"];  // ✅ Update status dynamically
              }
            }
          }
        });

        print("✅ Updated user-side return requests successfully!");
      } else {
        print("⚠ Failed to refresh return requests! Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching user return requests: $e");
    }
  }

  Future<void> fetchUserTypeAndSetVisibility() async {
    try {
      globals.usertype = await SharedPrefHelper.getUsertype() ??
          'default'; // Set a default if null
      setCartAndOrderVisibility();
    } catch (e) {
      print("Error fetching user type: $e"); // Log the error
    }
  }
  Future<void> fetchCartQty() async {
    String url = '${globals.uriname}cart_qty.php?c_custid=${globals.userid}';  // Use widget.userid dynamically
    print('API URL: $url');  // Debug print to check the URL

    try {
      final response = await http.post(Uri.parse(url), body: {
        'c_custid': globals.userid,  // Pass the logged-in user's ID
      });

      print('Response: ${response.body}');  // Debug print to check the response

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        if (responseBody.isNotEmpty && responseBody[0]['TotalQty'] != null) {
          setState(() {
            cartQty = int.parse(responseBody[0]['TotalQty'].toString());  // Convert string to int
          });
        } else {
          print('Failed to fetch cart quantity or TotalQty is null');
        }
      } else {
        print('Failed to load cart quantity. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cart quantity: $e');
    }
  }

  void setCartAndOrderVisibility() {
    if (globals.usertype == 'C') {
      setState(() {
        showCart = true;
        showOrder = true;
      });
    } else if (globals.usertype == 'A') {
      setState(() {
        showCart = false;
        showOrder = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
    fetchCartQty();
    fetchUserTypeAndSetVisibility();
    fetchReturnRequests();
    fetchUpdatedOrders();
  }
  int _selectedIndex = 0; // Track the selected index

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page based on the index
    switch (index) {
      case 0:
      // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(userid: widget.userid)),
        );
        break;
      case 1:
      // Navigate to Categories
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(userid: widget.userid)),
        );
        break;
      case 2:
      // Navigate to Cart
        if (showCart) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CartPagedetail(userid: globals.userid!)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrdersPage(userid: widget.userid)),
          );
        }
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompanyPage(userid: widget.userid)),
        );
        break;
// case 4:
//       // Open the barcode scanner page and await result
//       var res = await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
//       );
      case 4:
        if (showOrder) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrderMasterPage(userid: widget.userid)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    OrderMasterByCustId(userid: widget.userid)),
          );
        }

    // Handle the barcode scan result
    //    if (res is String) {
    //       await fetchAndNavigateToItemDetails(res); // Call the function to fetch item details
    //     }
    //     break;
    // }
    }
  }

  Future<void> fetchOrderDetails() async {
    String uri = "${globals.uriname}order_transaction.php?ot_id=${widget.customerId}";
    try {
      var res = await http.get(Uri.parse(uri));
      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response is List) {
          setState(() {
            orderDetails = response;
            calculateTotalAmount();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load data: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching order details: $e')),
      );
    }
  }

  void calculateTotalAmount() {
    totalAmount = orderDetails?.fold(0.0, (sum, item) {
      double amt = item['ot_amt'] != null
          ? double.tryParse(item['ot_amt'].toString()) ?? 0.0
          : 0.0;
      return (sum ?? 0.0) + amt;
    }) ??
        0.0;
  }
  Future<void> submitReturnRequest(Map<String, dynamic> item) async {
    try {
      var response = await http.post(
        Uri.parse('${globals.uriname}submit_return_requests.php'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'user_id': globals.userid.toString(),
          'product_name': item['IM_ItemName'],
          'price': item['c_mrp'].toString(),
          'reason': "User requested return",
          'product_image': item['c_images'] ?? "",
        },
      );

      var data = jsonDecode(response.body);
      if (data["status"] == "success") {
        print("✅ Return request submitted successfully!");

        // ✅ Update UI immediately
        setState(() {
          item['status'] = "pending"; // Change status dynamically
        });

        // ✅ Fetch updated return requests to sync with server
        fetchReturnRequests();
      } else {
        print("⚠ Failed to submit return request: ${data["message"]}");
      }
    } catch (e) {
      print("❌ Error submitting return request: $e");
    }
  }


  Future<File> _createPDF() async {
    if (orderDetails == null) {
      throw ArgumentError('Order details list is null');
    }

    final pdf = pw.Document();
    const int itemsPerPage = 20; // Number of items per page
    final orderDetailsLength = orderDetails!.length;
    final totalPages =
    (orderDetailsLength / itemsPerPage).ceil(); // Total pages

    // Iterate through the pages and generate each page
    for (int pageNum = 0; pageNum < totalPages; pageNum++) {
      final startIndex = pageNum * itemsPerPage;
      final endIndex = startIndex + itemsPerPage;
      final pageData = orderDetails!.sublist(
        startIndex,
        endIndex > orderDetailsLength ? orderDetailsLength : endIndex,
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Order ID: ${widget.orderNo ?? "N/A"}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Customer: ${widget.customerName ?? "N/A"}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${widget.orderDate ?? "N/A"}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Delivery Type: ${widget.deliverytype ?? "N/A"}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                // Table Header
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(2.5),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(1.5),
                    6: const pw.FlexColumnWidth(1.5),
                    7: const pw.FlexColumnWidth(1),
                    8: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(1),
                          child: pw.Text(
                            'No',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3.5),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(1.5),
                          child: pw.Text(
                            'Packing',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2.5),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Pcs/',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Cartoon',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'Company',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(1.5),
                          child: pw.Text(
                            'MRP',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(1.5),
                          child: pw.Text(
                            'Rate',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(1),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text(
                            'Amt',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: List.generate(10, (_) => pw.Divider()),
                    ),
                    // Table Body
                    for (int i = 0; i < pageData.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(1),
                            child: pw.Text('${startIndex + i + 1}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(3.5),
                            child: pw.Text(
                              '${pageData[i]["IM_ItemName"] ?? "N/A"}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(1.5),
                            child: pw.Text(
                              '${pageData[i]["c_packing"] ?? "N/A"}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2.5),
                            child: pw.Text(
                              '${pageData[i]["c_pcspercartoon"] ?? "N/A"}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              '${pageData[i]["c_company"] ?? "N/A"}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(1.5),
                            child: pw.Text(
                              (double.tryParse(
                                  pageData[i]["c_mrp"].toString()) ??
                                  0.0)
                                  .toStringAsFixed(pageData[i]["c_mrp"]
                                  .toString()
                                  .contains('.')
                                  ? 2
                                  : 2),
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(1.5),
                            child: pw.Text(
                              (double.tryParse(
                                  pageData[i]["ot_rate"].toString()) ??
                                  0.0)
                                  .toStringAsFixed(pageData[i]["ot_rate"]
                                  .toString()
                                  .contains('.')
                                  ? 2
                                  : 2),
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(1),
                            child: pw.Text(
                              '${pageData[i]["ot_qty"] ?? "0"}',
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              (double.tryParse(pageData[i]["ot_amt"].toString()) ?? 0.0).toStringAsFixed(pageData[i]["ot_amt"].toString().contains('.') ? 2 : 2),
                              style: const pw.TextStyle(fontSize: 9),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Total Amount
                if (pageNum == totalPages - 1) ...[
                  pw.Divider(),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Amount: ',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          ' ${(totalAmount.toString().contains('.') ? totalAmount.toStringAsFixed(2) : '$totalAmount.00')}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    final output = await getExternalStorageDirectory();
    final file = File('${output!.path}/OrderTransaction.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _sharePDF() async {
    try {
      final file =
      await _createPDF(); // Ensure _createPDF() returns the File object of the PDF
      if (file.existsSync()) {
        await Share.shareXFiles([XFile(file.path)]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF file does not exist.')),
        );
      }
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: Text(
          'Order - ${widget.customerName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Text(
          'Order is empty  😑',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ) // Sho
          : orderDetails != null && orderDetails!.isNotEmpty
          ? Column(
        children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: ListView.builder(
                  itemCount: orderDetails?.length ?? 0,
                  itemBuilder: (context, index) {
                    var item = orderDetails?[index];

                    if (item == null) {
                      return const SizedBox(); // ✅ Prevents crash if orderDetails is null
                    }

                    return Card(
                      shadowColor: getStatusShadowColor(item['status']?.toString() ?? "pending"), // ✅ Apply dynamic shadow color
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ First row: Image and Packaging
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ✅ Image
                                GestureDetector(
                                  onTap: () {
                                    // Handle image tap if necessary
                                  },
                                  child: SizedBox(
                                    width: 98,
                                    height: 110,
                                    child: Image.network(
                                      item["c_images"] != null && item["c_images"].isNotEmpty
                                          ? '${globals.baseImageUrl}${item["c_images"]}'
                                          : '${globals.baseImageUrl}0000000.jpg', // Fallback image
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // ✅ Expanded Columns for details
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // ✅ First Column: Packaging, Cartoon, Company, MRP
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Packing: ${item["c_packing"] ?? "N/A"}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Pcs/Cartoon: ${item["c_pcspercartoon"] ?? "N/A"}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item["c_company"] ?? "N/A"}',
                                              style: const TextStyle(fontSize: 14, color: Colors.red),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'MRP: ${item["c_mrp"] ?? "N/A"}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                      // ✅ Second Column: Rate, Qty, Update and Delete buttons
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                const Icon(Icons.currency_rupee, color: Colors.red, size: 16),
                                                Text(
                                                  '${item["ot_rate"] ?? "N/A"}',
                                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Qty: ${item["ot_qty"] ?? "N/A"}',
                                              style: const TextStyle(fontSize: 14, color: Colors.red),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                const Icon(Icons.currency_rupee, color: Colors.red, size: 16),
                                                Text(
                                                  '${item["ot_amt"] ?? "N/A"}',
                                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // ✅ Row for Item Name and Return Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item["IM_ItemName"] ?? "N/A"}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end, // ✅ Center align buttons
                                  children: [
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (item['status'] == null || item['status'].toString().isEmpty) {
                                            // ✅ No return request submitted → Navigate to Return Policy Page
                                            print("📢 Navigating to Return Policy Page for: ${item['IM_ItemName']}");

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ReturnPolicyPage(
                                                  itemName: item["IM_ItemName"] ?? "N/A",
                                                  userid: globals.userid.toString(),
                                                  itemPrice: item["ot_amt"]?.toString() ?? "N/A", // ✅ Fetch price
                                                  itemImage: item["c_images"] != null && item["c_images"].isNotEmpty
                                                      ? '${globals.baseImageUrl}${item["c_images"]}' // ✅ Fetch image
                                                      : '${globals.baseImageUrl}0000000.jpg', // ✅ Default image
                                                ),
                                              ),
                                            );
                                          } else if (item['status'].toString().toLowerCase() == "pending") {
                                            // ✅ If return request is already sent → Disable button
                                            print("⛔ Return request already pending.");
                                          } else {
                                            // ✅ Otherwise, send return request directly
                                            print("📢 Sending Return Request for: ${item['IM_ItemName']}");

                                            submitReturnRequest(item);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (item['status'] != null && item['status'].toString().toLowerCase() == "pending")
                                              ? Colors.grey // ✅ Disabled if return is pending
                                              : Colors.orange, // ✅ Enabled if return not requested
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          minimumSize: const Size(120, 40), // ✅ Button size
                                        ),
                                        child: Text(
                                          (item['status'] != null && item['status'].toString().toLowerCase() == "pending")
                                              ? "Pending" // ✅ Show "Pending" if request is sent
                                              : "Return", // ✅ Show "Return" if request is not sent
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6), // ✅ Add spacing between buttons

                                    // ✅ View Return Status Button (Always Clickable)
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          print("📢 Navigating to ReturnStatusPage for ${item["IM_ItemName"]}");

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ReturnStatusPage(
                                                itemName: item["IM_ItemName"] ?? "N/A",
                                                userId: globals.userId.toString(), // ✅ Pass userId
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange, // ✅ Button color
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          "View Return Status",
                                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),


                              ]
                            )
                          ],
                        ),
                      ),
                    );
                  },
                )
            ),
          ),
          // Total Amount at the Bottom
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orangeAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹ ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(child: Text('No Order Details Available')),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cartQty > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$cartQty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: showCart ? 'myCart' : 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Company',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: showOrder ? 'myOrder' : 'Order',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey, // Color for unselected items
        showUnselectedLabels: true, // Show labels for unselected items
        onTap: _onItemTapped,
      ),
    );
  }
}
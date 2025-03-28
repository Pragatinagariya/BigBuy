import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_return_requests.dart';
import 'globals.dart' as globals;
import 'shared_pref_helper.dart';
import 'dashboard.dart';
import 'cart.dart';
import 'company.dart';
import 'category.dart';
import 'order.dart';
import 'myorders.dart';
import 'mycart.dart';
class OrderDetailPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String quantity;
 final String userid;
  const OrderDetailPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.quantity,
    required this.userid,
  });

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  List<dynamic>? orderDetails;
  bool isLoading = true;
  int cartQty = 0;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
    fetchCartQty();
  }
   @override
void didChangeDependencies() {
  super.didChangeDependencies();
  fetchCartQty(); // Fetch cart quantity when dependencies change
}
@override
  void didChangeAppLifecycleState(AppLifecycleState state) {


    if (state == AppLifecycleState.resumed) {
      // Reinitialize speech to text when the app resumes
       fetchCartQty();

    }
  }
  Future<void> fetchCartQty() async {
  String url = '${globals.uriname}cart_qty.php?c_custid=${widget.userid}';  // Use widget.userid dynamically
  print('API URL: $url');  // Debug print to check the URL

  try {
    final response = await http.post(Uri.parse(url), body: {
      'c_custid': widget.userid,  // Pass the logged-in user's ID
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
      case 5:
        if (globals.usertype == 'A') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminReturnRequestsPage()),
          );
        }
        break;
      // Handle the barcode scan result
      //    if (res is String) {
      //       await fetchAndNavigateToItemDetails(res); // Call the function to fetch item details
      //     }
      //     break;
      // }
    }
  }

  Future<void> fetchOrderDetails() async {
    String uri = "${globals.uriname}orderdetails.php?c_custid=${widget.customerId}";
    try {
      var res = await http.get(Uri.parse(uri));
      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response is List) {
          setState(() {
            orderDetails = response; // Adjust if necessary to match your data structure
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

  Future<void> updateQuantity(int index) async {
    String uri = "${globals.uriname}cartupdate.php";

    try {
      var updatedQty = orderDetails![index]['c_qty'].toString();

      var res = await http.post(
        Uri.parse(uri),
        body: {
          'c_custid': orderDetails![index]['c_custid'].toString(),
          'c_itemid': orderDetails![index]['c_itemid'].toString(),
          'c_qty': updatedQty,
        },
      );

      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response['success'] == 'true') {
          setState(() {
            orderDetails![index]['c_qty'] = updatedQty;
          });
          showSuccessDialog('Quantity updated successfully!');
        } else {
          showErrorSnackBar('Failed to update quantity: ${response['message']}');
        }
      } else {
        showErrorSnackBar('Failed to update quantity: ${res.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error updating quantity: $e');
    }
  }

  void showUpdateQuantityDialog(int index) {
    TextEditingController quantityController = TextEditingController();
    quantityController.text = orderDetails![index]['c_qty'].toString();
    FocusNode quantityFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_){
    quantityFocusNode.requestFocus();
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: TextField(
            controller: quantityController,
            focusNode:quantityFocusNode,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter new quantity'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                setState(() {
                  orderDetails![index]['c_qty'] = int.parse(quantityController.text);
                });
                Navigator.of(context).pop();
                updateQuantity(index);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteRecord(int index) async {
    String uri = "${globals.uriname}cartdelete.php";
    try {
      var res = await http.post(
        Uri.parse(uri),
        body: {
          'c_custid': orderDetails![index]['c_custid'].toString(),
          'c_itemid': orderDetails![index]['c_itemid'].toString(),
        },
      );

      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        if (response['success'] == 'true') {
          setState(() {
            orderDetails!.removeAt(index);
          });
          showSuccessDialog('Record deleted successfully!');
        } else {
          showErrorSnackBar('Failed to delete record: ${response['message']}');
        }
      } else {
        showErrorSnackBar('Failed to delete record: ${res.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error deleting record: $e');
    }
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteRecord(index);
              },
            ),
          ],
        );
      },
    );
  }
bool showCart = false;
  bool showOrder = false;
  Future<void> fetchUserTypeAndSetVisibility() async {
    try {
      globals.usertype = await SharedPrefHelper.getUsertype() ??
          'default'; // Set a default if null
      setCartAndOrderVisibility();
    } catch (e) {
      print("Error fetching user type: $e"); // Log the error
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
  Widget build(BuildContext context) {
    // const String baseImageUrl = 'https://spk.amisys.in/images/';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cart - ${widget.customerName}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails != null && orderDetails!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ListView.builder(
                    itemCount: orderDetails!.length,
                    itemBuilder: (context, index) {
                      var item = orderDetails![index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: Image and Packaging
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Image
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
                                  // Expanded Columns for details
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // First Column: Packaging, Cartoon, Company, MRP
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Packaging
                                              Text(
                                                'Packing: ${item["c_packing"] ?? "N/A"}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              // Cartoon
                                              Text(
                                                'Pcs/Cartoon: ${item["c_pcspercartoon"] ?? "N/A"}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              // Company
                                              Text(
                                                '${item["c_company"] ?? "N/A"}',
                                                style: const TextStyle(fontSize: 14, color: Colors.red),
                                              ),
                                              const SizedBox(height: 2),
                                              // MRP
                                              Text(
                                                'MRP: ${item["c_mrp"] ?? "N/A"}',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        // Second Column: Rate, Qty, Update and Delete buttons
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              // Rate
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const Icon(
                                                    Icons.currency_rupee,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                  Text(
                                                    '${item["c_rate"] ?? "N/A"}',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              // Quantity
                                              Text(
                                                'Qty: ${item["c_qty"] ?? "N/A"}',
                                                style: const TextStyle(fontSize: 18,color: Colors.red),
                                              ),
                                              const SizedBox(height: 5),
                                              // Update and Delete buttons
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit),
                                                    onPressed: () {
                                                      showUpdateQuantityDialog(index);
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () {
                                                      showDeleteConfirmationDialog(index);
                                                    },
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
                              const SizedBox(height: 4),
                              Text(
                                '${item["c_itemname"] ?? "N/A"}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
          if (globals.usertype == 'A') // 🔹 Check if the logged-in user is Admin
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_return), // Return Icon
              label: 'Returns',
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
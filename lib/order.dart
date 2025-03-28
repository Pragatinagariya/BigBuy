import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_return_requests.dart';
import 'globals.dart' as globals;
import 'order_detail.dart'; 
import 'shared_pref_helper.dart';
import 'dashboard.dart';
import 'category.dart';
import 'company.dart';
import 'cart.dart';
import 'mycart.dart';
import 'myorders.dart';
class OrderMasterByCustId extends StatefulWidget {
  final String userid;
  const OrderMasterByCustId({required this.userid,super.key});

  @override
  _OrderMasterByCustIdState createState() => _OrderMasterByCustIdState();
}

class _OrderMasterByCustIdState extends State<OrderMasterByCustId> {
  List data = [];
bool showCart = false;
  bool showOrder = false;
  int cartQty = 0;
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
  void initState() {
    super.initState();
    fetchData();
    fetchCartQty();
    fetchUserTypeAndSetVisibility();
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
      case 5: // ✅ Admin's "Return Requests" Page
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

  Future<void> fetchData() async {
    String uri = "${globals.uriname}order_master_by_custid.php";
    try {
      var res = await http.get(Uri.parse(uri));
      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        print('Response: $response');

        if (response is List) {
          setState(() {
            data = response;
          });
        } else if (response is Map<String, dynamic> && response.containsKey('data')) {
          setState(() {
            data = response['data'];
          });
        } else {
          throw Exception('Invalid data format received');
        }
      } else {
        throw Exception('Failed to load data: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              fetchData(); // Retry fetching data
            },
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.orangeAccent,
         leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dashboard(userid: widget.userid)),
    );
  },
),
      ),
      body: data.isEmpty
          ? const  Center(
            child: Text(
              'Order is empty  😑',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )// Sho// Show loading spinner
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    // Navigate to the OrderTransactionPage on card tap
                    Navigator.push(
                      context,
                   MaterialPageRoute(
  builder: (context) => OrderTransactionByCustId(
    customerId: data[index]['om_id']?.toString() ?? 'N/A', // Ensure null safety
    customerName: data[index]['AM_AccName'] ?? 'N/A', // Ensure null safety
    orderNo: data[index]['om_no']?.toString() ?? 'N/A', // Ensure null safety
    orderDate: data[index]['om_date'] ?? 'N/A', // Ensure null safety
    deliverytype: data[index]['om_deliverytype'] ?? 'N/A', // Pass the customer name
    userid:widget.userid,
  ),
)

                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '${data[index]['om_no'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text('|', style: TextStyle(color: Colors.black)),
                                const SizedBox(width: 5),
                                Text(
                                  '${data[index]['om_date'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            // Customer Name
                            Text(
                              '${data[index]['AM_AccName'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            // SizedBox(height: 5),
                            // Quantity
                            Text(
                              'Qty: ${data[index]['om_totalqty'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            // Amount
                            Text(
                              'Amt: ₹${data[index]['om_amt'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                                
                            Text(
                            'Delivey: ${data[index]["om_deliverytype"]?? "N/A"}',
                                                    style:const TextStyle(color: Colors.black),
                                                    ),
                          
                          ],

                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'item_detail.dart';
import 'shared_pref_helper.dart';
import 'Login.dart';
import 'myorders.dart';
import 'dashboard.dart';
import 'category.dart';
import 'order.dart';
import 'cart.dart';
import 'cart_item_detail.dart';
import 'company.dart';
class CartPagedetail extends StatefulWidget {
// Data from the cart
  final String userid; // User ID
 // Total amount


  const CartPagedetail({super.key,  
    required this.userid,
    });

  @override
  _CartPagedetailState createState() => _CartPagedetailState();
}

class _CartPagedetailState extends State<CartPagedetail> {
  // List data = [];
  List<dynamic> currentItem = [];
String selectedOption = 'Pickup';
 double totalAmount = 0; // Declare as state variable
  int totalQuantity = 0;  // Declare as state variable
  int totalItems = 0;
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
  }     // Declare as state variable
  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCartQty();
    // calculateTotals();
    fetchUserTypeAndSetVisibility();
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
        setState(() {
          cartQty = 0;  // Set cartQty to 0 if no valid data is received
        });
      }
    } else {
      print('Failed to load cart quantity. Status code: ${response.statusCode}');
      setState(() {
        cartQty = 0;  // Set cartQty to 0 in case of a failed API response
      });
    }
  } catch (e) {
    print('Error fetching cart quantity: $e');
    setState(() {
      cartQty = 0;  // Set cartQty to 0 in case of an error
    });
  }
}


void calculateTotals() {
    totalAmount = 0;
    totalQuantity = 0;
    totalItems = currentItem .length; // Assume data is already populated

    for (var item in currentItem ) {
      var rate = double.tryParse(item["c_rate"]?.toString() ?? "0") ?? 0;
      var qty = int.tryParse(item["c_qty"]?.toString() ?? "0") ?? 0;
      totalAmount += rate * qty;
      totalQuantity += qty;
    }

    setState(() {}); // Update the UI
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
 Future<void> fetchData() async {
  String uri = "${globals.uriname}cart.php?c_custid=${widget.userid}";
  try {
    var res = await http.get(Uri.parse(uri));
    if (res.statusCode == 200) {
      var response = jsonDecode(res.body);
      print('Response: $response'); // Debugging to see the API response

      if (response is List) {
        setState(() {
          currentItem  = response;
        });
      } else if (response is Map<String, dynamic> &&
          response.containsKey('currentItem ')) {
        setState(() {
          currentItem  = response['currentItem '];
        });
      } else {
        showErrorSnackBar('Invalid data format received');
        return;
      }

      calculateTotals(); // Call after data is updated
    } else {
      showErrorSnackBar('Failed to load data: ${res.statusCode}');
    }
  } catch (e) {
    showErrorSnackBar('Error fetching data: $e');
  }
}
Future<double> fetchRate(String itemId, int qty) async {
  // Check if userid is set
  if (globals.userid == null) {
    print('Error: userid is not set. Please login first.');
    return 0.0;
  }

  // Debugging: Log input parameters
  print('Fetching rate with parameters:');
  print('Customer ID: ${globals.userid}');
  print('Item ID: $itemId');
  print('Quantity: $qty');

  final Uri url = Uri.parse('https://tlr.amisys.in/android/PHP/v0/get_rate_by_ratelist_2.php');

  try {
    final Map<String, String> queryParams = {
      'custid': globals.userid!,
      'itemid': itemId,
      'qty': qty.toString(),
    };

    final response = await http.get(
      url.replace(queryParameters: queryParams),
    ).timeout(Duration(seconds: 10));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> currentItem  = jsonDecode(response.body);

      if (currentItem ['status'] == 'success' && currentItem['rate'] != null) {
        double rate = double.parse(currentItem['rate'].toString());
        print('Rate fetched successfully: $rate');
        return rate;
      } else {
        print('Error in response: ${currentItem['message']}');
        throw Exception('Failed to fetch rate: ${currentItem['message']}');
      }
    } else {
      throw Exception('Failed to load rate, HTTP status: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception occurred: $e');
    return 0.0;
  }
}
Future<void> updateQuantity(int index) async {
  String uri = "${globals.uriname}cartupdate.php";

  try {
    var updatedQty = currentItem[index]['c_qty'].toString();

    var res = await http.post(
      Uri.parse(uri),
      body: {
        'c_custid': currentItem[index]['c_custid'].toString(),
        'c_itemid': currentItem[index]['c_itemid'].toString(),
        'c_qty': updatedQty,
      },
    );

    if (res.statusCode == 200) {
      var response = jsonDecode(res.body);
      if (response['success'] == 'true') {
        setState(() {
          currentItem[index]['c_qty'] = updatedQty;
        });

        // Fetch updated rate based on new quantity
        double newRate = await fetchRate( currentItem[index]['c_itemid'].toString(), int.parse(updatedQty));
        setState(() {
           currentItem[index]['c_rate'] = newRate;  // Assuming 'c_rate' is the key for the rate in your data
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
  quantityController.text =  currentItem[index]['c_qty'].toString();
  FocusNode quantityFocusNode = FocusNode();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    quantityFocusNode.requestFocus();
  });

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Update Quantity'),
        content: TextField(
          controller: quantityController,
          focusNode: quantityFocusNode,
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
                 currentItem[index]['c_qty'] = int.parse(quantityController.text);
              });
              Navigator.of(context).pop();
              updateQuantity(index);  // Backend update
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
    setState(() {
      // Optionally show a loading indicator or mark item as "deleting"
       currentItem
       [index]['isDeleting'] = true;
    });
    await fetchCartQty();

    var res = await http.post(
      Uri.parse(uri),
      body: {
        'c_custid':  currentItem[index]['c_custid'].toString(),
        'c_itemid':  currentItem[index]['c_itemid'].toString(),
      },
    );

    if (res.statusCode == 200) {
      var response = jsonDecode(res.body);
      if (response['success'] == 'true') {
        setState(() {
           currentItem.removeAt(index); // Update the UI
        });
         // Fetch updated cart quantity
        await fetchCartQty();
        showSuccessDialog('Record deleted successfully!');
      } else {
        showErrorSnackBar('Failed to delete record: ${response['message']}');
      }
    } else {
      showErrorSnackBar('Failed to delete record: ${res.statusCode}');
    }
  } catch (e) {
    showErrorSnackBar('Error deleting record: $e');
  } finally {
    setState(() {
       currentItem[index]['isDeleting'] = false; // Reset loading state
    });
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
               fetchCartQty();
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorSnackBar(String message) {
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
               // Fetch updated cart quantity
        fetchCartQty();
            },
          ),
        ],
      );
    },
  );
}
void confirmOrder() async {
  if ( currentItem.isEmpty || totalQuantity == 0 || totalAmount == 0) {
    showErrorSnackBar('Cart is empty or data is not yet loaded.');
    return;
  }

  String url = "${globals.uriname}order_insert.php";

  try {
    // Indicate loading (e.g., show a loading spinner)
    setState(() {
      // Optionally show a loading indicator
    });

    var response = await http.post(
      Uri.parse(url),
      body: {
        "om_custid": widget.userid,
        "om_totalqty": totalQuantity.toString(),
        "om_noofitems": totalItems.toString(),
        "om_amt": totalAmount.toStringAsFixed(2),
        "om_deliverytype": selectedOption,
      },
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      if (responseBody['success'] == 'true') {
        // Clear cart and reset totals
        setState(() {
           currentItem = [];
          totalAmount = 0;
          totalQuantity = 0;
          totalItems = 0;
        });

        showSuccessDialog('Order confirmed successfully!');
        await fetchCartQty();
      } else {
        showErrorSnackBar('Failed to confirm order: ${responseBody['message']}');
      }
    } else {
      showErrorSnackBar('Failed to confirm order. Status code: ${response.statusCode}');
    }
  } catch (e) {
    showErrorSnackBar('Error: $e');
  } finally {
  }
}

  @override
  Widget build(BuildContext context) {
    // const String baseImageUrl = 'https://spk.amisys.in/images/';
      // Calculate total amount
  double totalAmount = 0;
  int totalQuantity = 0;
  
  for (var item in  currentItem) {
    var rate = double.tryParse(item["c_rate"]?.toString() ?? "0") ?? 0;
    var qty = int.tryParse(item["c_qty"]?.toString() ?? "0") ?? 0;
    totalAmount += rate * qty;
    totalQuantity += qty;
  }
  int totalItems =   currentItem.length;
    return Scaffold(
          appBar: AppBar(
            
        backgroundColor: Colors.orange,
        leading:IconButton(icon:const Icon(Icons.arrow_back),
         onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dashboard(userid: widget.userid)),
    );
  },
        ),
          
        actions: [
    
          IconButton(
            icon: const Icon(Icons.logout), // Logout icon
            onPressed: () async {
              // Clear the saved login state
              await SharedPrefHelper.clearLoginState();

              // Navigate to the login page and clear the previous stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) =>
                        const LoginPage()), // Ensure LoginPage is imported and exists
                (Route<dynamic> route) =>
                    false, // This ensures all previous routes are removed
              );
            },
          ),
           IconButton(
            icon: const SizedBox(
              width: 40, // Set desired width
              height: 40, // Set desired height
              child:
                  Icon(Icons.assignment_turned_in, size: 30), // Adjust icon size
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        OrderMasterPage(userid: globals.userid!)),
              );
            },
          ),
          
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:  currentItem.isEmpty
                ? const Center(child: Text(' 🛒 Cart is empty 🛒'))
                : ListView.builder(
                    itemCount:  currentItem.length,
                    itemBuilder: (context, index) {
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CartItemDetailPage(
                                            productData:  currentItem[index],
                                            im_id:   currentItem[index]['c_itemid'].toString(), // Pass 
                                            userid: globals.userid ??
                                                '', // Pass the userid
                                            imageUrl:  currentItem[index]["c_images"] !=
                                                        null &&
                                                     currentItem[index]["c_images"]
                                                        .isNotEmpty
                                                ? '${globals.baseImageUrl}${ currentItem[index]["c_images"]}'
                                                : '${globals.baseImageUrl}0000000.jpg', // Fallback image
                                          ),
                                        ),
                                      ).then((updatedData) {
  if (updatedData != null) {
    setState(() {
      currentItem[index]['c_qty']= updatedData["c_qty"].toString(); // Ensure it's a string
      currentItem[index]['c_rate'] = updatedData["c_rate"].toString(); // Ensure it's a string
    });
  }
});
                                     
                                    },
                                    child: SizedBox(
                                      width: 98,
                                      height: 110,
                                      child: Image.network(
                                         currentItem[index]["c_images"] != null &&
                                                 currentItem[index]["c_images"]
                                                    .isNotEmpty
                                            ? '${globals.baseImageUrl}${ currentItem[index]["c_images"]}'
                                            : '${globals.baseImageUrl}0000000.jpg', // Fallback image
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),
                                  // Expanded Columns for details
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // First Column: Packaging, Cartoon, Company, MRP
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Packaging
                                              Text(
                                                //  contentPadding: EdgeInsets.zero,
                                                'Packing: ${ currentItem[index]["c_packing"] ?? "0"}',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              // Cartoon
                                              Text(
                                                'Pcs/Cartoon: ${ currentItem[index]["c_pcspercarton"] ?? "N/A"}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              // Company
                                              Text(
                                                '${ currentItem[index]["c_company"] ?? "N/A"}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              // MRP
                                              Text(
                                                'MRP: ${ currentItem[index]["c_mrp"] ?? "N/A"}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 9), // Space between columns
                                        // Second Column: Rate, Qty, Add to Cart button
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
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
                                                   '${ currentItem[index]["c_rate"] ?? "N/A"}',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 0),

                                               currentItem[index]["c_qty"] != null &&
                                                      int.tryParse( currentItem[index]
                                                              ["c_qty"]) !=
                                                          null &&
                                                      int.parse( currentItem[index]
                                                              ["c_qty"]) >
                                                          0
                                                  ? Text(
                                                      'Qty: ${ currentItem[index]["c_qty"]}',
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          color: Colors.red),
                                                    )
                                                  : const SizedBox.shrink(),
                                              // Empty widget when the quantity is not present

                                              const SizedBox(height: 2),

                                              // Update and Delete buttons
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  // Update button
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                   
                                                        color: Colors.black,
                                                        size:
                                                            18), 
                                                             padding:const EdgeInsets.only(left:40),// Smaller size
                                                    onPressed: () {
                                                      showUpdateQuantityDialog(
                                                          index); // Update quantity function
                                                    },
                                                  ),
                                                  // const SizedBox(
                                                  //     width:
                                                  //         2), // Space between buttons

                                                  // Delete button
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size:
                                                            18),
                                                            padding: const EdgeInsets.only(left: 20),  // Smaller size
                                                    onPressed: () {
                                                      showDeleteConfirmationDialog(
                                                          index); // Function to delete item
                                                    },
                                                  ),
                                                  // const SizedBox(height: 2),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Second row: Name
                              Text(
                                 currentItem[index]["c_itemname"] ?? "N/A",
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
          ),
    Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Row for total quantity and total number of items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total quantity text
                              
      // padding: const EdgeInsets.only(right: 40.0), // Shift "Total Items" slightly left
      Text(
        'Total Items: $totalItems',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    
    Padding(
    padding: const EdgeInsets.only(right: 20.0),

               child:   Text(
                    'Total Quantity: $totalQuantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
    ),
                  // Total number of items text
                     
        
                ],
              ),
              const SizedBox(height: 5), // Space between rows
  Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Pickup'),
                      leading: Radio<String>(
                        value: 'Pickup',
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Delivery'),
                      leading: Radio<String>(
                        value: 'Delivery',
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Row for total amount and confirm order button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total amount text
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Colors.orangeAccent,
                    ),
                    child: const Text(
                      'Confirm Order',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () {
                      confirmOrder();
                      setState(() {
                        // Fetch updated cart quantity after the order is confirmed
                        fetchCartQty();
                      });
                    },
                   ),
                  Text(
                    'Total Amt: ₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  // Confirm Order button
                  
                ],
              ),
            ],
          ),
        ),
      ],
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
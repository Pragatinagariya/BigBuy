import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'globals.dart' as globals;

class CartPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String im_id;
  final String userid;
  final String imageUrl;

  const CartPage({
    super.key,
    required this.productData,
    required this.im_id,
    required this.userid,
    required this.imageUrl,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  TextEditingController qtyController = TextEditingController();
  String cartMessage = '';
  double currentRate = 0.0;
 List<Map<String, dynamic>> rateSlabs = [];
  @override
  void initState() {
    super.initState();
    resetQuantity();
    currentRate = double.tryParse(widget.productData["im_rate"].toString()) ?? 0.0;
    int initialQty = int.tryParse(widget.productData["im_cartqty"]?.toString() ?? '0') ?? 0;
  qtyController.text = initialQty.toString();
  updateRateBasedOnQuantity(widget.im_id, initialQty);
  }

  void resetQuantity() {
    if (widget.productData["im_cartqty"] != null &&
        int.tryParse(widget.productData["im_cartqty"].toString()) != null) {
      qtyController.text = widget.productData["im_cartqty"].toString();
    } else {
      qtyController.text = ''; // Clear quantity when entering the page
    }
  }

 Future<void> updateRateBasedOnQuantity(String itemId, int qty) async {
  final Uri url = Uri.parse('${globals.uriname}get_rate_by_ratelist_2.php');

 try {
  print("Item ID: $itemId");
  print("Customer ID: ${widget.userid}");
  print("Quantity: $qty");

  final response = await http.get(
    url.replace(queryParameters: {
      'custid': widget.userid,
      'itemid': itemId,
      'qty': qty.toString(),
    }),
  );

  
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        if (data['status'] == 'success') {
          currentRate = data['rate'] != null ? double.parse(data['rate'].toString()) : 0.0;
          rateSlabs = (data['rate_slabs'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];
        } else {
          currentRate = 0.0; // Reset rate on failure
          rateSlabs = [];
        }
      });
    } else {
      throw Exception('Failed to load rate, status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching rate: $e');
    setState(() {
      currentRate = 0.0; // Reset rate on error
      rateSlabs = [];    // Clear slabs on error
    });
  }
}

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }
Widget _buildRateTable() {
  return rateSlabs.isEmpty
      ? const Text('No rate slabs available.')
      : Table(
          border: TableBorder.all(color: Colors.grey),
          children: [
            const TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Rate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...rateSlabs.map((slab) {
              final String fromQty = int.tryParse(slab['from_qty'].split('.')[0]).toString();
              final String toQty = slab['to_qty'] == 'Unlimited'
                  ? '>=$fromQty'
                  : int.tryParse(slab['to_qty'].split('.')[0]).toString();

              final String quantityRange = slab['to_qty'] == 'Unlimited'
                  ? toQty
                  : '$fromQty - $toQty';

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(quantityRange),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(slab['rate'].toString()),
                  ),
                ],
              );
            }),
          ],
        );
}


  
 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Cart Page"),
      backgroundColor: Colors.orange,
    ),
    resizeToAvoidBottomInset: true,
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewPage(
                        imageUrl: widget.imageUrl.isNotEmpty
                            ? widget.imageUrl
                            : '${globals.baseImageUrl}0000000.jpg',
                      ),
                    ),
                  );
                },
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        '${globals.baseImageUrl}0000000.jpg',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.productData["im_name"] ?? "N/A",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company: ${widget.productData["im_company"] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rate: $currentRate',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Packing: ${widget.productData["im_packing"] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cartoon: ${widget.productData["im_pcspercarton"] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MRP: ${widget.productData["im_mrp"] ?? "N/A"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildRateTable(), // Keep rate slab table always visible
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              cartMessage,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(
                labelText: 'Enter Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                int? qty = int.tryParse(value);
                if (qty != null) {
                  updateRateBasedOnQuantity(widget.im_id, qty);
                }
              },
            ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                 onPressed: () async {
  String qty = qtyController.text;

  // Validate quantity
    // Validate quantity
  if (qty.isEmpty || int.tryParse(qty) == null || int.parse(qty) <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid quantity greater than 0.')),
    );
    return;
  }

  // Validate rate
  if (currentRate <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rate must be greater than 0.')),
    );
    return;
  }

  String url = "${globals.uriname}addcart.php";

  try {
    var response = await http.post(
      Uri.parse(url),
      body: {
        'c_custid': widget.userid,
        'c_itemid': widget.im_id,
        'c_qty': qty,
        'c_rate': currentRate.toString(),
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        setState(() {
          cartMessage = 'Item added to cart: $qty';
        });
        
        // Update the cart message and show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to cart successfully!')),
        );

        // Return the updated data to the previous screen
        Navigator.pop(context, {
          "im_cartqty": int.tryParse(qty), // Updated quantity
          "im_rate": currentRate.toString(),          // Updated rate
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item to cart: ${jsonResponse['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed with status code: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
},
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("Add to Cart"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.all(16),
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

class PhotoViewPage extends StatelessWidget {
  final String imageUrl;

  const PhotoViewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zoom Image"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: PhotoViewGallery.builder(
          itemCount: 1,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: PageController(),
        ),
      ),
    );
  }
}

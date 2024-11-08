import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerPage extends StatefulWidget {
  final String email, language;

  ExpenseTrackerPage({required this.email, required this.language});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
  bool _isLoading = true;
  Map<String, double> monthlyTotalExpenses = {}; // To track total expenses per month

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('user_email', isEqualTo: widget.email)
          .where('status', isEqualTo: 'completed')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        for (var doc in snapshot.docs) {
          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
          String formattedMonth = _formatMonth(orderData['timestamp']);
          
          if (!groupedExpenses.containsKey(formattedMonth)) {
            groupedExpenses[formattedMonth] = [];
            monthlyTotalExpenses[formattedMonth] = 0.0; // Initialize monthly total
          }
          groupedExpenses[formattedMonth]!.add(orderData);

          // Calculate total monthly expenses
          monthlyTotalExpenses[formattedMonth] = 
              (monthlyTotalExpenses[formattedMonth] ?? 0.0) + (orderData['totalPrice'] as double? ?? 0.0);
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching expenses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatMonth(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('MMMM yyyy').format(date); // Format to "Month Year"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Expenses', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : groupedExpenses.isEmpty
                    ? Center(child: Text('No expenses available'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: groupedExpenses.keys.length,
                        itemBuilder: (context, index) {
                          final monthKey = groupedExpenses.keys.elementAt(index);
                          final expensesForMonth = groupedExpenses[monthKey]!;

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Month heading
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    monthKey,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Display all expenses for this month
                                        ...expensesForMonth.map((order) {
                                          // Ensure 'items' is a List of Maps
                                          final items = (order['items'] as List<dynamic>? ?? []);

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Display each item with its quantity and price
                                              ...items.map((item) {
                                                final quantity = item['quantity'] ?? 1; // Default to 1 if not provided
                                                final name = item['name'] ?? 'Unknown Item'; // Default name if not provided
                                                final price = item['price'] ?? 0.0; // Default price if not provided

                                                return Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.fastfood, color: Colors.grey),
                                                        SizedBox(width: 8),
                                                        Text(name),
                                                      ],
                                                    ),
                                                    Text('x$quantity'), // Display quantity as x2
                                                  ],
                                                );
                                              }).toList(),
                                              SizedBox(height: 4),
                                            ],
                                          );
                                        }).toList(),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                // Total Price for the month
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    'Total: ₹${monthlyTotalExpenses[monthKey]!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
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

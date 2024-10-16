import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerPage extends StatefulWidget {
  final String email;

  ExpenseTrackerPage({required this.email});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
  bool _isLoading = true;
  double _totalMonthlyExpenses = 0.0; // Store total monthly expenses

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('user_email', isEqualTo: widget.email) // Fetch only the orders of the current user
          .orderBy('timestamp', descending: true) // Ensure you have an index on user_email and timestamp
          .get();

      setState(() {
        // Group the expenses by date
        for (var doc in snapshot.docs) {
          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
          String formattedDate = _formatDate(orderData['timestamp']); // Format date

          if (!groupedExpenses.containsKey(formattedDate)) {
            groupedExpenses[formattedDate] = [];
          }
          groupedExpenses[formattedDate]!.add(orderData);

          // Calculate total monthly expenses
          _totalMonthlyExpenses += (orderData['totalPrice'] as double);
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

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('d MMMM yyyy').format(date); // Format date as '26 October 2024'
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Expenses', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Display total expenses of the month below the AppBar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Expenses: ₹${_totalMonthlyExpenses.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : groupedExpenses.isEmpty
                    ? Center(child: Text('No expenses available'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: groupedExpenses.keys.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedExpenses.keys.elementAt(index);
                          final expensesForDate = groupedExpenses[dateKey]!;

                          // Calculate total price for this date
                          double totalPriceForDate = expensesForDate.fold(
                              0.0, (sum, order) => sum + (order['totalPrice'] as double));

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Date heading with red background and white font, left-aligned
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
                                    dateKey,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left, // Left-aligned text
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Display all expenses for this date
                                        ...expensesForDate.map((order) {
                                          final items = List<String>.from(order['items']);
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Display each item
                                              ...items.map((item) => Row(
                                                    children: [
                                                      Icon(Icons.fastfood, color: Colors.grey), // Food icon
                                                      SizedBox(width: 8),
                                                      Text(item),
                                                    ],
                                                  )).toList(),
                                              SizedBox(height: 4),
                                            ],
                                          );
                                        }).toList(),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                // Total Price with red background and white font at the bottom
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
                                    'Total: ₹${totalPriceForDate.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right, // Right-aligned text
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

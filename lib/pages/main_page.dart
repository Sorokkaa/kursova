import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kursova/pages/sign_in.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  _ExpensesListScreenState createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  List<Map<String, dynamic>> expenses = [];
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? 'Невідомо';
          userEmail = userDoc['email'] ?? 'example@mail.com';
        });
      }

      QuerySnapshot expenseSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      setState(() {
        expenses = expenseSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    }
  }

  void _deleteExpense(int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final expenseId = expenses[index]['id'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      setState(() {
        expenses.removeAt(index);
      });
    }
  }

  void _editExpense(int index) {
    final expense = expenses[index];
    final itemNameController = TextEditingController(text: expense['item_name']);
    final quantityController = TextEditingController(text: expense['quantity'].toString());
    final priceController = TextEditingController(text: expense['price'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редагувати витрату'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemNameController,
                decoration: InputDecoration(labelText: 'Назва товару/послуги'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Кількість'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Ціна за одиницю'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedExpense = {
                  'item_name': itemNameController.text,
                  'quantity': int.tryParse(quantityController.text) ?? 0,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'total': (int.tryParse(quantityController.text) ?? 0) *
                      (double.tryParse(priceController.text) ?? 0.0),
                };

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final expenseId = expense['id'];
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('expenses')
                      .doc(expenseId)
                      .update(updatedExpense);

                  setState(() {
                    expenses[index] = updatedExpense..['id'] = expenseId;
                  });
                }

                Navigator.of(context).pop();
              },
              child: Text('Зберегти зміни'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExpenseDialog(
          onAddExpense: (newExpense) async {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final docRef = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('expenses')
                  .add(newExpense);

              setState(() {
                expenses.add(newExpense..['id'] = docRef.id);
              });
            }
          },
        );
      },
    );
  }


  void _deleteUserAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final expensesCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses');

        final expensesSnapshot = await expensesCollection.get();
        for (var doc in expensesSnapshot.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        await user.delete();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Помилка при видаленні акаунту: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              'Облік витрат',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            shadowColor: Colors.transparent,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName, style: TextStyle(fontSize: 18)),
              accountEmail: Text(userEmail),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.deepPurple),
              ),
            ),
            ListTile(
              leading: Icon(Icons.login, color: Colors.deepPurple),
              title: Text('Вийти з аккаунту', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignInScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Видалити аккаунт', style: TextStyle(fontSize: 16)),
              onTap: () {
                _showDeleteAccountDialog();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: expenses.isEmpty
            ? Center(child: Text('Немає доданих витрат'))
            : ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                title: Text(expense['item_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Кількість: ${expense['quantity']}, Ціна: ${expense['price']}, Сума: ${expense['total']}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editExpense(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteExpense(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: FloatingActionButton(
            onPressed: _showAddExpenseDialog,
            child: Icon(Icons.add, color: Colors.white),
            tooltip: 'Додати витрату',
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Видалити акаунт?'),
          content: Text('Це видалить ваш акаунт без можливості відновлення.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteUserAccount();
              },
              child: Text('Видалити акаунт'),
            ),
          ],
        );
      },
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddExpense;

  AddExpenseDialog({required this.onAddExpense});

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  double totalAmount = 0.0;

  void calculateTotal() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0.0;
    setState(() {
      totalAmount = quantity * price;
    });
  }

  void _saveExpense() {
    final newExpense = {
      'item_name': itemNameController.text,
      'quantity': int.tryParse(quantityController.text) ?? 0,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'total': totalAmount.toStringAsFixed(2),
    };
    widget.onAddExpense(newExpense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Додати витрату'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: itemNameController,
            decoration: InputDecoration(labelText: 'Назва товару/послуги'),
          ),
          TextField(
            controller: quantityController,
            decoration: InputDecoration(labelText: 'Кількість'),
            keyboardType: TextInputType.number,
            onChanged: (_) => calculateTotal(),
          ),
          TextField(
            controller: priceController,
            decoration: InputDecoration(labelText: 'Ціна за одиницю'),
            keyboardType: TextInputType.number,
            onChanged: (_) => calculateTotal(),
          ),
          SizedBox(height: 20),
          Text(
            'Сума: ${totalAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: _saveExpense,
          child: Text('Зберегти'),
        ),
      ],
    );
  }
}


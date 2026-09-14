import 'package:flutter/material.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../home/presentation/home_screen.dart';

class CategoryScreen extends StatefulWidget{
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}
class _CategoryScreenState extends State<CategoryScreen>{
final formkey = GlobalKey<FormState>();
TextEditingController categorySelectedController = TextEditingController();
TextEditingController categoryIconController = TextEditingController();


@override
  void dispose(){
  categoryIconController.dispose();
  categorySelectedController.dispose();
  super.dispose();

}

@override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Category",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),

        ),

      ),
      body: SafeArea(
          child:SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                )
            ),
          ) ),
    );
  }
}
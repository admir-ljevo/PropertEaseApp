import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/screens/property_detail_screen.dart';
import 'package:provider/provider.dart';

import '../widgets/master_screen.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});

  @override
  State<PropertyListWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  late PropertyProvider _propertyProvider;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _propertyProvider = context.read<PropertyProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title_widget: Text("Property List"),
      child: Container(
        child: Column(children: [
          Text("Test"),
          SizedBox(
            height: 8,
          ),
          ElevatedButton(
              onPressed: () async {
                //  Navigator.of(context).pop();
                var properties = await _propertyProvider.getProperties();
                print("Data: ${properties.result[0].name}");
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => PropertyDetailScreen(),
                //   ),
                // );
              },
              child: Text("Get Properties")),
        ]),
      ),
    );
  }
}

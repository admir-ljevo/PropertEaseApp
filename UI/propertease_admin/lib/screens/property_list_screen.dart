import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/screens/property_detail_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';
import '../widgets/master_screen.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});

  @override
  State<PropertyListWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  late PropertyProvider _propertyProvider;
  late PhotoProvider _photoProvider;
  SearchResult<Property>? result;
  TextEditingController _nameController = TextEditingController();

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _propertyProvider = context.read<PropertyProvider>();
    _photoProvider = context.read<PhotoProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
        title_widget: const Text("Property List"),
        child: Container(
          child: Column(children: [_buildSearch(), _buildDataListView()]),
        ));
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        TextField(
          decoration: InputDecoration(
              labelText: 'Naziv', prefixIcon: Icon(Icons.search)),
          controller: _nameController,
        ),
        const SizedBox(
          height: 8,
        ),
        ElevatedButton(
            onPressed: () async {
              //  Navigator.of(context).pop();
              var properties = await _propertyProvider
                  .getFiltered(filter: {'name': _nameController.text});
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => PropertyDetailScreen(),
              //   ),
              // );
              setState(() {
                result = properties;
              });
            },
            child: const Text("Search")),
      ]),
    );
  }

  Widget _buildDataListView() {
    return Expanded(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Expanded(
                child: Text(
                  "Id",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Name",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Average rating",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Daily price",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Monthly price",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  "Image",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
          rows: result?.result
                  .map((Property e) => DataRow(
                          onSelectChanged: (selected) => {
                                if (selected == true)
                                  {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PropertyDetailScreen(
                                                  property: e,
                                                )))
                                  }
                              },
                          cells: [
                            DataCell(Text(e.id?.toString() ?? "/")),
                            DataCell(Text(e.name ?? "/")),
                            DataCell(Text(formatNumber(e.dailyPrice) ?? "/")),
                            DataCell(Text(formatNumber(e.monthlyPrice) ?? "/")),
                            DataCell(Text(e.averageRating?.toString() ?? "/")),
                            DataCell(
                              FutureBuilder<Image>(
                                future: _photoProvider
                                    .getFirstImageByPropertyId(e.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else {
                                    return snapshot.data!;
                                  }
                                },
                              ),
                            ),
                          ]))
                  .toList() ??
              [],
        ),
      ),
    );
  }
}

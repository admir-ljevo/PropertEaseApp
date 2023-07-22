import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

import '../models/property.dart';

class PropertyDetailScreen extends StatefulWidget {
  Property? property;
  PropertyDetailScreen({super.key, this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  SearchResult<PropertyType>? propertyTypeResult;

  Map<String, dynamic> _initialValue = {};
  late PropertyTypeProvider _propertyTypeProvider;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    initForm();
  }

  @override
  void initState() {
    super.initState();
    _initialValue = {
      'name': widget.property?.name,
      'address': widget.property?.address,
    };

    // if (widget.property != null) {
    //   setState(() {
    //     _formKey.currentState?.patchValue({'name': widget.property?.name});
    //   });
    // }
  }

  Future initForm() async {
    propertyTypeResult = await _propertyTypeProvider.get();
    print("Vrste nekretnina: $propertyTypeResult");
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title: widget.property?.name ?? "Property details",
      child: FormBuilder(
          key: _formKey,
          initialValue: _initialValue,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                          decoration: const InputDecoration(labelText: 'Naziv'),
                          name: 'name'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: FormBuilderTextField(
                      decoration: const InputDecoration(labelText: 'Adresa'),
                      name: 'address',
                    )),
                  ],
                ),
              )
            ],
          )),
    );
  }
}

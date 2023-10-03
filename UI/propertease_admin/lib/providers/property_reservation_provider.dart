import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class PropertyReservationProvider extends BaseProvider<PropertyReservation> {
  PropertyReservationProvider() : super("PropertyReservation") {}

  @override
  PropertyReservation fromJson(data) {
    // TODO: implement fromJson
    return PropertyReservation.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(PropertyReservation data) {
    return data.toJson();
  }
}

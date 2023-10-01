import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:provider/provider.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import '../../models/photo.dart';
import '../../models/property.dart';

class PropertyDetailScreen extends StatefulWidget {
  Property? property;
  PropertyDetailScreen({super.key, this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  SearchResult<PropertyType>? propertyTypeResult;
  int currentImageIndex = 0;
  int maxImagesToShow = 5;
  int startIndex = 5;
  // Add a property to store the list of images
  List<Photo> images = [];
  String? displayedImageUrl;
  // Create a method to fetch images
  void fetchImages() async {
    // Get the photo provider from the context
    final photoProvider = context.read<PhotoProvider>();

    // Call your getImagesByProperty function
    final propertyId =
        widget.property?.id; // Replace with the actual property ID
    final fetchedImages = await photoProvider.getImagesByProperty(propertyId);

    // Update the state with the fetched images
    setState(() {
      images = fetchedImages;
      if (images.isNotEmpty) displayedImageUrl = images[0].url;
    });
  }

  Map<String, dynamic> _initialValue = {};
  late PropertyTypeProvider _propertyTypeProvider;

  @override
  void didChangeDependencies() {
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
      'images': images,
      'city': widget.property?.city?.name,
    };
  }

  Future initForm() async {
    propertyTypeResult = await _propertyTypeProvider.get();
    fetchImages();
  }

  void goToPreviousImage() {
    if (currentImageIndex > 0) {
      setState(() {
        currentImageIndex--;
        displayedImageUrl = images[currentImageIndex].url;
      });
    }
  }

  void goToNextImage() {
    if (currentImageIndex < images.length - 1) {
      setState(() {
        currentImageIndex++;
        displayedImageUrl = images[currentImageIndex].url;
      });
    }
  }

  Widget buildImageRow(
      int currentImageIndex, String displayedImageUrl, List<Photo> images) {
    List<Widget> imageWidgets = [];
    int rangeFrom = 2, rangeTo = 2;
    if (currentImageIndex == 0) {
      rangeFrom = 0;
      rangeTo = 4;
    }

    if (currentImageIndex == 1) {
      rangeFrom = 1;
      rangeTo = 3;
    }
    if (currentImageIndex >= 2 && currentImageIndex >= images.length - 3) {
      rangeFrom = 2;
      rangeTo = 2;
    }
    if (currentImageIndex > 2 && currentImageIndex == images.length - 2) {
      rangeFrom = 3;
      rangeTo = 1;
    }
    if (currentImageIndex > 2 && currentImageIndex == images.length - 1) {
      rangeFrom = 4;
      rangeTo = 0;
    }
    for (int i = currentImageIndex - rangeFrom;
        i <= currentImageIndex + rangeTo;
        i++) {
      if (i >= 0 && i < images.length) {
        imageWidgets.add(
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Opacity(
              opacity: images[i].url == displayedImageUrl ? 0.3 : 1.0,
              child: Image.network(
                "https://localhost:44340/${images[i].url}",
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: imageWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20.0,
              ), // Add top padding for vertical alignment
              child: Text(
                widget.property?.name ?? '', // Display the property name here
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text(
                "${widget.property?.city?.name ?? ''}, ${widget.property?.address ?? ''}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Stack(
              children: [
                images.isNotEmpty
                    ? Container(
                        constraints: const BoxConstraints(
                          maxWidth: 700, // Set the maximum width here
                          maxHeight: 300, // Set the maximum height here
                        ),
                        child: Stack(
                          children: [
                            // Container for Left Arrow

                            // Container for Image
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth:
                                      700, // Set the maximum width for the image
                                  maxHeight:
                                      300, // Set the maximum height for the image
                                ),
                                child: Image.network(
                                  "https://localhost:44340/${images[currentImageIndex].url}",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: goToPreviousImage,
                                color: Colors.blue,
                                iconSize: 32, // Adjust the icon size here
                              ),
                            ),
                            // Container for Right Arrow
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                color: Colors.blue,
                                onPressed: goToNextImage,
                                iconSize: 32, // Adjust the icon size here
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image.asset(
                        "assets/images/house_placeholder.jpg",
                        height: 300,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
              ],
            ),
            const Divider(
              color: Colors.blue,
              thickness: 1.0,
              height: 20.0,
            ),
            Container(
              color: const Color.fromARGB(255, 246, 246, 246),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (displayedImageUrl != null)
                    buildImageRow(currentImageIndex, displayedImageUrl!, images)
                ],
              ),
            ),
            const Divider(
              color: Colors.blue,
              thickness: 1.0,
              height: 20.0,
            ),
            // Centered Text widget at the bottom
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    visible: widget.property?.isDaily ==
                        true, // Show if isDaily is true
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.black
                          ], // Gradient colors
                          begin: Alignment.topCenter, // Gradient start position
                          end: Alignment.bottomCenter, // Gradient end position
                        ),
                        borderRadius: BorderRadius.circular(
                            12.0), // Adjust the radius as needed
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 10.0,
                        ),
                        child: Text(
                          '${widget.property?.dailyPrice?.round()} KM/ Dan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Visibility(
                    visible: widget.property?.isMonthly ==
                        true, // Show if isDaily is true
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue,
                            Colors.black
                          ], // Gradient colors
                          begin: Alignment.topCenter, // Gradient start position
                          end: Alignment.bottomCenter, // Gradient end position
                        ),
                        borderRadius: BorderRadius.circular(
                            12.0), // Adjust the radius as needed
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 10.0,
                        ),
                        child: Text(
                          '${widget.property?.monthlyPrice?.round()} KM/ Mjesec',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // Adjust the alignment as needed
                  children: [
                    // Item 1
                    const SizedBox(width: 45),
                    Column(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.bed,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                Text(
                                  'Sobe: ${widget.property?.numberOfRooms}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Item 2
                    Column(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.bathtub,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                Text(
                                  'Kupatila: ${widget.property?.numberOfBathrooms}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Item 3
                    Column(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.garage,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                Text(
                                  'Garaže: ${widget.property?.garageSize}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Item 4
                    Column(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.square_foot,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                Text(
                                  'Površina: ${widget.property?.squareMeters} m2',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Item 5
                    Column(
                      children: [
                        Container(
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.square_foot,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Add spacing between icon and text
                                Text(
                                  'Dvorište: ${widget.property?.gardenSize} m2',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Item 6
                    Column(
                      children: [
                        Container(
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.black
                                ], // Gradient colors
                                begin: Alignment
                                    .topCenter, // Gradient start position
                                end: Alignment
                                    .bottomCenter, // Gradient end position
                              ),
                              borderRadius: BorderRadius.circular(
                                  12.0), // Adjust the radius
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white, // Icon color
                                    size: 32, // Icon size
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ), // Add spacing between icon and text
                                  Text(
                                    widget.property?.isAvailable == true
                                        ? 'Dostupno: Da' // Display this text if isAvailable is true
                                        : 'Dostupno: Ne', // Display this text if isAvailable is false
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(width: 45),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              color: const Color.fromARGB(255, 242, 251, 255),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Namješteno: ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.isFurnished ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Klima',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasAirCondition ??
                                                false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Alarm:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasAlarm ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Video nadzor:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasSurveilance ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'WiFi:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasWiFi ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Centralno grijanje:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasOwnHeatingSystem ??
                                                false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TV',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasCableTV ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Kablovska:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasCableTV ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Parking mjesta:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        '${widget.property?.parkingSize}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Balkon:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasBalcony ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Bazen:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Icon(
                                        widget.property?.hasPool ?? false
                                            ? (Icons.check)
                                            : (Icons.remove),
                                        color: Colors.white, // Icon color
                                        size: 32, // Icon size
                                      ),
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.black
                                    ], // Gradient colors
                                    begin: Alignment
                                        .topCenter, // Gradient start position
                                    end: Alignment
                                        .bottomCenter, // Gradient end position
                                  ),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Adjust the radius
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Max osoba:',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        '${widget.property?.capacity}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      )
                                      // Add spacing between icon and text
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 200,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.black
                              ], // Gradient colors
                              begin: Alignment
                                  .topCenter, // Gradient start position
                              end: Alignment
                                  .bottomCenter, // Gradient end position
                            ),
                            borderRadius: BorderRadius.circular(
                                12.0), // Adjust the radius
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Detaljan opis',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  Icons.info,
                                  color: Colors.white, // Icon color
                                  size: 32, // Icon size
                                ),
                                // Add spacing between icon and text
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black, // Border color
                              width: 1.0, // Border width
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${widget.property?.description}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        // Add other widgets as needed in the Column
                      ],
                    ),
                    const SizedBox(
                      width: 30,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

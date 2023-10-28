import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:propertease_client/providers/image_provider.dart';
import 'package:provider/provider.dart';

import '../../models/photo.dart';
import '../../models/property.dart';

class PropertyDetailsScreen extends StatefulWidget {
  Property? property;

  PropertyDetailsScreen({super.key, this.property});

  @override
  State<StatefulWidget> createState() => PropertyDetailsScreenState();
  // TODO: implement createState
}

class PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late PhotoProvider _photoProvider;
  int currentImageIndex = 0;
  int maxImagesToShow = 5;
  int startIndex = 5;
  String? displayedImageBytes;
  TextEditingController _descriptionController = TextEditingController();
  // Add a property to store the list of images
  List<Photo> images = [];
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _photoProvider = context.read<PhotoProvider>();
    _descriptionController.text = widget.property?.description ?? '';

    fetchImages();
  }

  Future initForm() async {
    fetchImages();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _photoProvider = context.read<PhotoProvider>();
    _descriptionController.text = widget.property?.description ?? '';
    fetchImages();
  }

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
      if (images.isNotEmpty) displayedImageBytes = images[0].imageBytes;
    });
  }

  void goToPreviousImage() {
    if (currentImageIndex > 0) {
      setState(() {
        currentImageIndex--;
        displayedImageBytes = images[currentImageIndex].imageBytes;
      });
    }
  }

  void goToNextImage() {
    if (currentImageIndex < images.length - 1) {
      setState(() {
        currentImageIndex++;
        displayedImageBytes = images[currentImageIndex].imageBytes;
      });
    }
  }

  Widget buildImageRow(
      int currentImageIndex, String displayedImageUrl, List<Photo> images) {
    return Container(
      height: 120, // Set the desired height for the image row
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: Opacity(
              opacity: image.imageBytes == displayedImageUrl ? 0.3 : 1.0,
              child: Image.memory(
                base64Decode(image.imageBytes!),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Property details")),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  widget.property?.name ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (images.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 700,
                        maxHeight: 300,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 700,
                                maxHeight: 300,
                              ),
                              child: Image.memory(
                                base64Decode(
                                    images[currentImageIndex].imageBytes!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Center(
                            child: Row(
                              children: [
                                Positioned(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: goToPreviousImage,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Positioned(
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: goToNextImage,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Image.asset(
                      "assets/images/house_placeholder.jpg",
                      height: 300,
                      width: 300,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
              const Divider(
                color: Colors.blue,
                thickness: 2,
              ),
              if (images.isNotEmpty)
                SingleChildScrollView(
                  child: buildImageRow(
                      currentImageIndex, displayedImageBytes!, images),
                ),
              const Divider(
                color: Colors.blue,
                thickness: 2,
              ),
              Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                    10), // Adjust the radius as needed
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Renter: ${widget.property?.applicationUser?.userName}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                    10), // Adjust the radius as needed
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Property type: ${widget.property?.propertyType?.name ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.house,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                    10), // Adjust the radius as needed
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "City: ${widget.property?.city?.name ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_city,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                    10), // Adjust the radius as needed
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Address: ${widget.property?.address ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.location_pin,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(
                                    10), // Adjust the radius as needed
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.property!.isMonthly!)
                                      Text(
                                        "Price: ${widget.property?.monthlyPrice!}BAM/Month",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    if (widget.property!.isDaily!)
                                      Text(
                                        "Price: ${widget.property?.monthlyPrice!}BAM/Day",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ]),
              const Divider(
                color: Colors.blue,
                thickness: 2,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Rooms:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.numberOfRooms ?? ''}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.bed,
                            )
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Bathrooms:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.numberOfBathrooms ?? ''}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.bathtub,
                            )
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Garages:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.numberOfGarages ?? ''}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.garage,
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Parking size:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.parkingSize ?? ''}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.local_parking,
                            )
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Square meters:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.squareMeters ?? ''} m2",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.aspect_ratio,
                            )
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Max guests:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.capacity ?? ''}",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.man,
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Garden size:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.property?.gardenSize ?? ''}m2",
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Icon(
                              Icons.aspect_ratio,
                            )
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Available:",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: [
                            if (widget.property!.isAvailable!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.isAvailable! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(
                thickness: 2,
                color: Colors.blue,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Furnished:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.isFurnished!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.isFurnished! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Air condition:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasAirCondition!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasAirCondition! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Alarm:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasAlarm!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasAlarm! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Surveilance:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasSurveilance!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasSurveilance! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Heating: ",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasOwnHeatingSystem!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasOwnHeatingSystem! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Wi-fi:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasWiFi!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasWiFi! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "TV:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasTV!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasTV! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Cable TV:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasCableTV!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasCableTV! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Parking:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasParking!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasParking! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Pool:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasPool!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasPool! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Balcony:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasBalcony!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasBalcony! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(children: [
                            const Text(
                              "Garage:",
                              style: TextStyle(fontSize: 18),
                            ),
                            if (widget.property!.hasGarage!)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            if (widget.property!.hasGarage! == false)
                              const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              )
                          ]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 2, color: Colors.blue),
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          "Detailed information",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      minLines: 5,
                      maxLines:
                          12, // Set the minimum and maximum number of lines
                      controller: _descriptionController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue, // Set the border color
                            width: 2.0, // Set the border width
                          ),
                          borderRadius: BorderRadius.circular(
                              20.0), // Set the border radius
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white, // Set the button background color
                          ),
                          child: const Column(
                            children: [
                              Text(
                                "Compare",
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 20),
                              ), // Set text color
                              Row(
                                children: [
                                  Icon(
                                    Icons.house,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                  Icon(
                                    Icons.swap_horiz,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                  Icon(
                                    Icons.house,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )),
                    ),
                    Expanded(
                        child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.black,
                            Colors.blue
                          ], // Define gradient colors
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          primary: Colors
                              .transparent, // Make the button background transparent
                          elevation: 0, // Remove button elevation (shadow)
                        ),
                        child: const Column(
                          children: [
                            Text(
                              "Add rating",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.black,
                            Colors.blue
                          ], // Define gradient colors
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          primary: Colors
                              .transparent, // Make the button background transparent
                          elevation: 0, // Remove button elevation (shadow)
                        ),
                        child: const Column(
                          children: [
                            Text(
                              "Ask a question",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Icon(
                              Icons.message,
                              color: Colors.white,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Expanded(
                          child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue, // Set the border color
                            width: 2.0, // Set the border width
                          ),
                          borderRadius: BorderRadius.circular(
                              20.0), // Set the border radius
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white, // Set the button background color
                          ),
                          child: const Column(
                            children: [
                              Text(
                                "Reservation",
                                style:
                                    TextStyle(color: Colors.blue, fontSize: 20),
                              ), // Set text color
                              Row(
                                children: [
                                  Icon(
                                    Icons.house,
                                    color: Colors.black,
                                    size: 40,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:provider/provider.dart';

class UserDetailScreen extends StatefulWidget {
  ApplicationUser? user;

  UserDetailScreen({super.key, this.user});

  @override
  State<StatefulWidget> createState() => UserDetailScreenState();
}

class UserDetailScreenState extends State<UserDetailScreen> {
  late UserProvider _userProvider;
  TextEditingController _biographyController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
    _biographyController.text = widget.user?.person?.biography ?? '';
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    _biographyController.text = widget.user?.person?.biography ?? '';
  }

  String formatBirthDate(DateTime? birthDate) {
    if (birthDate != null) {
      final dateFormat = DateFormat('MM-dd-yyyy');
      return dateFormat.format(birthDate);
    } else {
      return 'N/A';
    }
  }

  Widget buildUserRoleRow(ApplicationUser user) {
    if (user.userRoles?[0].role?.roleLevel == 2) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info, // Replace this with the icon of your choice
                  color: Colors.blue, // Customize the icon color
                  size: 24.0, // Adjust the icon size as needed
                ),
                SizedBox(width: 5), // Add spacing between the icon and the text
                Text(
                  'Employee information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Adjust the font size as needed
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Position',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                  width: 200.0,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  padding: const EdgeInsets.all(10.0),
                                  margin: const EdgeInsets.all(10.0),
                                  alignment: Alignment
                                      .center, // Set the fixed width you desire
                                  child: Text(
                                    widget.user?.person?.position == 0
                                        ? 'Client'
                                        : widget.user?.person?.position == 1
                                            ? 'Renter'
                                            : '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Qualifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                  width: 200.0,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                    ),
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  padding: const EdgeInsets.all(10.0),
                                  margin: const EdgeInsets.all(10.0),
                                  alignment: Alignment
                                      .center, // Set the fixed width you desire
                                  child: Text(
                                    widget.user?.person?.qualifications ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Date of employment (MM-dd-yyyy)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                width: 200.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.all(10.0),
                                margin: const EdgeInsets.all(10.0),
                                alignment: Alignment.center,
                                child: Text(
                                  formatBirthDate(
                                      widget.user?.person?.dateOfEmployment),
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Work experience',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            width: 200.0,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            margin: const EdgeInsets.all(10.0),
                            alignment: Alignment.center,
                            child: widget.user?.person?.workExperience == true
                                ? const Icon(
                                    Icons.check, // Icon for true condition
                                    color: Colors.green, // Customize the color
                                    size: 30.0, // Customize the size
                                  )
                                : const Icon(
                                    Icons.clear, // To use the clear icon
                                    color: Colors.red, // Customize the color
                                    size: 30.0, // Customize the size
                                  ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Pay',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            width: 200.0,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            margin: const EdgeInsets.all(10.0),
                            alignment: Alignment.center,
                            child: Text(
                              '${widget.user?.person?.pay.toString()} BAM' ??
                                  '',
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Biography',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // TextArea Widget
                          Container(
                            width:
                                800.0, // Increase the width value to make it wider
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            padding: const EdgeInsets.all(10.0),
                            margin: const EdgeInsets.all(10.0),
                            alignment: Alignment.center,
                            child: TextFormField(
                              maxLines: 30,
                              minLines: 8,
                              enabled: false,
                              controller: _biographyController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: 'Enter additional information',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Divider(
              thickness: 2,
              color: Colors.grey,
            ),
          ],
        ),
      );
    } else {
      // User has no role, return an empty Row
      return const Row();
    }
  }

  Widget buildUserDetailsRow() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600, // Set the maximum width for the image
              maxHeight: 400, // Set the maximum height for the image
            ),
            child: widget.user?.person?.profilePhoto != null
                ? Image.network(
                    "https://localhost:44340/${widget.user?.person?.profilePhoto}",
                    fit: BoxFit.cover,
                  )
                : Image.asset("assets/images/user_placeholder.jpg",
                    fit: BoxFit.cover),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'First name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.firstName ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Last name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.lastName ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.userName ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Phone number',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.phoneNumber ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Residence',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.placeOfResidence?.name ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.address ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Postcode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.postCode ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.userRoles?[0].role?.name ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'JMBG',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment:
                            Alignment.center, // Set the fixed width you desire
                        child: Text(
                          widget.user?.person?.jmbg ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Date of birth (MM-dd-yyyy)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment: Alignment.center,
                        child: Text(
                          formatBirthDate(widget.user?.person?.birthDate),
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 200.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.all(10.0),
                        alignment: Alignment.center,
                        child: Text(
                          widget.user?.person?.gender == 0 ? 'Male' : 'Female',
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User detail screen"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info, // Replace this with the icon of your choice
                      color: Colors.blue, // Customize the icon color
                      size: 24.0, // Adjust the icon size as needed
                    ),
                    SizedBox(
                        width: 5), // Add spacing between the icon and the text
                    Text(
                      'User information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24, // Adjust the font size as needed
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              // Add a divider
              thickness: 2, // Customize the thickness of the divider
              color: Colors.grey, // Customize the color of the divider
            ),
            buildUserDetailsRow(),
            const Divider(
              // Add a divider
              thickness: 2, // Customize the thickness of the divider
              color: Colors.grey, // Customize the color of the divider
            ),
            buildUserRoleRow(widget.user!),
          ],
        ),
      ),
    );
  }
}

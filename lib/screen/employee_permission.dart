import 'dart:async';
import 'dart:convert';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:spo_balaesang/models/absent_permission.dart';
import 'package:spo_balaesang/repositories/data_repository.dart';
import 'package:spo_balaesang/screen/bottom_nav_screen.dart';
import 'package:spo_balaesang/utils/extensions.dart';
import 'package:spo_balaesang/utils/view_util.dart';
import 'package:spo_balaesang/widgets/employee_proposal_widget.dart';
import 'package:table_calendar/table_calendar.dart';

class EmployeePermissionScreen extends StatefulWidget {
  @override
  _EmployeePermissionScreenState createState() =>
      _EmployeePermissionScreenState();
}

class _EmployeePermissionScreenState extends State<EmployeePermissionScreen> {
  List<AbsentPermission> _permissions = List<AbsentPermission>();
  bool _isLoading = false;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final CalendarController _calendarController = CalendarController();
  List<AbsentPermission> _filteredPermission = List<AbsentPermission>();
  Set<String> choices = {'Semua', 'Disetujui', 'Belum Disetujui', 'Tanggal'};
  String _selectedChoice = 'Semua';
  DateTime _selectedDate = DateTime.now();
  bool _isDateChange = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _fetchPermissionData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var dataRepo = Provider.of<DataRepository>(context, listen: false);
      Map<String, dynamic> _result = await dataRepo.getAllEmployeePermissions();
      List<dynamic> permissions = _result['data'];

      List<AbsentPermission> _data =
          permissions.map((json) => AbsentPermission.fromJson(json)).toList();
      setState(() {
        _permissions = _data;
        _filteredPermission = _data;
      });
    } catch (e) {
      print(e.toString());
    } finally {
      _isLoading = false;
    }
  }

  _rejectPermission(AbsentPermission permission) {
    Get.defaultDialog(
        title: 'Alasan Pembatalan!',
        content: Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            width: Get.width * 0.9,
            child: TextFormField(
              decoration: InputDecoration(
                  labelText: 'Alasan',
                  focusColor: Colors.blueAccent,
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent))),
              controller: _reasonController,
            ),
          ),
        ),
        confirm: RaisedButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          color: Colors.blueAccent,
          textColor: Colors.white,
          onPressed: () {
            Get.back();
            _sendData(permission, false);
          },
          child: Text('OK'),
        ));
  }

  _approvePermission(AbsentPermission permission) {
    _sendData(permission, true);
  }

  _cancelButton(String label, AbsentPermission permission) {
    return SizedBox(
      width: Get.width,
      child: RaisedButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textColor: Colors.white,
        color: Colors.red[600],
        onPressed: () {
          _rejectPermission(permission);
        },
        child: Text(label),
      ),
    );
  }

  _approveButton(AbsentPermission permission) {
    return SizedBox(
      width: Get.width,
      child: RaisedButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textColor: Colors.white,
        color: Colors.blueAccent,
        onPressed: () {
          _approvePermission(permission);
        },
        child: Text('Setujui'),
      ),
    );
  }

  _buildButtonSection(AbsentPermission permission) {
    switch (permission.approvalStatus) {
      case 'Menunggu Persetujuan':
        return Column(
          children: <Widget>[
            _approveButton(permission),
            _cancelButton('Tolak', permission)
          ],
        );
      case 'Disetujui':
        return _cancelButton('Batal Setujui', permission);
      case 'Ditolak':
        return _approveButton(permission);
    }
  }

  Future<void> _sendData(AbsentPermission permission, bool isApproved) async {
    ProgressDialog pd = ProgressDialog(context, isDismissible: false);
    pd.show();
    try {
      final dataRepo = Provider.of<DataRepository>(context, listen: false);
      Map<String, dynamic> data = {
        'user_id': permission.user.id,
        'is_approved': isApproved,
        'permission_id': permission.id,
        'reason': _reasonController.value.text
      };
      http.Response response = await dataRepo.approvePermission(data);
      Map<String, dynamic> _res = jsonDecode(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        pd.hide();
        showAlertDialog("success", "Sukses", _res['message'], false);
        Timer(Duration(seconds: 5), () => Get.off(BottomNavScreen()));
      } else {
        if (pd.isShowing()) pd.hide();
        showErrorDialog(_res);
      }
    } catch (e) {
      pd.hide();
      print(e.toString());
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _nameController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _fetchPermissionData();
    super.initState();
  }

  Widget _buildBody() {
    if (_isLoading)
      return Container(
        height: Get.height * 0.8,
        child: Center(
            child: SpinKitFadingCircle(
          size: 45,
          color: Colors.blueAccent,
        )),
      );
    if (_filteredPermission.isEmpty) {
      return Container(
        height: Get.height * 0.6,
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: Get.width * 0.5,
                  height: Get.height * 0.3,
                  child: FlareActor(
                    'assets/flare/not_found.flr',
                    fit: BoxFit.contain,
                    animation: 'empty',
                    alignment: Alignment.center,
                  ),
                ),
                Text('Belum ada izin yang diajukan!')
              ]),
        ),
      );
    }
    return Column(
      children: _filteredPermission.map((permission) {
        DateTime dueDate = permission.dueDate;
        DateTime startDate = permission.startDate;
        return EmployeeProposalWidget(
          title: permission.title,
          description: permission.description,
          startDate: startDate,
          dueDate: dueDate,
          employeeName: permission.user.name,
          isApproved: permission.isApproved,
          approvalStatus: permission.approvalStatus,
          heroTag: permission.id.toString(),
          photo: permission.photo,
          isApprovalCard: true,
          button: _buildButtonSection(permission),
        );
      }).toList(),
    );
  }

  List<AbsentPermission> _setFilter(String value) {
    if (value == 'Disetujui') {
      return _permissions
          .where((element) => element.isApproved == true)
          .toList();
    }

    if (value == 'Belum Disetujui') {
      return _permissions
          .where((element) => element.isApproved == false)
          .toList();
    }

    if (value == 'Tanggal') {
      if (!_isDateChange) {
        _selectDate();
      }
      return _permissions.where((element) {
        setState(() {
          _isDateChange = false;
        });
        return element.startDate.isSameDate(_selectedDate) ||
            element.dueDate.isSameDate(_selectedDate);
      }).toList();
    }

    return _permissions;
  }

  _selectDate() {
    Get.defaultDialog(
        title: 'Pilih Tanggal Selesai',
        content: Flexible(
          child: Container(
            width: Get.width * 0.9,
            child: TableCalendar(
              availableCalendarFormats: <CalendarFormat, String>{
                CalendarFormat.month: '1 minggu',
                CalendarFormat.twoWeeks: '1 bulan',
                CalendarFormat.week: '2 minggu'
              },
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle:
                  HeaderStyle(formatButtonTextStyle: TextStyle(fontSize: 12.0)),
              calendarController: _calendarController,
              startingDayOfWeek: StartingDayOfWeek.monday,
              startDay: DateTime(2021),
              endDay: DateTime(DateTime.now().year + 5),
              initialSelectedDay: _selectedDate,
              locale: 'in_ID',
              initialCalendarFormat: CalendarFormat.month,
              onDaySelected: (day, events, holidays) {
                Get.back();
                setState(() {
                  _selectedDate = day;
                  if (!_isDateChange) {
                    _isDateChange = true;
                  }
                  _filteredPermission = _setFilter(_selectedChoice);
                  if (_nameController.value.text.isNotEmpty) {
                    _searchByName(_nameController.value.text);
                  }
                });
              },
            ),
          ),
        ));
  }

  void _searchByName(String value) {
    setState(() {
      if (value.length > 0) {
        _filteredPermission = _filteredPermission
            .where((element) =>
                element.user.name.toLowerCase().contains(value.toLowerCase()))
            .toList();
      } else {
        _filteredPermission = _setFilter(_selectedChoice);
      }
    });
  }

  Widget _buildLabelSection() {
    if (_selectedChoice == 'Tanggal') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Hasil      : ${_filteredPermission.length} izin'),
          Text(
              'Tanggal : ${DateFormat.yMMMMEEEEd('id_ID').format(_selectedDate)}')
        ],
      );
    }
    return Text('Hasil : ${_filteredPermission.length} izin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Daftar Izin Pegawai'),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Cari dengan nama pegawai',
                ),
                onChanged: _searchByName,
              ),
              SizedBox(height: 10.0),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Filter : ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16.0),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.grey[600])),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                            isExpanded: true,
                            value: _selectedChoice,
                            items: choices
                                .map(
                                  (choice) => DropdownMenuItem(
                                    child: Text(
                                      choice,
                                    ),
                                    value: choice,
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedChoice = value;
                                _filteredPermission = _setFilter(value);
                                if (_nameController.value.text.isNotEmpty) {
                                  _searchByName(_nameController.value.text);
                                }
                              });
                            }),
                      ),
                    ),
                  )
                ],
              ),
              Divider(),
              _buildLabelSection(),
              SizedBox(height: 8.0),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:blood_contacts/src/features/contacts/domain/blood_need_request.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as phone_contacts;

class NewNeedPage extends StatefulWidget {
  const NewNeedPage({super.key});

  @override
  State<NewNeedPage> createState() => _NewNeedPageState();
}

class _NewNeedPageState extends State<NewNeedPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _requestedByNameController = TextEditingController();
  final _requestedByPhoneController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _bloodGroup = 'O+';
  int _unitsNeeded = 2;
  bool _urgent = true;
  DateTime _needDate = DateTime.now();
  TimeOfDay? _needTime;
  String? _relation = 'Cousin';
  bool _requestedBySameAsContactPerson = true;
  bool _submitted = false;

  static const _relations = [
    'Self',
    'Father',
    'Mother',
    'Parent',
    'Husband',
    'Wife',
    'Spouse',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Grandfather',
    'Grandmother',
    'Grandparent',
    'Grandchild',
    'Uncle',
    'Aunt',
    'Nephew',
    'Niece',
    'Cousin',
    'Friend',
    'Colleague',
    'Neighbor',
    'Guardian',
    'Relative',
    'Other',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _requestedByNameController.dispose();
    _requestedByPhoneController.dispose();
    _patientNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPhoneContact({
    required TextEditingController nameController,
    required TextEditingController phoneController,
  }) async {
    final status = await phone_contacts.FlutterContacts.permissions.request(
      phone_contacts.PermissionType.read,
    );
    final permitted =
        status == phone_contacts.PermissionStatus.granted ||
        status == phone_contacts.PermissionStatus.limited;
    if (!permitted || !mounted) {
      _showSnack('Contacts permission is required.');
      return;
    }

    final contactId = await phone_contacts.FlutterContacts.native.showPicker();
    if (contactId == null || !mounted) return;

    final selected = await phone_contacts.FlutterContacts.get(
      contactId,
      properties: {
        phone_contacts.ContactProperty.name,
        phone_contacts.ContactProperty.phone,
      },
    );
    if (selected == null || !mounted) return;

    setState(() {
      nameController.text = selected.displayName ?? '';
      if (selected.phones.isNotEmpty) {
        phoneController.text = selected.phones.first.number;
      }
    });
  }

  Future<void> _pickNeedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _needDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _needDate = picked);
  }

  Future<void> _pickNeedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _needTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _needTime = picked);
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final requesterName = _requestedBySameAsContactPerson
        ? _contactNameController.text.trim()
        : _requestedByNameController.text.trim();
    final requesterPhone = _requestedBySameAsContactPerson
        ? _contactPhoneController.text.trim()
        : _requestedByPhoneController.text.trim();
    final patientName = _patientNameController.text.trim().isEmpty
        ? _contactNameController.text.trim()
        : _patientNameController.text.trim();
    final notes = _notesController.text.trim();
    final now = DateTime.now();
    final need = BloodNeedRequest(
      id: 'need-${now.microsecondsSinceEpoch}',
      patientName: patientName,
      summary: notes.isEmpty ? '${_relation ?? 'Patient'} needs blood.' : notes,
      bloodGroup: _bloodGroup ?? 'O+',
      hospital: _locationController.text.trim(),
      date: _formatNeedDate(_needDate),
      time: _needTime == null ? 'Any time' : _needTime!.format(context),
      requester: requesterName,
      phone: requesterPhone,
      units: _unitsNeeded,
      urgency: _urgent ? NeedUrgency.urgent : NeedUrgency.normal,
      status: NeedStatus.open,
      sortRank: now.millisecondsSinceEpoch,
      updatedAt: now,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood need saved successfully.')),
    );
    Navigator.pop(context, need);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            children: [
              _PageHeader(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 22),
              const _SectionTitle('BLOOD REQUIREMENT'),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;
                  final fields = [
                    _FieldCard(
                      child: _NeedDropdown<String>(
                        label: 'Blood Group *',
                        value: _bloodGroup,
                        icon: Icons.water_drop_outlined,
                        items: bloodGroups,
                        labelBuilder: (value) => value,
                        validator: (value) =>
                            value == null ? 'Blood group required' : null,
                        onChanged: (value) => setState(() {
                          _bloodGroup = value;
                        }),
                      ),
                    ),
                    _FieldCard(
                      child: _NeedDropdown<int>(
                        label: 'Units Needed *',
                        value: _unitsNeeded,
                        icon: Icons.local_drink_outlined,
                        items: List.generate(10, (index) => index + 1),
                        labelBuilder: (value) =>
                            '$value Unit${value == 1 ? '' : 's'}',
                        validator: (value) =>
                            value == null ? 'Units required' : null,
                        onChanged: (value) => setState(() {
                          _unitsNeeded = value ?? _unitsNeeded;
                        }),
                      ),
                    ),
                    _UrgencyCard(
                      urgent: _urgent,
                      onChanged: (value) => setState(() => _urgent = value),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 10),
                            Expanded(child: fields[1]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        fields[2],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: fields[2]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              _NeedByCard(
                date: _needDate,
                time: _needTime,
                onDate: _pickNeedDate,
                onClearDate: () => setState(() => _needDate = DateTime.now()),
                onTime: _pickNeedTime,
              ),
              const SizedBox(height: 22),
              const _SectionTitle('LOCATION'),
              const SizedBox(height: 10),
              _NeedTextField(
                controller: _locationController,
                label: 'Location / Hospital *',
                hint: 'Enter hospital or location',
                icon: Icons.location_on_outlined,
                validator: _requiredValidator('Location or hospital required'),
              ),
              const SizedBox(height: 22),
              _SectionHeaderAction(
                title: 'CONTACT PERSON',
                actionLabel: 'Choose from contacts',
                onAction: () => _selectPhoneContact(
                  nameController: _contactNameController,
                  phoneController: _contactPhoneController,
                ),
              ),
              const SizedBox(height: 10),
              _ResponsivePair(
                first: _NeedTextField(
                  controller: _contactNameController,
                  label: 'Contact Person Name *',
                  hint: 'Enter name',
                  icon: Icons.person_outline,
                  validator: _requiredValidator('Contact person name required'),
                ),
                second: _NeedTextField(
                  controller: _contactPhoneController,
                  label: 'Contact Person Phone *',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _requiredValidator(
                    'Contact person phone required',
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle('REQUESTED BY'),
              const SizedBox(height: 10),
              _SameAsContactPersonTile(
                value: _requestedBySameAsContactPerson,
                onChanged: (value) {
                  setState(() {
                    _requestedBySameAsContactPerson = value;
                  });
                },
              ),
              if (!_requestedBySameAsContactPerson) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _selectPhoneContact(
                      nameController: _requestedByNameController,
                      phoneController: _requestedByPhoneController,
                    ),
                    icon: const Icon(Icons.contacts_outlined, size: 18),
                    label: const Text('Choose from contacts'),
                  ),
                ),
                const SizedBox(height: 10),
                _ResponsivePair(
                  first: _NeedTextField(
                    controller: _requestedByNameController,
                    label: 'Requested By Name *',
                    hint: 'Enter name',
                    icon: Icons.person_add_alt_outlined,
                    validator: _requiredValidator('Requester name required'),
                  ),
                  second: _NeedTextField(
                    controller: _requestedByPhoneController,
                    label: 'Requested By Phone *',
                    hint: 'Enter phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator('Requester phone required'),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const _SectionTitle('PATIENT / RECIPIENT (OPTIONAL)'),
              const SizedBox(height: 10),
              _ResponsivePair(
                first: _NeedTextField(
                  controller: _patientNameController,
                  label: 'Patient / Recipient Name',
                  hint: 'Enter patient name',
                  icon: Icons.person_outline,
                ),
                second: _FieldCard(
                  child: _NeedDropdown<String>(
                    label: 'Relation',
                    value: _relation,
                    icon: Icons.group_outlined,
                    items: _relations,
                    labelBuilder: (value) => value,
                    onChanged: (value) => setState(() => _relation = value),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _NeedTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Add details donors should know',
                icon: Icons.article_outlined,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send, size: 24),
                  label: const Text('Save Need'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffd90416),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }

  String _formatNeedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SameAsContactPersonTile extends StatelessWidget {
  const _SameAsContactPersonTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xffe3e4ea)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              visualDensity: VisualDensity.compact,
              activeColor: const Color(0xffd90416),
              onChanged: (nextValue) => onChanged(nextValue ?? true),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Same as contact person',
                style: TextStyle(
                  color: Color(0xff111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          tooltip: 'Back',
          icon: Icons.arrow_back,
          onPressed: onBack,
        ),
        const SizedBox(width: 18),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Need',
                style: TextStyle(
                  color: Color(0xff050505),
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Create a blood request and notify donors.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xff44475a),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SquareIconButton(
          tooltip: 'Help',
          icon: Icons.help_outline,
          onPressed: () {},
          circular: true,
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.circular = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(58, 58),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff111827),
        side: const BorderSide(color: Color(0xffe9e2e2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(circular ? 29 : 14),
        ),
      ),
      icon: Icon(icon, size: 30),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff3b3e4f),
        fontSize: 20,
        letterSpacing: 0,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionHeaderAction extends StatelessWidget {
  const _SectionHeaderAction({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title)),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.contacts_outlined, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(children: [first, const SizedBox(height: 10), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _NeedDropdown<T> extends StatelessWidget {
  const _NeedDropdown({
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final IconData icon;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down, size: 30),
      decoration: _NeedDecoration.input(label: label, icon: icon),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff050505),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({required this.urgent, required this.onChanged});

  final bool urgent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _NeedDecoration.input(
        label: 'Urgency *',
        icon: Icons.notifications_active_outlined,
      ),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: _UrgencyOption(
                selected: urgent,
                icon: Icons.notification_important_outlined,
                label: 'Urgent',
                onTap: () => onChanged(true),
              ),
            ),
            Expanded(
              child: _UrgencyOption(
                selected: !urgent,
                icon: Icons.schedule_outlined,
                label: 'Normal',
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xffd90416) : const Color(0xff4c5163);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xfffff7f7) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xffff8b92) : const Color(0xffe0dfe6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedByCard extends StatelessWidget {
  const _NeedByCard({
    required this.date,
    required this.time,
    required this.onDate,
    required this.onClearDate,
    required this.onTime,
  });

  final DateTime date;
  final TimeOfDay? time;
  final VoidCallback onDate;
  final VoidCallback onClearDate;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _NeedDecoration.group(label: 'Need By *'),
      child: _ResponsivePair(
        first: _PickerTile(
          label: 'Date *',
          icon: Icons.calendar_today_outlined,
          value: _formatDate(date),
          trailing: IconButton(
            tooltip: 'Reset date',
            onPressed: onClearDate,
            icon: const Icon(Icons.cancel_outlined, size: 24),
          ),
          onTap: onDate,
        ),
        second: _PickerTile(
          label: 'Time (Optional)',
          icon: Icons.schedule_outlined,
          value: time == null
              ? 'Select time'
              : MaterialLocalizations.of(context).formatTimeOfDay(time!),
          muted: time == null,
          trailing: const Icon(Icons.keyboard_arrow_down, size: 30),
          onTap: onTime,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.trailing,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final String value;
  final Widget trailing;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: _NeedDecoration.input(label: label, icon: icon),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted ? const Color(0xff555a6a) : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _NeedTextField extends StatelessWidget {
  const _NeedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: _NeedDecoration.input(label: label, hint: hint, icon: icon),
      validator: validator,
    );
  }
}

class _NeedDecoration {
  const _NeedDecoration._();

  static InputDecoration input({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      prefixIcon: Icon(icon, color: const Color(0xffe60012), size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: const TextStyle(
        color: Color(0xff3f4354),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xff8a8b96),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffe3e4ea)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffff8b92), width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffd90416), width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffd90416), width: 1.3),
      ),
    );
  }

  static InputDecoration group({required String label}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      labelStyle: const TextStyle(
        color: Color(0xff3f4354),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffe3e4ea)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xffe3e4ea)),
      ),
    );
  }
}

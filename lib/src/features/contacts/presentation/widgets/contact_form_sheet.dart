import 'dart:convert';
import 'dart:typed_data';

import 'package:blood_contacts/src/features/contacts/domain/blood_contact.dart';
import 'package:blood_contacts/src/features/contacts/domain/contact_constants.dart';
import 'package:blood_contacts/src/features/contacts/presentation/widgets/contact_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as phone_contacts;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class AddBloodContactBottomSheet extends StatefulWidget {
  const AddBloodContactBottomSheet({
    super.key,
    this.contact,
    this.existingContacts = const [],
  });

  final BloodContact? contact;
  final List<BloodContact> existingContacts;

  @override
  State<AddBloodContactBottomSheet> createState() =>
      _AddBloodContactBottomSheetState();
}

class _AddBloodContactBottomSheetState
    extends State<AddBloodContactBottomSheet> {
  static const int _maxPhotoBytes = 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool _manualMode = true;
  bool _saveToPhoneContacts = false;
  bool _submitted = false;
  String? _bloodGroup;
  DonorAvailability? _availability;
  DateTime? _lastDonationDate;
  String? _photoPath;
  String? _photoName;
  Uint8List? _photoBytes;
  String? _photoError;
  String? _phoneDuplicateError;
  bool _removedContactPhotoDueToSize = false;

  bool get _isEditing => widget.contact != null;

  bool get _canSave {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _bloodGroup != null &&
        _availability != null;
  }

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact != null) {
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _emailController.text = contact.email;
      _noteController.text = contact.note;
      _bloodGroup = contact.bloodGroup;
      _availability = contact.availability;
      _lastDonationDate = contact.lastDonationDate;
      _photoPath = contact.photoPath;
      _photoName = contact.photoPath?.split('/').last;
      _photoBytes = contact.photoBytes;
      _saveToPhoneContacts = contact.saveToPhoneContacts;
    } else {
      _availability = DonorAvailability.available;
    }
    _nameController.addListener(_refresh);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onPhoneChanged() {
    if (_phoneDuplicateError == null) {
      _refresh();
      return;
    }

    setState(() => _phoneDuplicateError = null);
  }

  String? _phoneDuplicateMessage(String phone) {
    final duplicate = _duplicateBloodContactForPhone(phone);
    if (duplicate == null) return null;
    return 'This phone number already exists for ${duplicate.name}.';
  }

  BloodContact? _duplicateBloodContactForPhone(String phone) {
    final normalizedPhone = normalizedPhoneNumber(phone);
    if (normalizedPhone.isEmpty) return null;

    for (final contact in widget.existingContacts) {
      if (contact.id == widget.contact?.id) continue;
      if (normalizedPhoneNumber(contact.phone) == normalizedPhone) {
        return contact;
      }
    }

    return null;
  }

  Future<void> _pickImage() async {
    setState(() => _photoError = null);
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;

    final extension = image.name.split('.').last.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowed.contains(extension)) {
      setState(() => _photoError = 'Use JPG, PNG, or WebP image.');
      return;
    }

    final bytes = await image.readAsBytes();
    final compressed = await _compressPhotoToLimit(bytes);
    if (compressed == null) {
      setState(() => _photoError = 'Image must be 1 MB or smaller.');
      return;
    }

    setState(() {
      _photoPath = image.path;
      _photoName = image.name;
      _photoBytes = compressed;
      _photoError = null;
      _removedContactPhotoDueToSize = false;
    });
  }

  void _removeImage() {
    setState(() {
      _photoPath = null;
      _photoName = null;
      _photoBytes = null;
      _photoError = null;
      _removedContactPhotoDueToSize = false;
    });
  }

  Future<void> _selectPhoneContact() async {
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
        phone_contacts.ContactProperty.phone,
        phone_contacts.ContactProperty.email,
        phone_contacts.ContactProperty.photoThumbnail,
        phone_contacts.ContactProperty.photoFullRes,
      },
    );
    if (selected == null || !mounted) return;

    final photo = selected.photo;
    final selectedPhotoBytes = photo?.fullSize ?? photo?.thumbnail;
    final compressedPhotoBytes = selectedPhotoBytes == null
        ? null
        : await _compressPhotoToLimit(selectedPhotoBytes);
    final removedPhoto = selectedPhotoBytes != null && compressedPhotoBytes == null;

    setState(() {
      _manualMode = false;
      _nameController.text = selected.displayName ?? '';
      if (selected.phones.isNotEmpty) {
        _phoneController.text = selected.phones.first.number;
        _phoneDuplicateError = _phoneDuplicateMessage(_phoneController.text);
      } else {
        _phoneDuplicateError = null;
      }
      if (selected.emails.isNotEmpty) {
        _emailController.text = selected.emails.first.address;
      }
      if (compressedPhotoBytes != null) {
        _photoBytes = compressedPhotoBytes;
        _photoPath = null;
        _photoName = 'Contact photo';
        _removedContactPhotoDueToSize = false;
      } else if (removedPhoto) {
        _photoBytes = null;
        _photoPath = null;
        _photoName = null;
        _removedContactPhotoDueToSize = true;
      }
    });
  }

  Future<void> _pickLastDonationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonationDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _lastDonationDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || !_canSave) return;

    final duplicateContact = _duplicateBloodContactForPhone(
      _phoneController.text,
    );
    if (duplicateContact != null) {
      setState(() {
        _phoneDuplicateError =
            'This phone number already exists for ${duplicateContact.name}.';
      });
      _formKey.currentState!.validate();
      return;
    }

    final existingPhoneContact = _isEditing
        ? null
        : await _findPhoneContact(
            _phoneController.text.trim(),
            needsWritePermission: _saveToPhoneContacts,
          );
    if (!mounted) return;

    String donorName = _nameController.text.trim();
    if (_manualMode && existingPhoneContact != null) {
      final existingName = existingPhoneContact.displayName;
      if (existingName != null && existingName.trim().isNotEmpty) {
        final nameChoice = await _askNameChoice(existingName);
        if (!mounted || nameChoice == null) return;
        if (nameChoice == _ExistingNameChoice.useExisting) {
          donorName = existingName.trim();
          _nameController.text = donorName;
        }
      }
    }

    var shouldSaveToPhoneContacts = !_isEditing && _saveToPhoneContacts;
    if (_saveToPhoneContacts && existingPhoneContact != null) {
      final shouldAddNew = await _confirmDuplicatePhoneContact(
        existingPhoneContact.displayName,
      );
      if (!mounted || shouldAddNew == null) return;
      shouldSaveToPhoneContacts = shouldAddNew;
    }

    final existing = widget.contact;
    final normalizedPhone = normalizedPhoneNumber(_phoneController.text.trim());
    final contact = BloodContact(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: donorName,
      phone: normalizedPhone,
      email: _emailController.text.trim(),
      photoPath: _photoPath,
      photoBase64: _photoBytes == null ? null : base64Encode(_photoBytes!),
      bloodGroup: _bloodGroup!,
      availability: _availability!,
      lastDonationDate: _lastDonationDate,
      note: _noteController.text.trim(),
      saveToPhoneContacts: shouldSaveToPhoneContacts,
      updatedAt: DateTime.now(),
    );

    if (shouldSaveToPhoneContacts) {
      await _saveNativeContact(contact);
    }

    if (!mounted) return;
    if (_removedContactPhotoDueToSize) {
      _showSnack('Contact saved without photo.');
    }
    Navigator.pop(context, contact);
  }

  Future<Uint8List?> _compressPhotoToLimit(Uint8List input) async {
    if (input.isEmpty) return null;
    if (input.length <= _maxPhotoBytes) return input;

    final widths = [1600, 1400, 1200, 1000, 900, 800, 700, 600, 512, 420];
    final qualities = [92, 86, 80, 74, 68, 60, 52, 44, 36, 28, 20, 14];
    Uint8List? best;

    for (final width in widths) {
      for (final quality in qualities) {
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            input,
            minWidth: width,
            minHeight: width,
            quality: quality,
            format: CompressFormat.jpeg,
            keepExif: false,
          );
          if (compressed.isEmpty) continue;
          if (best == null || compressed.length < best.length) {
            best = compressed;
          }
          if (compressed.length <= _maxPhotoBytes) {
            return compressed;
          }
        } catch (_) {
          // Try next compression settings.
        }
      }
    }

    if (best != null && best.length <= _maxPhotoBytes) {
      return best;
    }
    return null;
  }

  Future<void> _saveNativeContact(BloodContact contact) async {
    final status = await phone_contacts.FlutterContacts.permissions.request(
      phone_contacts.PermissionType.readWrite,
    );
    final permitted =
        status == phone_contacts.PermissionStatus.granted ||
        status == phone_contacts.PermissionStatus.limited;
    if (!permitted) return;

    final emails = <phone_contacts.Email>[];
    if (contact.email.isNotEmpty) {
      emails.add(phone_contacts.Email(address: contact.email));
    }

    final photoBytes = contact.photoBytes;
    final nativeContact = phone_contacts.Contact(
      name: phone_contacts.Name(first: contact.name),
      phones: [phone_contacts.Phone(number: contact.phone)],
      emails: emails,
      photo: photoBytes == null
          ? null
          : phone_contacts.Photo(fullSize: photoBytes),
    );
    await phone_contacts.FlutterContacts.create(nativeContact);
  }

  Future<phone_contacts.Contact?> _findPhoneContact(
    String phone, {
    bool needsWritePermission = false,
  }) async {
    if (phone.trim().isEmpty) return null;

    final status = await phone_contacts.FlutterContacts.permissions.request(
      needsWritePermission
          ? phone_contacts.PermissionType.readWrite
          : phone_contacts.PermissionType.read,
    );
    final permitted =
        status == phone_contacts.PermissionStatus.granted ||
        status == phone_contacts.PermissionStatus.limited;
    if (!permitted) return null;

    final contacts = await phone_contacts.FlutterContacts.getAll(
      filter: phone_contacts.ContactFilter.phone(phone),
      properties: {
        phone_contacts.ContactProperty.name,
        phone_contacts.ContactProperty.phone,
      },
      limit: 1,
    );
    return contacts.isEmpty ? null : contacts.first;
  }

  Future<_ExistingNameChoice?> _askNameChoice(String existingName) {
    final inputName = _nameController.text.trim();
    return showAppOptionsDialog<_ExistingNameChoice>(
      context: context,
      title: 'Contact already exists',
      message:
          'This phone number already exists in your phone contacts as "$existingName". Do you want to use that name or keep "$inputName" for the blood contact?',
      options: const [
        AppDialogOption(
          value: _ExistingNameChoice.keepInput,
          label: 'Keep inputted name',
        ),
        AppDialogOption(
          value: _ExistingNameChoice.useExisting,
          label: 'Use phone contact name',
          filled: true,
          destructive: false,
        ),
      ],
    );
  }

  Future<bool?> _confirmDuplicatePhoneContact(String? existingName) {
    final displayName = existingName == null || existingName.trim().isEmpty
        ? 'this contact'
        : '"${existingName.trim()}"';

    return showAppConfirmationDialog(
      context: context,
      title: 'Already in phone contacts',
      message:
          'This contact already exists in your phone contacts as $displayName. Do you want to add a new phone contact anyway?',
      confirmLabel: 'Add new',
      cancelLabel: 'No, only save blood contact',
      destructive: false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _hasUnsavedChanges() {
    final existing = widget.contact;
    if (existing == null) {
      return _nameController.text.trim().isNotEmpty ||
          _phoneController.text.trim().isNotEmpty ||
          _emailController.text.trim().isNotEmpty ||
          _noteController.text.trim().isNotEmpty ||
          _bloodGroup != null ||
          _availability != DonorAvailability.available ||
          _lastDonationDate != null ||
          _photoBytes != null ||
          _photoPath != null ||
          _saveToPhoneContacts ||
          !_manualMode;
    }

    final currentPhotoBase64 = _photoBytes == null
        ? null
        : base64Encode(_photoBytes!);
    return _nameController.text.trim() != existing.name ||
        normalizedPhoneNumber(_phoneController.text.trim()) !=
            normalizedPhoneNumber(existing.phone) ||
        _emailController.text.trim() != existing.email.trim() ||
        _noteController.text.trim() != existing.note.trim() ||
        _bloodGroup != existing.bloodGroup ||
        _availability != existing.availability ||
        _lastDonationDate != existing.lastDonationDate ||
        _photoPath != existing.photoPath ||
        currentPhotoBase64 != existing.photoBase64 ||
        _saveToPhoneContacts != existing.saveToPhoneContacts;
  }

  Future<void> _attemptClose() async {
    if (!_hasUnsavedChanges()) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final shouldDiscard = await showAppConfirmationDialog(
      context: context,
      title: 'Discard changes?',
      message: 'You have unsaved changes in this form.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _attemptClose();
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 10, 18, bottomPadding + 18),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xffc9c4c4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.contact == null
                                  ? 'Add Blood Contact'
                                  : 'Edit Blood Contact',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _isEditing
                                  ? 'Update saved donor details'
                                  : 'Add a new donor to your list',
                              style: const TextStyle(
                                color: Color(0xff565660),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _attemptClose,
                        icon: const Icon(Icons.close, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isEditing) ...[
                    AddContactSegmentedControl(
                      manualMode: _manualMode,
                      onManual: () => setState(() => _manualMode = true),
                      onContacts: () async {
                        setState(() => _manualMode = false);
                        await _selectPhoneContact();
                      },
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (!_isEditing && !_manualMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OutlinedButton.icon(
                        onPressed: _selectPhoneContact,
                        icon: const Icon(Icons.contacts_outlined),
                        label: const Text('Choose phone contact'),
                      ),
                    ),
                  AppTextField(
                    controller: _nameController,
                    label: 'Name *',
                    hint: 'Enter full name',
                    icon: Icons.person_outline,
                    validator: _requiredValidator('Name required'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone number *',
                    hint: 'Enter phone number',
                    icon: Icons.phone,
                    errorText: _phoneDuplicateError,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      return _requiredValidator('Phone number required')(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    label: 'Blood Group *',
                    hint: 'Select blood group',
                    icon: Icons.water_drop,
                    value: _bloodGroup,
                    items: bloodGroups,
                    labelBuilder: (value) => value,
                    onChanged: (value) => setState(() => _bloodGroup = value),
                    validator: (value) =>
                        value == null ? 'Blood group required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<DonorAvailability>(
                    label: 'Availability *',
                    hint: 'Select availability',
                    icon: Icons.circle,
                    value: _availability,
                    items: DonorAvailability.values,
                    labelBuilder: (value) => value.label,
                    onChanged: (value) => setState(() => _availability = value),
                    validator: (value) =>
                        value == null ? 'Availability required' : null,
                  ),
                  const SizedBox(height: 12),
                  DatePickerField(
                    value: _lastDonationDate,
                    onTap: _pickLastDonationDate,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email (optional)',
                    hint: 'Enter email address',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _noteController,
                    label: 'Note (optional)',
                    hint: 'Add any note...',
                    icon: Icons.note_alt_outlined,
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ProfilePhotoField(
                    photoBytes: _photoBytes,
                    photoName: _photoName,
                    errorText: _photoError,
                    onPick: _pickImage,
                    onRemove: _removeImage,
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: _saveToPhoneContacts,
                          onChanged: (value) {
                            setState(
                              () => _saveToPhoneContacts = value ?? false,
                            );
                          },
                        ),
                        const Expanded(
                          child: Text('Also save to my phone contacts'),
                        ),
                        const Icon(
                          Icons.info_outline,
                          size: 19,
                          color: Color(0xff76727a),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffd90416),
                        disabledBackgroundColor: const Color(0xffffc9ce),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _canSave ? _submit : null,
                      child: const Text(
                        'Save Contact',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredValidator(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }
}

enum _ExistingNameChoice { useExisting, keepInput }

class ContactFormSheet extends AddBloodContactBottomSheet {
  const ContactFormSheet({super.key, super.contact, super.existingContacts});
}

class AddContactSegmentedControl extends StatelessWidget {
  const AddContactSegmentedControl({
    super.key,
    required this.manualMode,
    required this.onManual,
    required this.onContacts,
  });

  final bool manualMode;
  final VoidCallback onManual;
  final VoidCallback onContacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xfff4f1f1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentButton(
              selected: manualMode,
              icon: Icons.edit,
              label: 'Manual',
              onTap: onManual,
            ),
          ),
          Expanded(
            child: SegmentButton(
              selected: !manualMode,
              icon: Icons.people_outline,
              label: 'From Contacts',
              onTap: onContacts,
            ),
          ),
        ],
      ),
    );
  }
}

class SegmentButton extends StatelessWidget {
  const SegmentButton({
    super.key,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xfffff6f6) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(color: const Color(0xffff8b92), width: 1.4)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? const Color(0xffd90416)
                  : const Color(0xff66636a),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xffd90416)
                    : const Color(0xff66636a),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: AppFieldDecoration.input(
        label: label,
        hint: hint,
        icon: icon,
      ).copyWith(errorText: errorText),
      validator: validator,
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: AppFieldDecoration.input(
        label: label,
        hint: hint,
        icon: icon,
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class DatePickerField extends StatelessWidget {
  const DatePickerField({super.key, required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: AppFieldDecoration.input(
          label: 'Last Donation Date (optional)',
          hint: 'Select date',
          icon: Icons.calendar_today_outlined,
          suffixIcon: Icons.event,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == null ? const Color(0xff8d8a92) : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ProfilePhotoField extends StatelessWidget {
  const ProfilePhotoField({
    super.key,
    required this.photoBytes,
    required this.photoName,
    required this.errorText,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final String? photoName;
  final String? errorText;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get hasPhoto => photoBytes != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe9e2e2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.image_outlined, color: Color(0xff555560)),
              const SizedBox(width: 14),
              if (hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.memory(
                    photoBytes!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xffffeeee),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xffd90416),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Photo (optional)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasPhoto ? photoName ?? 'Selected image' : 'Upload Image',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xffd90416),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhoto) ...[
                TextButton(onPressed: onPick, child: const Text('Change')),
                IconButton(
                  tooltip: 'Remove image',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ] else
                IconButton(
                  tooltip: 'Upload image',
                  onPressed: onPick,
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xffd90416),
                  ),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class AppFieldDecoration {
  const AppFieldDecoration._();

  static InputDecoration input({
    required String label,
    required String hint,
    required IconData icon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe9e2e2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffef6670)),
      ),
    );
  }
}

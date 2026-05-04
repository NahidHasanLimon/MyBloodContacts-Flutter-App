import 'package:flutter/material.dart';

const bloodGroups = ['O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

const bloodGroupColors = {
  'O+': Color(0xffe5161d),
  'A+': Color(0xff078b91),
  'B+': Color(0xffff7a00),
  'AB+': Color(0xff6d2bd9),
  'O-': Color(0xffe5161d),
  'A-': Color(0xff078b91),
  'B-': Color(0xffff7a00),
  'AB-': Color(0xff6d2bd9),
};

enum ContactFilter {
  all('All', Icons.favorite_border),
  available('Available', Icons.volunteer_activism_outlined),
  nearby('Nearby', Icons.location_on_outlined);

  const ContactFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum AppTab { home, contacts }

enum AvailabilityFilter {
  all('All Status'),
  available('Available'),
  unavailable('Unavailable');

  const AvailabilityFilter(this.label);

  final String label;
}

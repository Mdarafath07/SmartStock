class AppValidators {
  AppValidators._();

  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price < 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Enter a positive number';
    }
    return null;
  }
}

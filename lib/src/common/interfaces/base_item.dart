abstract class BaseItem {
  String get dbRef; // Abstract getter for name
  String get name; // Abstract getter for code
  List<String> get imageUrls;
  // returns last image
  String get coverImageUrl;
  // this is a constructor mehtod that all children must implement
  //we need to use factory keyword for constructor methods
  factory BaseItem.fromMap(Map<String, dynamic> map) {
    // Abstract methods (like getters) do not need throw UnimplementedError.
    // Factory methods (like fromMap) that are intended to be implemented by
    //subclasses can use throw UnimplementedError to enforce implementation.
    throw UnimplementedError('fromMap must be implemented in subclasses');
  }
  Map<String, dynamic> toMap();
}

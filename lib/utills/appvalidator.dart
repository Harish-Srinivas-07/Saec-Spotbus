// login validate

class AppValidator{

  String? validateEmail(value){
    if(value!.isEmpty) {
      return 'Provide a mail please';
    }
    RegExp emailexp = RegExp(r'^[\w\-\.\+]+\@[a-zA-Z0-9\.\-]+\.[a-zA-z0-9]{2,4}$');
    if(!emailexp.hasMatch(value)) {
      return'Please enter a valid email';
    }
    return null;
  }
  String? stuvalidateName(value) {
    if(value!.isEmpty) {
      return 'Please enter a name';
    }
    return null;
  }

  String? stuvalidateEmail(value){
    if(value!.isEmpty) {
      return 'Provide a saec mail please';
    }
    RegExp emailexp = RegExp(r'^[a-zA-Z0-9]+@saec\.ac\.in$');
    if(!emailexp.hasMatch(value)) {
      return'Please enter a valid email';
    }
    return null;
  }


  String? validatemobile(value){
    if(value!.isEmpty) {
      return 'Please enter an Mobile number';
    }
    if(value.length !=10){
      return 'Please enter a 10-digit mobile number';

    }
    return null;
  }



  String? validateusername(value) {
    if(value!.isEmpty) {
      return 'Please enter a Username';
    }
    return null;
  }


  String? validatepassword(value) {
    if(value!.isEmpty) {
      return 'Please enter a password';
    }
    return null;
  }






}
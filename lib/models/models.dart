class Company {
  const Company({required this.id, required this.name, required this.email});

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );

  final int id;
  final String name;
  final String email;
}

class Job {
  const Job({
    required this.id,
    required this.companyName,
    required this.title,
    required this.description,
    required this.createdAt,
    this.location,
    this.contractType,
    this.applicationsCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] as int,
    companyName: json['companyName'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    location: json['location'] as String?,
    contractType: json['contractType'] as String?,
    applicationsCount: json['applicationsCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final int id;
  final String companyName;
  final String title;
  final String description;
  final String? location;
  final String? contractType;
  final int applicationsCount;
  final DateTime createdAt;
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvFilename,
    required this.createdAt,
    this.phone,
    this.message,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
    id: json['id'] as int,
    jobId: json['jobId'] as int,
    jobTitle: json['jobTitle'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    message: json['message'] as String?,
    cvFilename: json['cvFilename'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final int id;
  final int jobId;
  final String jobTitle;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? message;
  final String cvFilename;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName';
}

class ApplicationDraft {
  const ApplicationDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvFilename,
    required this.cvBytes,
    this.phone,
    this.message,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? message;
  final String cvFilename;
  final List<int> cvBytes;
}

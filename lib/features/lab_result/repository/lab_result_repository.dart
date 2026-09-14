import '../model/lab_result.dart';

abstract class LabResultRepository {
  Future<List<LabResult>> getLabResults();
}

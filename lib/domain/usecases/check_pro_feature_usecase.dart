import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/domain/repositories/pro_access_repository.dart';

/// Use case for checking Pro feature availability
class CheckProFeatureUseCase {
  final ProAccessRepository _repository;

  CheckProFeatureUseCase({required ProAccessRepository repository})
    : _repository = repository;

  Future<bool> execute(ProFeature feature) async {
    return await _repository.hasFeature(feature);
  }
}

/// Use case for getting Pro access state
class GetProAccessUseCase {
  final ProAccessRepository _repository;

  GetProAccessUseCase({required ProAccessRepository repository})
    : _repository = repository;

  Future<ProAccess> execute() async {
    return await _repository.getProAccess();
  }
}

/// Use case for validating Pro access
class ValidateProAccessUseCase {
  final ProAccessRepository _repository;

  ValidateProAccessUseCase({required ProAccessRepository repository})
    : _repository = repository;

  Future<bool> execute() async {
    return await _repository.validateProAccess();
  }
}

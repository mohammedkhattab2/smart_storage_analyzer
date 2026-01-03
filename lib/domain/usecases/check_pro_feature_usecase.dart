import 'package:smart_storage_analyzer/domain/entities/pro_access.dart';
import 'package:smart_storage_analyzer/domain/repositories/pro_access_repository.dart';

/// Use case for checking Pro feature availability
class CheckProFeatureUsecase {
  final ProAccessRepository _repository;
  
  CheckProFeatureUsecase({required ProAccessRepository repository})
      : _repository = repository;
  
  Future<bool> execute(ProFeature feature) async {
    return await _repository.hasFeature(feature);
  }
}

/// Use case for getting Pro access state
class GetProAccessUsecase {
  final ProAccessRepository _repository;
  
  GetProAccessUsecase({required ProAccessRepository repository})
      : _repository = repository;
  
  Future<ProAccess> execute() async {
    return await _repository.getProAccess();
  }
}

/// Use case for validating Pro access
class ValidateProAccessUsecase {
  final ProAccessRepository _repository;
  
  ValidateProAccessUsecase({required ProAccessRepository repository})
      : _repository = repository;
  
  Future<bool> execute() async {
    return await _repository.validateProAccess();
  }
}
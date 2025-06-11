import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_break_manager/providers/app_providers.dart';
import 'package:micro_break_manager/services/file_storage_service.dart';

void main() {
  group('Basic Provider Tests', () {
    test('storageServiceProvider creates FileStorageService', () {
      final container = ProviderContainer();
      
      final storage = container.read(storageServiceProvider);
      expect(storage, isA<FileStorageService>());
      
      container.dispose();
    });

    test('breakStateProvider initial state is inactive', () {
      final container = ProviderContainer();
      
      final breakState = container.read(breakStateProvider);
      expect(breakState.isActive, false);
      expect(breakState.startTime, isNull);
      expect(breakState.currentList, isNull);
      expect(breakState.currentItem, isNull);
      
      container.dispose();
    });

    test('savedIndicesProvider starts with empty map', () {
      final container = ProviderContainer();
      
      final indices = container.read(savedIndicesProvider);
      expect(indices, isEmpty);
      
      container.dispose();
    });

    test('selectedLogDateProvider starts as null', () {
      final container = ProviderContainer();
      
      final selectedDate = container.read(selectedLogDateProvider);
      expect(selectedDate, isNull);
      
      container.dispose();
    });
  });
}
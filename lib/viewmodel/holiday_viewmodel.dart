import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/holiday_model.dart';
import '../repo/holiday_repo.dart';

final holidayRepositoryProvider = Provider<HolidayRepository>((ref) => HolidayRepository());

class HolidayViewModel extends AsyncNotifier<List<HolidayModel>> {
  DateTime? _lastFrom;
  DateTime? _lastTo;

  int get currentYear => (_lastFrom ?? DateTime.now()).year;

  @override
  FutureOr<List<HolidayModel>> build() {
    final now = DateTime.now();
    _lastFrom = DateTime(now.year, 1, 1);
    _lastTo = DateTime(now.year, 12, 31);
    return ref.read(holidayRepositoryProvider).getHolidays(from: _lastFrom, to: _lastTo);
  }

  Future<void> loadYear(int year) async {
    _lastFrom = DateTime(year, 1, 1);
    _lastTo = DateTime(year, 12, 31);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(holidayRepositoryProvider).getHolidays(from: _lastFrom, to: _lastTo),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(holidayRepositoryProvider).getHolidays(from: _lastFrom, to: _lastTo),
    );
  }
}

final holidayViewModelProvider = AsyncNotifierProvider<HolidayViewModel, List<HolidayModel>>(HolidayViewModel.new);
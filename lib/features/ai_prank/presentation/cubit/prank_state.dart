import 'package:equatable/equatable.dart';
import '../../../todo_list/domain/entities/todo.dart';

/// State pro AI Prank generování
abstract class PrankState extends Equatable {
  const PrankState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PrankInitial extends PrankState {
  const PrankInitial();
}

/// Generování pranku probíhá
class PrankLoading extends PrankState {
  final bool isPrank; // ✅ true = prank loading, false = good deed loading

  const PrankLoading({this.isPrank = true});

  @override
  List<Object?> get props => [isPrank];
}

/// Prank/Good Deed úspěšně vygenerován
class PrankLoaded extends PrankState {
  final String prankMessage;
  final Todo completedTodo; // ✅ Přidáno pro zobrazení v UI
  final bool isPrank; // ✅ true = prank, false = good deed

  const PrankLoaded(this.prankMessage, this.completedTodo, {this.isPrank = true});

  @override
  List<Object?> get props => [prankMessage, completedTodo, isPrank];
}

/// Chyba při generování pranku
class PrankError extends PrankState {
  final String errorMessage;

  const PrankError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reso_tdd/core/error/failures.dart';
import 'package:reso_tdd/core/usecases/usecase.dart';
import 'package:reso_tdd/core/util/input_converter.dart';
import 'package:reso_tdd/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:reso_tdd/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:reso_tdd/features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'package:reso_tdd/features/number_trivia/presentation/bloc/bloc.dart';

class MockGetConcreteNumberTrivia extends Mock
    implements GetConcreteNumberTrivia {}

class MockGetRandomNumberTrivia extends Mock implements GetRandomNumberTrivia {}

class MockInputConverter extends Mock implements InputConverter {}

class FakeParams extends Fake implements Params {}

class FakeNoParams extends Fake implements NoParams {}

void main() {
  late NumberTriviaBloc bloc;
  late MockGetConcreteNumberTrivia mockGetConcreteNumberTrivia;
  late MockGetRandomNumberTrivia mockGetRandomNumberTrivia;
  late MockInputConverter mockInputConverter;

  setUp(() {
    mockGetConcreteNumberTrivia = MockGetConcreteNumberTrivia();
    mockGetRandomNumberTrivia = MockGetRandomNumberTrivia();
    mockInputConverter = MockInputConverter();
    bloc = NumberTriviaBloc(
      concrete: mockGetConcreteNumberTrivia,
      random: mockGetRandomNumberTrivia,
      inputConverter: mockInputConverter,
    );
  });

  // Necessary setup to use Params with mocktail null safety
  setUpAll(() {
    registerFallbackValue<Params>(FakeParams());
    registerFallbackValue<NoParams>(FakeNoParams());
  });

  test('initialState should be Empty', () {
    // assert
    expect(bloc.initialState, equals(Empty()));
  });

  group('GetTriviaForConcreteNumber', () {
    // The event takes in a string
    final tNumberString = '1';
    // This is the successful output of the InputConverter
    final tNumberParsed = 1;

    final tNumberTrivia = NumberTrivia(text: 'test trivia', number: 1);

    void setUpInputAndConcreteMocks() {
      when(() => mockInputConverter.stringToUnsignedInteger(any()))
          .thenReturn(Right(tNumberParsed));
      when(() => mockGetConcreteNumberTrivia(any()))
          .thenAnswer((_) async => Right(tNumberTrivia));
    }

    test(
      'should call the InputConverter to validate and convert the string to an unsigned integer',
      () async {
        // arrange
        setUpInputAndConcreteMocks();
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(
            () => mockInputConverter.stringToUnsignedInteger(any()));
        // assert
        verify(() => mockInputConverter.stringToUnsignedInteger(tNumberString));
      },
    );

    test(
      'should emit [Error] when the input is invalid',
      () async {
        // arrange
        when(() => mockInputConverter.stringToUnsignedInteger(any()))
            .thenReturn(Left(InvalidInputFailure()));
        // assert later
        final expected = [
          Error(message: INVALID_INPUT_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should get data from the concrete use case',
      () async {
        // arrange
        setUpInputAndConcreteMocks();
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(() => mockGetConcreteNumberTrivia(any()));
        // assert
        verify(
            () => mockGetConcreteNumberTrivia(Params(number: tNumberParsed)));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async {
        // arrange
        setUpInputAndConcreteMocks();
        // assert later
        final expected = [
          Loading(),
          Loaded(trivia: tNumberTrivia),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] with serverFailureMessage when getting data fails with a ServerFailure',
      () async {
        // arrange
        when(() => mockInputConverter.stringToUnsignedInteger(any()))
            .thenReturn(Right(tNumberParsed));
        when(() => mockGetConcreteNumberTrivia(any()))
            .thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          Loading(),
          Error(message: SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
        'should emit [Loading, Error] with cacheFailureMessage when getting data fails with a CacheFailure',
        () async {
      // arrange
      when(() => mockInputConverter.stringToUnsignedInteger(any()))
          .thenReturn(Right(tNumberParsed));
      when(() => mockGetConcreteNumberTrivia(any()))
          .thenAnswer((_) async => Left(CacheFailure()));
      // assert later
      final expected = [
        Loading(),
        Error(message: CACHE_FAILURE_MESSAGE),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      // act
      bloc.add(GetTriviaForConcreteNumber(tNumberString));
    });
  });

  group('GetTriviaForRandomNumber', () {
    final tNumberTrivia = NumberTrivia(text: 'test trivia', number: 1);

    test('should get data from the random case', () async {
      // arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Right(tNumberTrivia));
      // act
      bloc.add(GetTriviaForRandomNumber());
      await untilCalled(() => mockGetRandomNumberTrivia(any()));
      // assert
      verify(() => mockGetRandomNumberTrivia(NoParams()));
    });

    test('should emit [Loading, Loaded] when data is gotten successfully',
        () async {
      // arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Right(tNumberTrivia));
      // assert later
      final expected = [
        Loading(),
        Loaded(trivia: tNumberTrivia),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      // act
      bloc.add(GetTriviaForRandomNumber());
    });

    test(
        'should emit [Loading, Error] with serverFailureMessage when getting data fails with a ServerFailure',
        () async {
      // arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Left(ServerFailure()));
      // assert later
      final expected = [
        Loading(),
        Error(message: SERVER_FAILURE_MESSAGE),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      // act
      bloc.add(GetTriviaForRandomNumber());
    });

    test(
        'should emit [Loading, Error] with cacheFailureMessage when getting data fails with a CacheFailure',
        () async {
      // arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Left(CacheFailure()));
      // assert later
      final expected = [
        Loading(),
        Error(message: CACHE_FAILURE_MESSAGE),
      ];
      expectLater(bloc.stream, emitsInOrder(expected));
      // act
      bloc.add(GetTriviaForRandomNumber());
    });
  });
}

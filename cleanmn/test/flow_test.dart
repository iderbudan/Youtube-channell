import 'package:cleanmn/main.dart';
import 'package:cleanmn/services/mock_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Бүтэн урсгал: бараа сонгох → сагс → хаяг → QPay → захиалгын төлөв.
void main() {
  testWidgets('Захиалгын бүтэн урсгал', (tester) => _runFlow(tester, const Size(1080, 2400), 1.0));

  // Жижиг утас (320dp) + том фонт: ямар ч дэлгэц дээр overflow гарах ёсгүй.
  testWidgets('Жижиг дэлгэц, том фонт', (tester) => _runFlow(tester, const Size(800, 2000), 1.3));
}

Future<void> _runFlow(WidgetTester tester, Size physicalSize, double textScale) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 2.5;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(CleanMNApp(api: MockApiService()));
  await tester.pump(const Duration(seconds: 1)); // каталог ачаалах
  expect(find.text('Гарын шингэн саван'), findsOneWidget);

  // Ангиллаар шүүх
  await tester.scrollUntilVisible(
    find.text('Шүүр, арчуур'),
    100,
    scrollable: find.descendant(
      of: find.byKey(const Key('categories')),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(find.text('Шүүр, арчуур'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Шүүр, арчуур'));
  await tester.pump();
  expect(find.text('Гарын шингэн саван'), findsNothing);
  expect(find.text('Шал арчуур + хувин'), findsOneWidget);

  // Сагсанд нэмэх
  await tester.tap(find.byTooltip('Сагсанд нэмэх').first);
  await tester.pump();

  // Сагс таб
  await tester.tap(find.text('Сагс'));
  await tester.pumpAndSettle();
  expect(find.text('Захиалах'), findsOneWidget);
  expect(find.text('Үнэгүй'), findsNothing); // 45,000 < 50,000
  await tester.tap(find.text('Захиалах'));
  await tester.pumpAndSettle();

  // Хүргэлтийн мэдээлэл — эхлээд хоосноор илгээвэл алдаа
  await tester.tap(find.textContaining('QPay-ээр төлөх'));
  await tester.pump();
  expect(find.text('Утасны дугаараа оруулна уу'), findsOneWidget);

  await tester.enterText(find.widgetWithText(TextFormField, 'Хүлээн авагчийн нэр'), 'Болд');
  await tester.enterText(find.widgetWithText(TextFormField, 'Утасны дугаар'), '99112233');
  await tester.tap(find.text('Дүүрэг (Улаанбаатар)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Хан-Уул').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Хороо'), '15');
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Дэлгэрэнгүй хаяг'),
    'Ривер гарден, 305-р байр, 2 орц, 45 тоот',
  );
  await tester.tap(find.textContaining('QPay-ээр төлөх'));
  await tester.pump(const Duration(seconds: 1)); // захиалга үүсгэх
  await tester
      .pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      )
      .catchError((_) => 0);
  await tester.pump(const Duration(seconds: 1)); // нэхэмжлэх

  // QPay дэлгэц
  expect(find.text('QPay төлбөр'), findsOneWidget);
  expect(find.text('Хаан банк'), findsOneWidget);
  expect(find.text('50,000₮'), findsOneWidget);

  // Гараар 1 удаа, автомат 1 удаа шалгахад демо төлөгдөнө
  await tester.tap(find.text('Төлбөр шалгах'));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text('Төлбөр амжилттай'), findsOneWidget);

  await tester.tap(find.text('Захиалга харах'));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text('Хүргэлт'), findsWidgets);
  expect(find.textContaining('Хан-Уул дүүрэг, 15-р хороо'), findsOneWidget);
  expect(find.text('Төлбөр төлөгдсөн'), findsWidgets);

  // Таймеруудыг зогсоох
  await tester.pumpWidget(const SizedBox());
}

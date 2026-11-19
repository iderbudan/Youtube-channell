import '../models/product.dart';

/// Демо каталог. Сервер дээрх `cleanmn-server/catalog.json`-тэй ижил.
const demoCatalog = <Product>[
  Product(id: 'p01', name: 'Гарын шингэн саван', category: ProductCategory.soap, price: 6500, unit: '500мл', emoji: '🧴', description: 'Арьс хуурайшуулахгүй, алоэ вератай шингэн саван. Шахуургатай сав.'),
  Product(id: 'p02', name: 'Хүүхдийн саван', category: ProductCategory.soap, price: 2900, unit: '90г', emoji: '🧼', description: 'Үнэргүй, гипоаллерген хүүхдийн хатуу саван.'),
  Product(id: 'p03', name: 'Байгалийн гар саван (3ш)', category: ProductCategory.soap, price: 8900, unit: '3×100г', emoji: '🧼', description: 'Чацаргана, лаванда, гаа — 3 төрлийн байгалийн саван.'),
  Product(id: 'p04', name: 'Угаалгын нунтаг', category: ProductCategory.detergent, price: 24900, unit: '3кг', emoji: '📦', description: 'Автомат болон гар угаалгад тохиромжтой, 40 удаагийн хэрэглээ.'),
  Product(id: 'p05', name: 'Шингэн угаалгын бодис', category: ProductCategory.detergent, price: 19500, unit: '2л', emoji: '🫧', description: 'Өнгөт хувцасны өнгө хадгалах шингэн бодис.'),
  Product(id: 'p06', name: 'Аяга таваг угаагч', category: ProductCategory.detergent, price: 7800, unit: '1л', emoji: '🍽️', description: 'Тос сайн арилгадаг, нимбэгний үнэртэй.'),
  Product(id: 'p07', name: 'Шал арчуур + хувин', category: ProductCategory.broom, price: 45000, unit: 'иж бүрдэл', emoji: '🪣', description: 'Эргэдэг шахагчтай хувин, микрофибр толгойтой моп.'),
  Product(id: 'p08', name: 'Шүүр + хогийн хүрз', category: ProductCategory.broom, price: 15900, unit: 'иж бүрдэл', emoji: '🧹', description: 'Урт иштэй шүүр, резин ирмэгтэй хүрз.'),
  Product(id: 'p09', name: 'Микрофибр арчуур (5ш)', category: ProductCategory.broom, price: 9900, unit: '5ш', emoji: '🧽', description: 'Гал тогоо, шил, тавилганд зориулсан 30×30см арчуур.'),
  Product(id: 'p10', name: 'Ариутгагч спрей', category: ProductCategory.disinfectant, price: 8500, unit: '500мл', emoji: '🧪', description: 'Гадаргуугийн бактерийн 99.9%-ийг устгана.'),
  Product(id: 'p11', name: 'Гар ариутгагч гель', category: ProductCategory.disinfectant, price: 5900, unit: '250мл', emoji: '🫙', description: '70% спирттэй, арьс чийгшүүлэгчтэй гель.'),
  Product(id: 'p12', name: 'Хлортой цайруулагч', category: ProductCategory.disinfectant, price: 4500, unit: '1л', emoji: '🧴', description: 'Ариун цэврийн өрөө, шал ариутгах, цайруулах бодис.'),
  Product(id: 'p13', name: 'Нүүрний алчуур', category: ProductCategory.towel, price: 12900, unit: '50×90см', emoji: '🧺', description: '100% хөвөн, зөөлөн, ус сайн шингээдэг.'),
  Product(id: 'p14', name: 'Банны том алчуур', category: ProductCategory.towel, price: 32000, unit: '70×140см', emoji: '🛁', description: 'Зузаан хөвөн банны алчуур.'),
  Product(id: 'p15', name: 'Резин бээлий', category: ProductCategory.other, price: 3500, unit: '1 хос', emoji: '🧤', description: 'Цэвэрлэгээний урт резин бээлий, M/L хэмжээ.'),
  Product(id: 'p16', name: 'Хогийн уут 60л (30ш)', category: ProductCategory.other, price: 4900, unit: '30ш', emoji: '🗑️', description: 'Бат бөх, уяатай хогийн уут.'),
];

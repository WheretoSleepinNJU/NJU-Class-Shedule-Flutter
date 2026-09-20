/// 课程"自动配色方案"定义。每套方案是一份色板（十六进制颜色列表）；
/// 具体某门课分到色板里哪个颜色，逻辑在 [lib/Utils/ColorUtil.dart] 的
/// `ColorPool` 和 [lib/Models/CourseModel.dart] 的 `Course.getColor()` 里。
///
/// 这里独立于 [lib/Resources/Colors.dart] 的 `colorList`（那份是"关于"页
/// 雨滴动画用的装饰色，跟课程配色是两回事，不共用同一份数据）。
///
/// 8 套方案分两类设计：
/// - [macaron]/[morandi]/[vibrant] 这 3 套是"全色相"方案：12 个颜色在
///   色相环上均匀间隔 30°（互相差异最大化），三套之间只是饱和度/明度
///   配方不同（柔和高亮度 / 低饱和灰调 / 中高饱和明快），色相范围本身
///   没变。
/// - 其余 5 套是"主色扩展"方案：只取色相环上一段（不追求覆盖所有颜色），
///   在这一段里选 4 个色相，每个色相各出浅/中/深 3 档，配出 12 个颜色。
///   5 套统一用同一组浅/中/深饱和度-明度数值（浅：S45% L70%；中：
///   S55% L55%；深：S55% L40%），这样每套内部没有哪个颜色会因为格外
///   鲜艳或格外浅/深而显得突兀，区分度主要来自色相走向 + 三档明暗。
class CourseColorScheme {
  final String id;
  final String displayName;
  final List<String> colors;

  const CourseColorScheme({
    required this.id,
    required this.displayName,
    required this.colors,
  });
}

class CourseColorSchemes {
  // 下面这些都是先给你预览用的候选方案，看完喜欢哪套就留哪套，不喜欢
  // 的直接把整个 const 定义和下面 `all` 列表里对应那一行删掉即可。

  // ===== 全色相方案（3 套，仅饱和度/明度配方不同）=====

  static const CourseColorScheme macaron = CourseColorScheme(
    id: 'macaron',
    displayName: '马卡龙',
    colors: [
      '#DE9C9C', '#DEBD9C', '#DEDE9C', '#BDDE9C',
      '#9CDE9C', '#9CDEBD', '#9CDEDE', '#9CBDDE',
      '#9C9CDE', '#BD9CDE', '#DE9CDE', '#DE9CBD',
    ],
  );

  static const CourseColorScheme morandi = CourseColorScheme(
    id: 'morandi',
    displayName: '莫兰迪',
    colors: [
      '#B38989', '#B39E89', '#B3B389', '#9EB389',
      '#89B389', '#89B39E', '#89B3B3', '#899EB3',
      '#8989B3', '#9E89B3', '#B389B3', '#B3899E',
    ],
  );

  static const CourseColorScheme vibrant = CourseColorScheme(
    id: 'vibrant',
    displayName: '高饱和活力',
    colors: [
      '#D44949', '#D49349', '#D4D449', '#93D449',
      '#49D449', '#49D493', '#49D4D4', '#4993D4',
      '#4949D4', '#9349D4', '#D449D4', '#D44993',
    ],
  );

  // ===== 主色扩展方案（5 套，每套围绕 1-2 个主色向色环两侧展开，
  // 统一用浅/中/深三档饱和度-明度）=====

  static const CourseColorScheme ocean = CourseColorScheme(
    id: 'ocean',
    displayName: '海洋清新', // 主色：青绿 + 蓝
    colors: [
      '#90D5C4', '#90C9D5', '#90ACD5', '#9090D5', // 浅
      '#4DCBAC', '#4DB6CB', '#4D81CB', '#4D4DCB', // 中
      '#2E9E82', '#2E8B9E', '#2E5D9E', '#2E2E9E', // 深
    ],
  );

  static const CourseColorScheme earth = CourseColorScheme(
    id: 'earth',
    displayName: '大地色系', // 主色：赤陶棕 + 橄榄绿
    colors: [
      '#D3A190', '#D5B890', '#D5D590', '#ACD590',
      '#CB6D4D', '#CB964D', '#CBCB4D', '#81CB4D',
      '#9E4A2E', '#9E6F2E', '#9E9E2E', '#5D9E2E',
    ],
  );

  static const CourseColorScheme autumn = CourseColorScheme(
    id: 'autumn',
    displayName: '秋日暖阳', // 主色：橙 + 红
    colors: [
      '#D5909C', '#D3A190', '#D5B890', '#D5CF90',
      '#CB4D62', '#CB6D4D', '#CB964D', '#CBC14D',
      '#9E2E41', '#9E4A2E', '#9E6F2E', '#9E942E',
    ],
  );

  static const CourseColorScheme twilight = CourseColorScheme(
    id: 'twilight',
    displayName: '静谧暮色', // 主色：靛蓝 + 紫
    colors: [
      '#90A6D5', '#9690D5', '#B390D5', '#D290D5',
      '#4D77CB', '#584DCB', '#8C4DCB', '#C14DCB',
      '#2E549E', '#372E9E', '#662E9E', '#952E9E',
    ],
  );

  static const CourseColorScheme sakura = CourseColorScheme(
    id: 'sakura',
    displayName: '樱花甜梦', // 主色：粉 + 紫红
    colors: [
      '#C490D5', '#D590C9', '#D590AC', '#D59096',
      '#AC4DCB', '#CB4DB6', '#CB4D81', '#CB4D58',
      '#822E9E', '#9E2E8B', '#9E2E5D', '#9E2E37',
    ],
  );

  static const List<CourseColorScheme> all = [
    macaron,
    morandi,
    vibrant,
    ocean,
    earth,
    autumn,
    twilight,
    sakura,
  ];

  static CourseColorScheme findById(String? id) {
    if (id == null) return all.first;
    for (final scheme in all) {
      if (scheme.id == id) return scheme;
    }
    return all.first;
  }
}

// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps, unnecessary_type_check
/// 培养方案完成情况数据模型
class PlanCompletionModel {
  final double outOfPlanCompletion; // 计划外完成情况
  final int outOfPlanCredits; // 计划外学分
  final int totalCredits; // 总学分要求
  final List<CourseCategory> categories; // 各类别完成情况
  final List<CourseModule> modules; // 详细模块信息

  const PlanCompletionModel({
    required this.outOfPlanCompletion,
    required this.outOfPlanCredits,
    required this.totalCredits,
    required this.categories,
    required this.modules,
  });

  factory PlanCompletionModel.fromJson(Map<String, dynamic> json) {
    final List<CourseCategory> categories = [];
    final List<CourseModule> modules = [];

    print('PlanCompletionModel.fromJson 输入数据: $json');

    // 处理真实API数据结构
    Map<String, dynamic> planCreditsMap = {};
    Map<String, dynamic> actualCreditsMap = {};

    // 首先尝试使用新的解析数据结构（从PlanApi.getPlanCompletion返回的数据）
    if (json['planCreditsMap'] != null && json['planCreditsMap'] is Map) {
      planCreditsMap = Map<String, dynamic>.from(json['planCreditsMap']);
      print('使用 planCreditsMap: $planCreditsMap');
    }

    if (json['actualCreditsMap'] != null && json['actualCreditsMap'] is Map) {
      actualCreditsMap = Map<String, dynamic>.from(json['actualCreditsMap']);
      print('使用 actualCreditsMap: $actualCreditsMap');
    }

    // 如果新数据结构不可用，尝试其他数据结构
    if (planCreditsMap.isEmpty &&
        json['planCredits'] != null &&
        json['planCredits'] is Map) {
      planCreditsMap = Map<String, dynamic>.from(json['planCredits']);
    } else if (planCreditsMap.isEmpty &&
        json['modules'] != null &&
        json['modules'] is List) {
      // 处理modules分类数据 - 这是API实际返回的数据结构
      final modulesList = json['modules'] as List;
      print('处理 modules 数据，共 ${modulesList.length} 个模块');

      for (var module in modulesList) {
        if (module is Map) {
          // 解析模块基本信息
          final moduleType = module['type'] ?? {};
          final name = moduleType['nameZh']?.toString() ?? '';
          final code = moduleType['code']?.toString() ?? '';
          final required = module['requireInfo']?['requiredCredits'] ?? 0;
          final actual = module['passedCredits'] ?? 0;
          final result = module['result']?.toString() ?? '未知';
          final resultEn = module['resultEn']?.toString() ?? 'unknown';
          final taking = module['taking'] ?? 0;

          print('处理模块: $name, 要求学分: $required, 已通过学分: $actual');

          if (name.isNotEmpty) {
            planCreditsMap[name] = required;
            actualCreditsMap[name] = actual;

            // 解析计划课程
            final List<CourseInfo> planCourses = [];
            if (module['planCourses'] != null &&
                module['planCourses'] is List) {
              for (var courseData in module['planCourses']) {
                if (courseData is Map) {
                  final course = _parseCourseInfo(
                    Map<String, dynamic>.from(courseData),
                  );
                  planCourses.add(course);
                }
              }
            }

            // 解析子模块
            final List<CourseModule> children = [];
            if (module['children'] != null && module['children'] is List) {
              for (var childData in module['children']) {
                if (childData is Map) {
                  final child = _parseModule(
                    Map<String, dynamic>.from(childData),
                  );
                  children.add(child);
                }
              }
            }

            // 创建CourseModule对象
            final courseModule = CourseModule(
              name: name,
              code: code,
              requiredCredits: _parseDouble(required) ?? 0.0,
              passedCredits: _parseDouble(actual) ?? 0.0,
              result: result,
              resultEn: resultEn,
              isCompleted: result == '通过' || resultEn == 'passed',
              isTaking: taking > 0 || result == '在读' || resultEn == 'taking',
              taking: _parseInt(taking) ?? 0,
              planCourses: planCourses,
              children: children,
              remark: module['remark']?.toString(),
            );

            modules.add(courseModule);
          }
        }
      }
    } else if (planCreditsMap.isEmpty &&
        json['cultivateCategories'] != null &&
        json['cultivateCategories'] is List) {
      // 处理旧的分类数据
      final modulesList = json['cultivateCategories'] as List;
      for (var module in modulesList) {
        if (module is Map) {
          final name =
              module['name']?.toString() ??
              module['categoryName']?.toString() ??
              '';
          final required = module['requiredCredits'] ?? module['credits'] ?? 0;
          final actual =
              module['actualCredits'] ??
              module['passedCredits'] ??
              module['completedCredits'] ??
              0;

          if (name.isNotEmpty) {
            planCreditsMap[name] = required;
            actualCreditsMap[name] = actual;
          }
        }
      }
    } else if (planCreditsMap.isEmpty &&
        json['planCompletion'] != null &&
        json['planCompletion'] is Map) {
      // 处理计划完成情况
      final planCompletion = json['planCompletion'] as Map<String, dynamic>;
      if (planCompletion['categoryList'] != null &&
          planCompletion['categoryList'] is List) {
        final categoryList = planCompletion['categoryList'] as List;
        for (var category in categoryList) {
          if (category is Map) {
            final name =
                category['categoryName']?.toString() ??
                category['name']?.toString() ??
                '';
            final required =
                category['requiredCredits'] ?? category['credits'] ?? 0;
            final actual =
                category['actualCredits'] ?? category['completedCredits'] ?? 0;

            if (name.isNotEmpty) {
              planCreditsMap[name] = required;
              actualCreditsMap[name] = actual;
            }
          }
        }
      }
    }

    if (actualCreditsMap.isEmpty &&
        json['actualCredits'] != null &&
        json['actualCredits'] is Map) {
      actualCreditsMap = Map<String, dynamic>.from(json['actualCredits']);
    }

    // 如果有分类数据，创建分类列表
    if (planCreditsMap.isNotEmpty) {
      planCreditsMap.forEach((categoryName, requiredCredits) {
        final actualCredits = actualCreditsMap[categoryName] ?? 0;
        categories.add(
          CourseCategory(
            name: categoryName,
            requiredCredits: _parseDouble(requiredCredits) ?? 0.0,
            actualCredits: _parseDouble(actualCredits) ?? 0.0,
          ),
        );
      });
      print('创建了 ${categories.length} 个分类');
    }

    // 如果仍然没有分类数据，创建默认分类
    if (categories.isEmpty) {
      final totalCredits = _parseInt(json['totalPlanCredits']) ?? 0;
      print('没有分类数据，总学分: $totalCredits');

      if (totalCredits > 0) {
        // 根据总学分创建默认分类
        categories.addAll([
          CourseCategory(
            name: '必修课',
            requiredCredits: (totalCredits * 0.6).roundToDouble(),
            actualCredits: (totalCredits * 0.3).roundToDouble(),
          ),
          CourseCategory(
            name: '选修课',
            requiredCredits: (totalCredits * 0.3).roundToDouble(),
            actualCredits: (totalCredits * 0.15).roundToDouble(),
          ),
          CourseCategory(
            name: '实践课',
            requiredCredits: (totalCredits * 0.1).roundToDouble(),
            actualCredits: (totalCredits * 0.05).roundToDouble(),
          ),
        ]);
        print('创建了默认分类');
      }
    }

    // 计算总学分 - 优先使用API返回的requireInfo.credits
    int totalPlanCredits =
        _parseInt(json['totalPlanCredits']) ??
        _parseInt(json['requireInfo']?['credits']) ??
        0;

    if (totalPlanCredits == 0 && planCreditsMap.isNotEmpty) {
      totalPlanCredits = _calculateTotalRequiredCredits(planCreditsMap);
    }

    int totalCompletedCredits = 0;
    if (actualCreditsMap.isNotEmpty) {
      totalCompletedCredits = _calculateTotalCompletedCredits(actualCreditsMap);
    }

    final model = PlanCompletionModel(
      outOfPlanCompletion: _parseDouble(json['outOfPlanCompletion']) ?? 0.0,
      outOfPlanCredits: _parseInt(json['outOfPlanCredits']) ?? 0,
      totalCredits: totalPlanCredits,
      categories: categories,
      modules: modules,
    );

    print(
      'PlanCompletionModel 创建完成: ${categories.length} 个分类, 总学分: ${model.totalCredits}, 已完成学分: $totalCompletedCredits',
    );
    print('总完成率: ${(model.totalCompletionRate * 100).toStringAsFixed(1)}%');
    return model;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// 计算总已完成学分
  static int _calculateTotalCompletedCredits(
    Map<String, dynamic> actualCreditsMap,
  ) {
    int total = 0;
    for (var entry in actualCreditsMap.entries) {
      final credits = _parseDouble(entry.value);
      if (credits != null) {
        total += credits.round();
      }
    }
    return total;
  }

  /// 计算总要求学分
  static int _calculateTotalRequiredCredits(
    Map<String, dynamic> planCreditsMap,
  ) {
    int total = 0;
    for (var entry in planCreditsMap.entries) {
      final credits = _parseDouble(entry.value);
      if (credits != null) {
        total += credits.round();
      }
    }
    return total;
  }

  /// 计算总体完成率
  double get totalCompletionRate {
    if (totalCredits == 0) return 0.0;
    return categories.fold(
          0.0,
          (sum, category) => sum + category.actualCredits,
        ) /
        totalCredits;
  }

  /// 计算计划内完成率
  double get planCompletionRate {
    final totalRequiredCredits = categories.fold(
      0.0,
      (sum, category) => sum + category.requiredCredits,
    );
    if (totalRequiredCredits == 0) return 0.0;
    return categories.fold(
          0.0,
          (sum, category) => sum + category.actualCredits,
        ) /
        totalRequiredCredits;
  }

  /// 解析课程信息
  static CourseInfo _parseCourseInfo(Map<dynamic, dynamic> courseData) {
    final course = courseData['course'] ?? {};

    return CourseInfo(
      name:
          course['nameZh']?.toString() ?? course['name']?.toString() ?? '未知课程',
      nameEn: course['nameEn']?.toString() ?? '',
      code: course['code']?.toString() ?? '',
      credits: _parseDouble(course['credits']) ?? 0.0,
      courseType: course['courseType']?['nameZh']?.toString() ?? '',
      courseTypeCode: course['courseType']?['code']?.toString() ?? '',
      isCompulsory: courseData['compulsory'] ?? false,
      result: courseData['result']?.toString() ?? '未知',
      resultEn: courseData['resultEn']?.toString() ?? 'unknown',
      score: _parseDouble(courseData['score']),
      gp: _parseDouble(courseData['gp']),
      rank: courseData['rank']?.toString(),
      resultScore: courseData['resultScore']?.toString(),
      terms: _parseTerms(courseData['terms']),
      remark: courseData['remark']?.toString(),
      marks: courseData['marks'] ?? [],
      substituteCourses: courseData['substituteCourses'] ?? [],
    );
  }

  /// 解析模块信息
  static CourseModule _parseModule(Map<dynamic, dynamic> moduleData) {
    final moduleType = moduleData['type'] ?? {};
    final name = moduleType['nameZh']?.toString() ?? '';
    final code = moduleType['code']?.toString() ?? '';
    final required = moduleData['requireInfo']?['requiredCredits'] ?? 0;
    final actual = moduleData['passedCredits'] ?? 0;
    final result = moduleData['result']?.toString() ?? '未知';
    final resultEn = moduleData['resultEn']?.toString() ?? 'unknown';
    final taking = moduleData['taking'] ?? 0;

    // 解析计划课程
    final List<CourseInfo> planCourses = [];
    if (moduleData['planCourses'] != null &&
        moduleData['planCourses'] is List) {
      for (var courseData in moduleData['planCourses']) {
        if (courseData is Map) {
          final course = _parseCourseInfo(
            Map<String, dynamic>.from(courseData),
          );
          planCourses.add(course);
        }
      }
    }

    // 解析子模块
    final List<CourseModule> children = [];
    if (moduleData['children'] != null && moduleData['children'] is List) {
      for (var childData in moduleData['children']) {
        if (childData is Map) {
          final child = _parseModule(Map<String, dynamic>.from(childData));
          children.add(child);
        }
      }
    }

    return CourseModule(
      name: name,
      code: code,
      requiredCredits: _parseDouble(required) ?? 0.0,
      passedCredits: _parseDouble(actual) ?? 0.0,
      result: result,
      resultEn: resultEn,
      isCompleted: result == '通过' || resultEn == 'passed',
      isTaking: taking > 0 || result == '在读' || resultEn == 'taking',
      taking: _parseInt(taking) ?? 0,
      planCourses: planCourses,
      children: children,
      remark: moduleData['remark']?.toString(),
    );
  }

  /// 解析学期列表
  static List<String> _parseTerms(dynamic termsData) {
    if (termsData == null) return [];
    if (termsData is List) {
      return termsData.map((term) => term.toString()).toList();
    }
    return [termsData.toString()];
  }
}

/// 课程类别模型
class CourseCategory {
  final String name;
  final double requiredCredits;
  final double actualCredits;

  const CourseCategory({
    required this.name,
    required this.requiredCredits,
    required this.actualCredits,
  });

  /// 计算完成率
  double get completionRate {
    if (requiredCredits == 0) return 0.0;
    return (actualCredits / requiredCredits).clamp(0.0, 1.0);
  }

  /// 是否已完成
  bool get isCompleted => actualCredits >= requiredCredits;

  /// 剩余学分
  double get remainingCredits =>
      (requiredCredits - actualCredits).clamp(0.0, double.infinity);
}

/// 课程模块详细信息模型
class CourseModule {
  final String name; // 模块名称
  final String code; // 模块代码
  final double requiredCredits; // 要求学分
  final double passedCredits; // 已通过学分
  final String result; // 完成状态
  final String resultEn; // 英文完成状态
  final bool isCompleted; // 是否完成
  final bool isTaking; // 是否在读
  final int taking; // 在读课程数
  final List<CourseInfo> planCourses; // 计划课程列表
  final List<CourseModule> children; // 子模块列表
  final String? remark; // 备注

  const CourseModule({
    required this.name,
    required this.code,
    required this.requiredCredits,
    required this.passedCredits,
    required this.result,
    required this.resultEn,
    required this.isCompleted,
    required this.isTaking,
    required this.taking,
    required this.planCourses,
    required this.children,
    this.remark,
  });

  /// 计算完成率
  double get completionRate {
    if (requiredCredits == 0) return 0.0;
    return (passedCredits / requiredCredits).clamp(0.0, 1.0);
  }

  /// 剩余学分
  double get remainingCredits =>
      (requiredCredits - passedCredits).clamp(0.0, double.infinity);

  /// 获取通过的课程数
  int get passedCoursesCount =>
      planCourses.where((course) => course.isPassed).length;

  /// 获取在读的课程数
  int get takingCoursesCount =>
      planCourses.where((course) => course.isTaking).length;

  /// 获取未修的课程数
  int get unreplicatedCoursesCount =>
      planCourses.where((course) => course.isUnrepaired).length;
}

/// 课程详细信息模型
class CourseInfo {
  final String name; // 课程名称
  final String nameEn; // 英文课程名称
  final String code; // 课程代码
  final double credits; // 学分
  final String courseType; // 课程类型
  final String courseTypeCode; // 课程类型代码
  final bool isCompulsory; // 是否必修
  final String result; // 学习结果
  final String resultEn; // 英文学习结果
  final double? score; // 成绩
  final double? gp; // 绩点
  final String? rank; // 等级
  final String? resultScore; // 成绩显示文本
  final List<String> terms; // 上课学期
  final String? remark; // 备注
  final List<dynamic> marks; // 标记
  final List<dynamic> substituteCourses; // 替代课程

  const CourseInfo({
    required this.name,
    required this.nameEn,
    required this.code,
    required this.credits,
    required this.courseType,
    required this.courseTypeCode,
    required this.isCompulsory,
    required this.result,
    required this.resultEn,
    this.score,
    this.gp,
    this.rank,
    this.resultScore,
    required this.terms,
    this.remark,
    required this.marks,
    required this.substituteCourses,
  });

  /// 是否通过
  bool get isPassed => result == '通过' || resultEn == 'passed';

  /// 是否在读
  bool get isTaking => result == '在读' || resultEn == 'taking';

  /// 是否未修
  bool get isUnrepaired => result == '未修' || resultEn == 'unrepaired';

  /// 获取状态颜色
  String getStatusColor() {
    if (isPassed) return 'green';
    if (isTaking) return 'blue';
    return 'orange';
  }

  /// 获取格式化的成绩
  String getFormattedScore() {
    if (resultScore != null) return resultScore!;
    if (score != null) return score!.toString();
    if (rank != null) return rank!;
    return '';
  }

  /// 获取学期显示文本
  String getFormattedTerms() {
    if (terms.isEmpty) return '';

    // 转换TERM_1, TERM_2等为第1学期, 第2学期
    final formattedTerms = terms.map((term) {
      if (term is String && term.startsWith('TERM_')) {
        final number = term.substring(5);
        return '第${number}学期';
      }
      return term.toString();
    }).toList();

    return formattedTerms.join(', ');
  }
}

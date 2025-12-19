# 修复课表选择其他学期时无法正确切换的问题

## 问题描述

在课表页面中，当用户尝试选择其他学期（不是当前学期）时，学期选择器会立即重置回当前学期，无法正确切换到用户选择的学期。

## 问题根因

1. **过度刷新**: `schedule_view.dart` 中的学期选择器在选择学期后同时调用了 `selectSemester()` 和 `refreshData()`
2. **强制重置**: `refreshData()` 方法会重新加载所有数据，包括学期数据，这会覆盖用户的选择
3. **缺少判断**: `loadSemesterData()` 方法总是会设置当前学期为选中状态，不考虑用户是否已经选择了其他学期

## 修复方案

### 1. 修改 `loadSemesterData()` 方法 (`lib/jw/schedule/schedule_logic.dart`)

- 添加检查：如果已经有选中的学期，则保持不变
- 只有在没有选中任何学期时，才设置默认的当前学期
- 对于已选择的非当前学期，使用默认的周数范围（1-20周）

### 2. 修改 `selectSemester()` 方法 (`lib/jw/schedule/schedule_logic.dart`)

- 移除对 `refreshData()` 的调用
- 只调用 `loadScheduleData()` 来加载新课程数据
- 避免重新加载学期数据，从而保留用户的选择

### 3. 修改视图层 (`lib/jw/schedule/schedule_view.dart`)

- 学期选择下拉框只调用 `selectSemester()`
- 移除对 `refreshData()` 的调用

## 修改的文件

1. `lib/jw/schedule/schedule_logic.dart`
   - `loadSemesterData()`: 添加对已选中学期的保护逻辑
   - `selectSemester()`: 避免重新加载学期数据

2. `lib/jw/schedule/schedule_view.dart`
   - 学期选择器回调: 移除多余的 `refreshData()` 调用

## 测试

添加了以下测试来验证修复：

1. `test/semester_selection_test.dart`
   - 测试选择其他学期时不应被重置
   - 测试 `selectSemester` 不应调用 `loadSemesterData`

2. `test/semester_switching_flow_test.dart`
   - 测试完整的学期切换流程
   - 验证状态正确更新

所有现有和新测试均通过。

## 行为变化

### 修复前
- 选择学期 → 自动重置为当前学期 ❌

### 修复后
- 选择学期 → 正确切换到所选学期 ✅
- 其他学期显示默认周数（1-20周）✅
- 当前学期显示真实周数和当前周✅

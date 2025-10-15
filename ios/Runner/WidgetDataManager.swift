import Foundation

/// Widget数据管理器
/// 负责在 App 和 Widget Extension 之间共享数据
class WidgetDataManager {
    static let shared = WidgetDataManager()

    // App Group ID - 需要在 Xcode 中配置
    private let appGroupId = "group.com.wheretosleepinnju.scheduleapp"

    // UserDefaults keys
    private enum Keys {
        static let widgetData = "widget_data"
        static let liveActivityData = "live_activity_data"
        static let unifiedDataPackage = "unified_data_package"
        static let lastUpdateTime = "last_update_time"
    }

    private init() {}

    // MARK: - Save Data

    /// 保存 Widget 数据
    func saveWidgetData(_ data: [String: Any]) -> Bool {
        return saveData(data, forKey: Keys.widgetData)
    }

    /// 保存 Live Activity 数据
    func saveLiveActivityData(_ data: [String: Any]) -> Bool {
        return saveData(data, forKey: Keys.liveActivityData)
    }

    /// 保存统一数据包
    func saveUnifiedDataPackage(_ data: [String: Any]) -> Bool {
        let success = saveData(data, forKey: Keys.unifiedDataPackage)
        if success {
            setLastUpdateTime()
        }
        return success
    }

    /// 通用保存方法
    private func saveData(_ data: [String: Any], forKey key: String) -> Bool {
        guard let appGroup = UserDefaults(suiteName: appGroupId) else {
            print("Failed to access App Group: \(appGroupId)")
            return false
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            appGroup.set(jsonData, forKey: key)
            appGroup.synchronize()
            print("Data saved successfully for key: \(key)")
            return true
        } catch {
            print("Failed to save data for key \(key): \(error)")
            return false
        }
    }

    // MARK: - Load Data

    /// 加载 Widget 数据
    func loadWidgetData() -> WidgetScheduleData? {
        return loadDecodableData(forKey: Keys.widgetData)
    }

    /// 加载 Live Activity 数据
    func loadLiveActivityData() -> [LiveActivityData]? {
        return loadDecodableData(forKey: Keys.liveActivityData)
    }

    /// 加载统一数据包
    func loadUnifiedDataPackage() -> UnifiedDataPackage? {
        return loadDecodableData(forKey: Keys.unifiedDataPackage)
    }

    /// 加载原始 JSON 数据
    func loadRawData(forKey key: String) -> [String: Any]? {
        guard let appGroup = UserDefaults(suiteName: appGroupId),
              let jsonData = appGroup.data(forKey: key) else {
            return nil
        }

        do {
            let data = try JSONSerialization.jsonObject(with: jsonData, options: [])
            return data as? [String: Any]
        } catch {
            print("Failed to load raw data for key \(key): \(error)")
            return nil
        }
    }

    /// 通用加载方法（可解码类型）
    private func loadDecodableData<T: Decodable>(forKey key: String) -> T? {
        guard let appGroup = UserDefaults(suiteName: appGroupId),
              let jsonData = appGroup.data(forKey: key) else {
            print("No data found for key: \(key)")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let data = try decoder.decode(T.self, from: jsonData)
            return data
        } catch {
            print("Failed to decode data for key \(key): \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    /// 设置最后更新时间
    private func setLastUpdateTime() {
        guard let appGroup = UserDefaults(suiteName: appGroupId) else { return }
        appGroup.set(Date(), forKey: Keys.lastUpdateTime)
        appGroup.synchronize()
    }

    /// 获取最后更新时间
    func getLastUpdateTime() -> Date? {
        guard let appGroup = UserDefaults(suiteName: appGroupId) else { return nil }
        return appGroup.object(forKey: Keys.lastUpdateTime) as? Date
    }

    /// 清除所有数据
    func clearAllData() {
        guard let appGroup = UserDefaults(suiteName: appGroupId) else { return }
        appGroup.removeObject(forKey: Keys.widgetData)
        appGroup.removeObject(forKey: Keys.liveActivityData)
        appGroup.removeObject(forKey: Keys.unifiedDataPackage)
        appGroup.removeObject(forKey: Keys.lastUpdateTime)
        appGroup.synchronize()
        print("All widget data cleared")
    }

    /// 检查数据是否存在
    func hasData(forKey key: String) -> Bool {
        guard let appGroup = UserDefaults(suiteName: appGroupId) else { return false }
        return appGroup.data(forKey: key) != nil
    }

    /// 获取数据大小
    func getDataSize(forKey key: String) -> Int {
        guard let appGroup = UserDefaults(suiteName: appGroupId),
              let data = appGroup.data(forKey: key) else {
            return 0
        }
        return data.count
    }

    // MARK: - Widget Specific Helpers

    /// 获取今日课程
    func getTodayCourses() -> [WidgetCourse]? {
        return loadWidgetData()?.todayCourses
    }

    /// 获取下一节课
    func getNextCourse() -> WidgetCourse? {
        return loadWidgetData()?.nextCourse
    }

    /// 获取当前课程
    func getCurrentCourse() -> WidgetCourse? {
        return loadWidgetData()?.currentCourse
    }

    /// 获取学校时间模板
    func getTimeTemplate() -> SchoolTimeTemplate? {
        return loadWidgetData()?.timeTemplate
    }

    // MARK: - Debug Helpers

    /// 打印所有数据（用于调试）
    func printAllData() {
        print("=== Widget Data Manager Debug Info ===")
        print("App Group ID: \(appGroupId)")
        print("Last Update Time: \(getLastUpdateTime()?.description ?? "None")")
        print("Widget Data Size: \(getDataSize(forKey: Keys.widgetData)) bytes")
        print("Live Activity Data Size: \(getDataSize(forKey: Keys.liveActivityData)) bytes")
        print("Unified Package Size: \(getDataSize(forKey: Keys.unifiedDataPackage)) bytes")

        if let widgetData = loadWidgetData() {
            print("Today's Courses: \(widgetData.todayCourses.count)")
            print("Tomorrow's Courses: \(widgetData.tomorrowCourses.count)")
            print("Current Week: \(widgetData.currentWeek)")
        }
        print("====================================")
    }
}

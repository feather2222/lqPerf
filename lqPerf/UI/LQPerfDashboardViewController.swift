import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
final class LQPerfDashboardViewController: UITableViewController {
    var onClose: (() -> Void)?
    private var events: [LQPerfMetricEvent] = []
    private var filtered: [LQPerfMetricEvent] = []
    private var grouped: [LQPerfMetricType: [LQPerfMetricEvent]] = [:]
    private var isGrouped = false
    private var selectedType: LQPerfMetricType?
    private var searchText: String = ""

    private let chartView = LQPerfChartView()
    private let typeControl = UISegmentedControl(items: ["All", "startup", "fps", "memory", "lag", "cpu", "network", "appSwitch", "firstFrame", "device"])
    private let groupSwitch = UISwitch()
    private let groupLabel = UILabel()
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LQPerf"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeTapped))
        setupHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutHeader()
    }

    func reload() {
        events = LQPerf.shared.recentEvents().reversed()
        applyFilters()
    }

    @objc private func closeTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            onClose?()
        }
    }

    @objc private func exportTapped() {
        guard let url = exportURL() else { return }
        let ok = LQPerf.shared.exportRecentEvents(to: url)
        let message = ok ? "已导出：\n\(url.lastPathComponent)" : "导出失败"
        let alert = UIAlertController(title: "Export", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func exportURL() -> URL? {
        let fm = FileManager.default
        guard let dir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return dir.appendingPathComponent("lqperf-events.json")
    }

    private func setupHeader() {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchResultsUpdater = self
        navigationItem.searchController = search

        typeControl.selectedSegmentIndex = 0
        typeControl.addTarget(self, action: #selector(typeChanged), for: .valueChanged)

        groupLabel.text = "Group"
        groupLabel.font = UIFont.systemFont(ofSize: 12)
        groupSwitch.addTarget(self, action: #selector(groupChanged), for: .valueChanged)

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 180))
        header.backgroundColor = .clear

        chartView.frame = CGRect(x: 16, y: 8, width: header.bounds.width - 32, height: 100)
        header.addSubview(chartView)

        typeControl.frame = CGRect(x: 16, y: 116, width: header.bounds.width - 32, height: 28)
        header.addSubview(typeControl)

        let groupContainer = UIView(frame: CGRect(x: 16, y: 146, width: header.bounds.width - 32, height: 28))
        groupLabel.frame = CGRect(x: 0, y: 4, width: 60, height: 20)
        groupSwitch.frame = CGRect(x: 64, y: 0, width: 50, height: 28)
        groupContainer.addSubview(groupLabel)
        groupContainer.addSubview(groupSwitch)
        header.addSubview(groupContainer)

        tableView.tableHeaderView = header
    }

    private func layoutHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        let height: CGFloat = 180
        header.frame = CGRect(x: 0, y: 0, width: width, height: height)

        chartView.frame = CGRect(x: 16, y: 8, width: width - 32, height: 100)
        typeControl.frame = CGRect(x: 16, y: 116, width: width - 32, height: 28)

        if let groupContainer = header.subviews.last {
            groupContainer.frame = CGRect(x: 16, y: 146, width: width - 32, height: 28)
        }

        tableView.tableHeaderView = header
    }

    @objc private func typeChanged() {
        let index = typeControl.selectedSegmentIndex
        if index == 0 {
            selectedType = nil
        } else {
            let types: [LQPerfMetricType] = [.startup, .fps, .memory, .lag, .cpu, .network, .appSwitch, .firstFrame, .device]
            selectedType = types[index - 1]
        }
        applyFilters()
    }

    @objc private func groupChanged() {
        isGrouped = groupSwitch.isOn
        applyFilters()
    }

    private func applyFilters() {
        let text = searchText.lowercased()
        filtered = events.filter { event in
            let typeOk = selectedType == nil || event.type == selectedType
            if !typeOk { return false }
            guard !text.isEmpty else { return true }
            let valueText = String(format: "%.2f", event.value)
            let infoText = String(describing: event.info)
            let combined = "\(event.type.rawValue) \(valueText) \(infoText)".lowercased()
            return combined.contains(text)
        }

        grouped = Dictionary(grouping: filtered, by: { $0.type })
        updateChart()
        tableView.reloadData()
    }

    private func updateChart() {
        let data = filtered.prefix(50).map { $0.value }.reversed()
        chartView.values = Array(data)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isGrouped {
            let key = sectionType(section)
            return grouped[key]?.count ?? 0
        }
        return filtered.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isGrouped {
            return LQPerfMetricType.allCases.count
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isGrouped {
            let key = sectionType(section)
            return key.rawValue
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let event: LQPerfMetricEvent
        if isGrouped {
            let key = sectionType(indexPath.section)
            event = grouped[key]?[indexPath.row] ?? events[indexPath.row]
        } else {
            event = filtered[indexPath.row]
        }
        let time = formatter.string(from: event.timestamp)
        let value = String(format: "%.2f", event.value)
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = "[\(time)] \(event.type.rawValue): \(value)\n\(event.info)"
        return cell
    }

    private func sectionType(_ section: Int) -> LQPerfMetricType {
        return LQPerfMetricType.allCases[section]
    }
}

extension LQPerfDashboardViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        applyFilters()
    }
}
#endif

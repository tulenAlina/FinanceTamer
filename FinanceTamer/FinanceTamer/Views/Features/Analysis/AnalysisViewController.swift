import UIKit
import PieChart

final class AnalysisViewController: UIViewController {
    
    // MARK: - Properties
    
    var viewModel: MyHistoryViewModel
    var transactionsViewModel: TransactionsViewModel?
    var currencySymbol: String = "₽"
    
    private var cachedCategoryStats: [(category: Category, amount: Decimal, percentage: Double)] = []
    private var cachedTransactionStats: [(transaction: TransactionResponse, percentage: Double)] = []
    private var lastUpdateTime: Date = Date()
    
    private var startDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        let components = calendar.dateComponents([.year, .month, .day], from: monthAgo)
        return calendar.date(from: components) ?? today
    }()
    
    private var endDate: Date = {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.hour = 23
        components.minute = 59
        return calendar.date(from: components) ?? Date()
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(AnalysisCell.self, forCellReuseIdentifier: AnalysisCell.reuseIdentifier)
        tableView.register(DatePickerCell.self, forCellReuseIdentifier: DatePickerCell.reuseIdentifier)
        tableView.register(TotalAmountCell.self, forCellReuseIdentifier: TotalAmountCell.reuseIdentifier)
        tableView.register(SortingCell.self, forCellReuseIdentifier: SortingCell.reuseIdentifier)
        tableView.register(PieChartCell.self, forCellReuseIdentifier: PieChartCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        //tableView.separatorStyle = .singleLine
        //tableView.separatorInset = UIEdgeInsets(top: 0, left: 54, bottom: 0, right: 0)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.rowHeight = 44
        return tableView
    }()
    
    private let horizontalInset: CGFloat = 16
    private let cornerRadius: CGFloat = 10
    
    private var lastChartUpdateTime = Date()
    private let chartUpdateDebounceInterval: TimeInterval = 0.3
    private var isUpdatingChart = false
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var pieChartEntities: [Entity] {
        let topCategories = Array(cachedCategoryStats.prefix(5))
        let otherValue = cachedCategoryStats.dropFirst(5).reduce(Decimal(0)) { $0 + $1.amount }
        var entities = topCategories.map { Entity(value: $0.amount, label: $0.category.name) }
        if otherValue > 0 {
            entities.append(Entity(value: otherValue, label: "Остальные"))
        }
        return entities
    }
    
    // MARK: - Initialization
    
    init(viewModel: MyHistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var pieChartView: PieChartView = {
        let view = PieChartView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var chartContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupActivityIndicator()
        loadData()
        //tableView.separatorStyle = .none
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalInset),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        title = "Анализ"
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadData() {
        activityIndicator.startAnimating()
        Task {
            do {
                if let transactionsVM = transactionsViewModel {
                    await transactionsVM.loadTransactions()
                } else {
                    let accounts = try? await BankAccountsService().getAllAccounts()
                    let accountId = accounts?.first?.id ?? 1
                    await viewModel.loadData(from: startDate, to: endDate, accountId: accountId)
                }
                DispatchQueue.main.async {
                    self.updateCache()
                    self.tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    private func updateSorting(_ newSort: SortType) {
        guard newSort != viewModel.sortType else { return }
        
        viewModel.sortType = newSort
        updateCache()
        
        // Плавное обновление только секции с категориями
        UIView.transition(
            with: tableView,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
            }
        )
    }
    
    private func updateCache() {
        cachedCategoryStats = getCategoryStats()
        cachedTransactionStats = getTransactionStats()
        lastUpdateTime = Date()
        updatePieChart()
    }
    
    private var isChartUpdating = false
    
    private func updatePieChart() {
        let now = Date()
        guard now.timeIntervalSince(lastChartUpdateTime) > chartUpdateDebounceInterval else {
            return
        }
        
        lastChartUpdateTime = now
        
        let topCategories = Array(cachedCategoryStats.prefix(5))
        let otherValue = cachedCategoryStats.dropFirst(5).reduce(Decimal(0)) { $0 + $1.amount }
        
        var entities = topCategories.map { Entity(value: $0.amount, label: $0.category.name) }
        if otherValue > 0 {
            entities.append(Entity(value: otherValue, label: "Остальные"))
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.pieChartView.entities = entities
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func changeDate(newValue: Date, typeDate: TypeDate) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: newValue)
        
        switch typeDate {
        case .start:
            components.hour = 00
            components.minute = 00
            startDate = calendar.date(from: components) ?? newValue
            if startDate > endDate {
                endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newValue) ?? newValue
            }
        case .end:
            components.hour = 23
            components.minute = 59
            endDate = calendar.date(from: components) ?? newValue
            if endDate < startDate {
                startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: newValue) ?? newValue
            }
        }
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCache()
    }
    
    private func showDatePicker(for type: TypeDate, currentDate: Date) {
        let calendarVC = UIViewController()
        calendarVC.view.backgroundColor = .clear
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.date = currentDate
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        calendarVC.view.addSubview(datePicker)
        
        let height: CGFloat = 400
        calendarVC.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 40, height: height)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: calendarVC.view.topAnchor),
            datePicker.leadingAnchor.constraint(equalTo: calendarVC.view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: calendarVC.view.trailingAnchor),
            datePicker.heightAnchor.constraint(equalToConstant: height)
        ])
        
        let alert = UIAlertController(
            title: type == .start ? "Выберите начальную дату" : "Выберите конечную дату",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.setValue(calendarVC, forKey: "contentViewController")
        
        alert.addAction(UIAlertAction(title: "Готово", style: .default) { [weak self] _ in
            self?.changeDate(newValue: datePicker.date, typeDate: type)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func getFilteredTransactions() -> [TransactionResponse] {
        guard let transactionsVM = transactionsViewModel else { return [] }
        let isoFormatter = ISO8601DateFormatter()
        let filteredTransactions = transactionsVM.allTransactions.compactMap { transaction -> TransactionResponse? in
            // transaction: TransactionResponse
            let category = transactionsVM.category(for: transaction)
            let isCorrectDirection = category?.direction == viewModel.selectedDirection
            guard let date = isoFormatter.date(from: transaction.transactionDate) else { return nil }
            let isInDateRange = date >= startDate && date <= endDate
            return (isCorrectDirection && isInDateRange) ? transaction : nil
        }
        return filteredTransactions
    }
    
    private func getCategoryStats() -> [(category: Category, amount: Decimal, percentage: Double)] {
        guard let transactionsVM = transactionsViewModel else { return [] }
        let isoFormatter = ISO8601DateFormatter()
        let filteredTransactions = getFilteredTransactions()
        var categoryStats: [Int: (amount: Decimal, latestDate: Date)] = [:]
        let total = filteredTransactions.reduce(Decimal(0)) { sum, transaction in
            sum + (Decimal(string: transaction.amount) ?? 0)
        }
        for transaction in filteredTransactions {
            let categoryId = transaction.category.id
            let amount = Decimal(string: transaction.amount) ?? 0
            let date = isoFormatter.date(from: transaction.transactionDate) ?? Date.distantPast
            if let existing = categoryStats[categoryId] {
                let latestDate = date > existing.latestDate ? date : existing.latestDate
                categoryStats[categoryId] = (existing.amount + amount, latestDate)
            } else {
                categoryStats[categoryId] = (amount, date)
            }
        }
        let result = categoryStats.compactMap { categoryId, data -> (category: Category, amount: Decimal, percentage: Double, latestDate: Date)? in
            guard let category = transactionsVM.categories.first(where: { $0.id == categoryId }),
                  total > 0 else { return nil }
            let percentage = (data.amount / total as NSDecimalNumber).doubleValue * 100
            return (category, data.amount, percentage, data.latestDate)
        }
        let sortedResult: [(category: Category, amount: Decimal, percentage: Double)]
        switch viewModel.sortType {
        case .amountAscending:
            sortedResult = result.sorted { $0.amount < $1.amount }.map { ($0.category, $0.amount, $0.percentage) }
        case .amountDescending:
            sortedResult = result.sorted { $0.amount > $1.amount }.map { ($0.category, $0.amount, $0.percentage) }
        case .dateAscending:
            sortedResult = result.sorted { $0.latestDate < $1.latestDate }.map { ($0.category, $0.amount, $0.percentage) }
        case .dateDescending:
            sortedResult = result.sorted { $0.latestDate > $1.latestDate }.map { ($0.category, $0.amount, $0.percentage) }
        }
        return sortedResult
    }
    
    private func getTransactionStats() -> [(transaction: TransactionResponse, percentage: Double)] {
        let isoFormatter = ISO8601DateFormatter()
        let filteredTransactions = getFilteredTransactions()
        let total = filteredTransactions.reduce(Decimal(0)) { sum, transaction in
            sum + (Decimal(string: transaction.amount) ?? 0)
        }
        let result = filteredTransactions.compactMap { transaction -> (transaction: TransactionResponse, percentage: Double)? in
            guard total > 0 else { return nil }
            let amount = Decimal(string: transaction.amount) ?? 0
            let percentage = (amount / total as NSDecimalNumber).doubleValue * 100
            return (transaction, percentage)
        }
        let sortedResult: [(transaction: TransactionResponse, percentage: Double)]
        switch viewModel.sortType {
        case .amountAscending:
            sortedResult = result.sorted { (Decimal(string: $0.transaction.amount) ?? 0) < (Decimal(string: $1.transaction.amount) ?? 0) }
        case .amountDescending:
            sortedResult = result.sorted { (Decimal(string: $0.transaction.amount) ?? 0) > (Decimal(string: $1.transaction.amount) ?? 0) }
        case .dateAscending:
            sortedResult = result.sorted {
                let d0 = isoFormatter.date(from: $0.transaction.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transaction.transactionDate) ?? Date.distantPast
                return d0 < d1
            }
        case .dateDescending:
            sortedResult = result.sorted {
                let d0 = isoFormatter.date(from: $0.transaction.transactionDate) ?? Date.distantPast
                let d1 = isoFormatter.date(from: $1.transaction.transactionDate) ?? Date.distantPast
                return d0 > d1
            }
        }
        return sortedResult
    }
    
    private func configureDatePickerCell(_ cell: DatePickerCell, title: String, date: Date, action: @escaping () -> Void) {
        cell.configure(
            title: title,
            date: date,
            backgroundColor: UIColor(named: "AccentColor")?.withAlphaComponent(0.2) ?? .systemBackground,
            action: action
        )
    }
    
    private func configureCellAppearance(_ cell: UITableViewCell, at indexPath: IndexPath, forSection section: Int) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .secondarySystemGroupedBackground
        
        var corners: UIRectCorner = []
        
        if indexPath.row == 0 {
            corners.update(with: .topLeft)
            corners.update(with: .topRight)
        }
        
        if indexPath.row == tableView.numberOfRows(inSection: section) - 1 {
            corners.update(with: .bottomLeft)
            corners.update(with: .bottomRight)
        }
        
        let maskLayer = CAShapeLayer()
        let bounds = cell.bounds.insetBy(dx: 0, dy: 0)
        maskLayer.path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        ).cgPath
        
        cell.contentView.layer.mask = maskLayer
        cell.contentView.layer.masksToBounds = true
    }
}

// MARK: - UITableViewDataSource

extension AnalysisViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // 0 — фильтры, 1 — график, 2 — категории, 3 — операции
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // дата начала, дата конца, сортировка, сумма
        case 1: return 1 // PieChartCell
        case 2: return cachedCategoryStats.count
        case 3: return cachedTransactionStats.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: DatePickerCell.reuseIdentifier, for: indexPath) as! DatePickerCell
                configureDatePickerCell(cell, title: "Начало", date: startDate) { [weak self] in
                    self?.showDatePicker(for: .start, currentDate: self?.startDate ?? Date())
                }
                configureCellAppearance(cell, at: indexPath, forSection: 0)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: DatePickerCell.reuseIdentifier, for: indexPath) as! DatePickerCell
                configureDatePickerCell(cell, title: "Конец", date: endDate) { [weak self] in
                    self?.showDatePicker(for: .end, currentDate: self?.endDate ?? Date())
                }
                configureCellAppearance(cell, at: indexPath, forSection: 0)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: SortingCell.reuseIdentifier, for: indexPath) as! SortingCell
                cell.configure(selectedSort: viewModel.sortType) { [weak self] newSort in
                    self?.updateSorting(newSort)
                }
                configureCellAppearance(cell, at: indexPath, forSection: 0)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: TotalAmountCell.reuseIdentifier, for: indexPath) as! TotalAmountCell
                let total = cachedCategoryStats.reduce(Decimal(0)) { $0 + $1.amount }
                cell.configure(amount: total, currencySymbol: currencySymbol)
                configureCellAppearance(cell, at: indexPath, forSection: 0)
                return cell
            default:
                return UITableViewCell()
            }
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: PieChartCell.reuseIdentifier, for: indexPath) as! PieChartCell
            cell.configure(with: pieChartEntities)
            cell.selectionStyle = .none
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: AnalysisCell.reuseIdentifier, for: indexPath) as! AnalysisCell
            let stat = cachedCategoryStats[indexPath.row]
            cell.configure(category: stat.category, amount: stat.amount, percentage: stat.percentage, currencySymbol: currencySymbol)
            configureCellAppearance(cell, at: indexPath, forSection: 2)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: AnalysisCell.reuseIdentifier, for: indexPath) as! AnalysisCell
            guard indexPath.row < cachedTransactionStats.count else {
                return cell
            }
            let stats = cachedTransactionStats[indexPath.row]
            let category = transactionsViewModel?.category(for: stats.transaction) ?? viewModel.category(for: stats.transaction)
            cell.configure(category: category ?? Category(id: 0, name: "Не известно", emoji: "❓", direction: .outcome), amount: Decimal(string: stats.transaction.amount) ?? 0, percentage: stats.percentage, currencySymbol: currencySymbol)
            configureCellAppearance(cell, at: indexPath, forSection: 3)
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate

extension AnalysisViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let header = UIView()
            let label = UILabel()
            label.text = "Анализ"
            label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 0),
                label.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: 0),
                label.topAnchor.constraint(equalTo: header.topAnchor, constant: 10),
                label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -20)
            ])
            return header
        case 1:
            return nil // Без заголовка для графика
        case 2:
            let header = UIView()
            let label = UILabel()
            label.text = "КАТЕГОРИИ"
            label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: horizontalInset),
                label.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
            ])
            return header
        case 3:
            let header = UIView()
            let label = UILabel()
            label.text = "ОПЕРАЦИИ"
            label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: horizontalInset),
                label.topAnchor.constraint(equalTo: header.topAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
            ])
            return header
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 54
        case 1: return 0 // Без заголовка для графика
        case 2: return 44
        case 3: return 44
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 200 // Высота для PieChartCell
        }
        return 44
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

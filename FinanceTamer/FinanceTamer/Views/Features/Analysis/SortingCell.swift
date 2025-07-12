import UIKit

final class SortingCell: UITableViewCell {
    static let reuseIdentifier = "SortingCell"
    
    private var sortChanged: ((SortType) -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Сортировка"
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor(named: "accentColor"), for: .normal)
        button.addTarget(self, action: #selector(showSortMenu), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let image = UIImage(systemName: "chevron.down")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(UIColor(named: "accentColor") ?? .systemBlue)
        
        button.setImage(image, for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(sortButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            sortButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sortButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(selectedSort: SortType, sortChanged: @escaping (SortType) -> Void) {
        self.sortChanged = sortChanged
        sortButton.setTitle(selectedSort.rawValue, for: .normal)
    }
    
    @objc private func showSortMenu() {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        SortType.allCases.forEach { sortType in
            alert.addAction(UIAlertAction(title: sortType.rawValue, style: .default) { [weak self] _ in
                self?.sortButton.setTitle(sortType.rawValue, for: .normal)
                self?.sortChanged?(sortType)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sortButton
            popoverController.sourceRect = sortButton.bounds
        }
        
        window?.rootViewController?.present(alert, animated: true)
    }
}

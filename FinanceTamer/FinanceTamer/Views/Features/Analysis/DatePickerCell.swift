import UIKit

final class DatePickerCell: UITableViewCell {
    static let reuseIdentifier = "DatePickerCell"
    
    private var action: (() -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dateButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = UIColor(named: "accentColor")?.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        selectionStyle = .none    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateButton)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            dateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    func configure(title: String, date: Date, backgroundColor: UIColor, action: @escaping () -> Void) {
            titleLabel.text = title
            self.action = action
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            dateButton.setTitle(formatter.string(from: date), for: .normal)
            
            dateButton.backgroundColor = backgroundColor
            dateButton.layer.cornerRadius = 10
            dateButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        }
    
    @objc private func buttonTapped() {
        action?()
    }
}

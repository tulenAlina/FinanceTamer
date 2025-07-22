import UIKit
import PieChart

final class PieChartCell: UITableViewCell {
    static let reuseIdentifier = "PieChartCell"
    
    private let pieChartView = PieChartView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(pieChartView)
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pieChartView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            pieChartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            pieChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pieChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pieChartView.heightAnchor.constraint(equalToConstant: 180)
        ])
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    func configure(with entities: [Entity]) {
        pieChartView.entities = entities
    }
}

import AtomicCore
import UIKit

final class UserCell: UITableViewCell {
  // MARK: - UI Components

  private lazy var containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = 12
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 25
    imageView.layer.borderWidth = 2
    imageView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var usernameLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 16, weight: .semibold)
    label.textColor = .label
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var typeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var typeContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
    view.layer.cornerRadius = 8
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var typeLabelInContainer: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12, weight: .medium)
    label.textColor = .systemBlue
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var chevronImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "chevron.right")
    imageView.tintColor = .tertiaryLabel
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  // MARK: - Initialization

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupUI()
    self.setupConstraints()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  func configure(with user: UserEntity) {
    self.usernameLabel.text = user.login
    self.typeLabelInContainer.text = user.htmlUrl

    // Load avatar image
    if let avatarURL = URL(string: user.avatarUrl) {
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: avatarURL)
          if let image = UIImage(data: data) {
            await MainActor.run {
              self.avatarImageView.image = image
            }
          }
        } catch {
          // Silently ignore avatar load failures
        }
      }
    }
  }

  // MARK: - Private Methods

  private func setupUI() {
    selectionStyle = .none
    backgroundColor = .clear

    contentView.addSubview(self.containerView)
    self.containerView.addSubview(self.avatarImageView)
    self.containerView.addSubview(self.usernameLabel)
    self.containerView.addSubview(self.typeContainer)
    self.typeContainer.addSubview(self.typeLabelInContainer)
    self.containerView.addSubview(self.chevronImageView)
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // Container View
      self.containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      self.containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      self.containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      self.containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

      // Avatar Image
      self.avatarImageView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor, constant: 16),
      self.avatarImageView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor),
      self.avatarImageView.widthAnchor.constraint(equalToConstant: 50),
      self.avatarImageView.heightAnchor.constraint(equalToConstant: 50),

      // Username Label
      self.usernameLabel.leadingAnchor.constraint(equalTo: self.avatarImageView.trailingAnchor, constant: 12),
      self.usernameLabel.topAnchor.constraint(equalTo: self.containerView.topAnchor, constant: 16),
      self.usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.chevronImageView.leadingAnchor, constant: -8),

      // Type Container
      self.typeContainer.leadingAnchor.constraint(equalTo: self.usernameLabel.leadingAnchor),
      self.typeContainer.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor, constant: 4),
      self.typeContainer.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor, constant: -16),

      // Type Label in Container
      self.typeLabelInContainer.topAnchor.constraint(equalTo: self.typeContainer.topAnchor, constant: 4),
      self.typeLabelInContainer.leadingAnchor.constraint(equalTo: self.typeContainer.leadingAnchor, constant: 8),
      self.typeLabelInContainer.trailingAnchor.constraint(equalTo: self.typeContainer.trailingAnchor, constant: -8),
      self.typeLabelInContainer.bottomAnchor.constraint(equalTo: self.typeContainer.bottomAnchor, constant: -4),

      // Chevron Image
      self.chevronImageView.centerYAnchor.constraint(equalTo: self.containerView.centerYAnchor),
      self.chevronImageView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor, constant: -16),
      self.chevronImageView.widthAnchor.constraint(equalToConstant: 12),
      self.chevronImageView.heightAnchor.constraint(equalToConstant: 20)
    ])
  }

  // MARK: - Reuse

  override func prepareForReuse() {
    super.prepareForReuse()
    self.avatarImageView.image = nil
    self.usernameLabel.text = nil
    self.typeLabelInContainer.text = nil
  }

  // MARK: - Selection

  override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    super.setHighlighted(highlighted, animated: animated)
    UIView.animate(withDuration: 0.2) {
      self.containerView.alpha = highlighted ? 0.7 : 1.0
      self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
    }
  }
}

import AtomicCore
import Combine
import UIKit

protocol UserDetailViewControllerDelegate: AnyObject {
  func userDetailViewControllerDidFinish(_ viewController: UserDetailViewController)
}

final class UserDetailViewController: UIViewController, View {
  typealias ViewModelType = UserDetailViewModel

  // MARK: - Properties

  let viewModel: ViewModelType
  weak var delegate: UserDetailViewControllerDelegate?

  // MARK: - UI Components

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    return scrollView
  }()

  private lazy var contentView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var headerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var gradientLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    layer.colors = [
      UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
      UIColor.systemBackground.cgColor
    ]
    layer.locations = [0.0, 1.0]
    return layer
  }()

  private lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 60
    imageView.layer.borderWidth = 4
    imageView.layer.borderColor = UIColor.systemBackground.cgColor
    imageView.layer.shadowColor = UIColor.black.cgColor
    imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
    imageView.layer.shadowRadius = 4
    imageView.layer.shadowOpacity = 0.1
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 28, weight: .bold)
    label.textColor = .label
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var usernameLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 17)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var locationLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 15)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var bioLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 16)
    label.textColor = .label
    label.numberOfLines = 0
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var githubButton: UIButton = {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.filled()
    configuration.title = "View GitHub Profile"
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .systemFont(ofSize: 16, weight: .semibold)
      return outgoing
    }
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
    configuration.cornerStyle = .medium
    button.configuration = configuration
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(self.githubButtonTapped), for: .touchUpInside)
    return button
  }()

  private lazy var statsStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .equalSpacing
    stackView.spacing = 20
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  private lazy var followersView: StatView = {
    let view = StatView()
    view.configure(title: "Followers", value: "0")
    return view
  }()

  private lazy var followingView: StatView = {
    let view = StatView()
    view.configure(title: "Following", value: "0")
    return view
  }()

  private lazy var reposView: StatView = {
    let view = StatView()
    view.configure(title: "Repos", value: "0")
    return view
  }()

  private lazy var loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.color = .systemBlue
    indicator.hidesWhenStopped = true
    return indicator
  }()

  private lazy var errorView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemBackground
    view.isHidden = true
    view.alpha = 0
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  private lazy var errorImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
    imageView.tintColor = .systemOrange
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  private lazy var errorLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = .label
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var retryButton: UIButton = {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.filled()
    configuration.title = "Try Again"
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .systemFont(ofSize: 16, weight: .semibold)
      return outgoing
    }
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
    configuration.cornerStyle = .medium
    button.configuration = configuration
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private lazy var backButton: UIButton = {
    let button = UIButton(type: .system)
    var configuration = UIButton.Configuration.filled()
    configuration.image = UIImage(systemName: "chevron.left.circle.fill")
    configuration.baseForegroundColor = .systemBlue
    configuration.background.backgroundColor = .systemBackground
    configuration.cornerStyle = .capsule
    button.configuration = configuration
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
    return button
  }()

  // MARK: - Initialization

  init(viewModel: ViewModelType) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.setupConstraints()
    self.setupNavigationBar()
    self.bind()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.gradientLayer.frame = self.headerView.bounds
  }

  // MARK: - View Protocol

  func setupUI() {
    view.backgroundColor = .systemBackground

    // Add gradient layer to header view
    self.headerView.layer.addSublayer(self.gradientLayer)

    view.addSubview(self.scrollView)
    view.addSubview(self.backButton)
    self.scrollView.addSubview(self.contentView)

    self.contentView.addSubview(self.headerView)
    self.headerView.addSubview(self.avatarImageView)
    self.headerView.addSubview(self.nameLabel)
    self.headerView.addSubview(self.usernameLabel)
    self.headerView.addSubview(self.locationLabel)

    self.contentView.addSubview(self.bioLabel)
    self.contentView.addSubview(self.githubButton)
    self.contentView.addSubview(self.statsStackView)

    self.statsStackView.addArrangedSubview(self.followersView)
    self.statsStackView.addArrangedSubview(self.followingView)
    self.statsStackView.addArrangedSubview(self.reposView)

    view.addSubview(self.loadingIndicator)

    self.errorView.addSubview(self.errorImageView)
    self.errorView.addSubview(self.errorLabel)
    self.errorView.addSubview(self.retryButton)
    view.addSubview(self.errorView)
  }

  func setupConstraints() {
    NSLayoutConstraint.activate([
      // Back Button
      self.backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      self.backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      self.backButton.widthAnchor.constraint(equalToConstant: 44),
      self.backButton.heightAnchor.constraint(equalToConstant: 44),

      // Scroll View
      self.scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      self.scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      self.scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      self.scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Content View
      self.contentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
      self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
      self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
      self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
      self.contentView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor),

      // Header View
      self.headerView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
      self.headerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
      self.headerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
      self.headerView.heightAnchor.constraint(equalToConstant: 280),

      // Avatar Image
      self.avatarImageView.topAnchor.constraint(equalTo: self.headerView.topAnchor, constant: 40),
      self.avatarImageView.centerXAnchor.constraint(equalTo: self.headerView.centerXAnchor),
      self.avatarImageView.widthAnchor.constraint(equalToConstant: 120),
      self.avatarImageView.heightAnchor.constraint(equalToConstant: 120),

      // Name Label
      self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: 16),
      self.nameLabel.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 16),
      self.nameLabel.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -16),

      // Username Label
      self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: 4),
      self.usernameLabel.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 16),
      self.usernameLabel.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -16),

      // Location Label
      self.locationLabel.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor, constant: 8),
      self.locationLabel.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 16),
      self.locationLabel.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -16),

      // Bio Label
      self.bioLabel.topAnchor.constraint(equalTo: self.headerView.bottomAnchor, constant: 24),
      self.bioLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 24),
      self.bioLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -24),

      // GitHub Button
      self.githubButton.topAnchor.constraint(equalTo: self.bioLabel.bottomAnchor, constant: 24),
      self.githubButton.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),

      // Stats Stack View
      self.statsStackView.topAnchor.constraint(equalTo: self.githubButton.bottomAnchor, constant: 32),
      self.statsStackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 32),
      self.statsStackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -32),
      self.statsStackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -32),

      // Loading Indicator
      self.loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      self.loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      // Error View
      self.errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      self.errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      self.errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      self.errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Error Image
      self.errorImageView.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor),
      self.errorImageView.centerYAnchor.constraint(equalTo: self.errorView.centerYAnchor, constant: -60),
      self.errorImageView.widthAnchor.constraint(equalToConstant: 60),
      self.errorImageView.heightAnchor.constraint(equalToConstant: 60),

      // Error Label
      self.errorLabel.topAnchor.constraint(equalTo: self.errorImageView.bottomAnchor, constant: 16),
      self.errorLabel.leadingAnchor.constraint(equalTo: self.errorView.leadingAnchor, constant: 32),
      self.errorLabel.trailingAnchor.constraint(equalTo: self.errorView.trailingAnchor, constant: -32),

      // Retry Button
      self.retryButton.topAnchor.constraint(equalTo: self.errorLabel.bottomAnchor, constant: 24),
      self.retryButton.centerXAnchor.constraint(equalTo: self.errorView.centerXAnchor)
    ])
  }

  func bind() {
    // Create input publishers
    let loadUser = Just(()).eraseToAnyPublisher()

    // Transform input to output
    let output = self.viewModel.transform(input: .init(
      loadUser: loadUser
    ))

    // Bind output to UI
    output.viewState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        self?.handleViewState(state)
      }
      .store(in: &self.viewModel.cancellables)
  }

  // MARK: - Private Methods

  private func setupNavigationBar() {
    navigationItem.largeTitleDisplayMode = .never
    navigationController?.setNavigationBarHidden(true, animated: false)
    title = "User Details"
  }

  @objc private func githubButtonTapped() {
    if let url = URL(string: viewModel.user?.htmlUrl ?? "") {
      UIApplication.shared.open(url)
    }
  }

  @objc private func backButtonTapped() {
    self.delegate?.userDetailViewControllerDidFinish(self)
  }

  private func handleViewState(_ state: ViewModelType.ViewState) {
    switch state {
    case .idle:
      self.animateStateTransition {
        self.scrollView.isHidden = true
        self.loadingIndicator.stopAnimating()
        self.errorView.isHidden = true
      }

    case .loading:
      self.animateStateTransition {
        self.scrollView.isHidden = true
        self.loadingIndicator.startAnimating()
        self.errorView.isHidden = true
      }

    case let .loaded(user):
      self.animateStateTransition {
        self.scrollView.isHidden = false
        self.loadingIndicator.stopAnimating()
        self.errorView.isHidden = true
        self.configure(with: user)
      }

    case let .error(error):
      self.animateStateTransition {
        self.scrollView.isHidden = true
        self.loadingIndicator.stopAnimating()
        self.errorView.isHidden = false
        self.errorLabel.text = error.localizedDescription
      }
    }
  }

  private func animateStateTransition(_ changes: @escaping () -> Void) {
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
      changes()
      self.errorView.alpha = self.errorView.isHidden ? 0 : 1
    }
  }

  private func configure(with user: UserDetailEntity) {
    self.nameLabel.text = user.login
    self.usernameLabel.text = "@\(user.login)"
    self.locationLabel.text = user.location.isEmpty ? nil : "📍 \(user.location)"
    self.bioLabel.text = user.bio

    self.followersView.configure(title: "Followers", value: "\(user.followers)")
    self.followingView.configure(title: "Following", value: "\(user.following)")
    self.reposView.configure(title: "Repos", value: "\(user.publicRepos)")

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
}

// MARK: - StatView

private final class StatView: UIView {
  private lazy var valueLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 20, weight: .bold)
    label.textColor = .label
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupUI()
    self.setupConstraints()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(self.valueLabel)
    addSubview(self.titleLabel)
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      self.valueLabel.topAnchor.constraint(equalTo: topAnchor),
      self.valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      self.valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

      self.titleLabel.topAnchor.constraint(equalTo: self.valueLabel.bottomAnchor, constant: 4),
      self.titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      self.titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      self.titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  func configure(title: String, value: String) {
    self.titleLabel.text = title
    self.valueLabel.text = value
  }
}

import UIKit

open class NavigationRouter: NSObject {
  private let navigationController: UINavigationController
  private let routerRootController: UIViewController?
  private var onDismissForViewController: [UIViewController: () -> Void] = [:]

  public init(navigationController: UINavigationController) {
    self.navigationController = navigationController
    self.routerRootController = navigationController.viewControllers.first
    super.init()
    navigationController.delegate = self
  }

  open func present(
    _ viewController: UIViewController,
    animated: Bool,
    onDismissed: (() -> Void)?
  ) {
    self.onDismissForViewController[viewController] = onDismissed
    self.navigationController.pushViewController(
      viewController,
      animated: animated
    )
  }

  open func dismiss(animated: Bool) {
    guard let routerRootController else {
      self.navigationController.popToRootViewController(
        animated: animated
      )
      return
    }
    self.performOnDismissed(for: routerRootController)
    self.navigationController.popToViewController(
      routerRootController,
      animated: animated
    )
  }
}

// MARK: - Router

extension NavigationRouter: Router {
  private func performOnDismissed(for viewController: UIViewController) {
    guard let onDismiss = onDismissForViewController[viewController] else {
      return
    }
    onDismiss()
    self.onDismissForViewController[viewController] = nil
  }
}

// MARK: - UINavigationControllerDelegate

extension NavigationRouter: UINavigationControllerDelegate {
  public func navigationController(
    _ navigationController: UINavigationController,
    didShow _: UIViewController,
    animated _: Bool
  ) {
    guard
      let dismissedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
      !navigationController.viewControllers.contains(dismissedViewController)
    else {
      return
    }
    self.performOnDismissed(for: dismissedViewController)
  }
}

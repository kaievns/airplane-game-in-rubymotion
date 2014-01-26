class SceneViewController < UIViewController
  def viewDidLoad
    super
    self.view = SceneView.alloc.init
  end

  def viewWillLayoutSubviews
    super

    view.presentScene GameScene.alloc.initWithSize(view.bounds.size)
  end

  def prefersStatusBarHidden
    true
  end
end

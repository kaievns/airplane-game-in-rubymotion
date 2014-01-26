class GameScene < SKScene
  BULLETS = 1
  ENEMIES = 2

  def initWithSize(size)
    return self if ! super

    # setting up physics
    physicsWorld.gravity = CGVectorMake(0, 0)
    physicsWorld.contactDelegate = self

    # CoreMotion
    @current_max_accel_x = 0
    @current_max_accel_y = 0

    @motion_manager = CMMotionManager.alloc.init
    @motion_manager.accelerometerUpdateInterval = 0.2
    @motion_manager.startAccelerometerUpdatesToQueue(
      NSOperationQueue.currentQueue,
      withHandler: Proc.new{ |accelerometerData, error|
        outputAccelertionData(accelerometerData.acceleration)
        NSLog "#{error}" if error
      }
    )

    # init several sizes used in all scene
    @screen_rect   = UIScreen.mainScreen.bounds
    @screen_height = @screen_rect.size.height
    @screen_width  = @screen_rect.size.width

    # adding the background
    @background = SKSpriteNode.spriteNodeWithImageNamed("airPlanesBackground")
    @background.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame))
    addChild @background

    # adding the airplane
    @plane = SKSpriteNode.spriteNodeWithImageNamed("PLANE 8 N.png")
    @plane.scale = 0.6
    @plane.zPosition = 2
    @plane.position = CGPointMake(@screen_width/2, 15+@plane.size.height/2)
    addChild @plane

    @plane_shadow = SKSpriteNode.spriteNodeWithImageNamed("PLANE 8 SHADOW.png")
    @plane_shadow.scale = 0.6
    @plane_shadow.zPosition = 1
    @plane_shadow.position = CGPointMake(@screen_width/2+15, 0+@plane_shadow.size.height/2)
    addChild @plane_shadow

    @propeller = SKSpriteNode.spriteNodeWithImageNamed("PLANE PROPELLER 1.png")
    @propeller.scale = 0.2
    @propeller.zPosition = 2
    @propeller.position = CGPointMake(@screen_width/2, @plane.size.height+10)
    propeller1 = SKTexture.textureWithImageNamed("PLANE PROPELLER 1.png")
    propeller2 = SKTexture.textureWithImageNamed("PLANE PROPELLER 2.png")
    spin = SKAction.animateWithTextures([propeller1,propeller2], timePerFrame:0.1)
    @propeller.runAction SKAction.repeatActionForever(spin)
    addChild @propeller

    # adding the smokeTrail
    smoke_path = NSBundle.mainBundle.pathForResource("trail", ofType:"sks")
    @smoke_trail = NSKeyedUnarchiver.unarchiveObjectWithFile(smoke_path)
    @smoke_trail.position = CGPointMake(@screen_width/2, 15)
    addChild @smoke_trail

    # schedule enemies
    wait = SKAction.waitForDuration(1)
    callEnemies = SKAction.runBlock ->{ enemiesAndClouds }
    updateEnimies = SKAction.sequence([wait,callEnemies])
    runAction SKAction.repeatActionForever(updateEnimies)

    # load explosions
    explosion_atlas = SKTextureAtlas.atlasNamed("EXPLOSION")
    @explosion_textures = explosion_atlas.textureNames.map do |name|
      explosion_atlas.textureNamed(name)
    end

    # load clouds
    clouds_atlas = SKTextureAtlas.atlasNamed("Clouds")
    @clouds_textures = clouds_atlas.textureNames.map do |name|
      clouds_atlas.textureNamed(name)
    end

    return self
  end

  def touchesBegan(touches, withEvent:event)
    location = @plane.position
    bullet = SKSpriteNode.spriteNodeWithImageNamed("B 2.png")
    bullet.position = CGPointMake(location.x, location.y+@plane.size.height/2)
    bullet.zPosition = 1
    bullet.scale = 0.8

    bullet.physicsBody = SKPhysicsBody.bodyWithRectangleOfSize(bullet.size)
    bullet.physicsBody.dynamic = false
    bullet.physicsBody.categoryBitMask = BULLETS
    bullet.physicsBody.contactTestBitMask = ENEMIES
    bullet.physicsBody.collisionBitMask = 0

    move = SKAction.moveToY(self.frame.size.height+bullet.size.height, duration:2)
    bullet.runAction SKAction.sequence([move,SKAction.removeFromParent])
    addChild bullet
  end

  def outputAccelertionData(acceleration)
    @current_max_accel_x = 0
    @current_max_accel_y = 0

    if acceleration.x.abs > @current_max_accel_x.abs
      @current_max_accel_x = acceleration.x
    end

    if acceleration.y.abs > @current_max_accel_y.abs
      @current_max_accel_y = acceleration.y
    end
  end

  def didBeginContact(contact)
    first, second = if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask
      [contact.bodyA, contact.bodyB]
    else
      [contact.bodyB, contact.bodyA]
    end

    if (first.categoryBitMask & BULLETS) != 0
      bullet, enemy = first.node, second.node

      bullet.runAction(SKAction.removeFromParent)
      enemy.runAction(SKAction.removeFromParent)

      # add explosion
      explosion = SKSpriteNode.spriteNodeWithTexture(@explosion_textures.objectAtIndex(0))
      explosion.zPosition = 1
      explosion.scale = 0.6
      explosion.position = bullet.position
      addChild explosion

      action = SKAction.animateWithTextures(@explosion_textures, timePerFrame:0.07)
      explosion.runAction(SKAction.sequence([action, SKAction.removeFromParent]))
    end
  end

  def update(time)
    max_y = @screen_width - @plane.size.width/2
    min_y = @plane.size.width/2
    max_x = @screen_height - @plane.size.height/2
    min_x = @plane.size.height/2
    new_y = 0
    new_x = 0

    if @current_max_accel_x > 0.05
      new_x = @current_max_accel_x * 10
      @plane.texture = SKTexture.textureWithImageNamed("PLANE 8 R.png")
    elsif @current_max_accel_x < -0.05
      new_x = @current_max_accel_x * 10
      @plane.texture = SKTexture.textureWithImageNamed("PLANE 8 L.png")
    else
      new_x = @current_max_accel_x * 10
      @plane.texture = SKTexture.textureWithImageNamed("PLANE 8 N.png")
    end

    new_y = 6.0 + @current_max_accel_y *10
    new_xshadow = new_x + @plane_shadow.position.x
    new_yshadow = new_y + @plane_shadow.position.y
    new_xshadow = [[new_xshadow,min_y+15].max, max_y+15].min
    new_yshadow = [[new_yshadow,min_x-15].max, max_x-15].min
    new_xpropeller = new_x+@propeller.position.x
    new_ypropeller = new_y+@propeller.position.y
    new_xpropeller = [[new_xpropeller,min_y].max,max_y].min
    new_ypropeller = [[new_ypropeller,min_x+(@plane.size.height/2)-5].max,max_x+(@plane.size.height/2)-5].min
    new_x = [[new_x+@plane.position.x,min_y].max,max_y].min
    new_y = [[new_y+@plane.position.y,min_x].max,max_x].min

    @plane.position = CGPointMake(new_x, new_y)
    @plane_shadow.position = CGPointMake(new_xshadow, new_yshadow)
    @propeller.position = CGPointMake(new_xpropeller, new_ypropeller)

    @smoke_trail.position = CGPointMake(new_x,new_y-(@plane.size.height/2))
  end

  def enemiesAndClouds
    addEnemy if rand(0..1) == 0 # randomly add enemy
    addCloud if rand(0..1) == 0 # randomly add cloud
  end

  def addCloud
    cloud = SKSpriteNode.spriteNodeWithTexture(@clouds_textures.objectAtIndex(rand(0..3)))
    random_y_axix = rand(0..@screen_height)
    cloud.position = CGPointMake(@screen_height+cloud.size.height/2, random_y_axix)
    cloud.zPosition = 1
    move = SKAction.moveTo(CGPointMake(0-cloud.size.height, random_y_axix), duration:rand(9..19))
    cloud.runAction SKAction.sequence([move,SKAction.removeFromParent])

    addChild cloud
  end

  def addEnemy
    enemy = SKSpriteNode.spriteNodeWithImageNamed("PLANE #{rand(1..2)} N.png")
    enemy.scale = 0.6;
    enemy.position = CGPointMake(@screen_width/2, @screen_height/2)
    enemy.zPosition = 1

    enemy.physicsBody = SKPhysicsBody.bodyWithRectangleOfSize(enemy.size)
    enemy.physicsBody.dynamic = true
    enemy.physicsBody.categoryBitMask = ENEMIES
    enemy.physicsBody.contactTestBitMask = BULLETS
    enemy.physicsBody.collisionBitMask = 0

    addChild enemy

    # random start/end positions
    x_start = rand(enemy.size.width..(@screen_width-enemy.size.width))
    x_end   = rand(enemy.size.width..(@screen_width-enemy.size.width))

    # control point 1
    cp1_x = rand(enemy.size.width..(@screen_width-enemy.size.width))
    cp1_y = rand(enemy.size.width..(@screen_width-enemy.size.height))

    # control point 2
    cp2_x = rand(enemy.size.width..(@screen_width-enemy.size.width))
    cp2_y = rand(0..cp1_y)


    s = CGPointMake(x_start, @screen_height)
    e = CGPointMake(x_end, -100.0)
    cp1 = CGPointMake(cp1_x, cp1_y)
    cp2 = CGPointMake(cp2_x, cp2_y)

    cgpath = CGPathCreateMutable()

    CGPathMoveToPoint(cgpath, nil, s.x, s.y)
    CGPathAddCurveToPoint(cgpath, nil, cp1.x, cp1.y, cp2.x, cp2.y, e.x, e.y)

    fly = SKAction.followPath(cgpath, asOffset:false, orientToPath:true, duration:5)

    enemy.runAction SKAction.sequence([fly, SKAction.removeFromParent])
  end

  # a dirty patch over RubyMotion's Kernel.rand coz it doesn't support ranges
  def rand(range)
    if range.is_a?(Range)
      range.min.to_i + Kernel.rand(range.max.to_i - range.min.to_i + 1)
    else
      Kernel.rand(range)
    end
  end
end

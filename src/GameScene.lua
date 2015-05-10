require "Cocos2d"
require "Cocos2dConstants"

local kOuterWallSize        = 70 -- 壁の厚さ

local kJumpSpeed            = 500 -- ジャンプのスピード
local kWalkSpeed            = 150 -- 歩くスピード

local kMaxLife              = 5

-- 物理シミュレーションで使用するカテゴリ
local kCategoryPaddle       = 1    -- 00001
local kCategoryBall         = 2    -- 00010
local kCategoryBlock        = 4    -- 00100
local kCategoryBottom       = 8    -- 01000
local kCategoryWall         = 16   -- 10000

local GamePhase = {ReadyToStart = 1, Playing = 2, GameOver = 3, GameClear = 4}

local GameScene = class("GameScene",function()
    return cc.Scene:createWithPhysics()
end)

function GameScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.gamePhase  = GamePhase.ReadyToStart
    self.layer      = nil  -- レイヤー
    self.mario      = nil  -- マリオのスプライト
    self.wall       = nil  -- 床のスプライト

    self.jump       = nil  -- ジャンプボタンのスプライト
    self.left       = nil  -- 左ボタンのスプライト
    self.right      = nil  -- 右ボタンのスプライト

    self.life = 5
    self.material = cc.PhysicsMaterial(0, 0, 0) -- 密度, 反発, 摩擦
end

function GameScene.create()
    local scene = GameScene.new()

    scene:getPhysicsWorld():setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL) -- デバッグ用
    scene:getPhysicsWorld():setGravity(cc.p(0,-980))

    scene.layer = scene:createLayer()
    scene:addChild(scene.layer)

    scene:touchEvent()
    scene:contactTest()
    scene:readyToStart()
    return scene
end

-- レイヤーの作成
function GameScene:createLayer()
    local layer = cc.LayerColor:create(cc.c4b(0, 0, 255, 255)) -- 色は青、不透明

    self.mario = self:createMario()
    self.label = self:createLabel()
    self.wall = self:createBottomWall()
    self.jump = self:createJumpButton()
    self.left = self:createLeftButton()
    self.right = self:createRightButton()

    layer:addChild(self.mario)
    layer:addChild(self.label)
    layer:addChild(self.wall)
    layer:addChild(self.jump)
    layer:addChild(self.left)
    layer:addChild(self.right)

    return layer
end

-- マリオの作成
function GameScene:createMario()
    local sprite = cc.Sprite:create("mario.png")
    sprite:setScale(0.3)

    local physicsBody = cc.PhysicsBody:createBox(sprite:getBoundingBox(), self.material)
    physicsBody:setRotationEnable(false)
    physicsBody:setCategoryBitmask(kCategoryBall)
    physicsBody:setContactTestBitmask(kCategoryBottom)

    sprite:setPhysicsBody(physicsBody)

    return sprite
end

-- ジャンプボタンの作成
function GameScene:createJumpButton()
    local sprite = cc.Sprite:create("wall.png")
    sprite:setScale(0.3)

    sprite:setPosition(sprite:getBoundingBox().width * 2, sprite:getBoundingBox().height * 8)

    return sprite
end

-- 左ボタンの作成
function GameScene:createLeftButton()
    local sprite = cc.Sprite:create("wall.png")
    sprite:setScale(0.3)

    sprite:setPosition(sprite:getBoundingBox().width * 10, sprite:getBoundingBox().height * 8)

    return sprite
end

-- 右ボタンの作成
function GameScene:createRightButton()
    local sprite = cc.Sprite:create("wall.png")
    sprite:setScale(0.3)

    sprite:setPosition(sprite:getBoundingBox().width * 12, sprite:getBoundingBox().height * 8)

    return sprite
end

-- ラベルの作成
function GameScene:createLabel()
    local label = cc.Label:createWithSystemFont("", "Arial", 18)
    label:setPosition(self.visibleSize.width/2, self.visibleSize.height/2)

    return label
end

-- 底面にミス判定用の線を作る
function GameScene:createBottomWall()
    local sprite = cc.Sprite:create("wall.png")
    local size = sprite:getContentSize()
    sprite:setScale(self.visibleSize.width / size.width, kOuterWallSize / size.height)
    sprite:setPosition(sprite:getBoundingBox().width / 2, sprite:getBoundingBox().height / 2)

    local body = cc.PhysicsBody:createBox(sprite:getBoundingBox(), self.material)
    body:setDynamic(false)
    body:setCategoryBitmask(kCategoryBottom)
    body:setContactTestBitmask(kCategoryBall)

    -- ノードに物体を設定
    sprite:setPhysicsBody(body)

    return sprite
end


-- ゲーム開始準備
function GameScene:readyToStart()
    self.gamePhase = GamePhase.ReadyToStart
    self.label:setString("Tap to Start")
    self.label:setVisible(true)
    self.mario:setPosition(self.visibleSize.width / 10, kOuterWallSize + self.mario:getBoundingBox().height / 2)
end

-- ゲーム開始
function GameScene:gameStart()
    self.gamePhase = GamePhase.Playing
    self.label:setVisible(false)
end

-- ライフ減少
function GameScene:loseLife()
    self.life = self.life - 1
    if self.life == 0 then
        self:gameOver()
    else
        self.gamePhase = GamePhase.ReadyToStart
        self.label:setString("Tap to Start")
        self.label:setVisible(true)
    end
end

-- ゲームオーバー
function GameScene:gameOver()
    self.gamePhase = GamePhase.GameOver
    self.label:setString("Game Over")
    self.label:setVisible(true)
    self.mario:setPosition(self.visibleSize.width / 10, kOuterWallSize + self.mario:getBoundingBox().height / 2)
    self.life = kMaxLife
end

-- ゲームクリアー
function GameScene:gameClear()
    self.gamePhase = GamePhase.GameClear
    self.label:setString("Congratulations !!")
    self.label:setVisible(true)
    self.life = kMaxLife
end

-- タッチイベント処理
function GameScene:touchEvent()
    local touchLeft = nil
    local touchRight = nil

    -- タッチ開始
    local function onTouchBegan(touch, event)
        local location = touch:getLocation()

        if cc.rectContainsPoint(self.label:getBoundingBox(), location) then
            if self.gamePhase == GamePhase.ReadyToStart then
                self:gameStart()
                return false
            elseif self.gamePhase == GamePhase.GameOver or self.gamePhase == GamePhase.GameClear then
                self:readyToStart()
                return false
            end
        end

        if cc.rectContainsPoint(self.jump:getBoundingBox(), location) then
            if self.mario:getPhysicsBody():getVelocity().y == 0 then
                local velocity = cc.pAdd(self.mario:getPhysicsBody():getVelocity(), cc.pMul(cc.pNormalize(cc.p(0, 1)), kJumpSpeed))
                self.mario:getPhysicsBody():setVelocity(velocity)
            end
        end

        if cc.rectContainsPoint(self.left:getBoundingBox(), location) and touchLeft == nil then
            touchLeft = touch
            local velocity = cc.pSub(self.mario:getPhysicsBody():getVelocity(), cc.pMul(cc.pNormalize(cc.p(1, 0)), kWalkSpeed))
            self.mario:getPhysicsBody():setVelocity(velocity)
        end


        if cc.rectContainsPoint(self.right:getBoundingBox(), location) and touchRight == nil then
            touchRight = touch
            local velocity = cc.pAdd(self.mario:getPhysicsBody():getVelocity(), cc.pMul(cc.pNormalize(cc.p(1, 0)), kWalkSpeed))
            self.mario:getPhysicsBody():setVelocity(velocity)
        end


        return true
    end

    local function onTouchEnded(touch, event)
        local location = touch:getLocation()

        if touch == touchLeft then
            touchLeft = nil
            local velocity = cc.pAdd(self.mario:getPhysicsBody():getVelocity(), cc.pMul(cc.pNormalize(cc.p(1, 0)), kWalkSpeed))
            self.mario:getPhysicsBody():setVelocity(velocity)
        end

        if touch == touchRight then
            touchRight = nil
            local velocity = cc.pSub(self.mario:getPhysicsBody():getVelocity(), cc.pMul(cc.pNormalize(cc.p(1, 0)), kWalkSpeed))
            self.mario:getPhysicsBody():setVelocity(velocity)
        end
    end


    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

-- 衝突時に呼ばれるイベント処理
function GameScene:contactTest()

    local function onContactPostSolve(contact)
        local a = contact:getShapeA():getBody()
        local b = contact:getShapeB():getBody()
        if a:getCategoryBitmask() > b:getCategoryBitmask() then a, b = b, a end

        -- ボールとブロックが衝突した時
        if b:getCategoryBitmask() == kCategoryBlock then
            b:getNode():removeFromParent()
            self.blockCount = self.blockCount - 1
            if self.blockCount == 0 then
                self:gameClear()
            end
        end

        return true
    end

    -- 衝突時に指定した関数を呼び出すようにする
    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(onContactPostSolve, cc.Handler.EVENT_PHYSICS_CONTACT_POSTSOLVE)
    local eventDispatcher = self:getEventDispatcher():addEventListenerWithSceneGraphPriority(contactListener, self)
end

return GameScene
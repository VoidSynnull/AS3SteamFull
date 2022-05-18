package game.scenes.poptropolis.skiing
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	
	import game.components.motion.FollowTarget;
	import game.components.input.Input;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.ZDepth;
	import game.components.entity.character.Skin;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.ZDepthCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.animation.entity.character.poptropolis.HurdleStart;
	import game.data.animation.entity.character.poptropolis.HurdleStop;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.common.StateString;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.skiing.components.ObstacleType;
	import game.scenes.poptropolis.skiing.components.OrigSpatial;
	import game.scenes.poptropolis.skiing.systems.SkiingCharControlSystem;
	import game.scenes.poptropolis.skiing.systems.SkiingCollisionSystem;
	import game.scenes.time.shared.emitters.Bubbles;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.Smoke;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TribeUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Skiing extends PoptropolisScene
	{
		private var _bgEntities:Vector.<Entity>;
		private var _bgLooper:SkiingBgLooper;
		private var _charControlSystem:SkiingCharControlSystem;
		private var _collisionSystem:SkiingCollisionSystem;
		private var _checkReachedMaxSpeed:CheckReachedMaxSpeedSystem;
		private var _hud:SkiingHud;
		private var _obstacleGroups:Array;
		private var _lavaHot:Entity;
		private var input:Input;
		private var _loopingEntities:Vector.<Entity>;
		private var _surfboard:Entity;
		private var _surfboardSubmerged:Entity;
		private var _surfboardShadow:Entity;
		private var _surfboardSplash:Entity;
		private var _zDepthCreator:ZDepthCreator;
		private var _zControlEntity:Entity
		private var _snakeEyesAnim:Entity;
		private var _spritesForPooling:Object;
		private var _gateThroughEntity:Array;
		
		public static const SLOPE_WIDTH: Number = .576
		public static const SLOPE_DEPTH: Number = 1.7
		private static const INITIAL_VEL_X:Number = 400
		private static const THROUGH_GAME_VEL_X:Number = 1000
		private static const FINISH_LINE_X:Number = 999999
		private static const ACCEL_AFTER_PASS_FINISH:int = -150
		public static const BG_ACCEL_X:Number = -500
		public static const BG_ACCEL_Y:Number = BG_ACCEL_X * .576
		public static const COURSE_SPEED:Number = -600
		public static const COURSE_SPEED_JUMP:Number = -800; 
		public static const COURSE_SPEED_SLOW:Number = -60; 
		public static const X_VEL_MAX:Number = 1300
		public static const Y_VEL_MAX:Number = 1174
		public static const TREE_MIN_X:Number = -600
		public static const TREE_WRAP_X:Number = 700
		public static const TREE_WRAP_Y:Number = TREE_WRAP_X*SLOPE_WIDTH
		public static const GATE_SEPARATION_X:Number = -105
		public static const GATE_SEPARATION_Y:Number = 60
		public static var PLAYER_OFFSET_Y:Number = 30
		public static var GATE_BONUS_SECONDS:int = 1
		
		public static var DEBUG_SHOW_COLLISION_RECTS:Boolean = true
		
		public function Skiing()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/skiing/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			
			var i:int 
			var sp:Spatial
			var e:Entity
			
			super.loaded();
			
			_zDepthCreator = new ZDepthCreator()
			_zControlEntity = _zDepthCreator.createZDepth(this,super._hitContainer)
			
			CharUtils.lockControls(super.player)  	// Note: actual player is not used in this scene
			
			_playerDummy = super.getEntityById( "playerDummy" );
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook, TribeUtils.getTribeOfPlayer( super.shellApi) ); // apply tribal jersey to look
			Skin(_playerDummy.get(Skin)).applyLook( playerLook );
			addMotion (_playerDummy)
			CharUtils.setScale(_playerDummy,.26)
			_zDepthCreator.addZDepthEntity(_playerDummy,0,_zControlEntity)
			addOrigSpatial(_playerDummy)
			
			var inputEntity:Entity = shellApi.inputEntity;
			input = inputEntity.get(Input) as Input;
			input.inputDown.add( onMouseDown );
			input.inputUp.add( onMouseUp );
			
			var st:StateString
			var sl:Sleep
			_playerDummy.add(new StateString("startingLine"))
			
			sl = _playerDummy.get(Sleep)
			sl.ignoreOffscreenSleep = true
			sl.sleeping = false
			
			_bgEntities = new Vector.<Entity>
			
			var he:Entity;
			var mc:MovieClip
			var spr:Sprite
			
			_loopingEntities = new Vector.<Entity>
			
			_lavaHot = new Entity()
			mc = super._hitContainer["hotLava"]
			_lavaHot.add(new Display(mc));
			_lavaHot.add(new Spatial(mc.x,mc.y))
			_lavaHot.add (new Motion)
			_lavaHot.add (new Sleep)
			addOrigSpatial(_lavaHot)
			this.addEntity(_lavaHot);
			sl = _lavaHot.get(Sleep)
			sl.ignoreOffscreenSleep = true
			sl.sleeping = false
			
			var camera:CameraSystem = this.getSystem(CameraSystem) as CameraSystem;
			camera.target = new Spatial(480, 320);
			camera.rate = .5;
			
			// to do: The lava needs to animate, so need to turn it into a timeline
			//BitmapTimelineCreator.convertFromStage( mc,false,true );
			//this.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate );
			
			var lavaBg:Entity = new Entity()
			mc = super._hitContainer["lavaBg"]
			spr = DisplayUtils.convertToBitmapSprite(mc).sprite;
			lavaBg.add(new Display(spr));
			lavaBg.add(new Spatial(mc.x,mc.y))
			lavaBg.add (new Motion)
			addBackgroundEntity(lavaBg)
			this.addEntity(lavaBg);
			
			// Trees background
			for (i =0 ; i <= 2 ; i ++) {
				mc = super._hitContainer["backgroundTrees" + i]
				spr = DisplayUtils.convertToBitmapSprite(mc).sprite;
				he = new Entity()
				he.add(new Display (spr))
				he.add(new Spatial(mc.x,mc.y))
				he.add (new Motion)
				this.addEntity(he)
				_loopingEntities.push (he)
				addBackgroundEntity(he)
			}
			
			mc = super._hitContainer["snakeEyesAnim"]
			_snakeEyesAnim = BitmapTimelineCreator.createBitmapTimeline(mc,true,true )
			this.addSystem( new BitmapSequenceSystem(), SystemPriorities.animate );
			_snakeEyesAnim.add(new Spatial(mc.x,mc.y))
			_snakeEyesAnim.add (new Motion)			
			addEntity(_snakeEyesAnim)
			addBackgroundEntity(_snakeEyesAnim)
			_snakeEyesAnim.add(new ZDepth (10000))
			
			mc = super._hitContainer["snakeHead"]
			var snakeHead:Entity = createEntityFromClip(mc)
			addBackgroundEntity(snakeHead)
			snakeHead.add(new ZDepth (10001))
			
			// Trees foreground
			for (i =0 ; i <= 2 ; i ++) {
				mc = super._hitContainer["foregroundTrees" + i]
				spr = DisplayUtils.convertToBitmapSprite(mc).sprite
				he = new Entity()
				he.add(new Display(spr))
				he.add (new Motion)
				he.add(new Spatial(mc.x,mc.y))
				this.addEntity(he)
				_loopingEntities.push (he)
				addBackgroundEntity(he)
				spr.parent.addChild(spr)
				he.add(new ZDepth (99999))
			}
			
			// Surfboard 
			_surfboard = createEntityFromClip (super._hitContainer["surfBoard"])
			makeEntityFollowPlayer(_surfboard)
			_zDepthCreator.addZDepthEntity(_surfboard,0,_zControlEntity)
			
			_surfboardSubmerged = createEntityFromClip (super._hitContainer["surfBoardSubmerged"])
			makeEntityFollowPlayer(_surfboardSubmerged)
			_zDepthCreator.addZDepthEntity(_surfboardSubmerged,0,_zControlEntity)
			
			_surfboardShadow = createEntityFromClip (super._hitContainer["surfBoardShadow"])
			makeEntityFollowPlayer(_surfboardShadow)
			_zDepthCreator.addZDepthEntity(_surfboardShadow,50,_zControlEntity) 
			
			// Splash is animated
			mc = super._hitContainer["surfBoardSplash"]
			_surfboardSplash = BitmapTimelineCreator.createBitmapTimeline(mc,true,true )
			_surfboardSplash.add(new Spatial(mc.x,mc.y))
			_surfboardSplash.add (new Motion)			
			addEntity(_surfboardSplash)
			makeEntityFollowPlayer(_surfboardSplash)
			_zDepthCreator.addZDepthEntity(_surfboardSplash,0,_zControlEntity) 
			var tl:Timeline = _surfboardSplash.get (Timeline)
			tl.playing = true
			
			setSurfboardSubmerged (true)
			
			_hud = super.addChildGroup(new SkiingHud(super.overlayContainer)) as SkiingHud;
			_hud.stopRaceClicked.add(onStopRaceClicked)
			_hud.exitClicked.add(onExitPracticeClicked)
			_hud.startGunFire.add(startRace)
			_hud.ready.addOnce(initHud);
			
			_bgLooper = new SkiingBgLooper()
			_bgLooper.init (_loopingEntities)
			super.addSystem(_bgLooper, SystemPriorities.autoAnim );
			
			_checkReachedMaxSpeed = new CheckReachedMaxSpeedSystem()
			_checkReachedMaxSpeed.init (_bgEntities)
			_checkReachedMaxSpeed.speed = COURSE_SPEED
			super.addSystem(_checkReachedMaxSpeed, SystemPriorities.autoAnim );
			
			buildCourse()
			
			_charControlSystem = new SkiingCharControlSystem()
			_charControlSystem.init(_playerDummy,this,_surfboardShadow,_surfboard,_surfboardSubmerged,_surfboardSplash)
			_charControlSystem.jumpComplete.add(onJumpComplete);
			
			super.addSystem( _charControlSystem, SystemPriorities.autoAnim );
			
			SceneUtil.addTimedEvent( this, new TimedEvent(.1, 1, onSceneAnimateInComplete));
			
			super.removeEntity( super.player );
			
		}
		
		private function addOrigSpatial(e:Entity):void
		{
			var sp:Spatial = e.get(Spatial)
			e.add(new OrigSpatial (sp.x, sp.y))			
		}
		
		private function createEntityFromClip(mc:MovieClip):Entity
		{
			var e:Entity = new Entity
			var spr:Sprite = DisplayUtils.convertToBitmapSprite(mc).sprite
			e.add(new Display(spr))
			e.add(new Spatial(mc.x,mc.y))
			e.add (new Motion)			
			addEntity(e)
			spr.parent.addChild(spr)
			
			return e
		}
		
		private function makePlayerFollowMouseTrue ():void {
			makePlayerFollowMouse(true)
		}
		
		private function makePlayerFollowMouse(b:Boolean):void
		{
			trace ("[Skiing] makePlayerFollowMouse---------: " + b)
			var sp:Spatial
			_playerDummy.remove(FollowTarget)
			//trace ("_playerDummy.remove(FollowTarget):" + _playerDummy.remove(FollowTarget))
			
			if (b) {
				sp = super.shellApi.inputEntity.get(Spatial)
				var follow:FollowTarget = new FollowTarget(sp,.05);
				follow.properties = new <String>["x","y"];
				_playerDummy.add(follow);
			} 
		}
		
		private function setSurfboardSubmerged(b:Boolean):void
		{
			Display(_surfboard.get(Display)).visible = !b
			Display(_surfboardShadow.get(Display)).visible = !b
			Display(_surfboardSubmerged.get(Display)).visible = b
			Display(_surfboardSplash.get(Display)).visible = b
		}
		
		private function makeEntityFollowPlayer(e:Entity):void
		{
			var follow:FollowTarget = new FollowTarget(Spatial(_playerDummy.get(Spatial)));
			follow.properties = new <String>["x","y"];
			e.add(follow);
		}
		
		private function buildCourse():void
		{
			var e:Entity
			var courseXml:XML = getData("course.xml",true);
			var i:int;
			var mc:MovieClip
			var spr:Sprite;
			var gp:GatePartner
			
			var _collisionEntities:Vector.<Entity> = new Vector.<Entity>
			var _courseEntities:Vector.<Entity> = new Vector.<Entity>
			var sp:Spatial
			var elemTypes:Array = ["gate","rampSmall", "rampBig","lavaDecal","obstacleStatue","obstacleHead","obstacleFoot","obstacleRock0","obstacleRock1","obstacleRock2","obstacleRock3","obstacleTree","finishLineFront","finishLineBack"]
			
			var uncollideableObjectTypes:Array = []
			uncollideableObjectTypes.push ("lavaDecal","finishLineBack")
			
			var type:String
			
			_spritesForPooling = {}
			
			for (var t:int=0; t < elemTypes.length;t++) {
				type = elemTypes[t]
				_spritesForPooling[type]=[]
				i = 0
				while (_hitContainer[type + "_" + i] != undefined) {
					//trace ("[Skiing] --------type:" + type + " i: "+ i)
					mc = _hitContainer[type + "_" + i]
					spr = DisplayUtils.convertToBitmapSprite(mc).sprite;
					if (type == "gate") {
						addSmokeAndFire(spr)
					}
					_spritesForPooling[type].push (spr) 
					i++
				}
			}
			
			_gateThroughEntity = []
			for (i = 0; i < 2 ; i++) {
				mc = _hitContainer["gateThrough_" + i]
				spr = DisplayUtils.convertToBitmapSprite(mc).sprite;
				e = new Entity()
				e.add(new Display(spr)) 
				e.add(new Spatial())
				e.add(new Motion())
				this.addEntity(e)
				_zDepthCreator.addZDepthEntity(e,10000,_zControlEntity )
				_gateThroughEntity.push (e)
			}
			
			// Create course element entities.
			var elemXml:XML
			
			for ( t=0; t < elemTypes.length;t++) {
				type = elemTypes[t]
				for (i=0; i < courseXml[type].length();i++) {
					elemXml = courseXml[type][i][0]
					
					e = new Entity();
					e.add (new Motion);
					sp = new Spatial();
					sp.x = Number (elemXml.x);
					sp.y = Number (elemXml.y);
					e.add(sp);
					e.add(new Display());
					e.add(new ObstacleType(type));
					e.add(new StateString("normal"));
					this.addEntity(e);
					addBackgroundEntity(e);
					_courseEntities.push (e);
					_zDepthCreator.addZDepthEntity(e,calcZDepth(sp.x,sp.y),_zControlEntity );
					//trace ("[Skiing] -------adding elem of type " + type )
					if (uncollideableObjectTypes.indexOf(type) == -1) {
						_collisionEntities.push (e)
					}
					switch (type) {
						case "gate":
							var e2:Entity = new Entity();
							e.add (new GatePartner(e2));
							e2.add (new Motion);
							var sp2:Spatial = new Spatial();
							sp2.x = sp.x + GATE_SEPARATION_X;
							sp2.y = sp.y + GATE_SEPARATION_Y;
							e2.add(sp2);
							var o:ObstacleType = new ObstacleType("gate");
							e2.add(o);
							e2.add(new Display());
							this.addEntity(e2);
							addBackgroundEntity(e2);
							_courseEntities.push (e2);
							_zDepthCreator.addZDepthEntity(e2,calcZDepth(sp2.x,sp2.y) ,_zControlEntity );
							break
						case "lavaDecal": 
							//	trace ("[Skiing] found lavaDecal")
							e.get(ZDepth).z = 10;
							break
						default:
							break
					}
				}
			}
			
			var _obstacleSystem:SkiingObstacleSystem = new SkiingObstacleSystem
			_obstacleSystem.init (_courseEntities,_spritesForPooling)
			addSystem(_obstacleSystem, SystemPriorities.autoAnim );	
			_obstacleSystem.group = this
			
			_collisionSystem = new SkiingCollisionSystem()
			_collisionSystem.init(_playerDummy,_collisionEntities)
			_collisionSystem.collision.add( onCollision );
		}
		
		private function addBackgroundEntity(e:Entity):void
		{
			//trace ("[Skiing] addBgEntity:" + e)
			_bgEntities.push(e)
			var sp:Spatial = e.get(Spatial)
			e.add(new OrigSpatial (sp.x, sp.y))
		}
		
		private function addSmokeAndFire (spr:Sprite):void {
			var lz:LineZone = new LineZone( new Point( 0, -200), new Point( 0, -40 ) );
			var fire:Fire = new Fire
			fire.init(5, new RectangleZone(-6, 6, 0, 0));
			var h:Number = 47
			var v:Number = -137
			
			EmitterCreator.create(this, spr, fire, h, v, null,"fire");
			
			var smoke:Smoke = new Smoke
			smoke.init(new Spatial,lz)
			smoke.changeDirection()
			EmitterCreator.create(this, spr, smoke, h-1, v-2, null,"smoke");
		}
		
		private function addGateParticles(e:Entity):void
		{
			var spr:Sprite = Sprite(Display(e.get(Display)).displayObject )
			var lz:LineZone = new LineZone( new Point( 0, -200), new Point( 0, -40 ) );
			var bubbles:Bubbles = new Bubbles
			bubbles.init( new RectangleZone(-6, 6, 0, 0));
			var h:Number = 47
			var v:Number = -137
			EmitterCreator.create(this, spr, bubbles, h, v, null,"bubbles");
		}
		
		private function onSceneAnimateInComplete ():void {
			openInstructionsPopup()
			
			//			var _cameraControl:Entity = new Entity
			//			_cameraControl.add (new Spatial (500,0))
			//			this.addEntity(_cameraControl)
			//			SceneUtil.setCameraTarget(this,_cameraControl,true );
			//			
			//			var sp:Spatial = super.shellApi.inputEntity.get(Spatial)
			//			var follow:FollowTarget = new FollowTarget(sp,.05);
			//			follow.properties = new <String>["x","y"];
			//			//_cameraControl.add(follow);	
		}
		
		private function startRace():void {
			
			//CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.HurdleRun,false)
			
			_playerDummy.get(StateString).state = "skiing"
			
			var m:Motion = _playerDummy.get(Motion) as Motion
			m.velocity.x = INITIAL_VEL_X
			m.velocity.y = m.velocity.x * SLOPE_WIDTH
			
			//var d:Display = _lavaHot.get(Display) as Display
			//MovieClip (d.displayObject).play()
			
			SceneUtil.addTimedEvent( this, new TimedEvent(.1, 1, startBg));
			_hud.startRaceTimer()
			
			if (!_practice) {
				_hud.setMode("race")
			} else {
				_hud.setMode("practice")
			}
		}
		
		private function startBg():void {
			_bgLooper.start()
			
			var m:Motion 
			for each (var e:Entity in _bgEntities) {
				m = e.get (Motion) as Motion
				m.acceleration.x = BG_ACCEL_X
				m.acceleration.y = BG_ACCEL_Y
				m = _playerDummy.get(Motion) as Motion
				var tween:Tween = new Tween();
				e.add(tween)
				tween.to(m.velocity, .6, {x:0, y:0, ease:Sine.easeOut} );
				
				m.acceleration.x = 0
				m.acceleration.y = 0 
			}
		}
		
		private function stopBg():void {
			var m:Motion 
			for each (var e:Entity in _bgEntities) {
				m = e.get (Motion) as Motion
				m.acceleration.x = 0
				m.acceleration.y = 0
				m.velocity.x = 0
				m.velocity.y = 0
			}
		}
		
		private function setBgVelocity(x:Number,y:Number):void {
			var m:Motion 
			for each (var e:Entity in _bgEntities) {
				m = e.get (Motion) as Motion
				m.velocity.x = x
				m.velocity.y = y
				m.acceleration.x = BG_ACCEL_X
				m.acceleration.y = BG_ACCEL_Y // ????
			}
		}
		
		private function initHud (hud:SkiingHud):void {
			_hud.setMode("clear")
		}
		
		private function setupRace():void {
			
			var spatial:Spatial
			var motion:Motion
			
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.poptropolis.HurdleStart)
			spatial =_playerDummy.get(Spatial) as Spatial
			motion = Motion (_playerDummy.get(Motion))
			motion.acceleration.x = 0	
			motion.acceleration.y = 0	
			motion.velocity.x = 0;
			motion.velocity.y = 0;
			
			_collisionSystem.setupRace()
			super.addSystem( _collisionSystem, SystemPriorities.autoAnim );
			
			_hud.resetRaceTimer()
			
		}
		
		private function setPracticeMode (b:Boolean):void {
			_practice = b
		}
		
		private function abortRace ():void {
			_hud.setMode("clear")
			stopBg()
			openInstructionsPopup()
			_hud.abortRace()
			stopPlayer()
			makePlayerFollowMouse(false)
		}
		
		private function stopPlayer():void {
			var spatial:Spatial
			var motion:Motion
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.Stand)
			spatial =_playerDummy.get(Spatial) as Spatial
			motion = Motion (_playerDummy.get(Motion))
			motion.acceleration.x = 0	
			motion.acceleration.y = 0	
			motion.velocity.x = 0	
			motion.velocity.y = 0
		}
		
		private function onCollision (e:Entity):void {
			var playerM:Motion = _playerDummy.get(Motion)
			var t:String = e.get(ObstacleType).type
			//trace ("===========================[Skiing] onCollision:" + t)
			switch (t) {
				case "gate":
					//addGateParticles(e)
					var sp:Spatial = e.get(Spatial)
					var follow:FollowTarget = new FollowTarget(sp,1);
					follow.properties = new <String>["x","y"];
					_gateThroughEntity[0].add(follow);	
					_gateThroughEntity[0].get(ZDepth).z = e.get(ZDepth).z+1
					sp = e.get(GatePartner).partner.get(Spatial)
					follow = new FollowTarget(sp,1);
					follow.properties = new <String>["x","y"];
					_gateThroughEntity[1].add(follow);	
					_gateThroughEntity[1].get(ZDepth).z = e.get(GatePartner).partner.get(ZDepth).z+1
					e.get(StateString).state = "hit"
					_hud.showTimeBonus(_playerDummy)
					
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "points_ping_01a.mp3");
					
					break
				case "obstacleRock0":
				case "obstacleRock1":
				case "obstacleRock2":
				case "obstacleRock3":
				case "obstacleHead":
				case "obstacleFoot":
				case "obstacleStatue":
				case "obstacleTree":
					makePlayerFollowMouse(false)
					knockPlayerBack()
					
					SceneUtil.addTimedEvent( this, new TimedEvent(.5, 1, makePlayerFollowMouseTrue));
					SceneUtil.addTimedEvent( this, new TimedEvent(1, 1, onPlayerHitComplete));
					
					_playerDummy.get (StateString).state = "hit"
					setBgVelocity (0,0)
					var r:int = Math.floor (Math.random() * 4) + 1
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "stone_break_0" + r +".mp3");
					_hud.showTimePenalty()
					break
				case "rampBig":
					jump("big")
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "object_toss_01.mp3");
					break;
				
				case "rampSmall":
					jump("small")
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "object_toss_01.mp3");
					break;
				case "finishLineFront":
					_playerDummy.get (StateString).state = "crossedFinish"
					makePlayerFollowMouse(false)
					var m:Motion = _playerDummy.get(Motion) as Motion
					m.velocity.x = 1300
					m.velocity.y = m.velocity.x * SLOPE_WIDTH
					m.acceleration.x = 0
					m.acceleration.y = 0
					stopBg()
					_hud.stopRaceTimer()
					CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.poptropolis.HurdleStop)

					SceneUtil.addTimedEvent( this, new TimedEvent(.5, 1, raceOver));
					
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "victoryFanfare.mp3");
					
					break
			}
		}
		
		private function knockPlayerBack():void
		{
			var v:Number = -300
			var m:Motion = _playerDummy.get(Motion) as Motion
			var sp:Spatial = _playerDummy.get(Spatial)
			sp.x -= 50
			sp.y -= 50 * SLOPE_WIDTH
			
			//			m.velocity.x = v
			//			m.velocity.y = v*SLOPE_WIDTH
			//			m.acceleration.x = 0
			//			m.acceleration.y = 0
			
			trace ("[Skiing] _playerDummy.get(Motion).velocity:" +  _playerDummy.get(Motion).velocity.x  + "," + _playerDummy.get(Motion).velocity.y )
		}
		
		private function onPlayerHitComplete():void
		{
			_playerDummy.get (StateString).state = "skiing"
			//makePlayerFollowMouse(true)
		}
		
		private function raceOver():void {
			trace ("===========================[Skiing]race over!:" )
			
			//_practice = true // temp!
			if (_practice) {
				openInstructionsPopup()
			} else {
				var pop:Poptropolis = new Poptropolis( this.shellApi, this.reportResults );
				pop.setup();
			}
		}
		private function reportResults( gameInfo:Poptropolis ):void {
			trace ("[Skiing]  _hud.raceTime:" +  _hud.raceTime)
			gameInfo.reportScore( Matches.SKIING, _hud.raceTime, true );
		} 
		
		private function onJumpComplete():void {
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.Stand,true)
			_playerDummy.get (StateString).state = "skiing"
			makePlayerFollowMouse(true)
			setSurfboardSubmerged(true)
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "acid_splash_01.mp3");
			_checkReachedMaxSpeed.speed = COURSE_SPEED
		}
		
		override protected function onStartClicked (): void {
			trace ("[Skiing] ---------------- start!")
			setPracticeMode(false)
			startCommon()
		}
		
		override protected function onPracticeClicked (): void {
			trace ("[Skiing] ---------------- practice!!")
			setPracticeMode(true)
			startCommon()
		}
		
		override protected function onDebugClicked(): void {
			trace ("[Skiing] ---------------- debug!!")
			_checkReachedMaxSpeed.speed = COURSE_SPEED_SLOW
			setPracticeMode(false)
			startCommon()
		}
		
		private function startCommon():void
		{
			resetRace()
			setupRace()
			var sp:Spatial = _lavaHot.get(Spatial) as Spatial
			var t:Tween = new Tween()
			_lavaHot.add(t)
			t.to( sp, 2, { x: -975, y: -573, ease:Sine.easeInOut, onComplete: onLavaAnimComplete})
			startCountdown()
			
			var tl:Timeline = _snakeEyesAnim.get(Timeline) as Timeline
			tl.gotoAndPlay(1)
			
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, startLavaGushSound));
		}
		
		private function startLavaGushSound ():void {
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "LavaGush_01.mp3",3);
		}
		
		private function onLavaAnimComplete ():void {
			trace ("[Skiing] onLavaAnimComplete")
			makePlayerFollowMouse (true)
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "LavaSurf_01_L.mp3");
		}
		
		private function startCountdown():void {
			SceneUtil.addTimedEvent( this, new TimedEvent(.75, 1, _hud.startCountdown));
		}
		
		private function onExitPracticeClicked (): void {
			trace ("[Skiing] ---------------- stop practice!!")
			abortRace()
		}
		
		private function onStopRaceClicked (): void {
			trace ("[Skiing] ---------------- stop race!!")
			abortRace()
		}
		
		private function resetRace():void
		{
			// reset positions of all bg elems
			for each (var e:Entity in _bgEntities) {
				resetEntityToOrigSpatial(e)
				if (e.get(StateString))	e.get(StateString).state = "normal"
			}
			resetEntityToOrigSpatial(_playerDummy)
			resetEntityToOrigSpatial(_lavaHot)
		}
		
		private function resetEntityToOrigSpatial(e:Entity):void
		{
			var spatial:Spatial
			spatial = e.get(Spatial) as Spatial
			var os:OrigSpatial = e.get(OrigSpatial) as OrigSpatial
			spatial.x = os.x
			spatial.y = os.y
		}
		
		private function onMouseDown( input:Input ):void
		{
			
		}
		
		private function onMouseUp( input:Input ):void
		{
			
		}	
		
		public function jump (jumpType:String):void {
			//n	trace ("[SkiingCharControlSystem] Jump attempt. _playerDummy.get (RunnerState).state:" + _playerDummy.get (RunnerState).state)
			//if (_playerDummy.get (PlayerState).state == "skiing") {
			CharUtils.setAnim(_playerDummy,game.data.animation.entity.character.poptropolis.HurdleJump)
			var m:Motion = _playerDummy.get (Motion) as Motion
			trace ("[SkiingCharControlSystem] jump:" + (_playerDummy.get(Spatial).x))
			_playerDummy.get (StateString).state = "jumping"
			switch (jumpType) {
				case "small":
					m.velocity.x = 100 
					m.velocity.y = -400
					m.acceleration.x = -5
					m.acceleration.y = 600
					break
				case "big":
					m.velocity.x = 250 
					m.velocity.y = -850
					m.acceleration.x = -15
					m.acceleration.y = 1100
					break
			}
			_checkReachedMaxSpeed.speed = COURSE_SPEED_JUMP
			var sp:Spatial = _playerDummy.get(Spatial)
			_charControlSystem.bForShadow = sp.y - Skiing.SLOPE_WIDTH * sp.x
			_playerDummy.get(ZDepth).z = 10000 // on top of all
			setSurfboardSubmerged(false)
			makePlayerFollowMouse (false)
			
			//var r:Number = -40
			//_surfboard.get(Spatial).rotation = r
			
		}
		
		public static function calcZDepth(x:Number, y:Number):Number
		{
			var d:Number = Math.abs (y - Skiing.SLOPE_WIDTH*x - (-10000)) / Math.sqrt(Skiing.SLOPE_WIDTH * Skiing.SLOPE_WIDTH + 1)
			//trace ("calcZDepth:" + x + "," + y + "   z:" + d)
			return d
		}
	}
}
package game.scenes.mocktropica.robotBossBattle {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Sleep;
	import game.components.entity.VariableTimeline;
	import game.components.motion.Edge;
	import game.components.ui.Cursor;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.mainStreet.MainStreet;
	import game.scenes.mocktropica.robotBossBattle.classes.RobotBossManager;
	import game.scenes.mocktropica.robotBossBattle.components.CoinShot3D;
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.components.RobotBoss;
	import game.scenes.mocktropica.robotBossBattle.components.RobotPlayer;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthScale;
	import game.scenes.mocktropica.robotBossBattle.systems.CoinShotSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.RobotBossSystem;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.shared.components.Enemy;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.ZDepthSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;

	public class RobotBossBattle extends Scene {

		private const COIN_SCALE:Number = 0.3;
		private const COIN_SPEED:Number = 3000;

		private var mockEvents:MocktropicaEvents;

		/**
		 * there are two achievements that get blown up using the same set of functions.
		 * this indicates which achievement is current.
		 */
		private var achievementPhase:int = 1;

		/**
		 * The view with the ProspectiveProjection data that will contain the robot and missiles.
		 */
		private var view3D:MovieClip;

		private var robotManager:RobotBossManager;

		/**
		 * Used to position coins being fired on-screen.
		 */
		private var camera:CameraSystem;

		/**
		 * Entity for player input. code example taken from Archery.
		 */
		private var inputEntity:Entity;

		private var playerEntity:Entity;

		/**
		 * Used to scale all the stupid clips.
		 */
		private var scaleComponent:ZDepthScale;

		/**
		 * Reusable bitmap for the coin? It won't necessarily scale well.
		 * Try it anyway to save on load times.
		 */
		private var coinBitmap:BitmapData;

		public function RobotBossBattle() {

			super();

		} //

		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void {

			super.groupPrefix = "scenes/mocktropica/robotBossBattle/";			
			super.init( container );

			this.load();

		} //

		// initiate asset load of scene configuration.
		override public function load():void {

			super.shellApi.fileLoadComplete.addOnce( this.loadAssets );
			super.loadFiles( [GameScene.SCENE_FILE_NAME,GameScene.SOUNDS_FILE_NAME] );

		} // load()

		protected function loadAssets():void {

			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);

			super.sceneData = parser.parse( sceneXml );			
			super.shellApi.fileLoadComplete.addOnce( this.loaded );
			super.loadFiles( super.sceneData.assets );

		} //

		// all assets ready
		override public function loaded():void {

			this.mockEvents = this.events as MocktropicaEvents;

			super.addSystem(new TweenSystem(), SystemPriorities.update);			// needed for popup twween.
			this.addSystem( new ZDepthSystem(), SystemPriorities.preRender );
			this.addSystem( new CoinShotSystem(), SystemPriorities.update );
			this.addSystem( new BoundsCheckSystem(), SystemPriorities.preRender );
			//this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );

			var cameraGroup:CameraGroup = new CameraGroup();

			// This method of cameraGroup does all setup needed to add a camera to this scene.  After calling this method you just need to assign cameraGroup.target to the spatial component of the Entity you want to follow.
			// NOTE : The scene width/height MUST be bigger than the viewport when at the minimum scale.
			cameraGroup.setupScene( this, 0.8 );
			this.camera = this.shellApi.camera;

			this.prepareCoin( this.getAsset( "coin.swf", true ) );

			this.create3DView();

			this.inputEntity = this.shellApi.inputEntity;
			this.initPlayerEntity();

			this.robotManager = new RobotBossManager( this, this.view3D );
			this.robotManager.loadAssets( this.robotLoaded );

			super.loaded();
			
		} // loaded()

		private function robotLoaded( robotEntity:Entity ):void {

			var bossSystem:RobotBossSystem = this.getSystem( RobotBossSystem ) as RobotBossSystem;
			bossSystem.onBossDestroyed = this.onBossDied;

			this.initPlayerInput();

		} // robotLoaded()

		/**
		 * Set the parent displayObject PerspectiveProjection
		 */
		private function create3DView():void {

			var viewEntity:Entity = super.getEntityById( "view3d" );
			this.view3D = Display( viewEntity.get(Display) ).displayObject;

			this.scaleComponent = new ZDepthScale( -400 );

		} //

		private function initPlayerInput():void {

			//change tooltip to "target"
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.TARGET;

			/**
			 * Using the input entity will only work when you click on the background. I need to register all clicks.
			 * It uses a round-about event scheme anyway.
			 */
			this.view3D.stage.addEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );

			//  the follower target is the 'input' entity referred to in the shellApi.  This input entity is automatically mapped to the mouse position.
			EntityUtils.followTarget( this.playerEntity, this.inputEntity, 0.1, null, true );
			super.addSystem( new FollowTargetSystem(), SystemPriorities.move );

			/*var input:Input = this.inputEntity.get( Input ) as Input;
			input.inputDown.add( this.onMouseDown );*/

		} // inputPlayerInput()

		/**
		 * Create a hit area on the screen representing the area where the player can get hit.
		 */
		private function initPlayerEntity():void {

			var hit:HitBox3D = new HitBox3D( this.shellApi.viewportWidth/2, this.shellApi.viewportHeight*0.8, 10 );

			var spatial:Spatial = new Spatial( this.camera.areaWidth/2, 0.5*this.camera.areaHeight );
			var sprite:Sprite = this.makeHitSprite();
			var display:Display = new Display( sprite );
			display.visible = false;
			display.alpha = 0;

			var life:Life = new Life( 50 );
			life.hitResetTime = 2;
			life.onDie.addOnce( this.playerDied );

			this.view3D.addChild( display.displayObject );

			var e:Entity = this.playerEntity = new Entity( "playerHit" )
				.add( life, Life )
				.add( spatial, Spatial )
				.add( new RobotPlayer(), RobotPlayer )
				.add( display, Display )
				.add( new ZDepthNumber(-1), ZDepthNumber )
			.add( new Edge( this.camera.viewportWidth/2, this.camera.viewportHeight/2, this.camera.viewportWidth/2, this.camera.viewportHeight/2 ), Edge )
				.add( new MotionBounds( new Rectangle(0,0,this.camera.areaWidth, this.camera.areaHeight) ), MotionBounds )
				.add( hit, HitBox3D );

			// set the camera to use the new target entity's Spatial as its target.
			( super.getGroupById( "cameraGroup" ) as CameraGroup ).setTarget( spatial, true );

			this.addEntity( e );

		} // initPlayerEntity()

		private function makeHitSprite():Sprite {

			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;

			g.beginFill( 0xAA0000, 1 );
			g.drawRect( -0.8*this.camera.viewportWidth, -0.8*this.camera.viewportHeight, 1.6*this.camera.viewportWidth, 1.6*this.camera.viewportHeight );
			g.endFill();

			return s;

		} //

		private function onBossDied( entity:Entity ):void {
			
			this.removeEntity( entity, true );
			
			this.shellApi.completeEvent( this.mockEvents.DEFEATED_BOSS );
			
			// set the achievement for defeating the boss but don't actually load the achievement popup - the loaded enemy entity looks exactly like it.
			var grp:AchievementGroup = new AchievementGroup( this );
			grp.id = "achievement";
			this.addChildGroup( grp );
			grp.setAchievement( this.mockEvents.ACHIEVEMENT_POPTROPICA_MASTER );
			
			this.shellApi.loadFile( this.shellApi.assetPrefix + this.groupPrefix + "achievementBoss.swf", this.makeAchievementEntity );

		} //

		/**
		 * Create the achievement screen entity thing.
		 */
		private function makeAchievementEntity( clip:MovieClip ):void {

			//var clip:MovieClip = this.shellApi.getFile( this.shellApi.assetPrefix + this.groupPrefix + "achievementBoss.swf", true );
			var display:Display = new Display( clip );
			this.view3D.addChild( clip );

			var spatial:Spatial = new Spatial( this.camera.areaWidth/2, -clip.height );

			var life:Life = new Life( 14 );
			life.hitResetTime = 0.1;
			life.onDie.add( this.achievementDied );

			var target:MoveTarget3D = new MoveTarget3D( spatial.x, this.camera.areaHeight/2, RobotBoss.Z_MIN/2 );
			target.acceleration = 4000;
			target.decceleration = 3000;
			target.active = true;
			target.onReachedTarget.addOnce( this.achievementOnScreen );

			var tl:VariableTimeline = new VariableTimeline( false );
			tl.onTimelineEnd.addOnce( this.achievementBroken );
			tl.gotoAndStop( 1 );

			var e:Entity = new Entity( "achievementBoss" )
				.add( spatial, Spatial )
				.add( new Motion3D(), Motion3D )
				.add( new Sleep( false, true ), Sleep )
				.add( tl, VariableTimeline )
				e.add( life, Life )
				.add( target, MoveTarget3D )
				.add( new ColorBlink( 0x660000, 0.43, 0.5 ), ColorBlink )
				.add( new Enemy(), Enemy )
				.add( new HitBox3D( clip.width, clip.height, 30 ), HitBox3D )
				//.add( this.scaleComponent, ZDepthScale )					// don't scale - needs to look like the genuine popup.
				.add( new ZDepthNumber( RobotBoss.Z_MIN/2 ), ZDepthNumber )
				.add( display, Display );

			this.addEntity( e );

			SceneUtil.setCameraTarget( this, e );

		} //

		/**
		 * Now the stupid achievement is on the stupid screen so let the stupid player stupid shoot it.
		 */
		private function achievementOnScreen( e:Entity ):void {

			SceneUtil.setCameraTarget( this, this.playerEntity );

		} //

		private function achievementDied( e:Entity ):void {

			( e.get( VariableTimeline ) as VariableTimeline ).playing = true;

		} //

		/**
		 * The entity should be the achievement thingy.
		 */
		private function achievementBroken( e:Entity, tl:VariableTimeline ):void {

			var display:Display = e.get( Display ) as Display;

			this.burstSign( display.displayObject as MovieClip, ( e.get( ZDepthNumber ) as ZDepthNumber ).z );

			display.visible = false;
			this.removeEntity( e, true );

			// wait 2 seconds.
			var action:WaitAction = new WaitAction( 1 );
			action.run( this, this.achievementBlownUp );

		} //

		private function achievementBlownUp( a:ActionCommand ):void {

			if ( this.achievementPhase == 1 ) {

				// in theory we could re-use the old entity here.
				this.achievementPhase++;
				this.shellApi.loadFile( this.shellApi.assetPrefix + this.groupPrefix + "achievementBoss2.swf", this.makeAchievementEntity );

			} else {

				// end the game permanent-like.
				var grp:AchievementGroup = this.getGroupById( "achievement" ) as AchievementGroup;
				grp.setAchievement( this.mockEvents.ACHIEVEMENT_ULTIMATE_ACHIEVER );
				//shellApi.triggerEvent(mockEvents.DEFEATED_BOSS,true);
				this.shellApi.loadScene( MainStreet );
				//grp.completeAchievement( this.mockEvents.ACHIEVEMENT_ULTIMATE_ACHIEVER, Command.create( this.shellApi.loadScene, MainStreet ) );

			} // end-if.

		} //

		/**
		 * blow up the achievement sign thing.
		 */
		private function burstSign( signClip:MovieClip, zStart:Number ):void {

			var mc:MovieClip;
			var e:Entity;
			var p:Point = new Point();

			var noSleep:Sleep = new Sleep( false, true );

			for( var i:int = signClip.numChildren-1; i >= 0; i-- ) {

				mc = signClip.getChildAt( i ) as MovieClip;

				p.setTo( 0, 0 );		// reuse the last point since all these things keep wastefully generating new points...
				p = this.view3D.globalToLocal( mc.localToGlobal( p ) );

				this.view3D.addChild( mc );

				e = new Entity()
					.add( new Spatial( p.x, p.y ), Spatial )
					.add( new Display( mc ), Display )
					.add( new ZDepthNumber( zStart ), ZDepthNumber )
					.add( noSleep, Sleep )
					.add( this.scaleComponent, ZDepthScale )
					.add( new Motion3D( -500+1000*Math.random(), -400+800*Math.random(), -40+2000*Math.random(), 2*(-Math.PI+2*Math.PI*Math.random()) ), Motion3D );

				this.addEntity( e );

			} // end for-loop.
			// trigger sound
			shellApi.triggerEvent("break_achievement");
		} // burstSign()

		/**
		 * Player died. don't let them fire any more coins, for starters.
		 */
		private function playerDied( entity:Entity ):void {

			//var input:Input = this.inputEntity.get( Input ) as Input;
			//input.inputDown.remove( this.onMouseDown );

			this.view3D.stage.removeEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );
			this.shellApi.loadScene( MainStreet );

		} //

		/**
		 * Player click - fire a coin.
		 */
		private function onMouseDown( e:MouseEvent ):void {
			
			//this.shellApi.loadFile( this.shellApi.assetPrefix + this.groupPrefix + "coin.swf", this.coinLoaded );

			// display doesn't use bitmaps so we need to waste a sprite just to hold the frickin bitmap...
			var bitmap:Bitmap = new Bitmap( this.coinBitmap, "auto", true );
			bitmap.x = -this.coinBitmap.width/2;
			bitmap.y = -this.coinBitmap.height/2;

			var sprite:Sprite = new Sprite();
			sprite.addChild( bitmap );

			this.coinLoaded( sprite );

		} //

		/**
		 * Display for a new coin loaded.
		 */
		private function coinLoaded( sprite:Sprite ):void {

			sprite.scaleX = sprite.scaleY = COIN_SCALE;
			sprite.rotation = 260*Math.random();

			// x,y velocity? Maybe no x, only y.
			//missile.vy = -40;

			var igSleep:Sleep = new Sleep( false, true );
			var sp:Spatial = this.inputEntity.get( Spatial );
			var point:Point = DisplayUtils.localToLocal(inputEntity.get(Display).displayObject, view3D);

			var coin:Entity = new Entity()
				.add( igSleep, Sleep )
				.add( new Display( sprite, view3D ), Display )
				.add( new ZDepthNumber( 1 ), ZDepthNumber )
				.add( this.scaleComponent, ZDepthScale )
				.add( new Spatial( point.x + 20, point.y + 20))
				.add( new Motion3D( 0, 0, this.COIN_SPEED ), Motion3D )
				.add( new CoinShot3D(), CoinShot3D );
			
			this.addEntity( coin );
			shellApi.triggerEvent("throw_coin");
		} // coinLoaded()

		private function prepareCoin( mc:MovieClip ):void {

			this.coinBitmap = new BitmapData( mc.width, mc.height, true, 0 );
			this.coinBitmap.draw( mc, new Matrix( 2*COIN_SCALE, 0, 0, 2*COIN_SCALE, mc.width/2, mc.height/2 ) );
		} //

		public function getPlayer():Entity {
			return this.playerEntity;
		}

		public function getScaleComponent():ZDepthScale {
			return this.scaleComponent;
		}

		override public function destroy():void {

			// check first if the event exists?
			this.view3D.stage.removeEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );

			super.destroy();

		} //

	} // End RobotBossBattle

} // End package
package game.scenes.mocktropica.robotBossBattle.classes {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.entity.Sleep;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.mocktropica.robotBossBattle.RobotBossBattle;
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.MoveTarget3D;
	import game.scenes.mocktropica.robotBossBattle.components.RobotBoss;
	import game.scenes.mocktropica.robotBossBattle.components.RobotMissile;
	import game.scenes.mocktropica.robotBossBattle.components.StateMachine;
	import game.scenes.mocktropica.robotBossBattle.components.Track3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthScale;
	import game.scenes.mocktropica.robotBossBattle.systems.DepthScaleSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.LifeSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.Motion3DSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.MoveTarget3DSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.RobotBossSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.RobotMissileSystem;
	import game.scenes.mocktropica.robotBossBattle.systems.Track3DSystem;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.heart.systems.ColorBlinkSystem;
	import game.scenes.virusHunter.shared.components.Enemy;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;

	public class RobotBossManager {

		private var scene:Scene;
		private var shellApi:ShellApi;

		private var robotEntity:Entity;

		/**
		 * onLoaded( robotEntity:Entity )
		 */
		public var onLoaded:Signal;

		private var boss_prefix:String = "boss_";
		private var suffix:String = ".swf";

		private var view3D:DisplayObjectContainer;

		public function RobotBossManager( curScene:Scene, bossContainer:DisplayObjectContainer ) {

			this.scene = curScene;
			this.shellApi = curScene.shellApi;

			this.view3D = bossContainer;

			this.onLoaded = new Signal( Entity );

		} //

		/**
		 * callback returns the created robot entity.
		 */
		public function loadAssets( callback:Function ):void {

			this.onLoaded.addOnce( callback );

			var prefix:String = this.shellApi.assetPrefix + this.scene.groupPrefix + this.boss_prefix;

			this.shellApi.loadFiles( [
				prefix + RobotBoss.IDLE + ".swf",
				prefix + RobotBoss.BOULDER_IDLE + ".swf",
				prefix + RobotBoss.THROW + ".swf",
				prefix + RobotBoss.FIRE_MISSILE + ".swf",
				prefix + RobotBoss.DODGE + ".swf",
				prefix + RobotBoss.KILLED + ".swf" ],
					this.assetsLoaded );

		} //

		private function assetsLoaded():void {

			this.addRobotSystems();
			this.createRobot();

			this.initMissiles();

			this.onLoaded.dispatch( this.robotEntity );
			this.onLoaded.removeAll();
			this.onLoaded = null;

		} //

		private function addRobotSystems():void {

			this.scene.addSystem( new RobotBossSystem(), SystemPriorities.update );
			this.scene.addSystem( new RobotMissileSystem(), SystemPriorities.update );
			this.scene.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );
			this.scene.addSystem( new Motion3DSystem(), SystemPriorities.move );
			this.scene.addSystem( new MoveTarget3DSystem(), SystemPriorities.moveControl );
			this.scene.addSystem( new LifeSystem(), SystemPriorities.update );
			this.scene.addSystem( new DepthScaleSystem(), SystemPriorities.preRender );
			this.scene.addSystem( new Track3DSystem(), SystemPriorities.update );
			this.scene.addSystem( new ColorBlinkSystem(), SystemPriorities.update );

		} //

		private function createRobot():void {

			var e:Entity = this.robotEntity = new Entity( "robot" );

			var robot:RobotBoss = new RobotBoss();
			// this is the animation to run while fetching the boulder.
			robot.fetchAnimation = this.scene.getEntityById( "fetch_animation" );

			this.configStates( robot );

			var display:Display = new Display( robot.getStateDisplay( RobotBoss.IDLE ), this.view3D );

			var sp:Spatial = new Spatial( this.shellApi.camera.areaWidth/2, 0.3*this.shellApi.camera.areaHeight );

			var life:Life = new Life( 60 );
			life.hitResetTime = 0.5;

			var motion:Motion3D = new Motion3D();
			motion.friction = 0.15;

			e.add( sp, Spatial )
			.add( display, Display )
			.add( life, Life )
			// not sure on the sizes here, especially because the stupid robot isnt fricking centered.
			.add( new HitBox3D( display.displayObject.width, display.displayObject.height, 40 ) )
			.add( new ZDepthNumber( RobotBoss.Z_MAX/2 ), ZDepthNumber )
			.add( new Enemy(), Enemy )				// mark as enemy node.
			.add( new Motion3D(), Motion3D )
			.add( new MoveTarget3D(), MoveTarget3D )
			.add( new ColorBlink( 0x660000, 0.43, 0.5 ), ColorBlink )
			.add( new Sleep( false, true ) )

			.add( ( this.scene as RobotBossBattle ).getScaleComponent(), ZDepthScale )

			.add( new VariableTimeline(), VariableTimeline )

			this.scene.addEntity( e );

			this.setupTracking( e );

		} //

		private function configStates( robot:RobotBoss ):void {

			var prefix:String = this.shellApi.assetPrefix + this.scene.groupPrefix + this.boss_prefix;

			robot.addStateDisplay( RobotBoss.IDLE, this.shellApi.getFile( prefix + RobotBoss.IDLE + ".swf", true ) );
			robot.addStateDisplay( RobotBoss.BOULDER_IDLE, this.shellApi.getFile( prefix + RobotBoss.BOULDER_IDLE + ".swf", true ) );
			//robot.addStateDisplay( RobotBoss.FETCH_RETURN, robot.getStateDisplay( RobotBoss.BOULDER_IDLE ) );
			
			robot.addStateDisplay( RobotBoss.THROW, this.shellApi.getFile( prefix + RobotBoss.THROW + ".swf", true ) );
			robot.addStateDisplay( RobotBoss.FIRE_MISSILE, this.shellApi.getFile( prefix + RobotBoss.FIRE_MISSILE + ".swf", true ) );
			robot.addStateDisplay( RobotBoss.DODGE, this.shellApi.getFile( prefix + RobotBoss.DODGE + ".swf", true ) );
			robot.addStateDisplay( RobotBoss.KILLED, this.shellApi.getFile( prefix + RobotBoss.KILLED + ".swf", true ) );

			var machine:StateMachine = new StateMachine( this.robotEntity );

			machine.addState( new State( RobotBoss.IDLE ) );
			machine.addState( new State( RobotBoss.BOULDER_IDLE ) );
			machine.addState( new State( RobotBoss.FETCH_BOULDER ) );
			machine.addState( new State( RobotBoss.THROW ) );
			machine.addState( new State( RobotBoss.FIRE_MISSILE ) );
			machine.addState( new State( RobotBoss.DODGE ) );
			machine.addState( new State( RobotBoss.KILLED ) );

			this.robotEntity.add( machine, StateMachine );
			this.robotEntity.add( robot, RobotBoss );

		} //

		private function setupTracking( e:Entity ):void {

			var track:Track3D = new Track3D( ( this.scene as RobotBossBattle ).getPlayer() );

			// need to use our own zdepth so the robot doesn't fly at the player.
			track._trackZ = this.robotEntity.get( ZDepthNumber ) as ZDepthNumber;

			e.add( track, Track3D );

		} //

		/**
		 * Technically the left hand is really the right, but he's facing the viewer and it's on the left side of the screen.
		 */
		private function initMissiles():void {

			var robot:RobotBoss = this.robotEntity.get( RobotBoss );

			var clip:MovieClip = this.scene.getAsset( "missile.swf", true );
			this.view3D.addChild( clip );
			var display:Display = new Display( clip );
			display.visible = false;

			var e:Entity = new Entity( "leftHand" )
				.add( new Spatial( 0, 0 ), Spatial )
				.add( new Sleep( true, true ), Sleep )
				.add( display, Display )
				.add( ( this.scene as RobotBossBattle ).getScaleComponent(), ZDepthScale )
				.add( new RobotMissile( true ) )
				.add( new Motion3D(), Motion3D )
				.add( new ZDepthNumber(0) );

			this.scene.addEntity( e );
			robot.leftHand = e;

			clip = this.scene.getAsset( "missile2.swf", true );
			this.view3D.addChild( clip );
			display = new Display( clip );
			display.visible = false;

			e = new Entity( "rightHand" )
				.add( new Spatial( 0, 0 ), Spatial )
				.add( display, Display )
				.add( ( this.scene as RobotBossBattle ).getScaleComponent(), ZDepthScale )
				.add( new Sleep( true, true ), Sleep )
				.add( new RobotMissile( true ) )
				.add( new Motion3D(), Motion3D )
				.add( new ZDepthNumber(0) );

			this.scene.addEntity( e );
			robot.rightHand = e;


			// BOULDER:
			clip = this.scene.getAsset( "boulder.swf", true );
			this.view3D.addChild( clip );

			display = new Display( clip );
			display.visible = false;
			
			e = new Entity( "boulder" )
				.add( new Spatial( 0, 0 ), Spatial )
				.add( new Sleep( true, true ), Sleep )
				.add( display, Display )
				.add( ( this.scene as RobotBossBattle ).getScaleComponent(), ZDepthScale )
				.add( new Motion3D(), Motion3D )
				.add( new RobotMissile( false ) )
				.add( new ZDepthNumber(0) );
			
			this.scene.addEntity( e );
			robot.boulder = e;

		} //

		/*private function createDisplaySet( id:String, clip:MovieClip, componentSwap:ComponentSwap ):void {

			var tl:Timeline = new Timeline();
			TimelineUtils.parseMovieClip( tl, clip );

			var s:ComponentSet = new ComponentSet();
			s.add( tl );
			s.add( new Display( clip ) );

			componentSwap.addComponentSet( id, s );

		} //*/

	} // End RobotBossManager

} // End package
package game.scenes.mocktropica.mainStreet.bossIntro {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.media.Sound;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.VariableTimeline;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.mocktropica.mainStreet.MainStreet;
	import game.scenes.mocktropica.robotBossBattle.RobotBossBattle;
	import game.scenes.virusHunter.joesCondo.classes.CutScenePopup;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.SetVisibleAction;
	import game.systems.actionChain.actions.VariableTimelineAction;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;

	public class BossIntroGroup extends DisplayGroup {

		private const robot_urls:Array = [ "ft_robot.swf", "as_robot.swf", "cc_robot.swf", "si_robot.swf" ];

		/**
		 * Bad guy entitites.
		 */
		private var focusTester:Entity;
		private var salesManager:Entity;
		private var costCutter:Entity;
		private var safetyInspector:Entity;

		// player and programmer.
		private var player:Entity;
		//private var programmer:Entity;

		private var scene:MainStreet;
		private var popup:CutScenePopup;

		private var robots:Vector.<Entity>;

		// robots will idle until the hatches are actually opening. The timelines have to check this
		// in order to smooth the idle animation into the hatch open animation - you might be at
		// any point in the idle animation and can't instantly switch into hatch open - you need
		// to slide into it. :\
		//public var hatchesOpening:Boolean = false;

		private var openCount:int = 0;

		public function BossIntroGroup( scene:Scene, container:DisplayObjectContainer=null ) {

			super( container );

			this.groupPrefix = scene.groupPrefix;
			this.id = "bossIntro";

			scene.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );

			this.scene = scene as MainStreet;

			this.focusTester = this.scene.getEntityById( "focusTester" );			// robot 0
			this.salesManager = this.scene.getEntityById( "salesManager" );			// robot 1
			this.costCutter = this.scene.getEntityById( "costCutter" );				// robot 2
			this.safetyInspector = this.scene.getEntityById( "safetyInspector" );	// robot 3

			// stop the project manager from walking around.
			var pm:Entity = this.scene.getEntityById( "projectManager" );
			pm.remove( CharacterWander );
			//pm.remove( CharacterWander );
			//var t:MotionTarget = pm.get( MotionTarget );
			//var sp:Spatial = pm.get( Spatial );
			//t._targetX = sp.x;

			this.player = this.scene.getEntityById( "player" );
			//this.programmer = this.scene.getEntityById( "leadDeveloper" );

			// need to manually create the group container to set the correct depth.
			var s:Sprite = new Sprite();
			s.name = 'groupContainer';
			// no good way to get a depth to put these stupid robots at. lame.
			container.addChildAt( s, container.getChildIndex( ( this.player.get(Display) as Display ).displayObject )-6 );
			super.groupContainer = s;

			scene.addChildGroup( this );

		} //

		override public function init( container:DisplayObjectContainer=null ):void {	

			super.init( container );

			this.robots = new Vector.<Entity>();

			this.loadFiles( this.robot_urls, false, true, this.robotsLoaded );

		} //

		private function robotsLoaded():void {

			// need to get the top, left edge of the view to position incoming bots.
			var camera:CameraSystem = this.shellApi.camera;

			var x:Number = -camera.x - camera.viewportWidth/2 - 250;
			var y:Number = ( this.focusTester.get( Spatial ) as Spatial ).y + 10;

			var spacing:Number = camera.viewportWidth*0.18;

			for( var i:int = 0; i <= 3; i++ ) {

				this.createRobot( i, x + (i)*spacing, y );

			} // end for-loop.

			//( this.robots[3].get( VariableTimeline ) as VariableTimeline ).onLabelReached.add( this.testLabels );

			SceneUtil.setCameraTarget( this.scene, this.robots[2] );

			this.enterRobots();

		} //

		private function createRobot( id:int, x:Number, y:Number ):void {

			var clip:MovieClip = this.getAsset( this.robot_urls[id], true, false, true );
			clip.gotoAndStop( 1 );

			this.groupContainer.addChild( clip );

			var display:Display = new Display( clip );
			//display.visible = false;

			var spatial:Spatial = new Spatial( x, y );

			var vt:VariableTimeline = new VariableTimeline( false );

			// messy fix to make sure ships loop from hatchopen to idle.
			vt.handleLabel( "hatchopen", this.idleLoop, false );

			// counts whenever a robot is fully open. when all robots are open,
			// the popup will play.
			vt.onTimelineEnd.addOnce( this.robotOpen );	

			var e:Entity = new Entity( "robot"+id )
				.add( new Sleep( false, true ) )
				.add( new Display( clip ) )
				.add( spatial, Spatial )
				.add( vt, VariableTimeline );

			this.addEntity( e );

			this.robots.push( e );

		} //

		private function enterRobots():void {

			var chain:ActionChain = new ActionChain( this.parent as Scene );

			//chain.addAction( new SetVisibleAction( this.robots[0].get( Display ), true ) );
			// First have the stupid ships come in one at a time.
			var tlAction:VariableTimelineAction = new VariableTimelineAction( this.robots[0], "falling", "landing" );
			tlAction.stopAtLabel = false;
			chain.addAction( tlAction );

			//chain.addAction( new SetVisibleAction( this.robots[1].get( Display ), true ) );
			tlAction = new VariableTimelineAction( this.robots[1], "falling", "landing" );
			tlAction.stopAtLabel = false;
			chain.addAction( tlAction );

			//chain.addAction( new SetVisibleAction( this.robots[2].get( Display ), true ) );
			tlAction = new VariableTimelineAction( this.robots[2], "falling", "landing" );
			tlAction.stopAtLabel = false;
			chain.addAction( tlAction );

			//chain.addAction( new SetVisibleAction( this.robots[3].get( Display ), true ) );
			tlAction = new VariableTimelineAction( this.robots[3], "falling", "landing" );
			tlAction.stopAtLabel = false;
			chain.addAction( tlAction );

			var dirX:Number = ( this.player.get( Spatial ) as Spatial ).x;

			// now move the players to their respective robots.
			chain.addAction( new MoveAction( this.focusTester, this.robots[0].get(Spatial), null, dirX ) );
			chain.addAction( new MoveAction( this.salesManager, this.robots[1].get(Spatial), null, dirX ) );
			chain.addAction( new MoveAction( this.costCutter, this.robots[2].get(Spatial), null, dirX ) );
			chain.addAction( new MoveAction( this.safetyInspector, this.robots[3].get(Spatial), null, dirX ) );

			// now open all the hatches.
			//chain.addAction( new SetVisibleAction( this, "hatchesOpening", true ) );

			chain.execute( this.openHatches );

		} //

		private function openHatches( ac:ActionChain ):void {

			for( var i:int = robots.length-1; i >= 0; i-- ) {

				( this.robots[i].get( VariableTimeline ) as VariableTimeline ).removeLabelHandler( this.idleLoop );

			} //

		} //

		private function idleLoop( e:Entity, tl:VariableTimeline ):void {

			tl.gotoAndPlay( "idle" );

		} //

		public function showCutScene():void {

			this.popup = new CutScenePopup( "boss_cutscene.swf", this.scene.groupPrefix, this.scene.overlayContainer, this.cutSceneDone );

			popup.ready.addOnce( this.hideNpcs );

			this.scene.addChildGroup( this.popup );
			// sounds
			this.shellApi.triggerEvent( "show_cutscene" );

			//AudioUtils.stop( this.scene, null, "music" );
			//AudioUtils.getAudio(parent,"sceneSound").stop(SoundManager.MUSIC_PATH+"MocktropicaMainTheme.mp3","music");
			//AudioUtils.getAudio(parent,"sceneSound").stop(SoundManager.MUSIC_PATH+"MocktropicaMainThemeGlitched.mp3","music");
			//AudioUtils.getAudio(parent,"sceneSound").stop(SoundManager.MUSIC_PATH+"night_theme.mp3","music");
			//AudioUtils.getAudio(parent,"sceneSound").stop(SoundManager.MUSIC_PATH+"cricket_chirp_loop_01.mp3","ambient");
			//AudioUtils.play(this,SoundManager.MUSIC_PATH+"mfb_battle_intro_filtered.mp3",1,false);

		} //

		// hide the npcs and all the robots.
		private function hideNpcs( group:DisplayGroup ):void {

//			( this.focusTester.get( Display ) as Display ).visible = false;
//			( this.safetyInspector.get( Display ) as Display ).visible = false;
//			( this.salesManager.get( Display ) as Display ).visible = false;
//			( this.costCutter.get( Display ) as Display ).visible = false;

			for( var i:int = this.robots.length-1; i >= 0; i-- ) {
				this.removeEntity( this.robots[i], false );
			} //

		} //

		private function cutSceneDone():void {

			SceneUtil.setCameraTarget( this.scene, this.player );
			CharUtils.setDirection( this.player, true );
			this.shellApi.triggerEvent( "boss_transformed" );
		} //


		private function robotOpen( e:Entity, tl:VariableTimeline ):void {

			if ( ++this.openCount >= 4 ) {
				this.showCutScene();
				removeEntity(focusTester);
				removeEntity(safetyInspector);
				removeEntity(salesManager);
				removeEntity(costCutter);
			} //

		} //

		override public function destroy():void {

			/*if ( this.landingTween != null ) {
				this.landingTween.kill();
				this.landingTween = null;
			}*/

			//this.player = null;
			this.safetyInspector = this.salesManager = this.costCutter = this.focusTester = null;

			this.robots.length = 0;
			this.robots = null;

			super.groupContainer = null;
			super.destroy();

		} //

		// Apparently this dialog has already been done on main street.
		/*private function startIntroDialog():void {
		
		var chain:ActionChain = new ActionChain( this.parent as Scene );
		
		chain.onComplete = this.introDialogDone;
		
		} //
		
		private function introDialogDone( chain:ActionChain ):void {
		} //*/

	} // End BossIntroGroup

} // End package
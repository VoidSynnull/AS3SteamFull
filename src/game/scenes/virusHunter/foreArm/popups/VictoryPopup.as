package game.scenes.virusHunter.foreArm.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Tween;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Dialog;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Proud;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.DisplayPositionUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class VictoryPopup extends Popup
	{
		public function VictoryPopup(container:DisplayObjectContainer=null )
		{
			closeSignal = new Signal( );
			super(container);
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .1;
			super.transitionIn.startPos = new Point( 0, 0 );
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.addSystem( new TweenSystem() );
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/foreArm/popups/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( "gym.swf", "npcsVictory.xml", GameScene.DIALOG_FILE_NAME ));
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			super.screen = super.getAsset( "gym.swf", true ) as MovieClip;
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 1013, 654);
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup( this, super.screen, super.getData( "npcsVictory.xml" ), allCharactersLoaded );
			
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME, true ), super.screen );
			
			super.loaded();
		}
		
		private function allCharactersLoaded():void
		{
			_joe = super.getEntityById( "joe" );
			Dialog(_joe.get(Dialog)).container = this.screen.content;
			var barbell:Entity = EntityUtils.createSpatialEntity( this, super.screen.content.barbell );
			EntityUtils.position( barbell, 583, 494 );
			
			super.open();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, easePain ));
		}
		
		private function easePain():void
		{
			CharUtils.setAnim( _joe, Proud, true );
			
			Dialog( _joe.get( Dialog )).sayById( "victory" );
			Dialog( _joe.get( Dialog )).complete.addOnce( closePopup );
		}
		
		private function closePopup( ...args ):void
		{
			closeSignal.dispatch();
		}
		
		public var closeSignal:Signal;
		
		private var _tween:Tween;
		private var _joe:Entity;
	}
}
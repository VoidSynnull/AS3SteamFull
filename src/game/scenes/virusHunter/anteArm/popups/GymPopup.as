package game.scenes.virusHunter.anteArm.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.systems.TweenSystem;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.WeightLifting;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.systems.motion.EdgeSystem;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.DisplayPositionUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class GymPopup extends Popup
	{
		public function GymPopup(container:DisplayObjectContainer = null)
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
			super.groupPrefix = "scenes/virusHunter/anteArm/popups/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( "gym.swf", GameScene.NPCS_FILE_NAME, GameScene.DIALOG_FILE_NAME ));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset( "gym.swf", true ) as MovieClip;
			
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 1013, 654);
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen.content, super.getData(GameScene.NPCS_FILE_NAME), allCharactersLoaded );
			
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME, true ), super.screen.content );
			addSystem(new EdgeSystem());
			
			super.loaded();
		}
		
		private function allCharactersLoaded():void
		{
			_joe = super.getEntityById( "joe" );
			
			/**
			 * Drew
			 * 
			 * Changed Joe's weight lifting to have a handleLabel() on "drop" that always
			 * listens for when it's reached.
			 */
			var timeline:Timeline = _joe.get(Timeline);
			timeline.handleLabel("drop", this.countReps, false);
			CharUtils.setAnim( _joe, WeightLifting );
			
			var dialog:Dialog = _joe.get( Dialog );
			dialog.container = this.screen.content;
			super.open();
		}
		
		private function countReps():void
		{
			if( _rep < 4 )
			{
				Dialog( _joe.get( Dialog )).sayById( "rep" + _rep );
				Dialog( _joe.get( Dialog )).complete.addOnce( this.play );
				if( _rep == 3 )
				{
					SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, closePopup ));
				}
				_rep++;
			}
		}
		
		private function play(data:DialogData):void
		{
			CharUtils.setAnim( _joe, WeightLifting );
		}
		
		private function closePopup():void
		{
			closeSignal.dispatch();
		}
		
		public var closeSignal:Signal;
		
		private var _joe:Entity;
		private var _rep:int = 1;
	}
}
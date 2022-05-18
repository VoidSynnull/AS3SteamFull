package game.scenes.virusHunter.foreArm.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.WeightLifting;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.DisplayPositionUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;

	public class GymPopup extends Popup
	{
		public function GymPopup(container:DisplayObjectContainer = null )
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
			super.loadFiles( new Array( "gym.swf", GameScene.NPCS_FILE_NAME, GameScene.DIALOG_FILE_NAME ));
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			super.screen = super.getAsset( "gym.swf", true ) as MovieClip;
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 1013, 654);
			
			_barbell = EntityUtils.createMovingEntity( this, super.screen.content.barbell );
			_spatial = _barbell.get( Spatial );
			
			Display( _barbell.get( Display )).visible = false;

			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen.content, super.getData(GameScene.NPCS_FILE_NAME), allCharactersLoaded );
			
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME, true ), super.screen.content );
			
			super.loaded();
		}
		
		private function allCharactersLoaded():void
		{
			_joe = super.getEntityById( "joe" );
			Dialog(_joe.get(Dialog)).container = this.screen.content;
			super.open();
			joeLifting();
		}
		
		private function joeLifting( ...args ):void
		{
			CharUtils.setAnim( _joe, WeightLifting );
			var timeline:Timeline = CharUtils.getTimeline( _joe );
			timeline.labelReached.add( joeHandler );
		}
		
		private function joeHandler( label:String ):void
		{		
		 	switch( label )
			{
				case "drop":
					triggerCramp();
					SkinUtils.setSkinPart( _joe, SkinUtils.MOUTH, 14 );
					CharUtils.setAnim( _joe, Hurt, true );
					break;
				case "ending":
					CharUtils.setAnim( _joe, Grief, true );
					CharUtils.setAnim( _joe, Cry, true );
					break;
			}
		}
		
		private function triggerCramp():void
		{
			var item:Entity = CharUtils.getPart( _joe, CharUtils.ITEM );
			super.removeEntity( item );

			Display( _barbell.get( Display )).visible = true;
			
			_tween = new Tween();
			_tween.to( _spatial, .5, { x : 584, y : 484, rotation : 14, onComplete : barbellBounce });
			_barbell.add( _tween );
			
			Dialog( _joe.get( Dialog )).sayById( "cramp" );
			Dialog( _joe.get( Dialog )).complete.addOnce( closePopup );
		}
		
		private function barbellBounce():void
		{
			_tween.to( _spatial, .25, { x : 581, y : 489, rotation : -5.7, onComplete : barbellSettle });
		}
		
		private function barbellSettle():void
		{
			_tween.to( _spatial, .15, { x : 583, y : 494, rotation : 0 });
		}
		
		
		private function closePopup( ...args ):void
		{
			closeSignal.dispatch();
		}
		
		public var closeSignal:Signal;
		
		private var _barbell:Entity;
		private var _spatial:Spatial;
		private var _tween:Tween;
		private var _joe:Entity;
		private var _rep:int = 1;
	}
}
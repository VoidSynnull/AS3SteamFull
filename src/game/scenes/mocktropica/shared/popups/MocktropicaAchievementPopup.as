package game.scenes.mocktropica.shared.popups {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ui.TransitionData;
	import game.scenes.mocktropica.shared.Achievement;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;

	public class MocktropicaAchievementPopup extends Popup {

		private var curAchievement:Achievement;
		private var isLoaded:Boolean = false;
		private static const POP:String =		"fish_hit_01.mp3";

		private var autoHide:Boolean;

		public function MocktropicaAchievementPopup( achievement:Achievement, container:DisplayObjectContainer=null, autoHide:Boolean=false ) {

			super( container );

			this.autoHide = autoHide;
			this.curAchievement = achievement;

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			this.groupPrefix = "";
			this.screenAsset = "scenes/mocktropica/shared/achievementPopup.swf";

			// setup the transitions

			super.darkenBackground = false;
			super.init( container );

			this.load();

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {

			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			var base:MovieClip = ( super.getAsset( this.screenAsset, false ) ) as MovieClip;

			super.transitionIn = new TransitionData();

			super.transitionIn.init( (super.shellApi.viewportWidth - base.width)/2, -super.shellApi.viewportHeight,
				(super.shellApi.viewportWidth - base.width)/2,  (super.shellApi.viewportHeight - base.height )/2 );

			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();


			// The popup consists of three clips. a background which can be optionally bitmapped,
			// btnClose, and textClip - a clip with all the achievement texts.
			
			this.initCloseButton( base["btnClose"] );

			base["textClip"].gotoAndStop( curAchievement.frame );

			if ( this.autoHide == true ) {

				this.autoOpen = false;		// need to open the thing myself to get the callback on transition complete.
				super.loaded();
				this.open( this.openComplete );

			} else {
				super.loaded();
			}

			this.isLoaded = true;

		}

		private function openComplete():void 
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, onCloseClick ));
		}

		private function initCloseButton( closeClip:MovieClip ):void 
		{
			var closeBtn:Entity = ButtonCreator.createButtonEntity(closeClip, this, onCloseClick);
		}

		private function onCloseClick( e:Entity = null ):void {
			var audio:Audio = new Audio();
			var entity:Entity = new Entity();
			super.addEntity( entity );
			entity.add( audio );
			
			audio.play( SoundManager.EFFECTS_PATH + POP );
			this.close( true );
		}
	} // End MocktropicaAchievementPopup
} // End package
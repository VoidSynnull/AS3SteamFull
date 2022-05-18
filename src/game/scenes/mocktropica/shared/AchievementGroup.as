package game.scenes.mocktropica.shared {

	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.shared.popups.MocktropicaAchievementPopup;
	
	import org.osflash.signals.Signal;

	public class AchievementGroup extends DisplayGroup {

		/**
		 * indexed by achievement name: i.e:
		 * achievements[ "BigWinner" ] = Achievement Object
		 */
		private var achievements:Dictionary;

		private var curScene:Scene;

		/**
		 * Signal with no arguments in the callback function: onAchievementComplete():void {}
		 */
		public var onAchievementComplete:Signal;

		public function AchievementGroup( scene:Scene ) {

			super();

			this.curScene = scene;
			this.shellApi = scene.shellApi;

			this.onAchievementComplete = new Signal();

			this.initAchievements();

		} //

		override public function init( container:DisplayObjectContainer=null ):void {

			super.init( container );

		} //

		/**
		 * Set an achievement without showing the achievement popup. Mainly used for the last boss.
		 * We don't really even need to set that achievement at all... but for consistency...
		 */
		public function setAchievement( id:String ):void {

			this.shellApi.completeEvent( id );

		} //

		/**
		 * Optional callback that gets called when the achievement popup closes.
		 * It takes no parameters.
		 * 
		 * If autoHide == true, the achievement popup will go away by itself as soon as it comes out.
		 */
		public function completeAchievement( id:String, callback:Function=null, autoHide:Boolean=false ):void {

			// Check if achievement has already been set.
			if ( this.shellApi.checkEvent( id ) ) {
				if ( callback != null ) {
					callback();
				}
				return;
			}
			this.shellApi.completeEvent( id );

			if ( callback != null ) {
				this.onAchievementComplete.addOnce( callback );
			}

			// Display achievement popup.
			var popup:MocktropicaAchievementPopup = new MocktropicaAchievementPopup( this.achievements[ id ],
				super.shellApi.sceneManager.currentScene.overlayContainer, autoHide );
			this.addChildGroup( popup );

			popup.popupRemoved.add( this.achievementPopupDone );

		} //

		private function achievementPopupDone():void {

			this.onAchievementComplete.dispatch();

		} //

		/**
		 * This is just a pass-through function to the shellApi() check event, but it exists
		 * in case we ever change how achievements are handled. Probably not, but whatever.
		 */
		public function checkAchievement( id:String ):Boolean {

			return this.shellApi.checkEvent( id );

		} //

		public function getAchievement( id:String ):Achievement {

			return this.achievements[ id ];

		} //

		private function initAchievements():void {

			this.achievements = new Dictionary();

			if ( this.curScene.events != null ) {
				var evts:MocktropicaEvents = this.curScene.events as MocktropicaEvents;
			} else {
				evts = new MocktropicaEvents();
			}

			this.achievements[ evts.ACHIEVEMENT_ACHIEVER ] = new Achievement( 1, evts.ACHIEVEMENT_ACHIEVER, "Achiever", "Learn about Achievements" );
			this.achievements[ evts.ACHIEVEMENT_DOORK ] = new Achievement( 2, evts.ACHIEVEMENT_DOORK, "Doork", "Walk Through a Door" );
			this.achievements[ evts.ACHIEVEMENT_CHEESE_BALL ] = new Achievement( 3, evts.ACHIEVEMENT_CHEESE_BALL, "Cheese Ball", "Enter the Factory" );
			this.achievements[ evts.ACHIEVEMENT_MIC_SQUEAK ] = new Achievement( 4, evts.ACHIEVEMENT_MIC_SQUEAK, "Squeak into the Mic", "get a bag of deliciously squeaky cheese curds" );
			this.achievements[ evts.ACHIEVEMENT_SCENE_STEALER ] = new Achievement( 5, evts.ACHIEVEMENT_SCENE_STEALER, "Scene Stealer", "Walk into a new scene" );
			this.achievements[ evts.ACHIEVEMENT_JUST_FOCUS ] = new Achievement( 6, evts.ACHIEVEMENT_JUST_FOCUS, "Just Focus", "learn about the Focus Tester’s terrible new idea" );
			this.achievements[ evts.ACHIEVEMENT_CURD_BURGLAR ] = new Achievement( 7, evts.ACHIEVEMENT_CURD_BURGLAR, "Curd Burglar", "break the Curd Machine and force the designer to return to his miserable old job" );
			this.achievements[ evts.ACHIEVEMENT_MANCALA_MASTER ] = new Achievement( 8, evts.ACHIEVEMENT_MANCALA_MASTER, "Mancala Master", "find a man in a perfect Zen setting, destroy that, throw him back into the rat race" );
			this.achievements[ evts.ACHIEVEMENT_COLLECTOR ] = new Achievement( 9, evts.ACHIEVEMENT_COLLECTOR, "Collector", "collect your first collectible" );
			this.achievements[ evts.ACHIEVEMENT_CLASSIC ] = new Achievement( 10, evts.ACHIEVEMENT_CLASSIC, "Classic", "break blocks with your fat head" );
			this.achievements[ evts.ACHIEVEMENT_POPTROPICA_MASTER ] = new Achievement( 11, evts.ACHIEVEMENT_POPTROPICA_MASTER, "Poptropica Master", "beat the final boss" );
			this.achievements[ evts.ACHIEVEMENT_ULTIMATE_ACHIEVER ] = new Achievement( 12, evts.ACHIEVEMENT_ULTIMATE_ACHIEVER, "Ultimate Achiever", "break the achievement system" );

		} //

	} // End MocktropicaScene

} // End package
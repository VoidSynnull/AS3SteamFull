package game.scenes.prison.tower.popups
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scenes.prison.PrisonEvents;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.TweenUtils;
	
	public class NewspaperPopup extends Popup
	{
		
		private var _events:PrisonEvents;
		public var events:PrisonEvents;
		private var news:Entity;
		
		public function NewspaperPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new PrisonEvents();
			
			this.id 				= "NewspaperPopup";
			this.groupPrefix 		= "scenes/prison/tower/popups/";
			this.screenAsset 		= "newspaperPopup.swf";
			this.pauseParent 		= true;
			this.darkenAlpha		= 1;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			//this.transitionIn 			= new TransitionData();
			//this.transitionIn.duration 	= 0.3;
			//this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			//this.transitionIn.endPos 		= new Point(0, 0);
			//this.transitionIn.ease 		= Bounce.easeIn;
			//this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			//this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{	
			super.loaded();
			
			this.events = this.shellApi.islandEvents as PrisonEvents;
			
			this.setupContent();
			super.loadCloseButton();
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;
			content.x *= this.shellApi.viewportWidth / content.width / 2;
			content.y *= this.shellApi.viewportHeight / content.height / 2;
			
			var clip:MovieClip;
			if(!this.shellApi.checkEvent(_events.PLAYER_ESCAPED)){
				this.screen.content.news2.visible = false;
				clip = this.screen.content.news1;
				convertContainer(clip, 1);
				news = EntityUtils.createSpatialEntity(this, clip, this.screen.content);
			} else {
				this.screen.content.news1.visible = false;
				clip = this.screen.content.news2;
				convertContainer(clip, 1);
				news = EntityUtils.createSpatialEntity(this, clip, this.screen.content);
				
				var currentDay:Number = 0;
				currentDay = DataUtils.getNumber(shellApi.getUserField(_events.DAYS_IN_PRISON_FIELD, shellApi.island));
				if(isNaN(currentDay)) currentDay = 0;
				
				if(currentDay < _events.DAYS_FOR_NOSTRAND) {
					shellApi.triggerEvent(_events.PAROLE_PASSED + "nostrand", true);
				}
				if(currentDay < _events.DAYS_FOR_PATCHES) {
					shellApi.triggerEvent(_events.PAROLE_PASSED + "patches", true);
				}
				if(currentDay < _events.DAYS_FOR_MARION) {
					shellApi.triggerEvent(_events.PAROLE_PASSED + "marion", true);
				}
			}
			
			news.get(Spatial).scale = .2;
			TweenUtils.globalTo(this, news.get(Spatial), 1, {scale: 1, rotation:"1080", ease:Linear.easeNone, onComplete:playHit}, "spin_in");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grab_rope_04.mp3", 1, false);
		}
		
		private function playHit():void {
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "whoosh_01.mp3", 1, false);
		}
	}
}



package game.scenes.hub.profile.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.proxy.Connection;
	import game.ui.popup.Popup;
	
	public class MoodPopup extends Popup
	{	
		//tracking constants
		private const TRACK_CHOOSE_MOOD:String = "ChooseMood";
		//tracking - is on player's profile or visiting another profile
		private var selfOrFriend:String;
		
		private var content:MovieClip;
		private var dailyMood:MovieClip;
		private var xpos:Number;
		
		public var reloadMood:Function;
		private var loginData:Object;
		
		public function MoodPopup(ld:Object, xp:Number, container:DisplayObjectContainer=null)
		{
			loginData = ld;
			xpos = xp;
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/profile/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["moodPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("moodPopup.swf", true) as MovieClip;
			content = screen.content;
			content.mouseChildren = true;
			content.mouseEnabled = false;
			dailyMood = content["dailyMood"];
			
			// for tracking
			selfOrFriend = loginData.playerLogin == loginData.activeLogin ? "self" : "friend";
			
			setupButtons();
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
		}
		
		private function setupButtons():void 
		{
			dailyMood.mouseEnabled = false;
			dailyMood.mouseChildren = true;
			dailyMood.x = xpos;
			for (var i:uint = 1; i <= 21; i++){
				var btn:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(content.dailyMood)["emoji"+i]), this);
				btn.remove(Timeline);
				var int:Interaction = btn.get(Interaction);
				int.click.add(clickMoodBtn);
				btn.get(Id).id = "moodBtn"+i;
			}
		}
		
		private function clickMoodBtn(entity:Entity):void 
		{
			var frame:String = entity.get(Id).id.substring(7,10);
			
			// tracking
			shellApi.track(TRACK_CHOOSE_MOOD, frame, selfOrFriend, "Mood");
			
			var vars:URLVariables = new URLVariables();
			vars.login = loginData.playerLogin;
			vars.pass_hash = loginData.playerHash;
			vars.dbid = loginData.playerDBID;
			vars.lookup_user = loginData.activeLogin;
			vars.mood_id = frame;
			
			var connection:Connection = new Connection();
			connection.connect(shellApi.siteProxy.secureHost + "/quidgets/set_user_mood.php", vars, URLRequestMethod.POST, moodSaved, myErrorFunction);
		}
		
		private function moodSaved(event:Event):void 
		{
			reloadMood();
			super.close();
		}
		
		private function myErrorFunction(event:Event):void
		{
			
		}
	};
};
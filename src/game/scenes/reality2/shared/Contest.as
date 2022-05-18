package game.scenes.reality2.shared
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.creators.entity.character.CharacterCreator;
	import game.data.character.LookData;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	public class Contest extends RealityScene
	{
		protected var practice:Boolean = false;
		protected var practiceEnding:String = "";
		protected var contestEnding:String 	= "";
		public var participants:Vector.<Contestant>;//list of contestants for current game (player is always first)
		protected var hud:MovieClip;
		
		public function Contest()
		{
			super();
		}
		
		override protected function loadContestants():void
		{
			//initialize music before it normally is so that the games don't start with out music
			shellApi.sceneManager.sceneSound.initScene(getData("sounds.xml", true), this);
			
			hud = _hitContainer["hud"];
			overlayContainer.addChild(hud);
			var group:DisplayGroup = getGroupById("loadingScreen") as DisplayGroup;
			var popup:ConfirmationDialogBox = group.addChildGroup(new ConfirmationDialogBox(2)) as ConfirmationDialogBox;
			popup.confirmClicked.addOnce(Command.create(practiceMode, false));
			popup.cancelClicked.addOnce(Command.create(practiceMode, true));
			popup.configData("start.swf", groupPrefix, "", "");
			popup.init(group.groupContainer);
		}
		
		private function practiceMode(bool:Boolean):void
		{
			practice = bool;
			participants = new Vector.<Contestant>();
			super.loadContestants();
		}
		
		protected function setUpUi(prefix:String, index:int, look:LookData, onComplete:Function = null):MovieClip
		{
			var clip:MovieClip = hud[prefix+"Ui"];
			if(clip == null)
				return null;
			if(prefix != "player" && practice)
			{
				hud.removeChild(clip);
				return null;
			}
			
			var participant:Contestant = contestants[index].duplicate();
			participant.score = 0;
			participants.push(participant);
			
			if(!practice && prefix == "player")
			{
				// make player first
				participant = participants[participants.length-1];
				participants.splice(participants.length-1,1);
				participants.insertAt(0,participant);
			}
			
			clip.mouseChildren = clip.mouseEnabled = false;
			clip.x = 30 -clip.parent.width/2 + index/contestants.length * clip.parent.width;
			
			TextUtils.refreshText(clip["score"],"CreativeBlock BB");
			
			TextUtils.refreshText(clip["place"],"CreativeBlock BB").text = "" + (index+1);
			
			var portrait:MovieClip = clip["portrait"];
			
			var entity:Entity = charGroup.createDummy(prefix+"Portrait",look,"right","head",portrait,this,Command.create(dummyLoaded, onComplete),false,.25,CharacterCreator.TYPE_PORTRAIT);
			
			if(prefix == "player")
			{
				if(!shellApi.player)
				{
					shellApi.player = entity;
				}
				shellApi.player.add(participant);
			}
			
			return clip;
		}
		
		private function dummyLoaded(entity:Entity, onComplete:Function = null):void
		{
			if(PlatformUtils.isMobileOS)
			{
				createBitmapSprite(EntityUtils.getDisplayObject(entity));
			}
			if(onComplete)
			{
				onComplete(entity);
			}
		}
		
		protected function gameOver(...args):void
		{
			var ending:String = practice?practiceEnding:contestEnding;
			var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(1, ending)) as ConfirmationDialogBox;
			popup.confirmClicked.addOnce(gameOverPopupClosed);
			popup.configData(null, "scenes/reality2/shared/","");
			popup.init(overlayContainer);
		}
		
		protected function gameOverPopupClosed(...args):void
		{
			if(practice)
			{
				//reload the scene
				var scene:Class = this["constructor"] as Class;
				shellApi.loadScene(scene);
			}
			else
			{
				ShowResults();
			}
		}
		
		protected function ShowResults():void
		{
			var popup:Group = addChildGroup(new RankingsPopup(overlayContainer, this));
			popup.removed.addOnce(chooseNextContest);
		}
		
		private function chooseNextContest(...args):void
		{
			//cheetah run not set up for this
			var contestant:Contestant = shellApi.player.get(Contestant);
			var suffix:String = getSuffixFromPlace(contestant.place);
			shellApi.track("PlayerPlaced",contestant.place+suffix, RealityScene.getDifficultyStringFromAI(contestants[0].difficulty));
			getNextContest(shellApi);
		}
	}
}
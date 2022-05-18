package game.scenes.hub.race
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.scenes.con1.roofRace.Timer.Timer;
	import game.scenes.hub.town.Town;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	public class RaceUI extends Popup
	{
		private var content:MovieClip;
		
		private var messagePopup:Entity;
		private var messageTf:TextField;
		private var timeTf:TextField;
		private var timeTitle:TextField;
		private var recordTf:TextField;
		private var recordTitle:TextField;
		public var countDown:Timeline;
		private var trophy:Entity;
		private var go:Function;
		private var again:Function;
		public var timer:Timer;
		public var timeToBeat:Timer;
		
		public function RaceUI(container:DisplayObjectContainer, go:Function, again:Function)
		{
			super(container);
			this.go = go;
			this.again = again;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			this.darkenBackground = false;
			this.pauseParent = false;
			this.screenAsset = "raceUI.swf";
			this.groupPrefix = "scenes/hub/race/";
			super.load();
		}
		
		override public function destroy():void
		{
			content = null;
			messagePopup = null;
			messageTf = null;
			timeTf = null;
			countDown = null;
			trophy = null;
			super.destroy();
			timer.timesUp.removeAll();
			timeToBeat = null;
			timer = null;
			go = null;
			again = null;
		}
		
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content;
			setUpMessage();
			setUpCountDown();
			setUpTimers();
			setUpRestartButton();
		}
		
		private function setUpMessage():void
		{
			var clip:MovieClip = content["message"];
			clip.x = shellApi.viewportWidth / 2;
			clip.y = shellApi.viewportHeight / 2;
			
			messagePopup = EntityUtils.createSpatialEntity(this, clip);
			
			var btn:MovieClip = clip["quit"];
			setUpMessageButton(btn, 0xDF5F15, clickQuit);
			
			btn = clip["again"];
			setUpMessageButton(btn, 0x34D924, clickAgain);
			
			messageTf = TextUtils.refreshText(clip["message"], "CreativeBlock BB");
			messageTf.mouseEnabled = false;
			messageTf.autoSize = TextFieldAutoSize.CENTER;
			
			timeTitle = TextUtils.refreshText(clip["timeTitle"], "CreativeBlock BB");
			timeTitle.mouseEnabled = false;
			timeTitle.autoSize = TextFieldAutoSize.CENTER;
			
			timeTf = TextUtils.refreshText(clip["time"], "LCDMono");
			timeTf.mouseEnabled = false;
			timeTf.autoSize = TextFieldAutoSize.CENTER;
			
			recordTitle = TextUtils.refreshText(clip["recordTitle"], "CreativeBlock BB");
			recordTitle.mouseEnabled = false;
			recordTitle.autoSize = TextFieldAutoSize.CENTER;
			
			recordTf = TextUtils.refreshText(clip["record"], "LCDMono");
			recordTf.mouseEnabled = false;
			recordTf.autoSize = TextFieldAutoSize.CENTER;
			
			EntityUtils.visible(messagePopup, false, true);
			
			trophy = EntityUtils.createSpatialEntity(this, clip["trophy"]);
		}
		
		public function displayMessage(message:String, time:String, title:String, targetTime:String, targetTitle:String, showTrophy:Boolean = false):void
		{
			EntityUtils.visible(messagePopup);
			messageTf.text = message;
			timeTf.text = time;
			timeTitle.text = title;
			recordTf.text = targetTime;
			recordTitle.text = targetTitle;
			EntityUtils.visible(trophy, showTrophy, true);
		}
		
		private function setUpMessageButton(btn:MovieClip, color:Number, method:Function):void
		{
			var tfName:String = btn.name +"Tf";
			TextUtils.refreshText(btn.parent[tfName], "CreativeBlock BB").mouseEnabled = false;
			ColorUtil.colorize(btn["base"]["color"], color);
			ButtonCreator.createButtonEntity(btn, this, method);
		}
		
		private function clickAgain(entity:Entity):void
		{
			EntityUtils.visible(messagePopup, false);
			again();
		}
		
		private function clickQuit(entity:Entity):void
		{
			SceneUtil.lockInput(parent);
			SceneUtil.delay(this, 1, Command.create(shellApi.loadScene, Town,1100,960,"left"));
		}
		
		private function setUpCountDown():void
		{
			var clip:MovieClip = content["countDown"];
			clip.mouseChildren = clip.mouseEnabled = false;
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			clip.x = shellApi.viewportWidth / 2;
			clip.y = shellApi.viewportHeight / 2;
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			countDown = TimelineUtils.convertClip(clip, this, entity, null, false).get(Timeline);
			countDown.handleLabel("ending",countDownComplete, false);
		}
		
		private function countDownComplete():void
		{
			countDown.gotoAndStop(0);
			go();
		}
		
		private function setUpTimers():void
		{
			timer = setUpTimer("time").get(Timer);
			timeToBeat = setUpTimer("timeToBeat").get(Timer);
		}
		
		private function setUpTimer(timerName:String):Entity
		{
			var clip:MovieClip = content[timerName];
			clip.mouseEnabled = clip.mouseChildren = false;
			var entity:Entity = EntityUtils.createSpatialEntity(parent, clip);
			var tf:TextField = TextUtils.refreshText(clip["time"],"LCDMono");
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.mouseEnabled = false;
			var timer:Timer = new Timer(tf,Timer.TIMER,1,false);
			timer.showMiliSeconds = true;
			entity.add(timer).add(new Id(timerName));
			return entity;
		}
		
		private function setUpRestartButton():void
		{
			var clip:MovieClip = content["restart"];
			clip.x = 50;
			clip.y = shellApi.viewportHeight - 50;
			ButtonCreator.createButtonEntity(clip, parent, restartClicked);
		}
		
		private function restartClicked(entity:Entity):void
		{
			var popup:ConfirmationDialogBox = parent.addChildGroup(new ConfirmationDialogBox(2, "restart the race?",again)) as ConfirmationDialogBox;
			popup.configData(null, null,"restart","continue");
			popup.init(screen);
		}
	}
}
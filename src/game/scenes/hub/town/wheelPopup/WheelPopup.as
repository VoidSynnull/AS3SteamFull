package game.scenes.hub.town.wheelPopup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.scene.template.GameScene;
	import game.scenes.hub.town.wheelPopup.arrowFlop.ArrowFlop;
	import game.scenes.hub.town.wheelPopup.arrowFlop.ArrowFlopSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class WheelPopup extends Popup
	{
		private var wheelGroup:WheelOfFortuneGroup;
		private var content:MovieClip;
		public var prize:PrizeData;
		private var testing:Boolean = false;
		public function WheelPopup(container:DisplayObjectContainer=null, testing:Boolean = false)
		{
			this.testing = testing;
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			groupPrefix = GameScene(parent).groupPrefix+"wheelPopup/";
			screenAsset = "shipWheelPopup.swf";
			super.load();
		}
		
		override public function loaded():void
		{
			screen = getAsset(screenAsset,true);
			content = screen.content;
			wheelGroup = addChildGroup(new WheelOfFortuneGroup(testing)) as WheelOfFortuneGroup;
			wheelGroup.createWheelOfFortune(shellApi.fileManager.dataPrefix+groupPrefix+"prizeWheel.xml",content, wheelComplete);
		}
		
		private function wheelComplete(entity:Entity):void
		{
			content.bg.height = shellApi.viewportHeight + 5;
			content.bg.width = shellApi.viewportWidth + 5;
			convertContainer(content,PerformanceUtils.defaultBitmapQuality);
			
			var clip:MovieClip = content.spinbtn;
			clip.x = shellApi.viewportWidth/2;
			var button:Entity = ButtonCreator.createButtonEntity(clip,this, spinWheel).add(new Id("spinbtn"));
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = shellApi.viewportWidth / 2;
			spatial.rotation = Math.random() * 360;
			
			
			addSystem(new ArrowFlopSystem(), SystemPriorities.moveComplete);
			clip = content.pointer;
			clip.x = shellApi.viewportWidth / 2;
			var pointer:Entity = EntityUtils.createSpatialEntity(this,clip);
			var flop:ArrowFlop = new ArrowFlop(spatial, 5, 12, 75);
			flop.flopped = new Signal();
			flop.flopped.add(tick);
			pointer.add(flop);
			
			var soundManager:SoundManager = shellApi.getManager(SoundManager) as SoundManager;
			soundManager.cache(SoundManager.EFFECTS_PATH+"arrow_01.mp3");
			soundManager.cache(SoundManager.EFFECTS_PATH+"pop_01.mp3");//again sound
			
			super.loaded();
		}
		
		private function tick():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"arrow_01.mp3");
		}
		
		private function spinWheel(entity:Entity):void
		{
			SceneUtil.lockInput(this);
			wheelGroup.spinWheel(wheelStopped);
			EntityUtils.visible(entity, false);
		}
		
		private function wheelStopped(prize:PrizeData):void
		{
			if(prize == null)
			{
				close();
				return;
			}
			this.prize = prize;
			if(prize.type == "again")
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"pop_01.mp3");
				SceneUtil.lockInput(this, false);
				EntityUtils.visible(getEntityById("spinbtn"));
			}
			else
				SceneUtil.delay(this, 2, close);
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			SceneUtil.lockInput(this, false);
			super.close();
		}
	}
}
package game.scenes.con2.intro
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Proud;
	import game.scene.template.CutScene;
	import game.scenes.con2.Con2Events;
	import game.scenes.con2.theater.Theater;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Intro extends CutScene
	{
		private var _npc:Entity;
		
		public function Intro()
		{
			super();
			configData("scenes/con2/intro/", Con2Events(events).PLAYED_INTRO);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			if(shellApi.checkEvent(completeEvent))
			{
				shellApi.loadScene(Theater);
				return
			}
			super.load();
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.fg);
			CharUtils.setScale(player, 1.1);
			
			_npc = getEntityById("npc");
			setEntityContainer(_npc, screen.fg);
			CharUtils.setScale(_npc, 1.5);
			
			ColorUtil.colorize(EntityUtils.getDisplayObject(player),0x283746);
			ColorUtil.colorize(EntityUtils.getDisplayObject(_npc),0x1A2237);
				
			start();
		}
		
		// all assets ready
		override public function loaded():void
		{
			SceneUtil.removeIslandParts(this);
			
			this.convertContainer(_screen["sky"]);
			this.convertContainer(_screen["bd"]);
			this.convertContainer(_screen["bg"]);
			super.loaded();
		}
		
		override public function onLabelReached(label:String):void
		{
			if(label == "startCharacterAnimations")
			{
				CharUtils.setAnim(player, Proud);
				CharUtils.setAnim(_npc, Celebrate);
			}
		}
		
		override public function end():void
		{
			super.end();
			super.shellApi.loadScene( Theater, 1500, 480, "right" );
		}
	}
}
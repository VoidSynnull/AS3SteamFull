package game.scenes.backlot.kirkTrailerInterior
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.render.Reflection;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.character.LookData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.shared.emitters.HairSpray;
	import game.ui.costumizer.CostumizerPop;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class KirkTrailerInterior extends PlatformerGameScene
	{
		public function KirkTrailerInterior()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/kirkTrailerInterior/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.player.add(new Reflection());
			this._hitContainer["mirror"].gotoAndStop(1);
			
			this.setupHairSpray();
			setUpManikins();
		}
		
		private function setUpManikins():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var dummy:Entity = getEntityById("char"+i);
				dummy.add(new SceneInteraction());
				InteractionCreator.addToEntity(dummy, [InteractionCreator.CLICK],Display(dummy.get(Display)).displayObject);
				var interaction:SceneInteraction = dummy.get(SceneInteraction);
				interaction.reached.add(openCostumizePopup);
			}
		}
		
		private function openCostumizePopup(player:Entity, dummy:Entity):void
		{
			var dummyLook:LookData = SkinUtils.getLook( dummy, true );
			var costumizer:CostumizerPop = new CostumizerPop(overlayContainer, dummyLook);
			
			this.addChildGroup(costumizer);
		}
		
		private function setupHairSpray():void
		{
			var bottle:Entity = this.getEntityById("sprayBottleInteraction");
			
			var spray:HairSpray = new HairSpray();
			spray.init();
			
			var emitter:Entity = EmitterCreator.create(this, this._hitContainer, spray, 0, 0, bottle, null, null, false);
			
			var spatial:Spatial = emitter.get(Spatial);
			spatial.x = 650;
			spatial.y = 375;
			
			var interaction:SceneInteraction = bottle.get(SceneInteraction);
			interaction.approach = false;
			interaction.triggered.add(Command.create(this.spray, emitter));
		}
		
		private function spray(player:Entity, bottle:Entity, spray:Entity):void
		{
			var emitter:Emitter = spray.get(Emitter);
			emitter.start = true;
			emitter.emitter.counter.resume();
			
			function stopSpray(emitter:Emitter):void { emitter.emitter.counter.stop(); };
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(stopSpray, emitter)));
		}
	}
}
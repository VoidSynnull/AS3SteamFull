package game.data.specialAbility.store
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.Snow;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	
	import org.flintparticles.common.counters.Steady;
	
	public class WhiteOut extends SpecialAbility
	{
		private var displayGroup:DisplayGroup;
		private var container:Sprite;
		private var screenEffect:ScreenEffects;
		private var emitterEntity:Entity;
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
			displayGroup = parent as DisplayGroup;
			
			container = new Sprite();
			container.x = -shellApi.viewportWidth/2;
			container.y = -shellApi.viewportHeight/2;
			container.mouseEnabled = container.mouseChildren = false;
			
			displayGroup.groupContainer.addChildAt(container,displayGroup.groupContainer.numChildren -1);
			
			var snow:Snow = new Snow();
			snow.init(new Steady(100),new Rectangle(0,0,shellApi.viewportWidth, shellApi.viewportHeight));
			emitterEntity = EmitterCreator.create(displayGroup, container, snow,0,0,null,"whiteOutParticles",null,false);
			
			screenEffect = new ScreenEffects(container, shellApi.viewportWidth, shellApi.viewportHeight,.95,0xffffff);
			screenEffect.hide();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			var emitter:Emitter = emitterEntity.get(Emitter);
			if(emitter.emitter.counter.running)
				return;
			trace("start the storm");
			emitter.resume = true;
			emitter.emitter.counter.resume();
			
			SceneUtil.delay(displayGroup, 3, Command.create(screenEffect.fadeToBlack, 5, fadeOut));
		}
		
		private function fadeOut():void
		{
			Emitter(emitterEntity.get(Emitter)).emitter.counter.stop();
			SceneUtil.delay(displayGroup, 2, Command.create(screenEffect.fadeFromBlack, 5));
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			displayGroup.removeEntity(emitterEntity);
			screenEffect.deleteBox(container);
			screenEffect = null;
			displayGroup = null;
		}
	}
}
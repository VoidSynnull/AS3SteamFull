// Used by:
// Card 3086 using ability snow

package game.data.specialAbility.store 
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.Snow;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/**
	 * Add snow to scene 
	 */
	public class AddSnow extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// Create the emitter and init
			if(emitter == null)
			{
				emitter = new Snow(super.shellApi.sceneManager.currentScene.sceneData.bounds.width, super.shellApi.sceneManager.currentScene.sceneData.bounds.height);
				emitter.init();
				emitter.rate = _rate;
				
				var container:DisplayObjectContainer = super.entity.get(Display).container;
				emitterEntity = EmitterCreator.create( super.group, container, emitter as Emitter2D, 0, 0);
			}
			else
			{
				emitter.rate = (emitter.rate == 0)?_rate:0;
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.group.removeEntity(emitterEntity);
		}
		
		override public function removeSpecial(node:SpecialAbilityNode):void
		{
			deactivate(node);
			super.removeSpecial(node);
		}
		
		public var _rate:int = 100;
		private var emitterEntity:Entity;
		private var emitter:Snow;
	}
}
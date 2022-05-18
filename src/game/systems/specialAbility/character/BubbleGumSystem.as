package game.systems.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import engine.components.Spatial;
	import game.components.Emitter;
	import game.components.specialAbility.character.BubbleGum;
	import game.creators.entity.EmitterCreator;
	import game.nodes.specialAbility.character.BubbleGumNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class BubbleGumSystem extends GameSystem
	{
		public function BubbleGumSystem():void
		{
			super(BubbleGumNode, updateNode);
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:BubbleGumNode, time:Number):void
		{
			var gum:BubbleGum = node.gum;
			var spatial:Spatial = node.spatial;
			
			if(!gum.popped)
			{
				// Increasing the size of the bubble
				// After max size, make the bubble float up
				if(spatial.scaleX < gum.maxScale)
				{
					spatial.scaleX += time;
					spatial.scaleY += time;
				}
				else
				{
					if(node.motion.velocity.y < gum.maxHeight)
					{
						var container:DisplayObjectContainer = node.display.displayObject.parent;
						
						if (node.gum.particleClass)
						{
							var particleClass:Class = node.gum.particleClass;
							var emitter:Object = new particleClass();
							emitter.init();
							EmitterCreator.create( group, container, emitter as Emitter2D, spatial.x, spatial.y );
						}
						if(gum.trailsEmitter)
							Emitter(gum.trailsEmitter.get(Emitter)).emitter.counter.stop();
						node.entity.group.removeEntity(node.entity);
					}
				}
			}	
		}
	}
}
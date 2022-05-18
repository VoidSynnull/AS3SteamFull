package game.systems.entity.character.part
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.creators.entity.EmitterCreator;
	import game.nodes.entity.character.part.DripPartNode;
	import game.particles.emitter.Drip;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	
	import org.flintparticles.common.counters.Blast;
	
	public class DripPartSystem extends GameSystem
	{
		public function DripPartSystem()
		{
			super(DripPartNode, updateNode);
			this._defaultPriority = SystemPriorities.render;
		}

		private function updateNode(node:DripPartNode, time:Number):void
		{
			counter += time;
			if(counter > randomInterval)
			{
				randomInterval = Math.random() * 2 + .5;
				counter = 0;
				
				var charMotion:Motion = node.parent.parent.get(Motion);
				if ( charMotion )
				{
					var xSpeed:Number = -charMotion.velocity.x * .5;
				}
				
				this.group.removeEntity(emitter);
				var drip:Drip = new Drip();
				var loc:Point = DisplayUtils.localToLocalPoint(new Point(node.dripPart.location.x, node.dripPart.location.y), node.display.displayObject, node.parent.parent.get(Display).container);
				drip.init(new Blast(2), 2.5, node.dripPart.dripColor, new Rectangle(loc.x, loc.y, 500, 130), xSpeed);
				emitter = EmitterCreator.create(this.group, node.parent.parent.get(Display).container, drip, 0, 0, node.parent.parent);
			}
		}
		
		private var emitter:Entity;
		private var randomInterval:Number = 1;
		private var counter:Number = 0;
	}
}
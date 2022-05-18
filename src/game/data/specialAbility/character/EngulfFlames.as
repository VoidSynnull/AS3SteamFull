package game.data.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.render.FollowDisplayIndex;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.render.FollowDisplayIndexSystem;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.actions.TargetColor;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.EllipseBottom;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class EngulfFlames extends SpecialAbility
	{
		private var torchParticles1:Entity;
		private var torchParticles2:Entity;
		
		public function EngulfFlames()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if (!super.data.isActive)
			{
				super.setActive(true);
				
				node.entity.group.addSystem(new FollowDisplayIndexSystem());
							
				var spatial:Spatial = node.entity.get(Spatial);				
				var display:DisplayObject = Display(node.entity.get(Display)).displayObject;
				
				// body
				var emitter2D:Emitter2D = createEmitter(0);
				torchParticles1 = EmitterCreator.create(this, display.parent, emitter2D, -2, 23, node.entity, null, node.entity.get(Spatial), true, true);				
				torchParticles1.add(new FollowDisplayIndex(display, 2));
				
				// head
				emitter2D = createEmitter(15);
				torchParticles2 = EmitterCreator.create(this, display.parent, emitter2D, 8, -20, node.entity, null, node.entity.get(Spatial), true, true);				
				torchParticles2.add(new FollowDisplayIndex(display, 1));
			}
			else
			{
				super.setActive(false);
				node.entity.group.removeEntity(torchParticles1);
				node.entity.group.removeEntity(torchParticles2);
			}
		}
		
		private function createEmitter(expand:Number = 0):Emitter2D
		{
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Steady(50);
			
			emitter2D.addInitializer(new ImageClass(EllipseBottom, [15, 30, 0.6, 0xffff77], true));
			emitter2D.addInitializer(new Position(new EllipseZone(new Point(-0, 0), 10 + expand, 0)));
			emitter2D.addInitializer(new Lifetime(1.5, 2.0));
			
			emitter2D.addAction(new Age());
			emitter2D.addAction(new Move());
			emitter2D.addAction(new TargetColor(0xff0000, 0.5));
			emitter2D.addAction(new ScaleImage(1, 0));
			emitter2D.addAction(new Accelerate(0, -150));
			emitter2D.addAction(new Fade(0.25, 0.2));
			
			return emitter2D;
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			node.entity.group.removeEntity(torchParticles1);
			node.entity.group.removeEntity(torchParticles2);
		}
	}
}
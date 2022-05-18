package game.data.specialAbility.store
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.render.DisplayFilter;
	import game.components.render.FollowDisplayIndex;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.render.DisplayFilterSystem;
	import game.systems.render.FollowDisplayIndexSystem;
	import game.util.BitmapUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ellipse;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Torch extends SpecialAbility
	{
		private var torchParticles:Entity;
		
		public function Torch()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			node.entity.group.addSystem(new FollowDisplayIndexSystem());
			node.entity.group.addSystem(new DisplayFilterSystem());
			
			var filter:DisplayFilter;
			
			filter = new DisplayFilter();
			filter.filters.push(new GlowFilter(0xFFDC51, 1, 100, 100, 1, 1, true));
			filter.filters.push(new GlowFilter(0xFF6600, 1, 10, 10, 1, 1, true));
			filter.filters.push(new GlowFilter(0xFFDC51, 1, 18, 18, 1, 1));
			filter.inflate.setTo(18, 18);
			node.entity.add(filter);
			
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Steady(32);
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Ellipse(16,24, 0xFFDC51)); 
			
			emitter2D.addInitializer(new BitmapImage(bitmapData, true));
			emitter2D.addInitializer(new Position(new LineZone(new Point(-10, 0), new Point(10, 0))));
			emitter2D.addInitializer(new Lifetime(0.75, 1));
			
			emitter2D.addAction(new Age());
			emitter2D.addAction(new Move());
			emitter2D.addAction(new ScaleImage(1, 0));
			emitter2D.addAction(new Accelerate(0, -250));
			
			var spatial:Spatial = node.entity.get(Spatial);
			
			var display:DisplayObject = Display(node.entity.get(Display)).displayObject;
			torchParticles = EmitterCreator.create(this, display.parent, emitter2D, 10, -50, node.entity, null, node.entity.get(Spatial), true, true);
			
			// make effect not clickable if on card
			if (entity.get(Id).id == "cardDummy")
			{
				display.parent.parent.parent.mouseEnabled = false;
				display.parent.parent.parent.mouseChildren = false;
			}
			
			filter = new DisplayFilter();
			filter.filters.push(new GlowFilter(0xFFDC51, 1, 100, 100, 1, 1, true));
			filter.filters.push(new GlowFilter(0xFF6600, 1, 10, 10, 1, 1, true));
			filter.filters.push(new GlowFilter(0xFFDC51, 1, 18, 18, 1, 1));
			filter.inflate.setTo(18, 18);
			torchParticles.add(filter);
			
			torchParticles.add(new FollowDisplayIndex(display, -1));
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			node.entity.remove(DisplayFilter);	
			node.entity.group.removeEntity(torchParticles);
		}
	}
}
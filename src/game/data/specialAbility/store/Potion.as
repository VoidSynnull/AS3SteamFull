package game.data.specialAbility.store
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.render.FollowDisplayIndex;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.character.MessWithNpcPower;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorMultiChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.data.ColorStep;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Potion extends MessWithNpcPower
	{
		public var _potionName:String = "";
		public var _potionParticle:String = "";
		public var _potionClip:MovieClip;
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			this.shellApi.loadFile(this.shellApi.assetPrefix + _potionParticle, potionParticleLoaded);
		}
		
		private function potionParticleLoaded(clip:MovieClip):void
		{
			_potionClip = clip;
		}
		
		override protected function messWithNpc(npc:Entity):void
		{
			if(!_potionClip)
			{
				return;
			}
			
			var potion:Entity = EntityUtils.getChildById(npc, _potionName);
			
			if(potion)
			{
				potion.group.removeEntity(potion);
			}
			else
			{
				var emitter2D:Emitter2D = new Emitter2D();
				
				emitter2D.counter = new Random(1, 3);
				
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(_potionClip); 
				
				emitter2D.addInitializer(new BitmapImage(bitmapData, true));
				emitter2D.addInitializer(new Position(new LineZone(new Point(-15, 0), new Point(15, 0))));
				emitter2D.addInitializer(new Velocity(new LineZone(new Point(0, -350), new Point(0, -200))));
				emitter2D.addInitializer(new Lifetime(1.2));
				
				emitter2D.addAction(new ColorMultiChange(new ColorStep(0xFFFFFFFF, 1), new ColorStep(0xFFFFFFFF, 0.2), new ColorStep(0x00FFFFFF, 0)));
				emitter2D.addAction(new Age());
				emitter2D.addAction(new Move());
				emitter2D.addAction(new LinearDrag(2.3));
				emitter2D.addAction(new ScaleImage(0.1, 1));
				
				var display:DisplayObject = Display(npc.get(Display)).displayObject;
				potion = EmitterCreator.create(this, display.parent, emitter2D, 10, -40, npc, null, npc.get(Spatial), true, true);
				potion.add(new Id(_potionName));
				potion.add(new FollowDisplayIndex(display, 1));
			}
			
			super.messWithNpc(npc);
		}
	}
}
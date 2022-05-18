// Status: retired
// Usage (0) none

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Volcano extends SpecialAbility
	{
		private var smoke:Entity;
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			var fireSmoke:FireSmoke = new FireSmoke();
			var display:MovieClip;
			
			fireSmoke.init(_size, new PointZone(new Point(0, -100)),new LineZone(new Point(-_size,0),new Point(_size,0)));
			
			var container:DisplayObjectContainer = EntityUtils.getDisplayObject(node.entity).parent;
			
			var offset:Point;
			
			if(_partType)
			{
				var part:Entity = SkinUtils.getSkinPartEntity(node.entity, _partType);
				display = EntityUtils.getDisplayObject(part) as MovieClip;
				
				offset = DisplayUtils.localToLocal(display, display.parent);
			}
			else
			{
				display = EntityUtils.getDisplayObject(node.entity) as MovieClip;
				offset = new Point(0, -display.height);
			}
			
			smoke = EmitterCreator.create(super.group, container,fireSmoke,offset.x,offset.y,null,null,node.entity.get(Spatial));
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			super.group.removeEntity(smoke);
		}
		
		public var _size:Number = 15;
		public var _partType:String;
	}
}
// Status: retired
// Usage ????

package game.data.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	public class Glow extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			if(_partType)
			{
				var part:Entity = SkinUtils.getSkinPartEntity(node.entity, _partType);
				display = EntityUtils.getDisplayObject(part) as MovieClip;
			}
			else
			{
				display = EntityUtils.getDisplayObject(node.entity) as MovieClip;
			}
			
			display.filters = [new GlowFilter(_color,1,4,4)];
			
			data.isActive = _type != "default";
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			wave += time * _speed;
			
			var alpha:Number = 1;
			
			var radiance:Number = _radius;
			
			var value:Number = Math.abs( Math.cos(wave));
			
			if(_type.indexOf("radiate") >= 0)
				radiance = _range <=1 ? _radius + _radius * value:_radius + _range * value;
			
			if(_type.indexOf("glow"))
				alpha = _minAlpha + _range * value;
			
			var spatial:Spatial = node.entity.get(Spatial);
			
			display.filters = [new DropShadowFilter(radiance, spatial.scaleX > 0? -45:-135, _color, alpha, 8,8)];
		}
		
		public var _partType:String;
		public var _type:String = "default";
		public var _radius:Number = 5;
		public var _color:Number = 0xFFFFFF;
		public var _speed:Number = 1;
		public var _range:Number = 1;
		public var _minAlpha:Number = 1;
		
		private var display:MovieClip;
		private var wave:Number = 0;
	}
}
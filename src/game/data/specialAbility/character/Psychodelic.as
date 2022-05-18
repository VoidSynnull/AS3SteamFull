package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.specialAbility.ColorChanger;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.specialAbility.character.ColorChangeSystem;
	import game.util.EntityUtils;

	public class Psychodelic extends MaskedPartContent
	{
		public var _psychoName:String;
		public var _colors:Array;
		public var _changeTime:Number;
		
		public function Psychodelic()
		{
			super();
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			super.activate(node);
			var psychoContainer:DisplayObjectContainer = container[_psychoName];
			var entity:Entity = EntityUtils.createSpatialEntity(node.entity.group, psychoContainer);
			if(isNaN(_changeTime))
				_changeTime = 2;
			entity.add(new ColorChanger(_colors, _changeTime));
			
			if(node.entity.group.getSystem(ColorChangeSystem) == null)
				node.entity.group.addSystem(new ColorChangeSystem());
		}
	}
}